// THE ONE CROD BRAIN WITH LLM - ENHANCED CONFIDENCE
// Created: 2025-01-13
// This version includes Ollama integration for intelligent responses

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const WebSocket = require('ws');
const EventEmitter = require('events');
const readline = require('readline');
require('dotenv').config();

// Import new modules
const ClaudePatternEvaluator = require('./claude-pattern-evaluator');
const VibePatternSystem = require('./vibe-pattern-system');
const ClaudeBehaviorPatterns = require('./claude-behavior-patterns');
const CRODAgentTransformer = require('./crod-agent-transformer');
const CRODChainExecutor = require('./crod-chain-executor');
const QualityPatternManager = require('./quality-patterns');
const UnifiedResponse = require('./unified-response');
const EventSourcingSystem = require('./event-sourcing');
const WebSocketHandler = require('./websocket-handler');

// Pure pattern-based neural processing - no external dependencies

// Pattern Query class for JSONL
class PatternQuery {
    constructor() {
        this.patternsPath = path.join(__dirname, '..', '..', 'elixir', 'crod-complete', 'priv', 'data', 'patterns-jsonl', 'patterns.jsonl');
        this.indexPath = path.join(__dirname, '..', '..', 'elixir', 'crod-complete', 'priv', 'data', 'patterns-jsonl', 'patterns-index.json');
        this.patterns = [];
        this.index = null;
        this.loaded = false;
    }
    
    async load() {
        if (this.loaded) return;
        
        try {
            // Load index
            this.index = JSON.parse(fs.readFileSync(this.indexPath, 'utf8'));
            
            // Load patterns line by line
            const fileStream = fs.createReadStream(this.patternsPath);
            const rl = readline.createInterface({
                input: fileStream,
                crlfDelay: Infinity
            });
            
            for await (const line of rl) {
                if (line.trim()) {
                    this.patterns.push(JSON.parse(line));
                }
            }
            
            this.loaded = true;
            console.log(`📚 Loaded ${this.patterns.length} patterns from JSONL`);
        } catch (error) {
            console.error('Error loading JSONL patterns:', error);
            // Fall back to regular patterns
            this.loaded = false;
        }
    }
    
    findBySequence(words) {
        const results = [];
        
        this.patterns.forEach(pattern => {
            if (!pattern.pattern) return;
            
            const patternWords = pattern.pattern.toLowerCase().split(/\s+/);
            let matchCount = 0;
            
            words.forEach(word => {
                if (patternWords.includes(word.toLowerCase())) {
                    matchCount++;
                }
            });
            
            if (matchCount > 0) {
                results.push({
                    ...pattern,
                    matchScore: matchCount / Math.max(words.length, patternWords.length)
                });
            }
        });
        
        return results.sort((a, b) => b.matchScore - a.matchScore);
    }
}

// Enhanced CROD Brain with LLM
class TheOneCRODBrainLLM extends EventEmitter {
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
        this.patternIndex = new Map();
        this.pendingPatterns = new Map(); // Patterns waiting for Daniel validation
        
        // JSONL Pattern Query
        this.patternQuery = new PatternQuery();
        
        // Memory Systems
        this.memory = {
            shortTerm: new Map(),    // Last 100 interactions
            workingMemory: new Map(), // Active context
            longTerm: new Map(),     // Persistent knowledge
            episodic: []            // Conversation episodes
        };
        
        // Pure pattern-based processing - no external LLM needed
        
        // Decision tracking
        this.decisions = [];
        
        // Confidence Tracking
        this.confidenceHistory = [];
        this.lastActivity = Date.now();
        this.activationCount = 0;
        
        // WebSocket
        this.ws = null;
        this.wsPort = process.env.CROD_WS_PORT || 8890;
        
        // State
        this.initialized = false;
        this.patternCount = 0;
        
        // Response tracking
        this.responseDebounce = null;
        
        // Supabase connection
        this.supabase = null;
        this.supabaseConnected = false;
        
