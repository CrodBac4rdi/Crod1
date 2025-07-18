#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { CrodLayeredAtomicManager } from './layered-atomic-manager.js';

// CROD Layered Atomic Memory Server
const crodLayered = new CrodLayeredAtomicManager();

// Initialize server
const server = new Server(
    {
        name: "crod-layered-atomic-memory",
        version: "2.0.0",
    },
    {
        capabilities: {
            tools: {},
        },
    }
);

// Define layered tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
        {
            name: "search_meta",
            description: "Search atoms and get only meta information (tags, summary, links)",
            inputSchema: {
                type: "object",
                properties: {
                    query: { type: "string", description: "Search query" },
                    wingPaths: { 
                        type: "array", 
                        items: { type: "array", items: { type: "string" } }, 
                        description: "Optional wing paths to restrict search" 
                    },
                    limit: { type: "number", description: "Max results", default: 20 },
                    includeRelated: { 
                        type: "boolean", 
                        description: "Include first level of related atoms", 
                        default: false 
                    },
                    minRelevance: { 
                        type: "number", 
                        description: "Minimum relevance score", 
                        default: 0.3 
                    }
                },
                required: ["query"],
            },
        },
        {
            name: "get_atom_data",
            description: "Get full data for a specific atom (second layer access)",
            inputSchema: {
                type: "object",
                properties: {
                    atomId: { type: "string", description: "Atom ID to retrieve" }
                },
                required: ["atomId"],
            },
        },
        {
            name: "get_wing_structure",
            description: "Navigate wing structure without loading all atoms",
            inputSchema: {
                type: "object",
                properties: {
                    wingPath: { 
                        type: "array", 
                        items: { type: "string" }, 
                        description: "Wing path to explore (null for top level)" 
                    }
                },
            },
        },
        {
            name: "store_layered_atom",
            description: "Store atom with automatic meta extraction and layering",
            inputSchema: {
                type: "object",
                properties: {
                    wingPath: { 
                        type: "array", 
                        items: { type: "string" }, 
                        description: "Wing path like ['coding', 'elixir', 'phoenix']" 
                    },
                    atomData: { type: "object", description: "Data to store as atom" },
                    atomType: { 
                        type: "string", 
                        description: "Type of atom: fact, rule, pattern, memory, code", 
                        default: "fact" 
                    }
                },
                required: ["wingPath", "atomData"],
            },
        },
        {
            name: "link_atoms",
            description: "Create semantic links between atoms",
            inputSchema: {
                type: "object",
                properties: {
                    fromAtomId: { type: "string", description: "Source atom ID" },
                    toAtomId: { type: "string", description: "Target atom ID" },
                    linkType: { 
                        type: "string", 
                        description: "Type of link: related, extends, implements, contradicts", 
                        default: "related" 
                    }
                },
                required: ["fromAtomId", "toAtomId"],
            },
        },
        {
            name: "get_deep_context",
            description: "Get contextual atoms by following links (progressive depth)",
            inputSchema: {
                type: "object",
                properties: {
                    atomId: { type: "string", description: "Starting atom ID" },
                    depth: { 
                        type: "number", 
                        description: "How many link levels to follow", 
                        default: 2 
                    }
                },
                required: ["atomId"],
            },
        },
        {
            name: "bulk_search",
            description: "Search multiple queries and get aggregated meta results",
            inputSchema: {
                type: "object",
                properties: {
                    queries: { 
                        type: "array", 
                        items: { type: "string" }, 
                        description: "Multiple search queries" 
                    },
                    mergeStrategy: { 
                        type: "string", 
                        description: "How to merge results: union, intersection, weighted", 
                        default: "weighted" 
                    }
                },
                required: ["queries"],
            },
        }
    ],
}));

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const args = request.params.arguments;

    try {
        switch (request.params.name) {
            case "search_meta":
                const searchResults = await crodLayered.searchLayered(args.query, {
                    wingPaths: args.wingPaths,
                    limit: args.limit,
                    includeRelated: args.includeRelated,
                    minRelevance: args.minRelevance
                });
                return { 
                    content: [{ 
                        type: "text", 
                        text: JSON.stringify(searchResults, null, 2) 
                    }] 
                };

            case "get_atom_data":
                const atomData = await crodLayered.getAtomData(args.atomId);
                return { 
                    content: [{ 
                        type: "text", 
                        text: JSON.stringify(atomData, null, 2) 
                    }] 
                };

            case "get_wing_structure":
                const wingStructure = await crodLayered.getWingStructure(args.wingPath);
                return { 
                    content: [{ 
                        type: "text", 
                        text: JSON.stringify(wingStructure, null, 2) 
                    }] 
                };

            case "store_layered_atom":
                const storeResult = await crodLayered.storeLayeredAtom(
                    args.wingPath, 
                    args.atomData, 
                    args.atomType
                );
                return { 
                    content: [{ 
                        type: "text", 
                        text: JSON.stringify(storeResult, null, 2) 
                    }] 
                };

            case "link_atoms":
                const linkResult = await crodLayered.linkAtoms(
                    args.fromAtomId, 
                    args.toAtomId, 
                    args.linkType
                );
                return { 
                    content: [{ 
                        type: "text", 
                        text: JSON.stringify(linkResult, null, 2) 
                    }] 
                };

            case "get_deep_context":
                const contextResult = await crodLayered.getDeepContext(
                    args.atomId, 
                    args.depth
                );
                return { 
                    content: [{ 
                        type: "text", 
                        text: JSON.stringify(contextResult, null, 2) 
                    }] 
                };

            case "bulk_search":
                const bulkResults = await Promise.all(
                    args.queries.map(q => crodLayered.searchLayered(q, { limit: 10 }))
                );
                
                // Merge results based on strategy
                let mergedResults = [];
                if (args.mergeStrategy === 'union') {
                    const seen = new Set();
                    bulkResults.forEach(r => {
                        r.results.forEach(atom => {
                            if (!seen.has(atom.atomId)) {
                                seen.add(atom.atomId);
                                mergedResults.push(atom);
                            }
                        });
                    });
                } else if (args.mergeStrategy === 'intersection') {
                    // Find atoms that appear in all results
                    const allIds = bulkResults.map(r => 
                        new Set(r.results.map(a => a.atomId))
                    );
                    const intersection = allIds.reduce((a, b) => 
                        new Set([...a].filter(x => b.has(x)))
                    );
                    mergedResults = Array.from(intersection).map(id => {
                        return bulkResults[0].results.find(a => a.atomId === id);
                    });
                } else { // weighted
                    const weightMap = new Map();
                    bulkResults.forEach((r, idx) => {
                        r.results.forEach(atom => {
                            if (!weightMap.has(atom.atomId)) {
                                weightMap.set(atom.atomId, {
                                    ...atom,
                                    totalRelevance: 0,
                                    appearances: 0
                                });
                            }
                            const entry = weightMap.get(atom.atomId);
                            entry.totalRelevance += atom.relevance;
                            entry.appearances++;
                        });
                    });
                    mergedResults = Array.from(weightMap.values())
                        .map(e => ({
                            ...e,
                            relevance: e.totalRelevance / e.appearances
                        }))
                        .sort((a, b) => b.relevance - a.relevance)
                        .slice(0, 20);
                }

                return { 
                    content: [{ 
                        type: "text", 
                        text: JSON.stringify({
                            queries: args.queries,
                            strategy: args.mergeStrategy,
                            resultCount: mergedResults.length,
                            results: mergedResults
                        }, null, 2) 
                    }] 
                };

            default:
                throw new Error(`Unknown tool: ${request.params.name}`);
        }
    } catch (error) {
        console.error("Tool execution error:", error);
        return {
            content: [{
                type: "text",
                text: `Error: ${error.message}`
            }],
            isError: true,
        };
    }
});

// Start server
async function runServer() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("CROD Layered Atomic Memory Server running on stdio");
}

runServer().catch((error) => {
    console.error("Fatal error:", error);
    process.exit(1);
});