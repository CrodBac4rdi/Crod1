// 🚀 CROD Brain OPTIMIZED - Mit Turbo Pattern Matching und Async LLM!

const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');
const PatternTurbo = require('./pattern-turbo');
const CRODLocalMemory = require('./crod-memory-local');
const { Worker } = require('worker_threads');

// Async Ollama Client mit Queue!
class AsyncOllamaClient {
    constructor(model = 'deepseek-coder:1.3b') {
        this.model = model;
        this.baseUrl = 'http://localhost:11434';
        this.queue = [];
        this.processing = false;
        this.cache = new Map(); // Response cache
        this.stats = {
            requests: 0,
            cacheHits: 0,
            avgResponseTime: 0
        };
    }
    
    async generate(prompt, context = '') {
        // Check cache first
        const cacheKey = `${prompt}::${context}`.substring(0, 100);
        if (this.cache.has(cacheKey)) {
            this.stats.cacheHits++;
            console.log('💾 LLM Cache hit!');
            return this.cache.get(cacheKey);
        }
        
        // Add to queue
        return new Promise((resolve, reject) => {
            this.queue.push({ prompt, context, resolve, reject });
            this.processQueue();
        });
    }
    
    async processQueue() {
        if (this.processing || this.queue.length === 0) return;
        
        this.processing = true;
        const batch = this.queue.splice(0, 3); // Process up to 3 at once
        
        console.log(`🤖 Processing ${batch.length} LLM requests...`);
        
        await Promise.all(batch.map(async (req) => {
            const startTime = Date.now();
            
            try {
                const response = await fetch(`${this.baseUrl}/api/generate`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        model: this.model,
                        prompt: `${req.context}\n\nUser: ${req.prompt}\n\nAssistant:`,
                        stream: false,
                        options: {
                            temperature: 0.7,
                            num_predict: 150
                        }
                    }),
                    signal: AbortSignal.timeout(10000) // 10s timeout
                });
                
                const data = await response.json();
                const result = data.response || 'I need to think about that...';
                
                // Cache the response
                const cacheKey = `${req.prompt}::${req.context}`.substring(0, 100);
                this.cache.set(cacheKey, result);
                
                // Keep cache size limited
                if (this.cache.size > 50) {
                    const firstKey = this.cache.keys().next().value;
                    this.cache.delete(firstKey);
                }
                
                // Update stats
                const responseTime = Date.now() - startTime;
                this.stats.requests++;
                this.stats.avgResponseTime = (this.stats.avgResponseTime + responseTime) / 2;
                
                req.resolve(result);
            } catch (error) {
                console.error('❌ Ollama error:', error.message);
                req.resolve(null); // Don't reject, just return null
            }
        }));
        
        this.processing = false;
        
        // Process next batch if any
        if (this.queue.length > 0) {
            setTimeout(() => this.processQueue(), 100);
        }
    }
    
    showStats() {
        console.log('\n🤖 LLM Stats:');
        console.log(`   Total Requests: ${this.stats.requests}`);
        console.log(`   Cache Hits: ${this.stats.cacheHits} (${((this.stats.cacheHits/this.stats.requests)*100).toFixed(1)}%)`);
        console.log(`   Avg Response Time: ${this.stats.avgResponseTime.toFixed(0)}ms`);
    }
}

// Optimized CROD Brain
class CRODBrainOptimized {
    constructor() {
        this.wss = null;
        this.initialized = false;
        this.confidence = 0.5;
        
        // Turbo Pattern System!
        this.patternTurbo = new PatternTurbo();
        
        // Local Memory
        this.memory = new CRODLocalMemory();
        
        // Async LLM
        this.ollama = new AsyncOllamaClient();
        
        // Pre-computed prime neurons (no recalculation!)
        this.primeNeurons = this.precomputePrimes(1000);
        
        // WebSocket deduplication
        this.lastMessageHash = '';
        this.messageDebouncer = null;
        
        console.log('🧠 CROD Brain OPTIMIZED starting...');
        console.log('   Features: Pattern Turbo + Async LLM + Cached Neurons');
    }
    
