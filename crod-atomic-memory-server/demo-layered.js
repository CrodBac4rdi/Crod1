#!/usr/bin/env node
import { CrodLayeredAtomicManager } from './dist/layered-atomic-manager.js';

// Demo of CROD Layered Atomic Memory
async function demo() {
    const manager = new CrodLayeredAtomicManager();
    
    console.log("🧠 CROD Layered Atomic Memory Demo\n");
    console.log("=== Progressive Disclosure System ===\n");

    // Store some example atoms
    console.log("1️⃣ Storing atoms with automatic meta extraction...\n");
    
    const atom1 = await manager.storeLayeredAtom(
        ['coding', 'elixir', 'phoenix'],
        {
            title: "Phoenix LiveView Pattern",
            content: "LiveView enables rich, real-time user experiences with server-rendered HTML. It uses WebSockets for bidirectional communication.",
            code: "def mount(_params, _session, socket) do {:ok, assign(socket, :count, 0)} end",
            tags: ['liveview', 'websocket', 'real-time']
        },
        'pattern'
    );
    console.log("✅ Stored:", atom1);

    const atom2 = await manager.storeLayeredAtom(
        ['coding', 'elixir', 'genserver'],
        {
            title: "GenServer State Management",
            content: "GenServer provides a generic server behavior for managing state in Elixir applications.",
            pattern: "def handle_call(:get_state, _from, state) do {:reply, state, state} end",
            tags: ['genserver', 'state', 'otp']
        },
        'pattern'
    );

    const atom3 = await manager.storeLayeredAtom(
        ['semantic', 'concepts'],
        {
            concept: "Actor Model",
            definition: "A mathematical model of concurrent computation where actors are the fundamental units.",
            examples: ['Erlang', 'Elixir', 'Akka'],
            relatedTo: ['concurrency', 'message-passing', 'fault-tolerance']
        },
        'fact'
    );

    // Link atoms
    console.log("\n2️⃣ Creating semantic links between atoms...\n");
    await manager.linkAtoms(atom2.atomId, atom3.atomId, 'implements');
    console.log("✅ Linked GenServer to Actor Model");

    // Demo progressive search
    console.log("\n3️⃣ Progressive Search - Layer 1 (Meta only)...\n");
    
    const searchResults = await manager.searchLayered('elixir', {
        limit: 5,
        includeRelated: true
    });
    
    console.log("Search for 'elixir' returns only meta information:");
    console.log(JSON.stringify(searchResults, null, 2));
    
    // Show wing navigation
    console.log("\n4️⃣ Wing Navigation (without loading atoms)...\n");
    
    const topWings = await manager.getWingStructure();
    console.log("Top-level wings:");
    console.log(JSON.stringify(topWings, null, 2));
    
    const codingWing = await manager.getWingStructure(['coding']);
    console.log("\nCoding wing details:");
    console.log(JSON.stringify(codingWing, null, 2));

    // Demo accessing specific atom data
    console.log("\n5️⃣ Accessing specific atom data (Layer 2)...\n");
    
    if (searchResults.results.length > 0) {
        const firstAtomId = searchResults.results[0].atomId;
        console.log(`Fetching full data for atom: ${firstAtomId}`);
        
        const fullData = await manager.getAtomData(firstAtomId);
        console.log("\nFull atom data:");
        console.log(JSON.stringify(fullData, null, 2));
    }

    // Demo deep context navigation
    console.log("\n6️⃣ Deep Context Navigation (following links)...\n");
    
    const deepContext = await manager.getDeepContext(atom2.atomId, 2);
    console.log("Context around GenServer atom:");
    console.log(JSON.stringify(deepContext, null, 2));

    // Demo bulk search
    console.log("\n7️⃣ Bulk Search with Weighted Merge...\n");
    
    const bulkResults = await manager.searchLayered('elixir phoenix websocket', {
        limit: 3
    });
    console.log("Multi-term search results:");
    console.log(JSON.stringify(bulkResults, null, 2));

    console.log("\n✨ Demo complete! The layered system provides:");
    console.log("- Meta-only search results (no token explosion)");
    console.log("- Progressive data access (fetch only what you need)");
    console.log("- Wing-based navigation (explore structure without data)");
    console.log("- Semantic linking (follow relationships progressively)");
    console.log("- Heat tracking (frequently accessed items bubble up)");
}

// Run demo
demo().catch(console.error);