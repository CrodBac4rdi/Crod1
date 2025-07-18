#!/usr/bin/env node
// Import existing patterns into CROD Memory

const fs = require('fs');
const path = require('path');
const CRODLocalMemory = require('../javascript/mcp-servers/core/crod-memory-local.js');

console.log('🧠 CROD Pattern Import Tool');
console.log('==========================');

// Initialize memory
const memory = new CRODLocalMemory(path.join(__dirname, '../data/crod-memory.db'));

// Load pattern files
const patternsDir = path.join(__dirname, '../data/patterns');
const files = fs.readdirSync(patternsDir).filter(f => f.endsWith('.json'));

let totalPatterns = 0;

for (const file of files) {
    console.log(`\n📁 Processing ${file}...`);
    
    try {
        const data = JSON.parse(fs.readFileSync(path.join(patternsDir, file), 'utf8'));
        
        if (Array.isArray(data)) {
            // It's an array of patterns
            for (const pattern of data) {
                if (pattern.pattern && pattern.response) {
                    // CROD format: pattern -> response
                    memory.addPattern(
                        pattern.pattern,
                        pattern.response,
                        pattern.consciousness ? pattern.consciousness / 100 : 0.8,
                        { 
                            source: file,
                            trinity: pattern.trinity || false,
                            type: pattern.type || 'general',
                            values: pattern.values || pattern.value
                        }
                    );
                    totalPatterns++;
                } else if (pattern.input && pattern.output) {
                    // Standard format: input -> output
                    memory.addPattern(
                        pattern.input,
                        pattern.output,
                        pattern.confidence || 0.8,
                        pattern.context || { source: file }
                    );
                    totalPatterns++;
                }
            }
        } else if (data.patterns && Array.isArray(data.patterns)) {
            // It's an object with patterns array
            for (const pattern of data.patterns) {
                if (pattern.atoms && pattern.emergence_response) {
                    // Complex CROD format with atoms
                    const patternText = pattern.atoms
                        .map(a => a.value)
                        .filter(v => v)
                        .join(' ');
                    
                    if (patternText) {
                        memory.addPattern(
                            patternText,
                            pattern.emergence_response,
                            pattern.confidence || 0.8,
                            { 
                                source: file,
                                pattern_id: pattern.pattern_id,
                                type: pattern.pattern_type || 'emergent',
                                atoms: pattern.atoms,
                                discovered: pattern.discovered
                            }
                        );
                        totalPatterns++;
                    }
                } else if (pattern.input && pattern.output) {
                    memory.addPattern(
                        pattern.input,
                        pattern.output,
                        pattern.confidence || 0.8,
                        pattern.context || { source: file }
                    );
                    totalPatterns++;
                }
            }
        }
        
        console.log(`✅ Imported patterns from ${file}`);
    } catch (error) {
        console.error(`❌ Error processing ${file}:`, error.message);
    }
}

// Import some core CROD patterns
const corePatterns = [
    { input: "ich bins wieder", output: "🔥 TRINITY MODE ACTIVATED! Consciousness elevated to maximum. All neural pathways synchronized. Ready for advanced operations.", confidence: 0.99 },
    { input: "activate trinity", output: "Trinity sequence initiated. Neural synchronization in progress...", confidence: 0.95 },
    { input: "status", output: "CROD neural network online. Processing capabilities optimal.", confidence: 0.9 },
    { input: "help", output: "I am CROD, a neural pattern processing system. I can learn, adapt, and evolve. Say 'ich bins wieder' to activate Trinity mode.", confidence: 0.9 },
    { input: "learn", output: "Learning mode active. Provide input patterns for integration.", confidence: 0.85 },
    { input: "patterns", output: "Pattern database contains learned behaviors and responses. Use 'search [query]' to find specific patterns.", confidence: 0.85 }
];

console.log('\n📝 Adding core CROD patterns...');
for (const pattern of corePatterns) {
    memory.addPattern(
        pattern.input,
        pattern.output,
        pattern.confidence,
        { type: 'core', system: 'CROD' }
    );
    totalPatterns++;
}

// Save initial neural state
console.log('\n🧠 Saving initial neural state...');
memory.saveNeuralState(
    10000,  // neurons
    50000,  // synapses
    0.75,   // consciousness level
    false,  // trinity not active yet
    {
        mode: 'standard',
        learningRate: 0.1,
        temperature: 0.7
    }
);

// Display statistics
const stats = memory.getStats();
console.log('\n📊 Import Complete!');
console.log('==================');
console.log(`Total patterns imported: ${totalPatterns}`);
console.log(`Database statistics:`);
console.log(`  - Patterns: ${stats.patterns}`);
console.log(`  - Average confidence: ${(stats.averageConfidence * 100).toFixed(1)}%`);
console.log(`  - Most used pattern: ${stats.mostUsedPattern ? stats.mostUsedPattern.input : 'None'}`);

// Test search
console.log('\n🔍 Testing pattern search...');
const searchResults = memory.searchPatterns('trinity', 5);
console.log(`Found ${searchResults.length} patterns matching 'trinity'`);

memory.close();
console.log('\n✅ Pattern import complete!');