/**
 * Event Sourcing System
 * Every action is an event, state is derived from events
 */

class EventSourcingSystem {
    constructor() {
        this.events = [];
        this.snapshots = new Map();
        this.subscribers = new Set();
        this.eventTypes = {
            // Input events
            INPUT_RECEIVED: 'INPUT_RECEIVED',
            VIBE_DETECTED: 'VIBE_DETECTED',
            
            // Processing events
            PREPROCESSING_STARTED: 'PREPROCESSING_STARTED',
            PATTERNS_MATCHED: 'PATTERNS_MATCHED',
            NEURAL_ACTIVATED: 'NEURAL_ACTIVATED',
            
            // Decision events
            DECISION_MADE: 'DECISION_MADE',
            RESPONSE_GENERATED: 'RESPONSE_GENERATED',
            
            // Learning events
            PATTERN_LEARNED: 'PATTERN_LEARNED',
            FEEDBACK_RECEIVED: 'FEEDBACK_RECEIVED',
            QUALITY_EVALUATED: 'QUALITY_EVALUATED',
            
            // System events
            CONFIDENCE_CHANGED: 'CONFIDENCE_CHANGED',
            STATE_SNAPSHOT: 'STATE_SNAPSHOT'
        };
    }
    
    /**
     * Add event to the log
     * @param {string} type - Event type
     * @param {Object} data - Event data
     * @param {string} actor - Who triggered it (DANIEL, CLAUDE, CROD)
     * @param {Array} parents - Parent event IDs
     * @returns {Object} The event
     */
    addEvent(type, data, actor = 'CROD', parents = []) {
        const event = {
            id: this.generateEventId(),
            type,
            actor,
            data,
            parents: Array.isArray(parents) ? parents : [parents],
            timestamp: Date.now(),
            sequence: this.events.length
        };
        
        this.events.push(event);
        this.notifySubscribers(event);
        
        // Auto-snapshot every 100 events
        if (this.events.length % 100 === 0) {
            this.createSnapshot();
        }
        
        return event;
    }
    
