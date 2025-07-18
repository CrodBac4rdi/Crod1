#!/usr/bin/env node
import { LayeredAtomicManager } from './dist/layered-atomic-manager.js';
import fs from 'fs';

// Test persistence across restarts
async function testPersistence() {
    console.log("=== TESTING PERSISTENCE ACROSS RESTARTS ===\n");
    
    const dbPath = './data/layered-atomic.db';
    
    // Phase 1: Write data
    console.log("PHASE 1: Writing test data...");
    {
        const manager = new LayeredAtomicManager();
        
        // Store some atoms
        const atom1 = await manager.storeBaseAtom(
            ['persistence', 'test', 'atom1'],
            'test',
            ['persist', 'restart', 'test'],
            0.99
        );
        console.log(`✓ Stored atom 1: ${atom1}`);
        
        // Create context
        const ctx = await manager.createContext(atom1, 'semantic', 1.5);
        await manager.adjustContext(ctx, 'weight_boost', 2.0, 'Testing persistence');
        console.log(`✓ Created and adjusted context: ${ctx}`);
        
        // Create pattern chain
        const atom2 = await manager.storeBaseAtom(['persistence', 'test', 'atom2'], 'test', ['persist2'], 0.95);
        const atom3 = await manager.storeBaseAtom(['persistence', 'test', 'atom3'], 'test', ['persist3'], 0.90);
        
        const chain = await manager.createPatternChain(
            'Persistence Test Chain',
            'sequence',
            [atom1, atom2, atom3]
        );
        console.log(`✓ Created pattern chain: ${chain}`);
        
        // Close to ensure writes are flushed
        manager.close();
    }
    
    // Check file exists and has data
    const stats = fs.statSync(dbPath);
    console.log(`\nDatabase file size: ${stats.size} bytes`);
    
    // Phase 2: Read data after "restart"
    console.log("\nPHASE 2: Reading data after simulated restart...");
    {
        const manager2 = new LayeredAtomicManager();
        
        // Search for our atoms
        const results = await manager2.queryWithOptimization('persistence', ['base', 'context', 'validation']);
        console.log(`✓ Found ${results.length} persistence test atoms`);
        
        if (results.length === 0) {
            console.log("❌ ERROR: Data not persisted!");
        } else {
            console.log("✓ Data successfully persisted and retrieved");
            
            // Check if contexts were preserved
            const hasContexts = results.some(r => r.contexts && r.contexts.length > 0);
            console.log(`✓ Contexts preserved: ${hasContexts}`);
            
            // Check if patterns were preserved
            const hasPatterns = results.some(r => r.patterns && r.patterns.length > 0);
            console.log(`✓ Patterns preserved: ${hasPatterns}`);
        }
        
        manager2.close();
    }
    
    // Phase 3: Test actual process restart
    console.log("\nPHASE 3: Testing with actual subprocess restart...");
    
    // Write a unique marker
    const marker = `restart-test-${Date.now()}`;
    {
        const manager3 = new LayeredAtomicManager();
        await manager3.storeBaseAtom(['restart', 'marker'], 'marker', [marker], 1.0);
        manager3.close();
    }
    
    // Spawn a subprocess to verify
    const { spawn } = await import('child_process');
    const verifyProcess = spawn('node', ['-e', `
        import { LayeredAtomicManager } from './dist/layered-atomic-manager.js';
        
        const manager = new LayeredAtomicManager();
        const results = await manager.queryWithOptimization('${marker}', ['base']);
        console.log(results.length > 0 ? 'SUBPROCESS: Found marker' : 'SUBPROCESS: Marker lost');
        manager.close();
    `], { cwd: process.cwd() });
    
    verifyProcess.stdout.on('data', (data) => {
        console.log(`✓ ${data.toString().trim()}`);
    });
    
    verifyProcess.stderr.on('data', (data) => {
        console.error(`❌ Subprocess error: ${data}`);
    });
    
    await new Promise(resolve => verifyProcess.on('close', resolve));
    
    console.log("\n=== PERSISTENCE TEST COMPLETE ===");
}

testPersistence().catch(console.error);