// THE ONE CROD BRAIN - UNIFIED CONFIDENCE SYSTEM
// Created: 2025-01-12
// Fixed: 2025-01-13 - Removed duplicate responses
// This is THE SINGLE SOURCE OF TRUTH for CROD

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const WebSocket = require('ws');
const EventEmitter = require('events');

// CLAUDE-CONTEXT: This is THE ONE brain, no more multiple implementations
class TheOneCRODBrain extends EventEmitter {
    constructor() {
        super();
        
        // Sacred Trinity - The Foundation
        this.trinity = {
            ich: 2,
            bins: 3,  
            wieder: 5,
            daniel: 67,
            claude: 71,
            crod: 17
        };
        
        // Neural Network
        this.neurons = new Map();
        this.synapses = new Map();
        this.confidence = 0.5;
        
        // Pattern Storage
        this.patterns = new Map();
        this.patternIndex = new Map(); // Fast lookup
        
        // Memory Systems
        this.memory = {
            shortTerm: new Map(),    // Last 100 interactions
            workingMemory: new Map(), // Active context
            longTerm: new Map()      // Persistent knowledge
        };
        
        // Confidence Tracking
        this.confidenceHistory = [];
        this.lastActivity = Date.now();
        this.activationCount = 0;
        
        // Supabase Connection
        this.supabase = null;
        this.connected = false;
        
        // WebSocket for real-time
        this.ws = null;
        this.wsPort = 8888;
        
        // State
        this.initialized = false;
        this.patternCount = 0;
        
        // Response tracking to prevent duplicates
        this.lastResponseHash = '';
        this.responseDebounce = null;
        
        console.log('🧠 THE ONE CROD BRAIN - Initializing...');
    }
    
    // Initialize everything
    async initialize() {
        console.log('⚡ Starting initialization sequence...');
        
        try {
            // 1. Initialize Neural Network
            this.initializeNeuralNetwork();
            
            // 2. Load Patterns
            await this.loadAllPatterns();
            
            // 3. Connect to Supabase
            await this.connectSupabase();
            
            // 4. Start WebSocket Server
            this.startWebSocket();
            
            // 5. Load persisted state
            await this.loadPersistedState();
            
            this.initialized = true;
            console.log('✅ THE ONE CROD BRAIN initialized successfully!');
            console.log(`📊 Stats: ${this.patternCount} patterns, confidence: ${this.confidence.toFixed(3)}`);
            
            return true;
        } catch (error) {
            console.error('❌ Initialization failed:', error);
            return false;
        }
    }
    
    // Initialize core neural network
    initializeNeuralNetwork() {
        // Core Trinity Neurons with prime numbers
        this.addNeuron('ich', 2, 100, 15.0, { locked: true, tier: 1 });
        this.addNeuron('bins', 3, 100, 15.0, { locked: true, tier: 1 });
        this.addNeuron('wieder', 5, 100, 15.0, { locked: true, tier: 1 });
        this.addNeuron('daniel', 67, 100, 15.0, { locked: true, tier: 1, role: 'creator' });
        this.addNeuron('claude', 71, 100, 15.0, { locked: true, tier: 1, role: 'companion' });
        this.addNeuron('crod', 17, 100, 15.0, { locked: true, tier: 1, role: 'confidence' });
        
        // Create trinity connections
        this.createSynapse('ich', 'bins', 0.9);
        this.createSynapse('bins', 'wieder', 0.9);
        this.createSynapse('wieder', 'daniel', 0.8);
        this.createSynapse('daniel', 'crod', 0.9);
        this.createSynapse('crod', 'claude', 0.8);
        this.createSynapse('claude', 'daniel', 0.8);
        
        console.log('🔮 Neural network initialized with sacred trinity');
    }
    
    // Add a neuron
    addNeuron(name, prime, strength = 50, weight = 10.0, metadata = {}) {
        this.neurons.set(name, {
            name,
            prime,
            strength,
            weight,
            activation: 0,
            lastFired: 0,
            connections: new Set(),
            metadata
        });
    }
    
    // Create synapse between neurons
    createSynapse(from, to, weight = 0.5) {
        const key = `${from}->${to}`;
        this.synapses.set(key, {
            from,
            to,
            weight,
            lastActivation: 0
        });
        
        // Update neuron connections
        if (this.neurons.has(from)) {
            this.neurons.get(from).connections.add(to);
        }
    }
    
