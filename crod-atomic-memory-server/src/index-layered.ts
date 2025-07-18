#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { LayeredAtomicManager } from './layered-atomic-manager.js';
import crypto from 'crypto';

const layeredManager = new LayeredAtomicManager();

// MCP Server with layered atomic memory
const server = new Server({
    name: "crod-layered-atomic-memory",
    version: "2.0.0",
}, {
    capabilities: {
        tools: {},
    },
});

// Tool definitions
server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
        {
            name: "store_atom",
            description: "Store atom in multi-layer structure with tags, refs, and weights",
            inputSchema: {
                type: "object",
                properties: {
                    wingPath: {
                        type: "array",
                        items: { type: "string" },
                        description: "Wing path like ['coding', 'elixir', 'phoenix']"
                    },
                    atomType: {
                        type: "string",
                        default: "fact",
                        description: "Type of atom: fact, rule, pattern, memory, code"
                    },
                    tags: {
                        type: "array",
                        items: { type: "string" },
                        description: "Tags for pattern matching"
                    },
                    initialWeight: {
                        type: "number",
                        default: 1.0,
                        description: "Initial weight of the atom"
                    },
                    references: {
                        type: "array",
                        items: {
                            type: "object",
                            properties: {
                                refType: { type: "string" },
                                refTarget: { type: "string" },
                                refStrength: { type: "number", default: 0.5 }
                            },
                            required: ["refType", "refTarget"]
                        },
                        description: "References to other atoms or patterns"
                    },
                    contextType: {
                        type: "string",
                        description: "Context type: temporal, spatial, semantic, neural"
                    }
                },
                required: ["wingPath", "tags"]
            }
        },
        {
            name: "adjust_context",
            description: "Adjust atom context weights and values for optimization",
            inputSchema: {
                type: "object",
                properties: {
                    atomId: {
                        type: "string",
                        description: "Atom ID to adjust"
                    },
                    adjustmentType: {
                        type: "string",
                        description: "Type: weight_boost, confidence_adjust, relevance_tune"
                    },
                    adjustmentValue: {
                        type: "number",
                        description: "Adjustment multiplier or value"
                    },
                    reason: {
                        type: "string",
                        description: "Reason for adjustment"
                    }
                },
                required: ["atomId", "adjustmentType", "adjustmentValue"]
            }
        },
        {
            name: "create_pattern_chain",
            description: "Create pattern chain from atoms for validation",
            inputSchema: {
                type: "object",
                properties: {
                    chainName: {
                        type: "string",
                        description: "Name of the pattern chain"
                    },
                    chainType: {
                        type: "string",
                        description: "Type: sequence, network, hierarchy, cluster"
                    },
                    atomIds: {
                        type: "array",
                        items: { type: "string" },
                        description: "Ordered array of atom IDs"
                    }
                },
                required: ["chainName", "chainType", "atomIds"]
            }
        },
        {
            name: "validate_pattern",
            description: "Validate pattern chain for coherence and accuracy",
            inputSchema: {
                type: "object",
                properties: {
                    chainId: {
                        type: "string",
                        description: "Pattern chain ID to validate"
                    }
                },
                required: ["chainId"]
            }
        },
        {
            name: "refactor_pattern",
            description: "Refactor pattern chain for optimization",
            inputSchema: {
                type: "object",
                properties: {
                    chainId: {
                        type: "string",
                        description: "Pattern chain ID to refactor"
                    },
                    refactorType: {
                        type: "string",
                        description: "Type: merge, split, optimize, reorganize"
                    }
                },
                required: ["chainId", "refactorType"]
            }
        },
        {
            name: "query_layers",
            description: "Query across multiple layers with optimization",
            inputSchema: {
                type: "object",
                properties: {
                    query: {
                        type: "string",
                        description: "Search query"
                    },
                    layers: {
                        type: "array",
                        items: { type: "string" },
                        default: ["base", "context", "validation"],
                        description: "Layers to search: base, context, validation"
                    },
                    limit: {
                        type: "number",
                        default: 50,
                        description: "Maximum results"
                    }
                },
                required: ["query"]
            }
        },
        {
            name: "deep_research",
            description: "Deep research with multi-layer analysis",
            inputSchema: {
                type: "object",
                properties: {
                    topic: {
                        type: "string",
                        description: "Research topic"
                    },
                    maxAtoms: {
                        type: "number",
                        default: 1000,
                        description: "Max atoms to analyze"
                    },
                    consolidationLevel: {
                        type: "string",
                        enum: ["brief", "detailed", "comprehensive"],
                        default: "brief"
                    }
                },
                required: ["topic"]
            }
        },
        // Legacy compatibility tools
        {
            name: "search_atoms",
            description: "Search atoms (legacy compatibility)",
            inputSchema: {
                type: "object",
                properties: {
                    query: { type: "string", description: "Search query" },
                    wingPaths: {
                        type: "array",
                        items: { type: "array", items: { type: "string" } },
                        description: "Optional wing paths to restrict search"
                    },
                    limit: { type: "number", default: 50, description: "Max results" }
                },
                required: ["query"]
            }
        }
    ],
}));

