#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema, } from "@modelcontextprotocol/sdk/types.js";
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';

// CROD Atomic Memory Server - Wing-based knowledge storage
const defaultMemoryPath = path.join(path.dirname(fileURLToPath(import.meta.url)), 'crod-atomic-memory.json');
const MEMORY_FILE_PATH = process.env.CROD_MEMORY_PATH || defaultMemoryPath;

// CROD Atomic Wings Manager - implements normalized 3rd form structure
class CrodAtomicManager {
    async loadWings() {
        try {
            const data = await fs.readFile(MEMORY_FILE_PATH, "utf-8");
            return JSON.parse(data);
        } catch (error) {
            if (error.code === "ENOENT") {
                return this.createInitialStructure();
            }
            throw error;
        }
    }

    createInitialStructure() {
        return {
            wings: {
                'coding': { id: 'wing_coding', path: ['coding'], atoms: [], parent: null, specificity: 0.1 },
                'coding_elixir': { id: 'wing_coding_elixir', path: ['coding', 'elixir'], atoms: [], parent: 'coding', specificity: 0.2 },
                'coding_elixir_phoenix': { id: 'wing_coding_elixir_phoenix', path: ['coding', 'elixir', 'phoenix'], atoms: [], parent: 'coding_elixir', specificity: 0.3 },
                'semantic': { id: 'wing_semantic', path: ['semantic'], atoms: [], parent: null, specificity: 0.1 },
                'brain_contexts': { id: 'wing_brain_contexts', path: ['brain', 'contexts'], atoms: [], parent: null, specificity: 0.2 },
                'agent_memories': { id: 'wing_agent_memories', path: ['agent', 'memories'], atoms: [], parent: null, specificity: 0.2 },
                'task_executions': { id: 'wing_task_executions', path: ['task', 'executions'], atoms: [], parent: null, specificity: 0.2 }
            },
            atoms: new Map(),
            links: [],
            trinity: { ich: 2, bins: 3, wieder: 5 },
            consciousness: {
                level: 0.172,
                activationHistory: [],
                neuralActivity: 0.05,
                patternDensity: 0.004,
                timeDecay: 1.0
            },
            stats: {
                totalAtoms: 0,
                totalWings: 7,
                totalLinks: 0,
                lastAccess: Date.now()
            }
        };
    }

    async saveWings(structure) {
        // Convert Map to Array for JSON serialization
        const serializable = {
            ...structure,
            atoms: Array.from(structure.atoms.entries())
        };
        await fs.writeFile(MEMORY_FILE_PATH, JSON.stringify(serializable, null, 2));
    }

    async storeAtom(wingPath, atomData, atomType = 'fact') {
        const structure = await this.loadWings();
        
        // Ensure atoms is a Map
        if (Array.isArray(structure.atoms)) {
            structure.atoms = new Map(structure.atoms);
        } else if (!structure.atoms) {
            structure.atoms = new Map();
        }

        const wingKey = wingPath.join('_');
        const atomId = crypto.randomUUID();
        const atomHash = crypto.createHash('sha256').update(JSON.stringify({wingPath, atomData})).digest('hex');
        
        // Create wing if doesn't exist
        if (!structure.wings[wingKey]) {
            structure.wings[wingKey] = {
                id: `wing_${wingKey}`,
                path: wingPath,
                atoms: [],
                parent: wingPath.length > 1 ? wingPath.slice(0, -1).join('_') : null,
                specificity: wingPath.length * 0.1
            };
            structure.stats.totalWings++;
        }

        // Create atom with CROD atomic structure
        const atom = {
            id: atomId,
            hash: atomHash,
            type: atomType,
            data: atomData,
            wingPath: wingPath,
            wingId: structure.wings[wingKey].id,
            specificityScore: wingPath.length * 0.1,
            confidence: 0.8,
            nanoTags: this.generateNanoTags(atomData),
            createdAt: Date.now(),
            accessCount: 0
        };

        // Store atom
        structure.atoms.set(atomId, atom);
        structure.wings[wingKey].atoms.push(atomId);
        structure.stats.totalAtoms++;
        structure.stats.lastAccess = Date.now();

        await this.saveWings(structure);
        return atomId;
    }