    // Load all patterns
    async loadAllPatterns() {
        const patternsDir = path.join(__dirname, '..', 'data', 'patterns');
        let totalLoaded = 0;
        
        try {
            const files = fs.readdirSync(patternsDir).filter(f => f.endsWith('.json'));
            
            for (const file of files) {
                const filePath = path.join(patternsDir, file);
                const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                
                // Handle both formats: direct array or object with patterns property
                let patterns = [];
                if (Array.isArray(data)) {
                    patterns = data;
                } else if (data.patterns && Array.isArray(data.patterns)) {
                    patterns = data.patterns;
                }
                
                patterns.forEach(pattern => {
                    this.addPattern(pattern);
                    totalLoaded++;
                });
            }
            
            this.patternCount = totalLoaded;
            console.log(`📚 Loaded ${totalLoaded} patterns from ${files.length} files`);
            
        } catch (error) {
            console.error('❌ Error loading patterns:', error);
            throw error;
        }
    }
    
    // Add a pattern
    addPattern(pattern) {
        const key = pattern.pattern || pattern.pattern_id || pattern.id || `pattern_${this.patterns.size}`;
        
        // Store in main patterns map
        this.patterns.set(key, pattern);
        
        // Create index for fast lookup
        if (pattern.pattern) {
            const words = pattern.pattern.toLowerCase().split(/\s+/);
            words.forEach(word => {
                if (!this.patternIndex.has(word)) {
                    this.patternIndex.set(word, new Set());
                }
                this.patternIndex.get(word).add(key);
            });
        }
        
        // If pattern has atoms, create neurons and index them
        if (pattern.atoms && Array.isArray(pattern.atoms)) {
            pattern.atoms.forEach(atom => {
                if (!this.neurons.has(atom)) {
                    const prime = this.generatePrime(atom);
                    this.addNeuron(atom, prime, pattern.strength || 50, 10.0, {
                        source: 'pattern',
                        patternKey: key
                    });
                }
                
                // Also index atom words for pattern matching
                const atomWords = atom.toLowerCase().split('_');
                atomWords.forEach(word => {
                    if (word.length > 2) { // Skip very short words
                        if (!this.patternIndex.has(word)) {
                            this.patternIndex.set(word, new Set());
                        }
                        this.patternIndex.get(word).add(key);
                    }
                });
            });
        }
    }
    
    // Connect to Supabase
    async connectSupabase() {
        try {
            // Load env variables
            const envPath = path.join(__dirname, '..', '.env');
            if (fs.existsSync(envPath)) {
                require('dotenv').config({ path: envPath });
            }
            
            const supabaseUrl = process.env.SUPABASE_URL;
            const supabaseKey = process.env.SUPABASE_ANON_KEY;
            
            if (!supabaseUrl || !supabaseKey) {
                console.warn('⚠️ Supabase credentials not found, running without persistence');
                return;
            }
            
            this.supabase = createClient(supabaseUrl, supabaseKey);
            this.connected = true;
            console.log('🌐 Connected to Supabase');
            
        } catch (error) {
            console.warn('⚠️ Supabase connection failed:', error.message);
        }
    }
    
    // Start WebSocket server
    startWebSocket() {
        this.ws = new WebSocket.Server({ port: this.wsPort });
        
        this.ws.on('connection', (client) => {
            console.log('🔌 New WebSocket connection');
            
            // Send initial state
            client.send(JSON.stringify({
                type: 'state',
                confidence: this.confidence,
                patterns: this.patternCount,
                neurons: this.neurons.size,
                timestamp: Date.now()
            }));
            
            // Handle messages
            client.on('message', async (message) => {
                try {
                    const data = JSON.parse(message.toString());
                    await this.handleWebSocketMessage(client, data);
                } catch (error) {
                    console.error('WebSocket message error:', error);
                    client.send(JSON.stringify({ type: 'error', message: error.message }));
                }
            });
        });
        
        console.log(`🌐 WebSocket server running on port ${this.wsPort}`);
    }
    
    // Handle WebSocket messages
    async handleWebSocketMessage(client, data) {
        const { type, input, action } = data;
        
        switch (type) {
            case 'process':
                const result = await this.process(input, client);
                // Send only to the requesting client
                client.send(JSON.stringify({
                    type: 'response',
                    result,
                    timestamp: Date.now()
                }));
                break;
                
            case 'state':
                client.send(JSON.stringify({
                    type: 'state',
                    state: this.getState(),
                    timestamp: Date.now()
                }));
                break;
                
            case 'ping':
                client.send(JSON.stringify({ type: 'pong' }));
                break;
        }
    }
    