    // Pre-compute prime numbers once!
    precomputePrimes(max) {
        const primes = [];
        for (let n = 2; n <= max; n++) {
            let isPrime = true;
            for (let i = 2; i <= Math.sqrt(n); i++) {
                if (n % i === 0) {
                    isPrime = false;
                    break;
                }
            }
            if (isPrime) primes.push(n);
        }
        console.log(`⚡ Pre-computed ${primes.length} prime neurons!`);
        return primes;
    }
    
    async initialize() {
        console.log('\n🚀 Initializing OPTIMIZED Brain...');
        
        // Parallel initialization!
        const tasks = [
            this.loadPatternsAsync(),
            this.startWebSocketServer(),
            this.warmupLLM()
        ];
        
        await Promise.all(tasks);
        
        this.initialized = true;
        console.log('\n✅ CROD Brain OPTIMIZED ready!');
        console.log('   Performance: MAXIMUM');
        console.log('   Fun Level: OVER 9000!');
        
        // Show initial stats
        this.showPerformanceStats();
    }
    
    async loadPatternsAsync() {
        console.log('📂 Loading patterns...');
        
        // Load from memory first
        const dbPatterns = this.memory.getAllPatterns();
        
        // Then load from JSONL if exists
        const jsonlPath = path.join(__dirname, '..', 'data', 'patterns-jsonl', 'patterns.jsonl');
        if (fs.existsSync(jsonlPath)) {
            // Stream read for memory efficiency
            const patterns = [];
            const stream = fs.createReadStream(jsonlPath, { encoding: 'utf8' });
            
            await new Promise((resolve, reject) => {
                let buffer = '';
                
                stream.on('data', chunk => {
                    buffer += chunk;
                    const lines = buffer.split('\n');
                    buffer = lines.pop(); // Keep incomplete line
                    
                    lines.forEach(line => {
                        if (line.trim()) {
                            try {
                                patterns.push(JSON.parse(line));
                            } catch (e) {
                                // Skip bad lines
                            }
                        }
                    });
                });
                
                stream.on('end', () => resolve());
                stream.on('error', reject);
            });
            
            // Load into Turbo engine
            await this.patternTurbo.loadPatterns([...dbPatterns, ...patterns]);
        } else {
            await this.patternTurbo.loadPatterns(dbPatterns);
        }
    }
    
    async startWebSocketServer() {
        return new Promise((resolve) => {
            this.wss = new WebSocket.Server({ port: 8888 });
            
            this.wss.on('connection', (ws) => {
                console.log('🔌 Client connected');
                
                // Send welcome message with stats
                ws.send(JSON.stringify({
                    type: 'welcome',
                    message: 'Connected to CROD Brain OPTIMIZED!',
                    stats: {
                        patterns: this.patternTurbo.patterns.length,
                        confidence: this.confidence,
                        mode: 'TURBO'
                    }
                }));
                
                ws.on('message', async (message) => {
                    try {
                        const data = JSON.parse(message);
                        
                        // Deduplicate messages
                        const messageHash = this.hashMessage(data);
                        if (messageHash === this.lastMessageHash) {
                            return; // Skip duplicate
                        }
                        this.lastMessageHash = messageHash;
                        
                        const response = await this.process(data.input);
                        
                        // Send only to requesting client
                        if (ws.readyState === WebSocket.OPEN) {
                            ws.send(JSON.stringify(response));
                        }
                    } catch (error) {
                        console.error('Error:', error);
                        ws.send(JSON.stringify({
                            error: error.message,
                            type: 'error'
                        }));
                    }
                });
                
                ws.on('close', () => {
                    console.log('🔌 Client disconnected');
                });
            });
            
            this.wss.on('listening', () => {
                console.log('🌐 WebSocket server ready on ws://localhost:8888');
                resolve();
            });
        });
    }
    
    async warmupLLM() {
        console.log('🔥 Warming up LLM...');
        await this.ollama.generate('Hello', 'Warmup request');
        console.log('✅ LLM ready!');
    }
    
