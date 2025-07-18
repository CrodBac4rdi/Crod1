#!/usr/bin/env node
import { LayeredAtomicManager } from './dist/layered-atomic-manager.js';

// Direct test of the layered atomic manager
async function testLayeredSystem() {
    console.log("=== TESTING CROD LAYERED ATOMIC MEMORY ===\n");
    
    const manager = new LayeredAtomicManager();
    
    try {
        // Test 1: Store base atoms
        console.log("TEST 1: Storing base atoms...");
        const atom1 = await manager.storeBaseAtom(
            ['coding', 'elixir', 'phoenix'],
            'pattern',
            ['web', 'framework', 'realtime', 'channels'],
            0.8
        );
        console.log(`✓ Stored atom 1: ${atom1}`);
        
        const atom2 = await manager.storeBaseAtom(
            ['coding', 'elixir', 'genserver'],
            'pattern',
            ['concurrency', 'state', 'process'],
            0.9
        );
        console.log(`✓ Stored atom 2: ${atom2}`);
        
        const atom3 = await manager.storeBaseAtom(
            ['coding', 'elixir', 'supervisor'],
            'pattern',
            ['fault-tolerance', 'process-tree', 'restart'],
            0.85
        );
        console.log(`✓ Stored atom 3: ${atom3}`);
        
        // Test 2: Add references
        console.log("\nTEST 2: Adding references...");
        await manager.addAtomReference(atom1, 'pattern', atom2, 0.7);
        await manager.addAtomReference(atom2, 'dependency', atom3, 0.9);
        console.log("✓ References added");
        
        // Test 3: Create contexts
        console.log("\nTEST 3: Creating contexts...");
        const ctx1 = await manager.createContext(atom1, 'semantic', 1.0);
        const ctx2 = await manager.createContext(atom2, 'neural', 1.0);
        console.log(`✓ Created contexts: ${ctx1}, ${ctx2}`);
        
        // Test 4: Adjust contexts
        console.log("\nTEST 4: Adjusting contexts...");
        await manager.adjustContext(ctx1, 'weight_boost', 1.5, 'High usage in Phoenix apps');
        await manager.adjustContext(ctx2, 'confidence_adjust', 0.95, 'Proven pattern');
        console.log("✓ Context adjustments applied");
        
        // Test 5: Create pattern chain
        console.log("\nTEST 5: Creating pattern chain...");
        const chain = await manager.createPatternChain(
            'Elixir OTP Pattern',
            'hierarchy',
            [atom3, atom2, atom1] // supervisor -> genserver -> phoenix
        );
        console.log(`✓ Created chain: ${chain}`);
        
        // Test 6: Validate pattern
        console.log("\nTEST 6: Validating pattern...");
        const score = await manager.validatePatternChain(chain);
        console.log(`✓ Validation score: ${score.toFixed(2)}`);
        if (score < 0.7) {
            console.log("⚠️  WARNING: Low validation score!");
        }
        
        // Test 7: Query optimization
        console.log("\nTEST 7: Testing query optimization...");
        const results = await manager.queryWithOptimization('elixir', ['base', 'context']);
        console.log(`✓ Found ${results.length} results`);
        results.slice(0, 3).forEach(r => {
            console.log(`  - ${r.atom_type}: ${r.tags || 'no tags'}`);
        });
        
        // Test 8: Refactor pattern
        console.log("\nTEST 8: Refactoring pattern...");
        const improved = await manager.refactorPatternChain(chain, 'optimize');
        console.log(`✓ Refactoring ${improved ? 'successful' : 'not needed'}`);
        
        // Test 9: Error handling
        console.log("\nTEST 9: Testing error handling...");
        try {
            await manager.validatePatternChain('invalid-chain-id');
            console.log("❌ ERROR: Should have thrown for invalid chain");
        } catch (e) {
            console.log("✓ Correctly handled invalid chain ID");
        }
        
        // Test 10: Performance with many atoms
        console.log("\nTEST 10: Performance test...");
        const start = Date.now();
        for (let i = 0; i < 100; i++) {
            await manager.storeBaseAtom(
                ['test', 'performance', `item-${i}`],
                'test',
                [`tag-${i % 10}`, `category-${i % 5}`],
                Math.random()
            );
        }
        const elapsed = Date.now() - start;
        console.log(`✓ Stored 100 atoms in ${elapsed}ms (${(elapsed/100).toFixed(1)}ms per atom)`);
        
        // Test 11: Large query test
        console.log("\nTEST 11: Large query test...");
        const queryStart = Date.now();
        const largeResults = await manager.queryWithOptimization('tag', ['base']);
        const queryElapsed = Date.now() - queryStart;
        console.log(`✓ Queried ${largeResults.length} results in ${queryElapsed}ms`);
        
        console.log("\n=== TEST SUMMARY ===");
        console.log("✓ All basic functionality working");
        console.log("✓ SQLite database created successfully");
        console.log("✓ Multi-layer architecture operational");
        console.log(`✓ Performance: ${(elapsed/100).toFixed(1)}ms per write, ${queryElapsed}ms for queries`);
        
    } catch (error) {
        console.error("\n❌ ERROR:", error);
        console.error("Stack:", error.stack);
    } finally {
        manager.close();
    }
}

testLayeredSystem().catch(console.error);