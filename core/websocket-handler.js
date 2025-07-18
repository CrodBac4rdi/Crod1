/**
 * Clean WebSocket Handler
 * ONE message format, consistent responses
 */

const UnifiedResponse = require('./unified-response');
const EventSourcingSystem = require('./event-sourcing');

class WebSocketHandler {
    constructor(brain) {
        this.brain = brain;
        this.unifiedResponse = new UnifiedResponse();
        this.eventSystem = new EventSourcingSystem();
        this.connections = new Map();
        
        // Subscribe brain to event system
        this.brain.eventSystem = this.eventSystem;
    }
    
    /**
     * Handle incoming WebSocket message
     * @param {WebSocket} client - The client connection
     * @param {Object} message - Incoming message
     */
    async handleMessage(client, message) {
        const clientId = this.getClientId(client);
        
        try {
            // Parse message
            const data = typeof message === 'string' ? JSON.parse(message) : message;
            
            // Log input event
            this.eventSystem.addEvent(
                this.eventSystem.eventTypes.INPUT_RECEIVED,
                { input: data, clientId },
                'CLIENT'
            );
            
            // Route to handler
            const result = await this.routeMessage(data, client);
            
            // Send unified response
            this.sendResponse(client, data.type, result);
            
        } catch (error) {
            this.sendError(client, error);
        }
    }
    
    /**
     * Route message to appropriate handler
     * @param {Object} data - Message data
     * @param {WebSocket} client - Client connection
     * @returns {Object} Handler result
     */
    async routeMessage(data, client) {
        const { type, ...params } = data;
        
        // All handlers return data for unified response
        switch (type) {
            case 'process':
                return await this.handleProcess(params);
                
            case 'state':
                return await this.handleState();
                
            case 'subscribe':
                return await this.handleSubscribe(client, params);
                
            case 'history':
                return await this.handleHistory(params);
                
            case 'delta':
                return await this.handleDelta(params);
                
            default:
                throw new Error(`Unknown message type: ${type}`);
        }
    }
    
    /**
     * Handle process request
     * @param {Object} params - Request parameters
     * @returns {Object} Process result
     */
    async handleProcess(params) {
        const { input } = params;
        
        // Process through brain
        const result = await this.brain.process(input);
        
        // Return data for unified response
        return {
            message: result.message,
            confidence: result.confidence,
            patterns: result.patterns || [],
            vibe: result.vibe || this.brain.vibeSystem.detectVibe(input).category,
            processing: {
                time: result.processingTime,
                type: 'process'
            }
        };
    }
    
    /**
     * Handle state request
     * @returns {Object} State data
     */
    async handleState() {
        const brainState = this.brain.getState();
        const eventState = this.eventSystem.getCurrentState();
        
        return {
            message: `CROD State: ${brainState.initialized ? 'Active' : 'Offline'}`,
            confidence: brainState.confidence,
            patterns: [],
            vibe: eventState.currentVibe || 'neutral',
            processing: {
                type: 'state',
                brainState,
                eventState,
                eventCount: this.eventSystem.events.length
            }
        };
    }
    
    /**
     * Handle subscribe request
     * @param {WebSocket} client - Client to subscribe
     * @param {Object} params - Subscribe parameters
     * @returns {Object} Subscribe result
     */
    async handleSubscribe(client, params) {
        const clientId = this.getClientId(client);
        const { events = ['all'] } = params;
        
        // Set up subscription
        const unsubscribe = this.eventSystem.subscribe((event) => {
            if (events.includes('all') || events.includes(event.type)) {
                this.sendDelta(client, event);
            }
        });
        
        // Store subscription
        this.connections.set(clientId, {
            client,
            subscription: unsubscribe,
            subscribedEvents: events
        });
        
        return {
            message: `Subscribed to events: ${events.join(', ')}`,
            confidence: 1.0,
            patterns: [],
            vibe: 'neutral',
            processing: {
                type: 'subscribe',
                clientId,
                events
            }
        };
    }
    