// Tool handlers
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    
    if (!args) {
        return {
            content: [{
                type: "text",
                text: JSON.stringify({ error: "No arguments provided" }, null, 2)
            }]
        };
    }

    try {
        switch (name) {
            case "store_atom": {
                // Store in base layer
                const atomId = await layeredManager.storeBaseAtom(
                    args.wingPath as string[],
                    args.atomType as string || 'fact',
                    args.tags as string[],
                    args.initialWeight as number || 1.0
                );

                // Add references if provided
                if (args.references) {
                    const references = args.references as Array<{
                        refType: string;
                        refTarget: string;
                        refStrength?: number;
                    }>;
                    for (const ref of references) {
                        await layeredManager.addAtomReference(
                            atomId,
                            ref.refType,
                            ref.refTarget,
                            ref.refStrength || 0.5
                        );
                    }
                }

                // Create context if specified
                let contextId = null;
                if (args.contextType) {
                    contextId = await layeredManager.createContext(
                        atomId,
                        args.contextType as string,
                        args.initialWeight as number || 1.0
                    );
                }

                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify({
                            success: true,
                            atomId,
                            contextId,
                            message: "Atom stored in layered structure"
                        }, null, 2)
                    }]
                };
            }

            case "adjust_context": {
                // Find or create context for the atom
                const contexts = await layeredManager.queryWithOptimization(
                    args.atomId as string,
                    ['context']
                );

                let contextId = contexts[0]?.contexts?.[0]?.context_id;
                
                if (!contextId) {
                    // Create new context if none exists
                    contextId = await layeredManager.createContext(
                        args.atomId as string,
                        'dynamic',
                        1.0
                    );
                }

                await layeredManager.adjustContext(
                    contextId,
                    args.adjustmentType as string,
                    args.adjustmentValue as number,
                    args.reason as string
                );

                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify({
                            success: true,
                            contextId,
                            adjustmentApplied: true
                        }, null, 2)
                    }]
                };
            }

            case "create_pattern_chain": {
                const chainId = await layeredManager.createPatternChain(
                    args.chainName as string,
                    args.chainType as string,
                    args.atomIds as string[]
                );

                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify({
                            success: true,
                            chainId,
                            atomCount: (args.atomIds as string[]).length
                        }, null, 2)
                    }]
                };
            }

            case "validate_pattern": {
                const validationScore = await layeredManager.validatePatternChain(
                    args.chainId as string
                );

                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify({
                            success: true,
                            chainId: args.chainId as string,
                            validationScore,
                            status: validationScore > 0.7 ? 'valid' : 'needs_improvement'
                        }, null, 2)
                    }]
                };
            }

            case "refactor_pattern": {
                const improved = await layeredManager.refactorPatternChain(
                    args.chainId as string,
                    args.refactorType as string
                );

                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify({
                            success: true,
                            chainId: args.chainId as string,
                            refactored: improved,
                            message: improved ? 'Pattern refactored successfully' : 'No improvements found'
                        }, null, 2)
                    }]
                };
            }

            case "query_layers": {
                const results = await layeredManager.queryWithOptimization(
                    args.query as string,
                    args.layers as string[] || ['base', 'context', 'validation']
                );

                // Format results with layer information
                const formattedResults = results.slice(0, (args.limit as number) || 50).map((r: any) => ({
                    atomId: r.atom_id,
                    atomType: r.atom_type,
                    layer: r.layer,
                    tags: r.tags?.split(',') || [],
                    weight: r.initial_weight,
                    contexts: r.contexts?.map((c: any) => ({
                        type: c.context_type,
                        adjustedWeight: c.adjusted_weight,
                        confidence: c.confidence_score
                    })) || [],
                    patterns: r.patterns?.map((p: any) => ({
                        chainName: p.chain_name,
                        role: p.role,
                        validationScore: p.validation_score
                    })) || []
                }));

                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify({
                            query: args.query as string,
                            resultsFound: formattedResults.length,
                            results: formattedResults
                        }, null, 2)
                    }]
                };
            }

            case "deep_research": {
                const results = await layeredManager.queryWithOptimization(
                    args.topic as string,
                    ['base', 'context', 'validation']
                );

                // Analyze patterns and relationships
                const patternAnalysis = results
                    .filter((r: any) => r.patterns && r.patterns.length > 0)
                    .map((r: any) => ({
                        atom: r.atom_id,
                        participatesIn: r.patterns.length,
                        averageValidation: r.patterns.reduce((sum: number, p: any) => 
                            sum + p.validation_score, 0) / r.patterns.length
                    }));

                // High-relevance insights
                const insights = results
                    .filter((r: any) => r.contexts && r.contexts.some((c: any) => c.confidence_score > 0.8))
                    .slice(0, 10)
                    .map((r: any) => ({
                        id: r.atom_id,
                        type: r.atom_type,
                        tags: r.tags?.split(',') || [],
                        confidence: Math.max(...(r.contexts || []).map((c: any) => c.confidence_score || 0))
                    }));

                const consolidation = (args.consolidationLevel as string) === 'brief' ? 
                    [
                        `Found ${results.length} relevant atoms across layers`,
                        `${patternAnalysis.length} atoms participate in validated patterns`,
                        `Top insight: ${insights[0]?.tags?.join(', ') || 'No high-confidence insights'}`
                    ] : {
                        totalResults: results.length,
                        patternAnalysis,
                        topInsights: insights,
                        layerDistribution: {
                            base: results.filter(r => r.layer === 'base').length,
                            withContext: results.filter(r => r.contexts?.length > 0).length,
                            inPatterns: results.filter(r => r.patterns?.length > 0).length
                        }
                    };

                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify({
                            topic: args.topic as string,
                            atomsAnalyzed: results.length,
                            summary: consolidation
                        }, null, 2)
                    }]
                };
            }

            case "search_atoms": {
                // Legacy compatibility - map to query_layers
                const results = await layeredManager.queryWithOptimization(
                    args.query as string,
                    ['base']
                );

                const atomResults = results.slice(0, (args.limit as number) || 50).map((r: any) => ({
                    atomId: r.atom_id,
                    wingPath: JSON.parse(r.wing_path),
                    atomData: {
                        type: r.atom_type,
                        tags: r.tags?.split(',') || [],
                        weight: r.initial_weight
                    },
                    relevance: 0.8 // Default relevance for compatibility
                }));

                return {
                    content: [{
                        type: "text",
                        text: JSON.stringify(atomResults, null, 2)
                    }]
                };
            }

            default:
                throw new Error(`Unknown tool: ${name}`);
        }
    } catch (error) {
        return {
            content: [{
                type: "text",
                text: JSON.stringify({
                    error: error instanceof Error ? error.message : String(error),
                    tool: name
                }, null, 2)
            }]
        };
    }
});

// Start server
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("CROD Layered Atomic Memory Server running...");
}

main().catch((error) => {
    console.error("Server error:", error);
    process.exit(1);
});