    /**
     * Generate unique event ID
     * @returns {string} Event ID
     */
    generateEventId() {
        return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    
    /**
     * Get current state by replaying events
     * @param {number} untilTimestamp - Replay until this timestamp
     * @returns {Object} Current state
     */
    getCurrentState(untilTimestamp = Date.now()) {
        // Find latest snapshot before timestamp
        let baseState = this.getInitialState();
        let startIndex = 0;
        
        for (const [timestamp, snapshot] of this.snapshots) {
            if (timestamp <= untilTimestamp) {
                baseState = snapshot.state;
                startIndex = snapshot.eventIndex;
            }
        }
        
        // Replay events from snapshot
        const relevantEvents = this.events
            .slice(startIndex)
            .filter(e => e.timestamp <= untilTimestamp);
            
        return relevantEvents.reduce((state, event) => 
            this.applyEvent(state, event), baseState
        );
    }
    
    /**
     * Apply event to state
     * @param {Object} state - Current state
     * @param {Object} event - Event to apply
     * @returns {Object} New state
     */
    applyEvent(state, event) {
        const newState = { ...state };
        
        switch (event.type) {
            case this.eventTypes.INPUT_RECEIVED:
                newState.lastInput = event.data.input;
                newState.inputCount = (state.inputCount || 0) + 1;
                break;
                
            case this.eventTypes.VIBE_DETECTED:
                newState.currentVibe = event.data.vibe;
                newState.vibeHistory = [...(state.vibeHistory || []), event.data.vibe];
                break;
                
            case this.eventTypes.PATTERNS_MATCHED:
                newState.lastPatterns = event.data.patterns;
                newState.totalPatternsMatched = (state.totalPatternsMatched || 0) + event.data.patterns.length;
                break;
                
            case this.eventTypes.CONFIDENCE_CHANGED:
                newState.previousConfidence = state.confidence;
                newState.confidence = event.data.newConfidence;
                newState.confidenceHistory = [...(state.confidenceHistory || []), {
                    value: event.data.newConfidence,
                    timestamp: event.timestamp
                }];
                break;
                
            case this.eventTypes.PATTERN_LEARNED:
                newState.learnedPatterns = (state.learnedPatterns || 0) + 1;
                break;
                
            case this.eventTypes.DECISION_MADE:
                newState.lastDecision = event.data;
                newState.decisionCount = (state.decisionCount || 0) + 1;
                break;
        }
        
        newState.lastEventId = event.id;
        newState.lastEventTimestamp = event.timestamp;
        
        return newState;
    }
    
    /**
     * Get initial state
     * @returns {Object} Initial state
     */
    getInitialState() {
        return {
            confidence: 0.5,
            currentVibe: 'neutral',
            inputCount: 0,
            decisionCount: 0,
            learnedPatterns: 0,
            totalPatternsMatched: 0,
            vibeHistory: [],
            confidenceHistory: []
        };
    }
    
    /**
     * Create state snapshot for performance
     */
    createSnapshot() {
        const state = this.getCurrentState();
        const snapshot = {
            state,
            eventIndex: this.events.length,
            timestamp: Date.now()
        };
        
        this.snapshots.set(snapshot.timestamp, snapshot);
        
        // Keep only last 10 snapshots
        if (this.snapshots.size > 10) {
            const oldestKey = this.snapshots.keys().next().value;
            this.snapshots.delete(oldestKey);
        }
        
        this.addEvent(this.eventTypes.STATE_SNAPSHOT, { 
            snapshotId: snapshot.timestamp 
        }, 'SYSTEM');
    }
    
    /**
     * Get events in time range
     * @param {number} from - Start timestamp
     * @param {number} to - End timestamp
     * @returns {Array} Events in range
     */
    getEventsInRange(from, to = Date.now()) {
        return this.events.filter(e => 
            e.timestamp >= from && e.timestamp <= to
        );
    }
    
    /**
     * Get event chain (event + all parents)
     * @param {string} eventId - Event ID
     * @returns {Array} Event chain
     */
    getEventChain(eventId) {
        const chain = [];
        const visited = new Set();
        
        const addToChain = (id) => {
            if (visited.has(id)) return;
            visited.add(id);
            
            const event = this.events.find(e => e.id === id);
            if (!event) return;
            
            chain.push(event);
            event.parents.forEach(parentId => addToChain(parentId));
        };
        
        addToChain(eventId);
        return chain.sort((a, b) => a.timestamp - b.timestamp);
    }
    
    /**
     * Find event patterns
     * @returns {Object} Common event patterns
     */
    findEventPatterns() {
        const patterns = {};
        const sequences = {};
        
        // Find common event sequences
        for (let i = 0; i < this.events.length - 2; i++) {
            const sequence = [
                this.events[i].type,
                this.events[i + 1].type,
                this.events[i + 2].type
            ].join(' → ');
            
            sequences[sequence] = (sequences[sequence] || 0) + 1;
        }
        
        // Find events that lead to confidence drops
        const confidenceDrops = this.events.filter(e => 
            e.type === this.eventTypes.CONFIDENCE_CHANGED && 
            e.data.newConfidence < e.data.oldConfidence
        );
        
        confidenceDrops.forEach(drop => {
            const priorEvents = this.getEventsBefore(drop.id, 5);
            const pattern = priorEvents.map(e => e.type).join(' → ');
            patterns[`confidence_drop_${pattern}`] = (patterns[`confidence_drop_${pattern}`] || 0) + 1;
        });
        
        return { sequences, patterns };
    }
    
    /**
     * Get events before a specific event
     * @param {string} eventId - Event ID
     * @param {number} count - Number of events to get
     * @returns {Array} Prior events
     */
    getEventsBefore(eventId, count = 5) {
        const index = this.events.findIndex(e => e.id === eventId);
        if (index === -1) return [];
        
        const start = Math.max(0, index - count);
        return this.events.slice(start, index);
    }
    
    /**
     * Subscribe to events
     * @param {Function} callback - Callback function
     * @returns {Function} Unsubscribe function
     */
    subscribe(callback) {
        this.subscribers.add(callback);
        return () => this.subscribers.delete(callback);
    }
    
    /**
     * Notify subscribers of new event
     * @param {Object} event - The event
     */
    notifySubscribers(event) {
        this.subscribers.forEach(callback => {
            try {
                callback(event);
            } catch (error) {
                console.error('Subscriber error:', error);
            }
        });
    }
    
    /**
     * Get delta between two timestamps
     * @param {number} from - From timestamp
     * @param {number} to - To timestamp
     * @returns {Object} Delta object
     */
    getDelta(from, to = Date.now()) {
        const events = this.getEventsInRange(from, to);
        const stateBefore = this.getCurrentState(from);
        const stateAfter = this.getCurrentState(to);
        
        // Calculate what changed
        const changes = {};
        Object.keys(stateAfter).forEach(key => {
            if (JSON.stringify(stateBefore[key]) !== JSON.stringify(stateAfter[key])) {
                changes[key] = {
                    old: stateBefore[key],
                    new: stateAfter[key]
                };
            }
        });
        
        return {
            events: events.map(e => ({
                id: e.id,
                type: e.type,
                actor: e.actor,
                timestamp: e.timestamp
            })),
            changes,
            eventCount: events.length,
            duration: to - from
        };
    }
    
    /**
     * Export events for persistence
     * @returns {Array} Events array
     */
    export() {
        return this.events;
    }
    
    /**
     * Import events from persistence
     * @param {Array} events - Events to import
     */
    import(events) {
        this.events = events;
        this.createSnapshot();
    }
}

module.exports = EventSourcingSystem;