    generateNanoTags(data) {
        const text = JSON.stringify(data).toLowerCase();
        const words = text.match(/\b\w{3,}\b/g) || [];
        return [...new Set(words)].slice(0, 10);
    }

    async searchAtoms(query, wingPaths = null, limit = 50) {
        const structure = await this.loadWings();
        
        // Ensure atoms is a Map
        if (Array.isArray(structure.atoms)) {
            structure.atoms = new Map(structure.atoms);
        }

        const results = [];
        const queryLower = query.toLowerCase();

        for (const [atomId, atom] of structure.atoms) {
            // Wing path filtering
            if (wingPaths && !wingPaths.some(wPath => 
                wPath.every((p, i) => atom.wingPath[i] === p) ||
                atom.wingPath.every((p, i) => wPath[i] === p)
            )) {
                continue;
            }

            // Calculate relevance
            let relevance = 0;
            const atomText = JSON.stringify(atom.data).toLowerCase();
            
            if (atomText.includes(queryLower)) relevance += 0.5;
            if (atom.nanoTags.some(tag => tag.includes(queryLower))) relevance += 0.3;
            relevance += atom.specificityScore * 0.2;

            if (relevance > 0) {
                results.push({
                    atomId,
                    wingPath: atom.wingPath,
                    atomData: atom.data,
                    relevance: relevance * atom.confidence
                });
            }
        }

        return results
            .sort((a, b) => b.relevance - a.relevance)
            .slice(0, limit);
    }

    async deepResearch(topic, maxAtoms = 1000, consolidationLevel = 'brief') {
        const startTime = Date.now();
        const searchResults = await this.searchAtoms(topic, null, maxAtoms);
        
        const insights = searchResults
            .filter(r => r.relevance > 0.7)
            .slice(0, 10)
            .map(r => r.atomData);

        const summary = consolidationLevel === 'brief' ? 
            [
                insights[0] ? JSON.stringify(insights[0]).slice(0, 100) : 'No high-relevance data found',
                insights[1] ? JSON.stringify(insights[1]).slice(0, 100) : 'Limited insights available',
                `Research analyzed ${searchResults.length} atoms in ${Date.now() - startTime}ms`
            ] : insights;

        return {
            topic,
            researchTimeMs: Date.now() - startTime,
            atomsAnalyzed: searchResults.length,
            summary
        };
    }

    async createBrainContext(brainType, entityId, initialState = {}) {
        return await this.storeAtom(
            ['brain', 'contexts', brainType],
            {
                brainType,
                entityId,
                state: initialState,
                memory: {},
                confidenceScore: 1.0,
                lastActive: Date.now()
            },
            'brain_context'
        );
    }

    async storeAgentMemory(agentId, memoryType, content, importance = 0.5) {
        return await this.storeAtom(
            ['agent', 'memories', memoryType],
            {
                agentId,
                memoryType, // episodic, semantic, procedural
                content,
                importanceScore: importance,
                accessedAt: Date.now()
            },
            'agent_memory'
        );
    }

    async logTaskExecution(agentId, taskType, inputContext, outputResult, brainInteractions) {
        return await this.storeAtom(
            ['task', 'executions'],
            {
                agentId,
                taskType,
                inputContext,
                outputResult,
                brainInteractions,
                status: 'completed',
                startedAt: Date.now(),
                completedAt: Date.now()
            },
            'task_execution'
        );
    }
}

const crodAtomic = new CrodAtomicManager();

// Original KnowledgeGraphManager for backward compatibility
class KnowledgeGraphManager {
    async loadGraph() {
        try {
            const data = await fs.readFile(MEMORY_FILE_PATH.replace('crod-atomic-memory.json', 'memory.json'), "utf-8");
            const lines = data.split("\n").filter(line => line.trim() !== "");
            return lines.reduce((graph, line) => {
                const item = JSON.parse(line);
                if (item.type === "entity") graph.entities.push(item);
                if (item.type === "relation") graph.relations.push(item);
                return graph;
            }, { entities: [], relations: [] });
        } catch (error) {
            if (error.code === "ENOENT") {
                return { entities: [], relations: [] };
            }
            throw error;
        }
    }