    /**
     * Handle history request
     * @param {Object} params - History parameters
     * @returns {Object} History data
     */
    async handleHistory(params) {
        const { from, to, limit = 100 } = params;
        
        const events = this.eventSystem.getEventsInRange(
            from || Date.now() - 3600000, // Default: last hour
            to || Date.now()
        ).slice(-limit);
        
        return {
            message: `Found ${events.length} events`,
            confidence: 1.0,
            patterns: [],
            vibe: 'neutral',
            processing: {
                type: 'history',
                events: events.map(e => ({
                    id: e.id,
                    type: e.type,
                    actor: e.actor,
                    timestamp: e.timestamp
                })),
                totalEvents: this.eventSystem.events.length
            }
        };
    }
    
    /**
     * Handle delta request
     * @param {Object} params - Delta parameters
     * @returns {Object} Delta data
     */
    async handleDelta(params) {
        const { from, to } = params;
        
        if (!from) {
            throw new Error('Delta requires "from" timestamp');
        }
        
        const delta = this.eventSystem.getDelta(from, to);
        
        return {
            message: `Delta: ${delta.eventCount} events, ${Object.keys(delta.changes).length} changes`,
            confidence: 1.0,
            patterns: [],
            vibe: 'neutral',
            processing: {
                type: 'delta',
                delta
            }
        };
    }
    
    /**
     * Send unified response
     * @param {WebSocket} client - Client connection
     * @param {string} requestType - Original request type
     * @param {Object} data - Response data
     */
    sendResponse(client, requestType, data) {
        const response = this.unifiedResponse.create({
            ...data,
            processing: {
                ...data.processing,
                type: requestType
            }
        });
        
        client.send(JSON.stringify(response));
    }
    
    /**
     * Send error response
     * @param {WebSocket} client - Client connection
     * @param {Error} error - The error
     */
    sendError(client, error) {
        const response = this.unifiedResponse.create({
            message: error.message,
            confidence: 0,
            patterns: [],
            vibe: 'error',
            processing: {
                type: 'error',
                error: true
            }
        });
        
        client.send(JSON.stringify(response));
    }
    
    /**
     * Send delta update to subscribed client
     * @param {WebSocket} client - Client connection
     * @param {Object} event - The event
     */
    sendDelta(client, event) {
        // Delta updates are minimal
        const delta = {
            type: 'delta_update',
            event: {
                id: event.id,
                type: event.type,
                timestamp: event.timestamp
            },
            changes: this.calculateChanges(event),
            state_hash: this.hashState()
        };
        
        client.send(JSON.stringify(delta));
    }
    
    /**
     * Calculate changes from event
     * @param {Object} event - The event
     * @returns {Object} Changes object
     */
    calculateChanges(event) {
        const changes = {};
        
        switch (event.type) {
            case 'CONFIDENCE_CHANGED':
                changes.confidence = {
                    old: event.data.oldConfidence,
                    new: event.data.newConfidence
                };
                break;
                
            case 'VIBE_DETECTED':
                changes.vibe = event.data.vibe;
                break;
                
            case 'PATTERNS_MATCHED':
                changes.patterns = {
                    count: event.data.patterns.length,
                    new: event.data.patterns.slice(0, 3)
                };
                break;
        }
        
        return changes;
    }
    
    /**
     * Get or create client ID
     * @param {WebSocket} client - Client connection
     * @returns {string} Client ID
     */
    getClientId(client) {
        if (!client._crodId) {
            client._crodId = `client_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        }
        return client._crodId;
    }
    
    /**
     * Hash current state for comparison
     * @returns {string} State hash
     */
    hashState() {
        const state = this.eventSystem.getCurrentState();
        const stateString = JSON.stringify({
            confidence: state.confidence,
            vibe: state.currentVibe,
            eventCount: this.eventSystem.events.length
        });
        
        // Simple hash
        let hash = 0;
        for (let i = 0; i < stateString.length; i++) {
            const char = stateString.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash;
        }
        return hash.toString(36);
    }
    
    /**
     * Clean up client connection
     * @param {WebSocket} client - Client connection
     */
    handleDisconnect(client) {
        const clientId = this.getClientId(client);
        const connection = this.connections.get(clientId);
        
        if (connection && connection.subscription) {
            connection.subscription(); // Unsubscribe
        }
        
        this.connections.delete(clientId);
    }
}

module.exports = WebSocketHandler;