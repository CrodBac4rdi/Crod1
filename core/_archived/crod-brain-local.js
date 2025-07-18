// CROD Brain with Local Memory (no Supabase!)
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');
const CRODLocalMemory = require('./crod-memory-local');

// Ollama client for LLM
class OllamaClient {
    constructor(model = 'deepseek-coder:1.3b') {
        this.model = model;
        this.baseUrl = 'http://localhost:11434';
    }
    
    async generate(prompt, context = '') {
        try {
            const response = await fetch(`${this.baseUrl}/api/generate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: this.model,
                    prompt: `${context}\n\nUser: ${prompt}\n\nAssistant:`,
                    stream: false
                })
            });
            
            const data = await response.json();
            return data.response || 'I need to think about that...';
        } catch (error) {
            console.error('Ollama error:', error);
            return null;
        }
    }
}

// Main CROD Brain
class CRODBrainLocal {
    constructor() {
        this.wss = null;
        this.initialized = false;
        this.confidence = 0.5;
        
        // Local memory instead of Supabase
        this.memory = new CRODLocalMemory();
        
        // Load patterns from memory
        this.patterns = [];
        this.loadPatternsFromMemory();
        
        // Ollama LLM
        this.ollama = new OllamaClient();
        
        // Decision tracking
        this.decisions = [];
        
        // Response tracking
        this.lastResponseHash = '';
        this.responseDebounce = null;
        
        console.log('🧠 CROD Brain (Local Memory) initializing...');
    }
    
    loadPatternsFromMemory() {
        // Load patterns from SQLite
        const dbPatterns = this.memory.getAllPatterns();
        
        this.patterns = dbPatterns.map(p => ({
            id: p.id,
            pattern: p.pattern,
            response: p.response,
            trinity: JSON.parse(p.trinity || '{}'),
            context: JSON.parse(p.context || '{}'),
            usage_count: p.usage_count,
            success_rate: p.success_rate
        }));
        
        console.log(`📊 Loaded ${this.patterns.length} patterns from local memory`);
    }
    
    async initialize() {
        // Create user entity
        this.memory.createEntity('user', 'daniel', {
            role: 'creator',
            preferences: { mood: 'curious' }
        });
        
        // Start WebSocket server
        this.wss = new WebSocket.Server({ port: 8888 });
        
        this.wss.on('connection', (ws) => {
            console.log('🔌 Client connected');
            
            ws.on('message', async (message) => {
                try {
                    const data = JSON.parse(message);
                    const response = await this.process(data.input);
                    
                    // Send only to requesting client
                    if (ws.readyState === WebSocket.OPEN) {
                        ws.send(JSON.stringify(response));
                    }
                } catch (error) {
                    console.error('Error processing:', error);
                    ws.send(JSON.stringify({
                        message: 'Error processing request',
                        error: error.message
                    }));
                }
            });
            
            ws.on('close', () => {
                console.log('🔌 Client disconnected');
            });
        });
        
        this.initialized = true;
        console.log('✅ CROD Brain ready on ws://localhost:8888');
        console.log('📊 Using local SQLite database');
        
        // Log startup
        this.memory.addObservation('system', 'crod', 'Started with local memory', 1.0);
    }
    
    async process(input) {
        const startTime = Date.now();
        
        if (!input || typeof input !== 'string') {
            return { message: 'Invalid input', confidence: 0 };
        }
        
        // Check for trinity activation
        if (input.toLowerCase().includes('ich bins wieder')) {
            this.confidence = Math.min(this.confidence + 0.1, 1.0);
            
            // Log trinity activation
            this.memory.createRelation('user', 'daniel', 'pattern', 'trinity', 'triggered');
            
            const response = {
                message: 'CROD AWAKENS - ich bins wieder',
                type: 'trinity',
                source: 'trinity',
                confidence: this.confidence,
                patterns: ['trinity']
            };
            
            this.trackDecision(input, response, startTime);
            return response;
        }
        
        // Pattern matching
        const matchedPatterns = this.findMatchingPatterns(input);
        
        if (matchedPatterns.length > 0) {
            const bestPattern = matchedPatterns[0];
            
            // Update pattern usage in memory
            this.memory.updatePatternSuccess(bestPattern.pattern, true);
            
            const response = {
                message: bestPattern.response,
                type: 'pattern',
                source: 'patterns',
                confidence: this.confidence,
                patterns: matchedPatterns.map(p => p.pattern)
            };
            
            this.trackDecision(input, response, startTime);
            return response;
        }
        
        // Try LLM enhancement
        const llmResponse = await this.generateLLMResponse(input, matchedPatterns);
        
        if (llmResponse) {
            const response = {
                message: llmResponse,
                type: 'llm_enhanced',
                source: 'ollama',
                confidence: Math.max(0.3, this.confidence - 0.2),
                patterns: matchedPatterns.map(p => p.pattern)
            };
            
            // Suggest for learning if confidence is low
            if (response.confidence < 0.5) {
                this.memory.addToLearningQueue(
                    input,
                    llmResponse,
                    { source: 'llm', matchedPatterns },
                    response.confidence
                );
            }
            
            this.trackDecision(input, response, startTime);
            return response;
        }
        
        // Fallback
        const response = {
            message: "I'm still learning. Can you teach me how to respond to this?",
            type: 'learning',
            source: 'fallback',
            confidence: 0.1,
            patterns: []
        };
        
        this.trackDecision(input, response, startTime);
        return response;
    }
    
    findMatchingPatterns(input) {
        const inputLower = input.toLowerCase();
        const matches = [];
        
        for (const pattern of this.patterns) {
            if (inputLower.includes(pattern.pattern.toLowerCase())) {
                matches.push({
                    ...pattern,
                    score: pattern.usage_count * pattern.success_rate
                });
            }
        }
        
        // Sort by score
        return matches.sort((a, b) => b.score - a.score);
    }
    
    async generateLLMResponse(input, patterns) {
        const context = patterns.length > 0 
            ? `Related patterns: ${patterns.map(p => p.pattern).join(', ')}`
            : 'No matching patterns found.';
            
        return await this.ollama.generate(input, context);
    }
    
    trackDecision(input, response, startTime) {
        const decision = {
            id: `decision_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            timestamp: new Date().toISOString(),
            input,
            response: response.message,
            type: response.type,
            source: response.source,
            confidence: response.confidence,
            patterns: response.patterns,
            processingTime: Date.now() - startTime
        };
        
        this.decisions.push(decision);
        
        // Log to memory
        this.memory.logInteraction(input, response, {
            type: response.type,
            confidence: response.confidence,
            patterns: response.patterns,
            processingTime: decision.processingTime
        });
        
        // Keep only recent decisions in memory
        if (this.decisions.length > 100) {
            this.decisions = this.decisions.slice(-100);
        }
        
        // Adjust confidence based on processing
        if (response.type === 'pattern') {
            this.confidence = Math.min(this.confidence + 0.01, 1.0);
        } else if (response.type === 'learning') {
            this.confidence = Math.max(this.confidence - 0.01, 0.1);
        }
    }
    
    // Learn new pattern
    async learnPattern(pattern, response, context = {}) {
        // Add to memory
        this.memory.learnPattern(pattern, response, null, context, 'api');
        
        // Add to runtime patterns
        this.patterns.push({
            pattern,
            response,
            context,
            usage_count: 0,
            success_rate: 0
        });
        
        // Create relation
        this.memory.createRelation('user', 'daniel', 'pattern', pattern, 'taught');
        
        return { learned: true, pattern };
    }
    
    // Provide feedback
    async learnFromFeedback(decisionId, feedback) {
        const decision = this.decisions.find(d => d.id === decisionId);
        if (!decision) return false;
        
        if (feedback.success) {
            // Update pattern success rates
            decision.patterns.forEach(pattern => {
                this.memory.updatePatternSuccess(pattern, true);
            });
            
            // Add positive observation
            this.memory.addObservation(
                'interaction',
                decision.input,
                `Successful response: ${decision.response}`,
                0.8
            );
        } else {
            // Add to learning queue
            this.memory.addToLearningQueue(
                decision.input,
                feedback.notes || 'Needs better response',
                { originalResponse: decision.response },
                0.3
            );
        }
        
        return true;
    }
    
    getState() {
        const stats = this.memory.getStats();
        
        return {
            initialized: this.initialized,
            confidence: this.confidence,
            patterns: this.patterns.length,
            decisions: this.decisions.length,
            memory: {
                entities: stats.total_entities,
                patterns: stats.total_patterns,
                interactions: stats.total_interactions,
                relations: stats.total_relations,
                avgConfidence24h: stats.avg_confidence_24h,
                pendingLearning: stats.pending_learning
            },
            ollama: this.ollama ? 'active' : 'inactive'
        };
    }
    
    getDecisionHistory(limit = 10) {
        return this.decisions.slice(-limit).reverse();
    }
    
    async shutdown() {
        console.log('🛑 Shutting down CROD Brain...');
        
        if (this.wss) {
            this.wss.close();
        }
        
        if (this.memory) {
            this.memory.close();
        }
        
        console.log('👋 CROD Brain stopped');
    }
}

// Auto-start if run directly
if (require.main === module) {
    const brain = new CRODBrainLocal();
    
    brain.initialize().catch(error => {
        console.error('Failed to initialize:', error);
        process.exit(1);
    });
    
    // Handle shutdown
    process.on('SIGINT', async () => {
        await brain.shutdown();
        process.exit(0);
    });
}

module.exports = CRODBrainLocal;