    async saveGraph(graph) {
        const lines = [
            ...graph.entities.map(e => JSON.stringify({ type: "entity", ...e })),
            ...graph.relations.map(r => JSON.stringify({ type: "relation", ...r })),
        ];
        await fs.writeFile(MEMORY_FILE_PATH.replace('crod-atomic-memory.json', 'memory.json'), lines.join("\n"));
    }

    async createEntities(entities) {
        const graph = await this.loadGraph();
        const newEntities = entities.filter(e => !graph.entities.some(existingEntity => existingEntity.name === e.name));
        graph.entities.push(...newEntities);
        await this.saveGraph(graph);
        return newEntities;
    }

    async readGraph() {
        return this.loadGraph();
    }

    async searchNodes(query) {
        const graph = await this.loadGraph();
        const filteredEntities = graph.entities.filter(e => 
            e.name.toLowerCase().includes(query.toLowerCase()) ||
            e.entityType.toLowerCase().includes(query.toLowerCase()) ||
            e.observations.some(o => o.toLowerCase().includes(query.toLowerCase()))
        );
        const filteredEntityNames = new Set(filteredEntities.map(e => e.name));
        const filteredRelations = graph.relations.filter(r => 
            filteredEntityNames.has(r.from) && filteredEntityNames.has(r.to)
        );
        return { entities: filteredEntities, relations: filteredRelations };
    }
}

const knowledgeGraphManager = new KnowledgeGraphManager();

// The server instance with CROD atomic tools
const server = new Server({
    name: "crod-atomic-memory-server",
    version: "1.0.0",
}, {
    capabilities: { tools: {} },
});