    async process(input) {
        const startTime = performance.now();
        
        if (!input || typeof input !== 'string') {
            return { message: 'Invalid input', confidence: 0 };
        }
        
        // Trinity check (still the fastest!)
        if (input.toLowerCase().includes('ich bins wieder')) {
            this.confidence = Math.min(this.confidence + 0.1, 1.0);
            const response = {
                message: 'CROD AWAKENS - ich bins wieder! 🚀',
                type: 'trinity',
                confidence: this.confidence,
                processingTime: performance.now() - startTime,
                mode: 'TURBO'
            };
            
            this.memory.logInteraction(input, response.message, response);
            return response;
        }
        
        // TURBO Pattern Matching!
        const patterns = this.patternTurbo.findMatches(input);
        
        if (patterns.length > 0) {
            const best = patterns[0];
            
            // Update pattern success
            this.memory.updatePatternSuccess(best.pattern, true);
            
            const response = {
                message: best.response,
                type: 'pattern',
                confidence: this.confidence * best.score,
                matchMethod: best.method,
                processingTime: performance.now() - startTime,
                mode: 'TURBO'
            };
            
            this.memory.logInteraction(input, response.message, response);
            return response;
        }
        
        // Async LLM fallback
        const llmContext = patterns.length > 0 
            ? `Similar patterns: ${patterns.slice(0, 3).map(p => p.pattern).join(', ')}`
            : 'No patterns matched.';
            
        const llmResponse = await this.ollama.generate(input, llmContext);
        
        if (llmResponse) {
            const response = {
                message: llmResponse,
                type: 'llm',
                confidence: this.confidence * 0.7,
                processingTime: performance.now() - startTime,
                mode: 'TURBO'
            };
            
            this.memory.logInteraction(input, response.message, response);
            
            // Learn from this?
            if (response.confidence < 0.5) {
                this.memory.addToLearningQueue(input, llmResponse, { source: 'llm' }, response.confidence);
            }
            
            return response;
        }
        
        // Ultimate fallback
        const response = {
            message: "I'm learning at TURBO speed! Teach me something new! 🎮",
            type: 'learning',
            confidence: 0.1,
            processingTime: performance.now() - startTime,
            mode: 'TURBO'
        };
        
        this.memory.logInteraction(input, response.message, response);
        return response;
    }
    
    hashMessage(data) {
        return `${data.input}::${Date.now() / 1000 | 0}`; // 1 second resolution
    }
    
    showPerformanceStats() {
        console.log('\n📊 PERFORMANCE STATS:');
        console.log('━'.repeat(50));
        
        // Pattern stats
        this.patternTurbo.showStats();
        
        // LLM stats
        this.ollama.showStats();
        
        // Memory stats
        const memStats = this.memory.getStats();
        console.log('\n💾 Memory Stats:');
        console.log(`   Entities: ${memStats.total_entities}`);
        console.log(`   Interactions: ${memStats.total_interactions}`);
        console.log(`   Learning Queue: ${memStats.pending_learning}`);
        
        console.log('━'.repeat(50));
        console.log('🎮 Performance Mode: MAXIMUM FUN!');
    }
    
    async shutdown() {
        console.log('\n🛑 Shutting down OPTIMIZED Brain...');
        
        // Show final stats
        this.showPerformanceStats();
        
        if (this.wss) {
            this.wss.close();
        }
        
        if (this.memory) {
            this.memory.close();
        }
        
        console.log('👋 Thanks for the optimization party!');
    }
}

// Auto-start if run directly
if (require.main === module) {
    const brain = new CRODBrainOptimized();
    
    brain.initialize().catch(error => {
        console.error('Failed to initialize:', error);
        process.exit(1);
    });
    
    // Handle shutdown
    process.on('SIGINT', async () => {
        await brain.shutdown();
        process.exit(0);
    });
    
    // Show stats every 30 seconds
    setInterval(() => {
        console.log('\n⏱️ 30 Second Performance Check:');
        brain.showPerformanceStats();
    }, 30000);
}

module.exports = CRODBrainOptimized;