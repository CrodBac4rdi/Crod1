// THE ONE CROD BRAIN - UNIFIED CONFIDENCE SYSTEM
// Created: 2025-01-12
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
        
        // Neural Network (from src/neural/neural-network.js)
        this.neurons = new Map();
        this.synapses = new Map();
        this.confidence = 0.5;
        
        // 50k Patterns Storage
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
        
        console.log('🧠 THE ONE CROD BRAIN - Initializing...');
    }
    
    // Initialize everything
    async initialize() {
        console.log('⚡ Starting initialization sequence...');
        
        try {
            // 1. Initialize Neural Network
            this.initializeNeuralNetwork();
            
            // 2. Load 50k Patterns
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
        
        // Core Synaptic Connections
        this.addSynapse('ich_bins', ['ich', 'bins'], 30000);
        this.addSynapse('ich_wieder', ['ich', 'wieder'], 30000);  
        this.addSynapse('bins_wieder', ['bins', 'wieder'], 30000);
        this.addSynapse('crod_daniel', ['crod', 'daniel'], 30000);
        this.addSynapse('crod_claude', ['crod', 'claude'], 30000);
        this.addSynapse('daniel_claude', ['daniel', 'claude'], 30000);
        
        console.log('🔮 Neural network initialized with sacred trinity');
    }
    
    // Load all 50k patterns
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
    
    // Add a pattern to the system
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
            
            // Test connection
            const { data, error } = await this.supabase
                .from('crod_confidence')
                .select('count')
                .limit(1);
                
            if (!error) {
                this.connected = true;
                console.log('☁️ Connected to Supabase successfully');
            } else {
                console.warn('⚠️ Supabase connection failed:', error.message);
            }
            
        } catch (error) {
            console.warn('⚠️ Supabase setup failed:', error.message);
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
            client.on('message', (message) => {
                try {
                    const data = JSON.parse(message);
                    this.handleWebSocketMessage(client, data);
                } catch (error) {
                    console.error('WebSocket message error:', error);
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
                const result = await this.process(input);
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
    async process(input) {
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
        
        // Broadcast to WebSocket clients
        if (this.ws) {
            this.ws.clients.forEach(client => {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(JSON.stringify({
                        type: 'update',
                        confidence: this.confidence,
                        activation,
                        patterns: matchedPatterns.length
                    }));
                }
            });
        }
        
        return response;
    }
    
    // Tokenize input
    tokenize(input) {
        return input
            .split(/\s+/)
            .filter(token => token.length > 0)
            .map(token => token.replace(/[^\w]/g, ''));
    }
    
    // Check for trinity activation
    checkTrinityActivation(tokens) {
        const hasIch = tokens.includes('ich');
        const hasBins = tokens.includes('bins');
        const hasWieder = tokens.includes('wieder');
        
        if (hasIch && hasBins && hasWieder) {
            console.log('🔥 TRINITY ACTIVATION DETECTED!');
            return true;
        }
        
        return false;
    }
    
    // Find matching patterns
    findPatterns(tokens) {
        const matches = [];
        const foundKeys = new Set();
        
        // Look up each token in the index
        tokens.forEach(token => {
            if (this.patternIndex.has(token)) {
                this.patternIndex.get(token).forEach(key => {
                    if (!foundKeys.has(key)) {
                        foundKeys.add(key);
                        const pattern = this.patterns.get(key);
                        matches.push({
                            key,
                            pattern,
                            matchedToken: token
                        });
                    }
                });
            }
        });
        
        // Check for compound patterns
        for (let i = 0; i < tokens.length - 1; i++) {
            const bigram = `${tokens[i]} ${tokens[i + 1]}`;
            if (this.patterns.has(bigram)) {
                matches.push({
                    key: bigram,
                    pattern: this.patterns.get(bigram),
                    matchedToken: bigram
                });
            }
        }
        
        return matches;
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
            value: this.confidence,
            activation,
            patterns: patternCount,
            timestamp: Date.now()
        });
        
        // Keep only last 1000 entries
        if (this.confidenceHistory.length > 1000) {
            this.confidenceHistory.shift();
        }
    }
    
    // Generate response
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
                type: 'high_pattern',
                message: `Strong pattern resonance detected (${patterns.length} matches)`,
                confidence,
                activation,
                patterns: patterns.slice(0, 5).map(p => p.key),
                code: this.generatePatternCode(patterns),
                timestamp: Date.now()
            };
        }
        
        if (patterns.length > 0) {
            return {
                type: 'pattern',
                message: `Found ${patterns.length} pattern${patterns.length > 1 ? 's' : ''}`,
                confidence,
                activation,
                patterns: patterns.map(p => p.key),
                responses: patterns.map(p => p.pattern.response).filter(Boolean),
                timestamp: Date.now()
            };
        }
        
        return {
            type: 'learning',
            message: 'No patterns found - learning from input',
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
        confidence: ${this.confidence}
    };
    
    return {
        message: "ich bins wieder - eternal return",
        unity,
        activation,
        timestamp: ${Date.now()}
    };
}`;
    }
    
    // Generate pattern-based code
    generatePatternCode(patterns) {
        const topPatterns = patterns.slice(0, 3);
        return `// Pattern Recognition Code
