# CROD Layered Atomic Memory Guide

## Overview

The CROD Layered Memory implements progressive disclosure to prevent token explosion while maintaining rich interconnected knowledge.

## Key Concepts

### 1. Progressive Disclosure
- **Layer 1**: Meta information only (tags, summary, links)
- **Layer 2**: Full atom data (accessed on demand)
- **Layer 3**: Deep context (following semantic links)

### 2. Wing Structure
```
coding/
├── elixir/
│   ├── phoenix/     (LiveView patterns, routing, etc.)
│   └── genserver/   (OTP patterns, state management)
├── javascript/
└── docker/

semantic/
└── concepts/        (Actor Model, Concurrency, etc.)
```

### 3. Atom Structure
```javascript
// Meta Layer (always returned in search)
{
  atomId: "uuid",
  summary: "First 100 chars...",
  tags: ["elixir", "phoenix"],
  wingPath: ["coding", "elixir", "phoenix"],
  relevance: 0.85,
  relatedCount: 3,
  size: 1024
}

// Full Data (fetched separately)
{
  meta: { /* same as above */ },
  data: { /* complete atom content */ }
}
```

## Usage Examples

### 1. Search Without Token Explosion
```javascript
// Returns only meta information
const results = await search_meta({
  query: "phoenix liveview",
  limit: 10,
  includeRelated: true
});

// Results contain summaries and tags, not full content
results.results.forEach(atom => {
  console.log(atom.summary); // Just the summary
  console.log(atom.atomId);  // ID to fetch full data if needed
});
```

### 2. Navigate Wings Without Loading Data
```javascript
// Get wing structure
const wings = await get_wing_structure();

// Explore specific wing
const phoenixWing = await get_wing_structure(["coding", "elixir", "phoenix"]);
// Returns atom count and recent summaries, not full data
```

### 3. Selective Data Access
```javascript
// First, search for relevant atoms
const search = await search_meta({ query: "genserver patterns" });

// Then, fetch only the specific atom you need
const atomData = await get_atom_data(search.results[0].atomId);
// Now you have the full data for just this one atom
```

### 4. Follow Semantic Links
```javascript
// Get context by following links
const context = await get_deep_context({
  atomId: "some-uuid",
  depth: 2  // Follow links 2 levels deep
});

// Returns meta info for connected atoms, not full data
```

### 5. Bulk Search with Merge Strategies
```javascript
// Search multiple terms
const bulk = await bulk_search({
  queries: ["elixir", "phoenix", "websocket"],
  mergeStrategy: "weighted"  // or "union", "intersection"
});
```

## Best Practices

1. **Start with Meta Search**: Always search first to find relevant atoms
2. **Navigate by Wings**: Use wing structure to explore domains
3. **Fetch on Demand**: Only get full data for atoms you need
4. **Use Links**: Follow semantic connections for context
5. **Track Heat**: Frequently accessed items have higher heat scores

## MCP Tool Reference

### search_meta
- Search with meta results only
- Options: query, wingPaths, limit, includeRelated, minRelevance

### get_atom_data
- Fetch full data for specific atom
- Increases heat score on access

### get_wing_structure
- Navigate wing hierarchy
- Returns counts and summaries only

### store_layered_atom
- Auto-extracts meta information
- Creates summaries and tags

### link_atoms
- Create semantic connections
- Types: related, extends, implements, contradicts

### get_deep_context
- Follow links progressively
- Control depth of exploration

### bulk_search
- Multiple queries at once
- Merge strategies for results

## Benefits

1. **No Token Explosion**: Search 1000s of atoms without overwhelming context
2. **Targeted Access**: Get exactly what you need, when you need it
3. **Rich Navigation**: Explore structure without loading content
4. **Semantic Connections**: Follow relationships progressively
5. **Heat Optimization**: Frequently used knowledge surfaces faster

## Integration

The layered memory is available as an MCP server:
```json
{
  "crod-layered-memory": {
    "command": "node",
    "args": ["/path/to/index-layered.js"],
    "env": {
      "CROD_LAYERED_MEMORY_PATH": "/path/to/storage.json"
    }
  }
}
```

Use it in your Claude conversations to maintain context without token overflow!