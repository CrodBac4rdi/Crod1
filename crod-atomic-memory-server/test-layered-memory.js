#!/usr/bin/env node

// Test script for multi-layer atomic memory system
async function testLayeredMemory() {
    console.log("=== CROD MULTI-LAYER ATOMIC MEMORY TEST ===\n");

    // Note: This would normally be done through MCP tools
    console.log("1. STORE ATOMS IN BASE LAYER:");
    console.log("   - Storing coding patterns with tags and initial weights");
    console.log("   - Example: ['coding', 'elixir', 'phoenix'] with tags: ['web', 'framework', 'realtime']");
    console.log("");

    console.log("2. CONTEXT LAYER ADJUSTMENTS:");
    console.log("   - Adjusting weights based on usage patterns");
    console.log("   - Example: weight_boost x1.5 for frequently accessed atoms");
    console.log("   - Context types: temporal, spatial, semantic, neural");
    console.log("");

    console.log("3. PATTERN VALIDATION LAYER:");
    console.log("   - Creating pattern chains from related atoms");
    console.log("   - Validating coherence, completeness, accuracy");
    console.log("   - Refactoring patterns: merge, split, optimize, reorganize");
    console.log("");

    console.log("4. CROSS-LAYER OPTIMIZATION:");
    console.log("   - Query optimization across all layers");
    console.log("   - Heat map tracking for frequently accessed atoms");
    console.log("   - Performance metrics and learning velocity");
    console.log("");

    console.log("=== ARCHITECTURE BENEFITS ===");
    console.log("✓ Base layer: Minimal storage, fast pattern matching");
    console.log("✓ Context layer: Dynamic weight adjustment without modifying base");
    console.log("✓ Validation layer: Pattern relationships and network analysis");
    console.log("✓ SQLite: ACID compliance, relational queries, proper indexing");
    console.log("");

    console.log("=== EXAMPLE MCP TOOL USAGE ===");
    console.log(`
// Store atom with references
store_atom({
    wingPath: ['coding', 'elixir', 'phoenix'],
    atomType: 'pattern',
    tags: ['web', 'framework', 'realtime', 'channels'],
    initialWeight: 0.8,
    references: [
        { refType: 'pattern', refTarget: 'websocket-pattern', refStrength: 0.9 },
        { refType: 'dependency', refTarget: 'erlang-vm', refStrength: 1.0 }
    ],
    contextType: 'semantic'
});

// Adjust context based on usage
adjust_context({
    atomId: 'atom-uuid-here',
    adjustmentType: 'weight_boost',
    adjustmentValue: 1.5,
    reason: 'High frequency access in Phoenix channel implementations'
});

// Create and validate pattern chain
create_pattern_chain({
    chainName: 'Phoenix WebSocket Flow',
    chainType: 'sequence',
    atomIds: ['connect-atom', 'channel-join-atom', 'message-handle-atom']
});

validate_pattern({
    chainId: 'chain-uuid-here'
});

// Refactor for optimization
refactor_pattern({
    chainId: 'chain-uuid-here',
    refactorType: 'optimize'
});

// Query across layers
query_layers({
    query: 'phoenix channels',
    layers: ['base', 'context', 'validation'],
    limit: 10
});
`);
}

testLayeredMemory();