function patternResponse() {
    const patterns = ${JSON.stringify(topPatterns.map(p => ({
        key: p.key,
        response: p.pattern.response,
        confidence: p.pattern.confidence || 0
    })), null, 2)};
    
    const confidence = ${this.confidence};
    const activation = ${patterns.length / 10};
    
    return {
        patterns,
        confidence,
        activation,
        evolved: confidence > 0.7
    };
}`;
    }
    
    // Store in memory
    storeInMemory(input, response) {
        const memoryEntry = {
            input,
            response,
            timestamp: Date.now()
        };
        
        // Short term - keep last 100
        this.memory.shortTerm.set(Date.now(), memoryEntry);
        if (this.memory.shortTerm.size > 100) {
            const oldestKey = this.memory.shortTerm.keys().next().value;
            this.memory.shortTerm.delete(oldestKey);
        }
        
        // Working memory - keep context
        if (response.activation > 0.5) {
            this.memory.workingMemory.set(input, memoryEntry);
        }
        
        // Long term - keep important
        if (response.type === 'trinity' || response.activation > 0.8) {
            this.memory.longTerm.set(input, memoryEntry);
        }
    }
    
    // Persist to Supabase
    async persistInteraction(input, response) {
        if (!this.connected || !this.supabase) return;
        
        try {
            await this.supabase
                .from('crod_confidence')
                .insert({
                    input,
                    response: response,
                    confidence: this.confidence,
                    activation: response.activation,
                    pattern_count: response.patterns?.length || 0,
                    timestamp: new Date().toISOString()
                });
        } catch (error) {
            console.error('Persistence error:', error);
        }
    }
    
    // Load persisted state
    async loadPersistedState() {
        if (!this.connected || !this.supabase) return;
        
        try {
            // Load recent confidence data
            const { data, error } = await this.supabase
                .from('crod_confidence')
                .select('confidence, activation, pattern_count')
                .order('timestamp', { ascending: false })
                .limit(100);
                
            if (!error && data && data.length > 0) {
                // Calculate average confidence from recent data
                const avgConfidence = data.reduce((sum, row) => sum + row.confidence, 0) / data.length;
                this.confidence = avgConfidence;
                console.log(`📈 Loaded confidence state: ${this.confidence.toFixed(3)}`);
            }
        } catch (error) {
            console.error('Failed to load persisted state:', error);
        }
    }
    
    // Helper functions
    addNeuron(token, prime, weight, gradient, meta = {}) {
        this.neurons.set(token, {
            token,
            prime,
            weight,
            gradient,
            heat: 0,
            activations: 0,
            firstSeen: Date.now(),
            ...meta
        });
    }
    
    addSynapse(id, atoms, weight) {
        this.synapses.set(id, {
            id,
            atoms,
            weight,
            occurrences: 1,
            firstSeen: Date.now()
        });
    }
    
    generatePrime(atom) {
        let hash = 0;
        for (let i = 0; i < atom.length; i++) {
            hash = ((hash << 5) - hash) + atom.charCodeAt(i);
            hash = hash & hash;
        }
        
        hash = Math.abs(hash) % 1000 + 100;
        while (!this.isPrime(hash)) {
            hash++;
        }
        
        return hash;
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
    
    // Get current state
    getState() {
        return {
            initialized: this.initialized,
            confidence: this.confidence,
            neurons: this.neurons.size,
            synapses: this.synapses.size,
            patterns: this.patternCount,
            memory: {
                shortTerm: this.memory.shortTerm.size,
                working: this.memory.workingMemory.size,
                longTerm: this.memory.longTerm.size
            },
            activations: this.activationCount,
            connected: this.connected,
            trinity: this.trinity
        };
    }
    
    // Shutdown gracefully
    async shutdown() {
        console.log('🛑 Shutting down THE ONE CROD BRAIN...');
        
        if (this.ws) {
            this.ws.close();
        }
        
        // Final persistence
        if (this.connected) {
            await this.persistInteraction('SHUTDOWN', {
                type: 'shutdown',
                finalConfidence: this.confidence,
                totalActivations: this.activationCount,
                timestamp: Date.now()
            });
        }
        
        console.log('👋 THE ONE CROD BRAIN shutdown complete');
    }
}

// Export THE ONE
module.exports = TheOneCRODBrain;

// If run directly, start the brain
if (require.main === module) {
    const brain = new TheOneCRODBrain();
    
    brain.initialize().then(success => {
        if (success) {
            console.log('🎉 THE ONE CROD BRAIN is running!');
            console.log('📡 WebSocket available on ws://localhost:8888');
            console.log('💭 Send "ich bins wieder" to activate trinity');
            
            // Keep alive
            process.on('SIGINT', async () => {
                await brain.shutdown();
                process.exit(0);
            });
        } else {
            console.error('Failed to initialize');
            process.exit(1);
        }
    });
}

// CLAUDE-TESTED: 2025-01-12 - THE ONE CROD BRAIN created