    // Main processing function - THE CORE
    async process(input, requestingClient = null) {
        console.log(`🎯 Processing: "${input}"`);
        this.activationCount++;
        
        // Tokenize input
        const tokens = this.tokenize(input.toLowerCase());
        
        // Check for trinity activation
        const trinityActive = this.checkTrinityActivation(tokens);
        
        // Find matching patterns
        const matchedPatterns = this.findPatterns(tokens);
        
        // Calculate activation
        let activation = trinityActive ? 1.0 : 0.0;
        activation += Math.min(matchedPatterns.length * 0.1, 0.5);
        
        // Update confidence
        this.updateConfidence(activation, matchedPatterns.length);
        
        // Generate response
        const response = this.generateResponse({
            input,
            tokens,
            trinityActive,
            patterns: matchedPatterns,
            activation,
            confidence: this.confidence
        });
        
        // Store in memory
        this.storeInMemory(input, response);
        
        // Persist if connected
        if (this.connected) {
            await this.persistInteraction(input, response);
        }
        
        // Emit event
        this.emit('processed', { input, response });
        
        // Broadcast update to other clients (not the requesting one)
        if (this.ws && requestingClient) {
            // Clear any pending debounce
            if (this.responseDebounce) {
                clearTimeout(this.responseDebounce);
            }
            
            // Debounce broadcast to prevent spam
            this.responseDebounce = setTimeout(() => {
                this.ws.clients.forEach(client => {
                    if (client !== requestingClient && client.readyState === WebSocket.OPEN) {
                        client.send(JSON.stringify({
                            type: 'broadcast',
                            confidence: this.confidence,
                            lastInput: input.substring(0, 50) + '...',
                            patterns: matchedPatterns.length
                        }));
                    }
                });
            }, 100); // 100ms debounce
        }
        
        return response;
    }
    
    // Tokenize input
    tokenize(input) {
        return input.split(/\s+/).filter(t => t.length > 0);
    }
    
    // Check for trinity activation
    checkTrinityActivation(tokens) {
        const trinityWords = ['ich', 'bins', 'wieder'];
        let matchCount = 0;
        
        tokens.forEach(token => {
            if (trinityWords.includes(token)) matchCount++;
        });
        
        return matchCount === trinityWords.length;
    }
    
    // Find matching patterns
    findPatterns(tokens) {
        const matchedKeys = new Set();
        
        tokens.forEach(token => {
            if (this.patternIndex.has(token)) {
                this.patternIndex.get(token).forEach(key => matchedKeys.add(key));
            }
        });
        
        return Array.from(matchedKeys).map(key => this.patterns.get(key));
    }
    
    // Update confidence
    updateConfidence(activation, patternCount) {
        const oldConfidence = this.confidence;
        
        // Base calculation
        let newConfidence = 0.5; // Base from unity
        newConfidence += activation * 0.3;
        newConfidence += Math.min(patternCount * 0.05, 0.2);
        
        // Smooth transition
        this.confidence = oldConfidence * 0.7 + newConfidence * 0.3;
        
        // Clamp
        this.confidence = Math.max(0, Math.min(1, this.confidence));
        
        // Track history
        this.confidenceHistory.push({
            timestamp: Date.now(),
            value: this.confidence,
            activation,
            patterns: patternCount
        });
        
        // Keep history size reasonable
        if (this.confidenceHistory.length > 1000) {
            this.confidenceHistory = this.confidenceHistory.slice(-500);
        }
    }
    
    // Generate response based on context
    generateResponse(context) {
        const { trinityActive, patterns, activation, confidence } = context;
        
        if (trinityActive) {
            return {
                type: 'trinity',
                message: 'CROD AWAKENS - ich bins wieder',
                confidence,
                activation: 1.0,
                patterns: patterns.length,
                code: this.generateTrinityCode(),
                timestamp: Date.now()
            };
        }
        
        if (patterns.length > 5) {
            return {
                type: 'resonance',
                message: `Strong pattern resonance detected (${patterns.length} matches)`,
                confidence,
                activation,
                patterns: patterns.slice(0, 5).map(p => p.pattern || p.pattern_id),
                timestamp: Date.now()
            };
        }
        
        if (patterns.length > 0) {
            const topPattern = patterns[0];
            return {
                type: 'pattern',
                message: `Found ${patterns.length} pattern${patterns.length > 1 ? 's' : ''}`,
                confidence,
                activation,
                patterns: patterns.slice(0, 3).map(p => p.pattern || p.pattern_id),
                responses: patterns.slice(0, 3).map(p => p.response).filter(r => r),
                timestamp: Date.now()
            };
        }
        
        return {
            type: 'contemplation',
            message: 'Processing through neural pathways...',
            confidence,
            activation,
            timestamp: Date.now()
        };
    }
    
