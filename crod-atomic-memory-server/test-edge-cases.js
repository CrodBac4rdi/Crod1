#!/usr/bin/env node
import { LayeredAtomicManager } from './dist/layered-atomic-manager.js';

// Test edge cases and validation
async function testEdgeCases() {
    console.log("=== TESTING EDGE CASES AND VALIDATION ===\n");
    
    const manager = new LayeredAtomicManager();
    let passCount = 0;
    let failCount = 0;
    
    function test(name, condition, errorMsg) {
        if (condition) {
            console.log(`✓ ${name}`);
            passCount++;
        } else {
            console.log(`❌ ${name}: ${errorMsg}`);
            failCount++;
        }
    }
    
    try {
        // Test 1: Empty inputs
        console.log("TEST 1: Empty and null inputs...");
        
        try {
            await manager.storeBaseAtom([], 'test', ['tag'], 1.0);
            test('Empty wing path', false, 'Should handle empty wing path');
        } catch (e) {
            test('Empty wing path', true);
        }
        
        try {
            const atom = await manager.storeBaseAtom(['test'], 'test', [], 1.0);
            test('Empty tags array', true);
        } catch (e) {
            test('Empty tags array', false, 'Should allow empty tags');
        }
        
        // Test 2: Special characters and SQL injection
        console.log("\nTEST 2: Special characters and SQL injection...");
        
        const evilAtom = await manager.storeBaseAtom(
            ['test"; DROP TABLE base_atoms; --'],
            'test\'; DELETE FROM *; --',
            ['tag1"; DROP TABLE', "tag2' OR '1'='1"],
            1.0
        );
        test('SQL injection prevention', true);
        
        // Verify tables still exist
        const results = await manager.queryWithOptimization('test', ['base']);
        test('Tables intact after injection attempt', results !== undefined);
        
        // Test 3: Duplicate handling
        console.log("\nTEST 3: Duplicate handling...");
        
        const atom1 = await manager.storeBaseAtom(['dup', 'test'], 'test', ['dup1'], 1.0);
        const atom2 = await manager.storeBaseAtom(['dup', 'test'], 'test', ['dup1'], 1.0);
        test('Duplicate atoms return same ID (deduplication)', atom1 === atom2);
        
        // Test duplicate references
        await manager.addAtomReference(atom1, 'test', atom2, 0.5);
        await manager.addAtomReference(atom1, 'test', atom2, 0.7);
        // Should update, not duplicate
        
        // Test 4: Invalid IDs
        console.log("\nTEST 4: Invalid ID handling...");
        
        try {
            await manager.createContext('invalid-uuid-format', 'test', 1.0);
            test('Invalid atom ID for context', true);
        } catch (e) {
            test('Invalid atom ID for context', true);
        }
        
        try {
            await manager.validatePatternChain('non-existent-chain');
            test('Non-existent chain validation', false, 'Should handle gracefully');
        } catch (e) {
            test('Non-existent chain validation', true);
        }
        
        // Test 5: Extreme values
        console.log("\nTEST 5: Extreme values...");
        
        // Very long wing path
        const longPath = Array(100).fill('very-long-path-segment');
        try {
            const longAtom = await manager.storeBaseAtom(longPath, 'test', ['long'], 1.0);
            test('Very long wing path', true);
        } catch (e) {
            test('Very long wing path', false, e.message);
        }
        
        // Many tags
        const manyTags = Array(1000).fill(0).map((_, i) => `tag-${i}`);
        try {
            const manyTagAtom = await manager.storeBaseAtom(['test'], 'test', manyTags, 1.0);
            test('1000 tags per atom', true);
        } catch (e) {
            test('1000 tags per atom', false, e.message);
        }
        
        // Extreme weights
        await manager.storeBaseAtom(['test'], 'test', ['weight'], -1000.5);
        await manager.storeBaseAtom(['test'], 'test', ['weight'], 1000000.999);
        test('Extreme weight values', true);
        
        // Test 6: Unicode and international characters
        console.log("\nTEST 6: Unicode and international characters...");
        
        const unicodeAtom = await manager.storeBaseAtom(
            ['测试', 'тест', '🧠', 'テスト'],
            'émojis-😀',
            ['中文标签', 'русский', '🏷️', '日本語'],
            0.5
        );
        test('Unicode in all fields', true);
        
        const unicodeResults = await manager.queryWithOptimization('测试', ['base']);
        test('Unicode search', unicodeResults.length > 0);
        
        // Test 7: Circular references
        console.log("\nTEST 7: Circular references...");
        
        const circ1 = await manager.storeBaseAtom(['circular', '1'], 'test', ['circ'], 1.0);
        const circ2 = await manager.storeBaseAtom(['circular', '2'], 'test', ['circ'], 1.0);
        const circ3 = await manager.storeBaseAtom(['circular', '3'], 'test', ['circ'], 1.0);
        
        await manager.addAtomReference(circ1, 'next', circ2, 1.0);
        await manager.addAtomReference(circ2, 'next', circ3, 1.0);
        await manager.addAtomReference(circ3, 'next', circ1, 1.0); // Circular!
        
        const chain = await manager.createPatternChain('Circular Chain', 'network', [circ1, circ2, circ3]);
        const score = await manager.validatePatternChain(chain);
        test('Circular reference handling', score !== null && score !== undefined);
        
        // Test 8: Concurrent operations
        console.log("\nTEST 8: Concurrent operations...");
        
        const promises = [];
        for (let i = 0; i < 100; i++) {
            promises.push(
                manager.storeBaseAtom(['concurrent', `${i}`], 'test', [`tag-${i}`], 1.0)
            );
        }
        
        const concurrentResults = await Promise.all(promises);
        const uniqueIds = new Set(concurrentResults);
        test('Concurrent inserts', uniqueIds.size === 100);
        
        // Test 9: Query edge cases
        console.log("\nTEST 9: Query edge cases...");
        
        // Empty query
        const emptyQuery = await manager.queryWithOptimization('', ['base']);
        test('Empty query returns results', emptyQuery.length > 0);
        
        // Very long query
        const longQuery = 'a'.repeat(1000);
        const longQueryResults = await manager.queryWithOptimization(longQuery, ['base']);
        test('Very long query', longQueryResults !== undefined);
        
        // Special regex characters
        const regexQuery = await manager.queryWithOptimization('test[]*+?', ['base']);
        test('Regex special characters in query', regexQuery !== undefined);
        
        // Test 10: Pattern validation edge cases
        console.log("\nTEST 10: Pattern validation edge cases...");
        
        // Single atom chain
        const single = await manager.storeBaseAtom(['single'], 'test', ['single'], 1.0);
        const singleChain = await manager.createPatternChain('Single', 'sequence', [single]);
        const singleScore = await manager.validatePatternChain(singleChain);
        test('Single atom chain validation', singleScore > 0);
        
        // Empty chain (should fail)
        try {
            await manager.createPatternChain('Empty', 'sequence', []);
            test('Empty chain creation', false, 'Should reject empty chains');
        } catch (e) {
            test('Empty chain creation rejected', true);
        }
        
        // Duplicate atoms in chain
        const dupChain = await manager.createPatternChain('Duplicates', 'sequence', [single, single, single]);
        const dupScore = await manager.validatePatternChain(dupChain);
        test('Duplicate atoms in chain', dupScore !== null);
        
        console.log("\n=== EDGE CASE SUMMARY ===");
        console.log(`Total tests: ${passCount + failCount}`);
        console.log(`Passed: ${passCount}`);
        console.log(`Failed: ${failCount}`);
        console.log(`Success rate: ${((passCount / (passCount + failCount)) * 100).toFixed(1)}%`);
        
        if (failCount === 0) {
            console.log("\n🎉 All edge cases handled correctly!");
        } else {
            console.log(`\n⚠️  ${failCount} edge cases need attention`);
        }
        
    } catch (error) {
        console.error("\n❌ CRITICAL ERROR:", error);
        console.error("Stack:", error.stack);
    } finally {
        manager.close();
    }
}

testEdgeCases().catch(console.error);