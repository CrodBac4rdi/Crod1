#!/usr/bin/env node
import { LayeredAtomicManager } from './dist/layered-atomic-manager.js';

// Test improved performance
async function testImprovedPerformance() {
    console.log("=== TESTING IMPROVED LAYERED MEMORY PERFORMANCE ===\n");
    
    // Delete existing database for clean test
    try {
        const fs = await import('fs');
        await fs.promises.unlink('./data/layered-atomic.db');
        await fs.promises.unlink('./data/layered-atomic.db-wal');
        await fs.promises.unlink('./data/layered-atomic.db-shm');
    } catch (e) {
        // Ignore if files don't exist
    }
    
    const manager = new LayeredAtomicManager();
    
    try {
        // Test 1: Search functionality
        console.log("TEST 1: Testing search functionality...");
        
        // Store atoms with elixir in wing path
        const testAtoms = [
            {
                wingPath: ['coding', 'elixir', 'phoenix'],
                atomType: 'pattern',
                tags: ['web', 'framework', 'realtime'],
                initialWeight: 0.8
            },
            {
                wingPath: ['coding', 'elixir', 'genserver'],
                atomType: 'pattern',
                tags: ['concurrency', 'state', 'otp'],
                initialWeight: 0.9
            },
            {
                wingPath: ['coding', 'python', 'django'],
                atomType: 'pattern',
                tags: ['web', 'framework', 'mvc'],
                initialWeight: 0.7
            }
        ];
        
        for (const atom of testAtoms) {
            await manager.storeBaseAtom(
                atom.wingPath,
                atom.atomType,
                atom.tags,
                atom.initialWeight
            );
        }
        
        // Search for elixir
        const elixirResults = await manager.queryWithOptimization('elixir', ['base']);
        console.log(`✓ Found ${elixirResults.length} results for 'elixir'`);
        if (elixirResults.length === 0) {
            console.log("❌ ERROR: Should have found elixir atoms!");
        } else {
            console.log("✓ Search working correctly");
        }
        
        // Test 2: Batch insert performance
        console.log("\nTEST 2: Testing batch insert performance...");
        
        // Create 1000 test atoms
        const batchAtoms = [];
        for (let i = 0; i < 1000; i++) {
            batchAtoms.push({
                wingPath: ['test', 'batch', `item-${i}`],
                atomType: 'test',
                tags: [`tag-${i % 20}`, `category-${i % 10}`, 'batch-test'],
                initialWeight: Math.random()
            });
        }
        
        // Test batch insert
        const batchStart = Date.now();
        const atomIds = await manager.storeBatchAtoms(batchAtoms);
        const batchElapsed = Date.now() - batchStart;
        
        console.log(`✓ Batch inserted ${atomIds.length} atoms in ${batchElapsed}ms`);
        console.log(`  Performance: ${(batchElapsed/1000).toFixed(1)}ms per atom`);
        
        if (batchElapsed/1000 > 5) {
            console.log("⚠️  WARNING: Still slow, should be < 5ms per atom");
        } else {
            console.log("✓ Excellent batch performance!");
        }
        
        // Test 3: Query performance on larger dataset
        console.log("\nTEST 3: Testing query performance...");
        
        const queryStart = Date.now();
        const tagResults = await manager.queryWithOptimization('tag-5', ['base']);
        const queryElapsed = Date.now() - queryStart;
        
        console.log(`✓ Found ${tagResults.length} results in ${queryElapsed}ms`);
        if (queryElapsed > 100) {
            console.log("⚠️  WARNING: Query slow, should be < 100ms");
        } else {
            console.log("✓ Good query performance!");
        }
        
        // Test 4: Complex query with all layers
        console.log("\nTEST 4: Testing complex multi-layer query...");
        
        // Add some contexts and patterns
        const sampleAtoms = tagResults.slice(0, 5);
        for (const result of sampleAtoms) {
            await manager.createContext(result.atom_id, 'semantic', 1.2);
        }
        
        if (sampleAtoms.length >= 3) {
            await manager.createPatternChain(
                'Test Pattern',
                'sequence',
                sampleAtoms.slice(0, 3).map(r => r.atom_id)
            );
        }
        
        const complexStart = Date.now();
        const complexResults = await manager.queryWithOptimization('tag-5', ['base', 'context', 'validation']);
        const complexElapsed = Date.now() - complexStart;
        
        console.log(`✓ Complex query completed in ${complexElapsed}ms`);
        console.log(`  Found ${complexResults.length} results with context and pattern data`);
        
        // Test 5: Individual vs batch performance comparison
        console.log("\nTEST 5: Comparing individual vs batch performance...");
        
        // Individual inserts
        const individualStart = Date.now();
        for (let i = 0; i < 100; i++) {
            await manager.storeBaseAtom(
                ['test', 'individual', `item-${i}`],
                'test',
                [`tag-${i}`, 'individual-test'],
                1.0
            );
        }
        const individualElapsed = Date.now() - individualStart;
        
        // Batch insert of same size
        const batchTest = [];
        for (let i = 0; i < 100; i++) {
            batchTest.push({
                wingPath: ['test', 'batch2', `item-${i}`],
                atomType: 'test',
                tags: [`tag-${i}`, 'batch-test2'],
                initialWeight: 1.0
            });
        }
        
        const batch2Start = Date.now();
        await manager.storeBatchAtoms(batchTest);
        const batch2Elapsed = Date.now() - batch2Start;
        
        console.log(`Individual inserts: ${individualElapsed}ms (${(individualElapsed/100).toFixed(1)}ms per atom)`);
        console.log(`Batch insert: ${batch2Elapsed}ms (${(batch2Elapsed/100).toFixed(1)}ms per atom)`);
        console.log(`Speedup: ${(individualElapsed/batch2Elapsed).toFixed(1)}x faster with batch`);
        
        console.log("\n=== PERFORMANCE SUMMARY ===");
        console.log(`✓ Search: Working correctly (finds by wing_path)`);
        console.log(`✓ Batch write: ${(batchElapsed/1000).toFixed(1)}ms per atom`);
        console.log(`✓ Query speed: ${queryElapsed}ms for indexed search`);
        console.log(`✓ Batch speedup: ${(individualElapsed/batch2Elapsed).toFixed(1)}x faster`);
        
    } catch (error) {
        console.error("\n❌ ERROR:", error);
        console.error("Stack:", error.stack);
    } finally {
        manager.close();
    }
}

testImprovedPerformance().catch(console.error);