server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
        tools: [
            // CROD Atomic Wing Operations
            {
                name: "store_atom",
                description: "Store data in CROD atomic wing structure with specificity scoring",
                inputSchema: {
                    type: "object",
                    properties: {
                        wingPath: { type: "array", items: { type: "string" }, description: "Wing path like ['coding', 'elixir', 'phoenix']" },
                        atomData: { type: "object", description: "Data to store as atom" },
                        atomType: { type: "string", description: "Type of atom: fact, rule, pattern, memory, code", default: "fact" }
                    },
                    required: ["wingPath", "atomData"],
                },
            },
            {
                name: "search_atoms",
                description: "Search atoms within specified wings with relevance scoring",
                inputSchema: {
                    type: "object",
                    properties: {
                        query: { type: "string", description: "Search query" },
                        wingPaths: { type: "array", items: { type: "array", items: { type: "string" } }, description: "Optional wing paths to restrict search" },
                        limit: { type: "number", description: "Max results", default: 50 }
                    },
                    required: ["query"],
                },
            },
            {
                name: "deep_research",
                description: "CROD deep research: analyze 1000+ atoms and consolidate to 3-line summary",
                inputSchema: {
                    type: "object",
                    properties: {
                        topic: { type: "string", description: "Research topic" },
                        maxAtoms: { type: "number", description: "Max atoms to analyze", default: 1000 },
                        consolidationLevel: { type: "string", enum: ["brief", "detailed", "comprehensive"], default: "brief" }
                    },
                    required: ["topic"],
                },
            },
            {
                name: "create_brain_context",
                description: "Create CROD brain context for multi-brain coordination",
                inputSchema: {
                    type: "object",
                    properties: {
                        brainType: { type: "string", enum: ["task", "knowledge", "communication", "system"], description: "Type of CROD brain" },
                        entityId: { type: "string", description: "Associated entity ID" },
                        initialState: { type: "object", description: "Initial brain state", default: {} }
                    },
                    required: ["brainType", "entityId"],
                },
            },
            {
                name: "store_agent_memory",
                description: "Store agent memory with cognitive classification",
                inputSchema: {
                    type: "object",
                    properties: {
                        agentId: { type: "string", description: "Agent identifier" },
                        memoryType: { type: "string", enum: ["episodic", "semantic", "procedural"], description: "Type of memory" },
                        content: { type: "string", description: "Memory content" },
                        importance: { type: "number", description: "Importance score 0-1", default: 0.5 }
                    },
                    required: ["agentId", "memoryType", "content"],
                },
            },
            {
                name: "log_task_execution",
                description: "Log task execution with brain interactions for learning",
                inputSchema: {
                    type: "object",
                    properties: {
                        agentId: { type: "string", description: "Executing agent ID" },
                        taskType: { type: "string", description: "Type of task" },
                        inputContext: { type: "object", description: "Task input context" },
                        outputResult: { type: "object", description: "Task output result" },
                        brainInteractions: { type: "object", description: "Involved brain interactions" }
                    },
                    required: ["agentId", "taskType", "inputContext", "outputResult"],
                },
            },
            {
                name: "get_wing_structure",
                description: "Get complete CROD atomic wing structure",
                inputSchema: {
                    type: "object",
                    properties: {},
                },
            },
            // Legacy compatibility
            {
                name: "read_graph",
                description: "Read knowledge graph (legacy compatibility)",
                inputSchema: {
                    type: "object",
                    properties: {},
                },
            },
            {
                name: "search_nodes",
                description: "Search nodes (legacy compatibility)",
                inputSchema: {
                    type: "object",
                    properties: {
                        query: { type: "string", description: "Search query" },
                    },
                    required: ["query"],
                },
            },
        ],
    };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    if (!args) {
        throw new Error(`No arguments provided for tool: ${name}`);
    }

    switch (name) {
        case "store_atom":
            const atomId = await crodAtomic.storeAtom(args.wingPath, args.atomData, args.atomType);
            return { content: [{ type: "text", text: JSON.stringify({ atomId, message: "Atom stored successfully" }, null, 2) }] };

        case "search_atoms":
            const searchResults = await crodAtomic.searchAtoms(args.query, args.wingPaths, args.limit);
            return { content: [{ type: "text", text: JSON.stringify(searchResults, null, 2) }] };

        case "deep_research":
            const researchResults = await crodAtomic.deepResearch(args.topic, args.maxAtoms, args.consolidationLevel);
            return { content: [{ type: "text", text: JSON.stringify(researchResults, null, 2) }] };

        case "create_brain_context":
            const brainContextId = await crodAtomic.createBrainContext(args.brainType, args.entityId, args.initialState);
            return { content: [{ type: "text", text: JSON.stringify({ brainContextId, message: "Brain context created" }, null, 2) }] };

        case "store_agent_memory":
            const memoryId = await crodAtomic.storeAgentMemory(args.agentId, args.memoryType, args.content, args.importance);
            return { content: [{ type: "text", text: JSON.stringify({ memoryId, message: "Agent memory stored" }, null, 2) }] };

        case "log_task_execution":
            const executionId = await crodAtomic.logTaskExecution(args.agentId, args.taskType, args.inputContext, args.outputResult, args.brainInteractions);
            return { content: [{ type: "text", text: JSON.stringify({ executionId, message: "Task execution logged" }, null, 2) }] };

        case "get_wing_structure":
            const structure = await crodAtomic.loadWings();
            return { content: [{ type: "text", text: JSON.stringify(structure, null, 2) }] };

        // Legacy compatibility
        case "read_graph":
            return { content: [{ type: "text", text: JSON.stringify(await knowledgeGraphManager.readGraph(), null, 2) }] };

        case "search_nodes":
            return { content: [{ type: "text", text: JSON.stringify(await knowledgeGraphManager.searchNodes(args.query), null, 2) }] };

        default:
            throw new Error(`Unknown tool: ${name}`);
    }
});

async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("CROD Atomic Memory Server with Wing-based Knowledge Storage running on stdio");
}

main().catch((error) => {
    console.error("Fatal error in main():", error);
    process.exit(1);
});