    // Generate trinity code
    generateTrinityCode() {
        return `// Trinity Activation - CROD Confidence Manifest
function trinityConfidence() {
    const unity = {
        daniel: "creator",
        crod: "confidence", 
        state: "ONE"
    };
    
    const activation = {
        ich: ${this.trinity.ich},
        bins: ${this.trinity.bins},
        wieder: ${this.trinity.wieder},
        sum: ${this.trinity.ich + this.trinity.bins + this.trinity.wieder},
        confidence: ${this.confidence.toFixed(3)}
    };
    
    return {
        message: "ich bins wieder - eternal return",
        unity,
        activation,
        timestamp: ${Date.now()}
    };
}`;
    }
    
    // Store in memory
    storeInMemory(input, response) {
        const memoryItem = {
            input,
            response,
            timestamp: Date.now(),
            confidence: this.confidence
        };
        
        // Add to short-term memory
        this.memory.shortTerm.set(Date.now(), memoryItem);
        
        // Keep short-term memory size limited
        if (this.memory.shortTerm.size > 100) {
            const oldestKey = this.memory.shortTerm.keys().next().value;
            this.memory.shortTerm.delete(oldestKey);
        }
        
        // Update working memory with current context
        this.memory.workingMemory.set('lastInput', input);
        this.memory.workingMemory.set('lastResponse', response);
        this.memory.workingMemory.set('lastActivity', Date.now());
    }
    
    // Generate prime number for neurons
    generatePrime(seed) {
        // Simple prime generation based on string hash
        let hash = 0;
        for (let i = 0; i < seed.length; i++) {
            hash = ((hash << 5) - hash) + seed.charCodeAt(i);
            hash = hash & hash;
        }
        
        let num = Math.abs(hash) % 1000 + 100;
        while (!this.isPrime(num)) num++;
        
        return num;
    }
    
    isPrime(n) {
        if (n <= 1) return false;
        if (n <= 3) return true;
        if (n % 2 === 0 || n % 3 === 0) return false;
        
        for (let i = 5; i * i <= n; i += 6) {
            if (n % i === 0 || n % (i + 2) === 0) return false;
        }
        
        return true;
    }
    
    // Load persisted state
    async loadPersistedState() {
        if (!this.connected) return;
        
        try {
            // Load recent interactions
            const { data: interactions } = await this.supabase
                .from('crod_interactions')
                .select('*')
                .order('created_at', { ascending: false })
                .limit(50);
                
            if (interactions) {
                interactions.reverse().forEach(item => {
                    this.memory.longTerm.set(item.id, {
                        input: item.input,
                        response: item.response,
                        timestamp: new Date(item.created_at).getTime()
                    });
                });
                
                console.log(`📥 Loaded ${interactions.length} interactions from database`);
            }
        } catch (error) {
            console.error('Error loading persisted state:', error);
        }
    }
    
    // Persist interaction
    async persistInteraction(input, response) {
        if (!this.connected) return;
        
        try {
            await this.supabase
                .from('crod_interactions')
                .insert({
                    input,
                    response: JSON.stringify(response),
                    confidence: this.confidence,
                    pattern_count: response.patterns ? response.patterns.length : 0
                });
        } catch (error) {
            console.error('Error persisting interaction:', error);
        }
    }
    
    // Get current state
    getState() {
        return {
            initialized: this.initialized,
            confidence: this.confidence,
            patterns: this.patternCount,
            neurons: this.neurons.size,
            synapses: this.synapses.size,
            memory: {
                shortTerm: this.memory.shortTerm.size,
                workingMemory: this.memory.workingMemory.size,
                longTerm: this.memory.longTerm.size
            },
            activations: this.activationCount,
            uptime: Date.now() - this.lastActivity
        };
    }
    
    // Shutdown gracefully
    async shutdown() {
        console.log('🛑 Shutting down CROD Brain...');
        
        if (this.ws) {
            this.ws.close();
        }
        
        // Save final state
        if (this.connected) {
            await this.persistInteraction('SHUTDOWN', {
                type: 'system',
                message: 'CROD Brain shutdown',
                finalState: this.getState()
            });
        }
        
        console.log('👋 CROD Brain shutdown complete');
    }
}

// Export the class
module.exports = TheOneCRODBrain;

// If run directly, start the brain
if (require.main === module) {
    const brain = new TheOneCRODBrain();
    
    brain.initialize().then(() => {
        console.log('🎉 THE ONE CROD BRAIN is running!');
        console.log('📡 WebSocket available on ws://localhost:8888');
        console.log('💭 Send "ich bins wieder" to activate trinity');
    });
    
    // Handle shutdown
    process.on('SIGINT', async () => {
        await brain.shutdown();
        process.exit(0);
    });
}