        // Advanced Claude optimization systems
        this.patternEvaluator = new ClaudePatternEvaluator();
        this.vibeSystem = new VibePatternSystem();
        this.behaviorPatterns = new ClaudeBehaviorPatterns();
        this.agentTransformer = new CRODAgentTransformer();
        this.chainExecutor = new CRODChainExecutor();
        
        // New unified systems
        this.qualityPatterns = new QualityPatternManager();
        this.unifiedResponse = new UnifiedResponse();
        this.eventSystem = new EventSourcingSystem();
        this.wsHandler = null; // Will be set when WS starts
        
        console.log('🧠 THE ONE CROD BRAIN WITH UNIFIED ARCHITECTURE - Initializing...');
    }
    
    async initialize() {
        console.log('⚡ Starting enhanced initialization...');
        
        try {
            // 1. Initialize Neural Network
            this.initializeNeuralNetwork();
            
            // 2. Skip loading garbage patterns
            // await this.patternQuery.load();  // NOPE! Daniel said these are bullshit
            this.patternCount = 0;  // Start fresh with ONLY good patterns!
            
            // 3. Pattern-based processing ready
            console.log('🧠 Pattern-based neural processing active');
            
            // 4. Connect to Supabase
            await this.connectSupabase();
            
            // 5. Start WebSocket Server
            this.startWebSocket();
            
            // 6. Load persisted state
            await this.loadPersistedState();
            
            this.initialized = true;
            console.log('✅ THE ONE CROD BRAIN WITH LLM initialized!');
            console.log(`📊 Stats: ${this.patternCount} patterns, Supabase: ${this.supabaseConnected ? 'connected' : 'offline'}`);
            
            return true;
        } catch (error) {
            console.error('❌ Initialization failed:', error);
            return false;
        }
    }
    
    // Initialize core neural network
    initializeNeuralNetwork() {
        // Core Trinity Neurons
        this.addNeuron('ich', 2, 100, 15.0, { locked: true, tier: 1 });
        this.addNeuron('bins', 3, 100, 15.0, { locked: true, tier: 1 });
        this.addNeuron('wieder', 5, 100, 15.0, { locked: true, tier: 1 });
        this.addNeuron('daniel', 67, 100, 15.0, { locked: true, tier: 1, role: 'creator' });
        this.addNeuron('claude', 71, 100, 15.0, { locked: true, tier: 1, role: 'companion' });
        this.addNeuron('crod', 17, 100, 15.0, { locked: true, tier: 1, role: 'confidence' });
        
        // Create connections
        this.createSynapse('ich', 'bins', 0.9);
        this.createSynapse('bins', 'wieder', 0.9);
        this.createSynapse('wieder', 'daniel', 0.8);
        this.createSynapse('daniel', 'crod', 0.9);
        this.createSynapse('crod', 'claude', 0.8);
        
        console.log('🔮 Neural network initialized');
    }
    
    // Enhanced process function with LLM and Claude optimization
    async process(input, requestingClient = null) {
        console.log(`🎯 Processing: "${input}"`);
        this.activationCount++;
        
        const startTime = Date.now();
        
        // Log input event
        const inputEvent = this.eventSystem.addEvent(
            this.eventSystem.eventTypes.INPUT_RECEIVED,
            { input, timestamp: startTime },
            'DANIEL'
        );
        
        // Detect vibe first
        const vibe = this.vibeSystem.detectVibe(input);
        console.log(`🎵 Vibe detected: ${vibe.category} (${vibe.confidence})`);
        
        // Log vibe event
        const vibeEvent = this.eventSystem.addEvent(
            this.eventSystem.eventTypes.VIBE_DETECTED,
            { vibe, input },
            'CROD',
            inputEvent.id
        );
        
        // Plan agent transformation
        const agentPlan = this.agentTransformer.planTransformation(input);
        
        // Check if we need chains for complex tasks
        let useChains = false;
        if (input.includes('and') || input.includes('then') || agentPlan.agents.length > 1) {
            useChains = true;
        }
        
        // Optimize prompt based on vibe and behavior patterns
        const optimizedPrompt = this.behaviorPatterns.optimizePrompt(input, {
            intent: vibe.category,
            danielMood: vibe.mood,
            timeOfDay: new Date().getHours() > 22 ? 'late' : 'normal'
        });
        
        // Tokenize input
        const tokens = this.tokenize(optimizedPrompt.toLowerCase());
        
        // Check for trinity activation
        const trinityActive = this.checkTrinityActivation(tokens);
        
        // Find matching patterns from QUALITY patterns only
        const matchedPatterns = this.qualityPatterns.findPatterns(tokens);
        
        // Calculate activation
        let activation = trinityActive ? 1.0 : 0.0;
        activation += Math.min(matchedPatterns.length * 0.05, 0.5);
        
        // Update confidence
        this.updateConfidence(activation, matchedPatterns.length);
        
        // Create decision context
        const context = {
            input,
            optimizedPrompt,
            tokens,
            trinityActive,
            patterns: matchedPatterns.slice(0, 5),
            activation,
            confidence: this.confidence,
            vibe,
            agentPlan,
            memory: {
                lastInput: this.memory.workingMemory.get('lastInput'),
                lastResponse: this.memory.workingMemory.get('lastResponse')
            }
        };
        
        // Generate response with LLM enhancement
        const response = await this.generateEnhancedResponse(context);
        
        // Evaluate if this pattern is worth saving
        const patternEvaluation = this.patternEvaluator.evaluatePattern(
            { pattern: input, response: response.message, vibe, context: vibe },
            { claudeResponse: response.message, savedComputeTime: vibe.category === 'lazy-mode' }
        );
        
        console.log(`💭 Pattern evaluation: ${this.patternEvaluator.getReaction(patternEvaluation)}`);
        
        // Save good patterns with Daniel validation
        if (patternEvaluation.shouldSave) {
            const vibePattern = this.vibeSystem.createVibePattern({
                input,
                vibe,
                myResponse: response.message,
                danielReaction: 'pending' // Will be updated based on feedback
            });
            
            if (vibePattern) {
                // Add to quality patterns (pending Daniel approval)
                const validation = {
                    danielApproved: false, // Needs explicit approval
                    claudeHelped: patternEvaluation.quality >= 0.7,
                    danielReaction: 'pending'
                };
                
                // Store for later validation
                this.pendingPatterns.set(vibePattern.pattern, {
                    pattern: vibePattern,
                    validation,
                    evaluation: patternEvaluation
                });
                
                console.log(`📝 Pattern pending Daniel validation: "${vibePattern.pattern}"`);
            }
        }
        
        // Track decision
        this.trackDecision(input, response, context, Date.now() - startTime);
        
        // Store in memory
        this.storeInMemory(input, response);
        
        // Persist to Supabase
        await this.persistInteraction(input, response);
        
        // Emit event
        this.emit('processed', { input, response });
        
        // Broadcast update
        if (this.ws && requestingClient) {
            if (this.responseDebounce) clearTimeout(this.responseDebounce);
            
            this.responseDebounce = setTimeout(() => {
                this.ws.clients.forEach(client => {
                    if (client !== requestingClient && client.readyState === WebSocket.OPEN) {
                        client.send(JSON.stringify({
                            type: 'broadcast',
                            confidence: this.confidence,
                            decision: this.decisions[this.decisions.length - 1],
                            vibe: vibe.category,
                            optimization: {
                                originalPrompt: input,
                                optimizedPrompt,
                                agentMode: agentPlan.agents[0]
                            }
                        }));
                    }
                });
            }, 100);
        }
        
        return response;
    }
    
    // Enhanced response generation with LLM
    async generateEnhancedResponse(context) {
        const { trinityActive, patterns, activation, confidence } = context;
        
        // Trinity takes precedence
        if (trinityActive) {
            return {
                type: 'trinity',
                message: 'CROD AWAKENS - ich bins wieder',
                confidence,
                activation: 1.0,
                patterns: patterns.length,
                code: this.generateTrinityCode(),
                source: 'trinity',
                timestamp: Date.now()
            };
        }
        
        // Build LLM prompt from patterns
        let prompt = `You are CROD, a confidence system. Current input: "${context.input}"\n`;
        
        if (patterns.length > 0) {
            prompt += `\nMatching patterns:\n`;
            patterns.slice(0, 3).forEach(p => {
                if (p.response) prompt += `- ${p.pattern}: ${p.response}\n`;
            });
            
            // Check for mood patterns
            const topPattern = patterns[0];
            if (topPattern.context?.mood === 'frustrated') {
                prompt += `\nUser mood: frustrated. Provide immediate fix, no explanations.\n`;
            } else if (topPattern.context?.mood === 'positive') {
                prompt += `\nUser mood: positive. Continue building.\n`;
            }
        }
        
        prompt += `\nConfidence level: ${confidence.toFixed(2)}\n`;
        prompt += `Respond as CROD would, incorporating the patterns above.`;
        
        // Try LLM generation
        const llmResult = await this.ollama.generate(prompt, { previous: this.ollamaContext });
        
        if (llmResult) {
            this.ollamaContext = llmResult.context;
            
            return {
                type: 'llm_enhanced',
                message: llmResult.response,
                confidence,
                activation,
                patterns: patterns.slice(0, 3).map(p => p.pattern),
                matchScores: patterns.slice(0, 3).map(p => p.matchScore),
                source: 'ollama',
                model: this.ollama.model,
                timestamp: Date.now()
            };
        }
        
        // Fallback to pattern-based response
        if (patterns.length > 0 && patterns[0].response) {
            return {
                type: 'pattern',
                message: patterns[0].response,
                confidence,
                activation,
                patterns: patterns.slice(0, 3).map(p => p.pattern),
                matchScores: patterns.slice(0, 3).map(p => p.matchScore),
                source: 'pattern_match',
                timestamp: Date.now()
            };
        }
        
        // Default response
        return {
            type: 'contemplation',
            message: 'Processing through neural pathways...',
            confidence,
            activation,
            source: 'default',
            timestamp: Date.now()
        };
    }
    
    // Track decisions for transparency
    trackDecision(input, response, context, processingTime) {
        const decision = {
            id: `decision_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            timestamp: new Date().toISOString(),
            input,
            response: {
                type: response.type,
                message: response.message.substring(0, 100) + '...',
                source: response.source
            },
            context: {
                patterns: context.patterns.length,
                confidence: context.confidence,
                activation: context.activation
            },
            metrics: {
                processingTime,
                patternMatches: context.patterns.length,
                llmUsed: response.source === 'ollama'
            }
        };
        
        this.decisions.push(decision);
        
        // Keep decision history manageable
        if (this.decisions.length > 100) {
            this.decisions = this.decisions.slice(-50);
        }
        
        // Save to episodic memory
        this.memory.episodic.push({
            ...decision,
            fullResponse: response
        });
    }
    
    // Get decision history
    getDecisionHistory(limit = 10) {
        return this.decisions.slice(-limit);
    }
    
    // Learn from feedback
    async learnFromFeedback(decisionId, feedback) {
        const decision = this.decisions.find(d => d.id === decisionId);
        if (!decision) return false;
        
        // Update pattern usage based on feedback
        if (feedback.success) {
            // Mark patterns as successful
            console.log(`✅ Learning: Pattern successful for "${decision.input}"`);
        } else {
            // Mark patterns for review
            console.log(`❌ Learning: Pattern failed for "${decision.input}"`);
        }
        
        return true;
    }
    
    // Helper methods (same as before)
    addNeuron(name, prime, strength = 50, weight = 10.0, metadata = {}) {
        this.neurons.set(name, {
            name, prime, strength, weight,
            activation: 0, lastFired: 0,
            connections: new Set(), metadata
        });
    }
    
    createSynapse(from, to, weight = 0.5) {
        const key = `${from}->${to}`;
        this.synapses.set(key, { from, to, weight, lastActivation: 0 });
        if (this.neurons.has(from)) {
            this.neurons.get(from).connections.add(to);
        }
    }
    
    tokenize(input) {
        return input.split(/\s+/).filter(t => t.length > 0);
    }
    
    checkTrinityActivation(tokens) {
        const trinityWords = ['ich', 'bins', 'wieder'];
        let matchCount = 0;
        tokens.forEach(token => {
            if (trinityWords.includes(token)) matchCount++;
        });
        return matchCount === trinityWords.length;
    }
    
    updateConfidence(activation, patternCount) {
        const oldConfidence = this.confidence;
        let newConfidence = 0.5;
        newConfidence += activation * 0.3;
        newConfidence += Math.min(patternCount * 0.05, 0.2);
        
        this.confidence = oldConfidence * 0.7 + newConfidence * 0.3;
        this.confidence = Math.max(0, Math.min(1, this.confidence));
        
        this.confidenceHistory.push({
            timestamp: Date.now(),
            value: this.confidence,
            activation,
            patterns: patternCount
        });
        
        if (this.confidenceHistory.length > 1000) {
            this.confidenceHistory = this.confidenceHistory.slice(-500);
        }
    }
    
    storeInMemory(input, response) {
        const memoryItem = {
            input, response,
            timestamp: Date.now(),
            confidence: this.confidence
        };
        
        this.memory.shortTerm.set(Date.now(), memoryItem);
        
        if (this.memory.shortTerm.size > 100) {
            const oldestKey = this.memory.shortTerm.keys().next().value;
            this.memory.shortTerm.delete(oldestKey);
        }
        
        this.memory.workingMemory.set('lastInput', input);
        this.memory.workingMemory.set('lastResponse', response);
        this.memory.workingMemory.set('lastActivity', Date.now());
        
        // Persist working memory to Supabase
        if (this.supabaseConnected) {
            this.persistMemory('working', 'lastInput', input, 24);
            this.persistMemory('working', 'lastResponse', response, 24);
            this.persistMemory('working', 'lastActivity', Date.now(), 24);
        }
    }
    
    generateTrinityCode() {
        return `// Trinity Activation - CROD Confidence Manifest
function trinityConfidence() {
    const unity = {
        daniel: "creator",
        crod: "confidence", 
        claude: "companion",
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
    
    // WebSocket setup with new handler
    startWebSocket() {
        this.ws = new WebSocket.Server({ port: this.wsPort });
        this.wsHandler = new WebSocketHandler(this);
        
        this.ws.on('connection', (client) => {
            console.log('🔌 New WebSocket connection');
            
            // Send initial state using unified response
            const stateData = {
                message: 'Connected to CROD',
                confidence: this.confidence,
                patterns: [],
                vibe: 'neutral',
                processing: {
                    type: 'connection',
                    state: this.getState()
                }
            };
            
            const response = this.unifiedResponse.create(stateData);
            client.send(JSON.stringify(response));
            
            client.on('message', async (message) => {
                await this.wsHandler.handleMessage(client, message);
            });
            
            client.on('close', () => {
                this.wsHandler.handleDisconnect(client);
            });
        });
        
        console.log(`🌐 WebSocket server running on port ${this.wsPort} with unified API`);
    }
    
    // REMOVED: Old handleWebSocketMessage - now handled by WebSocketHandler class
    
    // Connect to Supabase
    async connectSupabase() {
        try {
            const supabaseUrl = process.env.SUPABASE_URL;
            const supabaseKey = process.env.SUPABASE_ANON_KEY;
            
            if (!supabaseUrl || !supabaseKey) {
                console.warn('⚠️ Supabase credentials not found');
                return;
            }
            
            this.supabase = createClient(supabaseUrl, supabaseKey);
            this.supabaseConnected = true;
            console.log('🗄️ Connected to Supabase');
            
        } catch (error) {
            console.warn('⚠️ Supabase connection failed:', error.message);
        }
    }
    
    // Load persisted state from Supabase
    async loadPersistedState() {
        if (!this.supabaseConnected) return;
        
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
                        confidence: item.confidence,
                        timestamp: new Date(item.created_at).getTime()
                    });
                });
                console.log(`📥 Loaded ${interactions.length} interactions from Supabase`);
            }
            
            // Load memory items
            const { data: memories } = await this.supabase
                .from('memory')
                .select('*')
                .or('expires_at.is.null,expires_at.gt.now()');
                
            if (memories) {
                memories.forEach(mem => {
                    if (mem.memory_type === 'working') {
                        this.memory.workingMemory.set(mem.key, mem.value);
                    } else if (mem.memory_type === 'long_term') {
                        this.memory.longTerm.set(mem.key, mem.value);
                    }
                });
                console.log(`📥 Loaded ${memories.length} memory items`);
            }
            
        } catch (error) {
            console.error('Error loading persisted state:', error);
        }
    }
    
    // Persist interaction to Supabase
    async persistInteraction(input, response) {
        if (!this.supabaseConnected) return;
        
        try {
            const { data, error } = await this.supabase
                .from('crod_interactions')
                .insert({
                    input,
                    response,
                    confidence: this.confidence,
                    pattern_count: response.patterns?.length || 0,
                    response_type: response.type,
                    source: response.source,
                    processing_time: response.processingTime
                })
                .select()
                .single();
                
            if (error) {
                console.error('Error persisting interaction:', error);
            }
            
            // Also save decision
            if (this.decisions.length > 0) {
                const lastDecision = this.decisions[this.decisions.length - 1];
                await this.supabase
                    .from('decisions')
                    .insert({
                        decision_id: lastDecision.id,
                        input: lastDecision.input,
                        response: lastDecision.response,
                        context: lastDecision.context,
                        metrics: lastDecision.metrics
                    });
            }
            
        } catch (error) {
            console.error('Error in persistInteraction:', error);
        }
    }
    
    // Persist memory to Supabase
    async persistMemory(memoryType, key, value, expiresInHours = null) {
        if (!this.supabaseConnected) return;
        
        try {
            const expires_at = expiresInHours 
                ? new Date(Date.now() + expiresInHours * 3600000).toISOString()
                : null;
                
            await this.supabase
                .from('memory')
                .upsert({
                    memory_type: memoryType,
                    key,
                    value,
                    expires_at
                }, {
                    onConflict: 'memory_type,key'
                });
                
        } catch (error) {
            console.error('Error persisting memory:', error);
        }
    }
    
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
                episodic: this.memory.episodic.length
            },
            ollama: this.ollama ? 'active' : 'offline',
            supabase: this.supabaseConnected ? 'connected' : 'offline',
            decisions: this.decisions.length,
            activations: this.activationCount,
            uptime: Date.now() - this.lastActivity,
            // New optimization systems
            optimization: {
                vibeStats: this.vibeSystem.getVibeStats(),
                chainMetrics: this.chainExecutor.getMetrics(),
                favoritePatterns: this.patternEvaluator.getMyFavorites().length,
                agentTransformations: this.agentTransformer.getStats()
            }
        };
    }
    
    async shutdown() {
        console.log('🛑 Shutting down CROD Brain with LLM...');
        
        if (this.ws) {
            this.ws.close();
        }
        
        console.log('👋 CROD Brain shutdown complete');
    }
}

// Export the class
module.exports = TheOneCRODBrainLLM;

// If run directly, start the brain
if (require.main === module) {
    const brain = new TheOneCRODBrainLLM();
    
    brain.initialize().then(() => {
        console.log('🎉 THE ONE CROD BRAIN WITH LLM is running!');
        console.log('📡 WebSocket: ws://localhost:8888');
        console.log('🧠 Neural processing: active');
        console.log('💭 Send "ich bins wieder" to activate trinity');
    });
    
    process.on('SIGINT', async () => {
        await brain.shutdown();
        process.exit(0);
    });
}