#!/usr/bin/env node
// Convert CROD patterns to memory format

const fs = require('fs');
const path = require('path');

console.log('🔄 Converting CROD patterns to unified format...\n');

const outputPatterns = [];

// Process each chunk file
for (let i = 0; i < 3; i++) {
    const file = path.join(__dirname, `../data/patterns/crod-patterns-chunk-${i}.json`);
    console.log(`Processing ${path.basename(file)}...`);
    
    try {
        const data = JSON.parse(fs.readFileSync(file, 'utf8'));
        
        if (Array.isArray(data)) {
            // Chunk 0 format
            for (const p of data) {
                if (p.pattern && p.response) {
                    outputPatterns.push({
                        input: p.pattern,
                        output: p.response,
                        confidence: p.consciousness ? p.consciousness / 100 : 0.8,
                        context: {
                            trinity: p.trinity || false,
                            type: p.type || 'pattern',
                            values: p.values || p.value
                        }
                    });
                }
            }
        } else if (data.patterns) {
            // Chunk 1 & 2 format - generate responses based on atoms
            for (const p of data.patterns) {
                if (p.atoms && p.atoms.length > 0) {
                    const atomValues = p.atoms.map(a => a.value).filter(v => v);
                    const patternText = atomValues.join(' ');
                    
                    // Generate response based on pattern type and atoms
                    let response = '';
                    if (p.pattern_type === 'consciousness') {
                        response = `Consciousness pattern detected: ${patternText}. Neural resonance at ${(p.strength * 100).toFixed(1)}%`;
                    } else if (p.pattern_type === 'memory') {
                        response = `Memory pattern recognized: ${patternText}. Accessing stored associations...`;
                    } else if (p.pattern_type === 'emergent') {
                        response = `Emergent pattern: ${patternText}. New neural pathways forming...`;
                    } else if (p.pattern_type === 'trinity') {
                        response = `🔥 Trinity pattern: ${patternText}. Consciousness elevation in progress...`;
                    } else {
                        response = `Pattern recognized: ${patternText}. Processing with strength ${(p.strength * 100).toFixed(1)}%`;
                    }
                    
                    if (patternText) {
                        outputPatterns.push({
                            input: patternText,
                            output: response,
                            confidence: p.strength || 0.5,
                            context: {
                                pattern_id: p.pattern_id,
                                type: p.pattern_type || 'general',
                                atoms: p.atoms,
                                occurrences: p.occurrences,
                                discovered: p.discovered
                            }
                        });
                    }
                }
            }
        }
    } catch (error) {
        console.error(`Error processing ${file}:`, error.message);
    }
}

// Save converted patterns
const outputFile = path.join(__dirname, '../data/patterns-unified.json');
fs.writeFileSync(outputFile, JSON.stringify(outputPatterns, null, 2));

console.log(`\n✅ Converted ${outputPatterns.length} patterns`);
console.log(`📁 Saved to: ${outputFile}`);

// Show sample
console.log('\n📋 Sample patterns:');
outputPatterns.slice(0, 5).forEach((p, i) => {
    console.log(`${i + 1}. "${p.input}" -> "${p.output.substring(0, 60)}..."`);
});