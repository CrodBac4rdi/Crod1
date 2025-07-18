// 🏎️ CROD Pattern Turbo - Macht Pattern Matching zum Vergnügen!

class PatternTurbo {
    constructor() {
        this.patterns = [];
        this.cache = new Map(); // LRU Cache für häufige Patterns
        this.trie = new TrieNode(); // Für super-schnelle Prefix-Suche
        this.hashIndex = new Map(); // Pattern-Hashes für O(1) Lookup
        this.stats = {
            hits: 0,
            misses: 0,
            cacheHits: 0,
            avgSearchTime: 0
        };
        
        console.log('🏎️ Pattern Turbo Engine initialized!');
        console.log('   Features: Trie + Hash Index + LRU Cache');
        console.log('   Status: READY TO RACE!');
    }
    
    // Lädt Patterns mit Style!
    async loadPatterns(patterns) {
        console.log(`\n⚡ TURBO LOADING ${patterns.length} patterns...`);
        const startTime = Date.now();
        
        // Parallel processing mit Progress Bar!
        const chunkSize = 100;
        let loaded = 0;
        
        for (let i = 0; i < patterns.length; i += chunkSize) {
            const chunk = patterns.slice(i, i + chunkSize);
            await Promise.all(chunk.map(p => this.indexPattern(p)));
            
            loaded += chunk.length;
            this.showProgress(loaded, patterns.length);
        }
        
        const loadTime = Date.now() - startTime;
        console.log(`\n✅ LOADED in ${loadTime}ms - That's ${(patterns.length/loadTime*1000).toFixed(0)} patterns/sec!`);
        console.log('🎮 Achievement Unlocked: Speed Demon!');
    }
    
    // Zeigt coolen Progress Bar
    showProgress(current, total) {
        const percent = Math.floor((current / total) * 100);
        const filled = Math.floor(percent / 2);
        const bar = '█'.repeat(filled) + '░'.repeat(50 - filled);
        process.stdout.write(`\r   [${bar}] ${percent}% (${current}/${total})`);
    }
    
    // Indexiert ein Pattern auf 3 Arten gleichzeitig!
    async indexPattern(pattern) {
        // Skip invalid patterns
        if (!pattern || !pattern.pattern) {
            console.warn('⚠️ Skipping invalid pattern:', pattern);
            return;
        }
        
        // 1. In Array für vollständige Suche
        this.patterns.push(pattern);
        
        // 2. In Trie für Prefix-Matching
        this.trie.insert(pattern.pattern.toLowerCase(), pattern);
        
        // 3. In Hash-Index für exakte Matches
        const hash = this.hashPattern(pattern.pattern);
        if (!this.hashIndex.has(hash)) {
            this.hashIndex.set(hash, []);
        }
        this.hashIndex.get(hash).push(pattern);
    }
    
    // Super-schnelle Pattern Suche!
    findMatches(input, limit = 10) {
        const startTime = performance.now();
        
        // Check Cache first (TURBO MODE!)
        const cacheKey = input.toLowerCase();
        if (this.cache.has(cacheKey)) {
            this.stats.cacheHits++;
            this.stats.hits++;
            const searchTime = performance.now() - startTime;
            console.log(`⚡ CACHE HIT! Found in ${searchTime.toFixed(2)}ms`);
            return this.cache.get(cacheKey);
        }
        
        // Multi-Strategy Search!
        const results = new Map(); // Use Map to deduplicate
        
        // Strategy 1: Exact Hash Match (Fastest!)
        const exactHash = this.hashPattern(input);
        if (this.hashIndex.has(exactHash)) {
            this.hashIndex.get(exactHash).forEach(p => {
                results.set(p.pattern, { ...p, score: 1.0, method: 'exact' });
            });
        }
        
        // Strategy 2: Trie Prefix Search
        const words = input.toLowerCase().split(' ');
        words.forEach(word => {
            const prefixMatches = this.trie.search(word);
            prefixMatches.forEach(p => {
                if (!results.has(p.pattern)) {
                    results.set(p.pattern, { ...p, score: 0.8, method: 'prefix' });
                }
            });
        });
        
        // Strategy 3: Fuzzy Contains (if needed)
        if (results.size < limit) {
            const inputLower = input.toLowerCase();
            for (const pattern of this.patterns) {
                if (results.size >= limit) break;
                if (!results.has(pattern.pattern) && 
                    pattern.pattern.toLowerCase().includes(inputLower)) {
                    results.set(pattern.pattern, { ...pattern, score: 0.6, method: 'fuzzy' });
                }
            }
        }
        
        // Convert to array and sort by score
        const sortedResults = Array.from(results.values())
            .sort((a, b) => b.score - a.score)
            .slice(0, limit);
        
        // Update cache
        this.cache.set(cacheKey, sortedResults);
        if (this.cache.size > 100) {
            // Simple LRU: remove first (oldest) entry
            const firstKey = this.cache.keys().next().value;
            this.cache.delete(firstKey);
        }
        
        // Update stats
        const searchTime = performance.now() - startTime;
        this.stats.avgSearchTime = (this.stats.avgSearchTime + searchTime) / 2;
        
        if (sortedResults.length > 0) {
            this.stats.hits++;
            console.log(`🎯 Found ${sortedResults.length} patterns in ${searchTime.toFixed(2)}ms`);
            console.log(`   Methods used: ${[...new Set(sortedResults.map(r => r.method))].join(', ')}`);
        } else {
            this.stats.misses++;
        }
        
        return sortedResults;
    }
    
    // Einfacher Hash für schnelle Lookups
    hashPattern(pattern) {
        let hash = 0;
        for (let i = 0; i < pattern.length; i++) {
            const char = pattern.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }
        return hash;
    }
    
    // Zeigt coole Statistiken
    showStats() {
        console.log('\n📊 PATTERN TURBO STATS:');
        console.log('━'.repeat(40));
        console.log(`🎯 Hit Rate: ${((this.stats.hits / (this.stats.hits + this.stats.misses)) * 100).toFixed(1)}%`);
        console.log(`⚡ Cache Hit Rate: ${((this.stats.cacheHits / this.stats.hits) * 100).toFixed(1)}%`);
        console.log(`🏎️ Avg Search Time: ${this.stats.avgSearchTime.toFixed(2)}ms`);
        console.log(`📦 Patterns Indexed: ${this.patterns.length}`);
        console.log(`💾 Cache Size: ${this.cache.size}`);
        console.log('━'.repeat(40));
        
        // Easter Egg: Special achievement messages
        if (this.stats.avgSearchTime < 1) {
            console.log('🏆 ACHIEVEMENT: Lightning Fast! (<1ms average)');
        }
        if (this.stats.cacheHits > 50) {
            console.log('🏆 ACHIEVEMENT: Cache Master!');
        }
    }
}

// Trie Node für Prefix-Suche
class TrieNode {
    constructor() {
        this.children = new Map();
        this.patterns = [];
        this.isEndOfWord = false;
    }
    
    insert(word, pattern) {
        let node = this;
        for (const char of word) {
            if (!node.children.has(char)) {
                node.children.set(char, new TrieNode());
            }
            node = node.children.get(char);
            node.patterns.push(pattern); // Store pattern at each node
        }
        node.isEndOfWord = true;
    }
    
    search(prefix) {
        let node = this;
        for (const char of prefix) {
            if (!node.children.has(char)) {
                return [];
            }
            node = node.children.get(char);
        }
        return node.patterns;
    }
}

module.exports = PatternTurbo;