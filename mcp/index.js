#!/usr/bin/env node
/**
 * ENHANCED CROD MCP Server
 * With pattern learning and decision tracking
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Import THE ONE CROD Brain
const TheOneCRODBrainLLM = require(path.join(__dirname, '../core/crod-brain.js'));

class EnhancedCRODServer {
    constructor() {
        this.server = new Server({
            name: 'crod-minimal',
            version: '2.0.0'
        }, {
            capabilities: {
                tools: {}
            }
        });
        
        // Initialize enhanced brain
        this.brain = new TheOneCRODBrainLLM();
        
        // Pattern learning storage
        this.learnedPatterns = [];
        this.patternLogPath = path.join(__dirname, '..', 'data', 'learned-patterns.jsonl');
        
        this.setupHandlers();
    }

    async initialize() {
        console.error('🧠 Initializing Enhanced CROD Brain...');
        const success = await this.brain.initialize();
        if (!success) {
            throw new Error('Failed to initialize CROD brain');
        }
        console.error('✅ Enhanced CROD Brain ready with LLM!');
    }

    setupHandlers() {
        this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
            tools: [
                {
                    name: 'crod_process',
                    description: 'Process input through CROD confidence with LLM enhancement',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            input: { 
                                type: 'string', 
                                description: 'Input to process' 
                            },
                            context: {
                                type: 'object',
                                description: 'Optional context for better understanding',
                                properties: {
                                    mood: { type: 'string' },
                                    previousError: { type: 'string' }
                                }
                            }
                        },
                        required: ['input']
                    }
                },
                {
                    name: 'crod_learn_pattern',
                    description: 'Teach CROD a new pattern based on current conversation',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            pattern: { 
                                type: 'string', 
                                description: 'The input pattern to learn' 
                            },
                            response: { 
                                type: 'string', 
                                description: 'The desired response' 
                            },
                            context: {
                                type: 'object',
                                description: 'Context for when to use this pattern',
                                properties: {
                                    mood: { type: 'string' },
                                    keywords: { 
                                        type: 'array',
                                        items: { type: 'string' }
                                    },
                                    action: { type: 'string' }
                                }
                            }
                        },
                        required: ['pattern', 'response']
                    }
                },
                {
                    name: 'crod_get_decisions',
                    description: 'Get recent decision history to see how CROD processed inputs',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            limit: { 
                                type: 'number', 
                                description: 'Number of decisions to return',
                                default: 10
                            }
                        }
                    }
                },
                {
                    name: 'crod_feedback',
                    description: 'Provide feedback on a CROD decision',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            decisionId: { 
                                type: 'string', 
                                description: 'ID of the decision to provide feedback on' 
                            },
                            success: { 
                                type: 'boolean', 
                                description: 'Was the response helpful?' 
                            },
                            notes: {
                                type: 'string',
                                description: 'Additional feedback notes'
                            }
                        },
                        required: ['decisionId', 'success']
                    }
                },
                {
                    name: 'crod_status',
                    description: 'Get CROD brain status including LLM state',
                    inputSchema: {
                        type: 'object',
                        properties: {}
                    }
                },
                {
                    name: 'crod_trinity',
                    description: 'Activate trinity sequence',
                    inputSchema: {
                        type: 'object',
                        properties: {}
                    }
                },
                {
                    name: 'crod_suggest_chain',
                    description: 'Get smart prompt chain suggestions for complex tasks',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            input: {
                                type: 'string',
                                description: 'The task description'
                            }
                        },
                        required: ['input']
                    }
                },
                {
                    name: 'crod_analyze_vibe',
                    description: 'Analyze input vibe and get optimization suggestions',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            input: {
                                type: 'string',
                                description: 'The input to analyze for vibe'
                            }
                        },
                        required: ['input']
                    }
                }
            ]
        }));

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;
            
            try {
                switch (name) {
                    case 'crod_process': {
                        // Add context awareness
                        if (args.context?.mood) {
                            this.brain.memory.workingMemory.set('userMood', args.context.mood);
                        }
                        
                        const result = await this.brain.process(args.input);
                        
                        // Log pattern usage for learning
                        this.logPatternUsage(args.input, result);
                        
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify({
                                    response: result.message,
                                    details: {
                                        type: result.type,
                                        source: result.source,
                                        confidence: result.confidence,
                                        patterns: result.patterns,
                                        decisionId: this.brain.decisions[this.brain.decisions.length - 1]?.id
                                    }
                                }, null, 2)
                            }]
                        };
                    }
                    
                    case 'crod_learn_pattern': {
                        const pattern = {
                            id: `learned_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                            pattern: args.pattern,
                            response: args.response,
                            context: args.context || {},
                            source: 'mcp_learning',
                            created: new Date().toISOString(),
                            usage: { count: 0, success: [] }
                        };
                        
                        // Add to brain's patterns
                        this.brain.patternQuery.patterns.push(pattern);
                        
                        // Save to learned patterns file
                        fs.appendFileSync(this.patternLogPath, JSON.stringify(pattern) + '\n');
                        
                        this.learnedPatterns.push(pattern);
                        
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify({
                                    message: 'Pattern learned successfully',
                                    pattern: pattern,
                                    totalLearned: this.learnedPatterns.length
                                }, null, 2)
                            }]
                        };
                    }
                    
                    case 'crod_get_decisions': {
                        const decisions = this.brain.getDecisionHistory(args.limit || 10);
                        
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify({
                                    decisions: decisions,
                                    total: decisions.length
                                }, null, 2)
                            }]
                        };
                    }
                    
                    case 'crod_feedback': {
                        const learned = await this.brain.learnFromFeedback(
                            args.decisionId,
                            { success: args.success, notes: args.notes }
                        );
                        
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify({
                                    message: learned ? 'Feedback recorded' : 'Decision not found',
                                    decisionId: args.decisionId,
                                    success: args.success
                                }, null, 2)
                            }]
                        };
                    }
                    
                    case 'crod_status': {
                        const state = this.brain.getState();
                        
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify({
                                    ...state,
                                    message: `CROD is ${state.initialized ? 'ACTIVE' : 'OFFLINE'}`,
                                    learnedPatterns: this.learnedPatterns.length,
                                    timestamp: Date.now()
                                }, null, 2)
                            }]
                        };
                    }
                    
                    case 'crod_trinity': {
                        const result = await this.brain.process('ich bins wieder');
                        
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify({
                                    trinity: 'ACTIVATED',
                                    result,
                                    confidence: this.brain.confidence
                                }, null, 2)
                            }]
                        };
                    }
                    
                    case 'crod_suggest_chain': {
                        const smartChain = this.brain.chainExecutor.createSmartChain(args.input);
                        const optimizedChain = this.brain.chainExecutor.optimizeChain(smartChain);
                        
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify({
                                    input: args.input,
                                    chain: optimizedChain,
                                    explanation: 'Use these steps for optimal execution'
                                }, null, 2)
                            }]
                        };
                    }
                    
                    case 'crod_analyze_vibe': {
                        const vibe = this.brain.vibeSystem.detectVibe(args.input);
                        const agentPlan = this.brain.agentTransformer.planTransformation(args.input);
                        const behaviorTips = this.brain.behaviorPatterns.generateCRODInstruction({
                            taskComplexity: args.input.split(' ').length > 10 ? 'high' : 'low',
                            danielMood: vibe.mood,
                            needsCreativity: vibe.category === 'make-it',
                            errorProne: vibe.category === 'fix-it'
                        });
                        
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify({
                                    vibe: {
                                        category: vibe.category,
                                        mood: vibe.mood,
                                        confidence: vibe.confidence,
                                        approach: vibe.approach
                                    },
                                    agentTransformation: agentPlan,
                                    behaviorOptimization: behaviorTips,
                                    recommendation: `Use ${vibe.approach} approach with ${agentPlan.agents[0]} agent mode`
                                }, null, 2)
                            }]
                        };
                    }
                    
                    default:
                        throw new Error(`Unknown tool: ${name}`);
                }
            } catch (error) {
                console.error(`Error in ${name}:`, error);
                return {
                    content: [{
                        type: 'text',
                        text: JSON.stringify({
                            error: error.message,
                            tool: name
                        }, null, 2)
                    }]
                };
            }
        });
    }
    
    // Log pattern usage for learning
    logPatternUsage(input, response) {
        const usage = {
            timestamp: new Date().toISOString(),
            input,
            responseType: response.type,
            source: response.source,
            patterns: response.patterns || [],
            confidence: response.confidence
        };
        
        // Append to usage log
        const logPath = path.join(__dirname, '..', 'data', 'pattern-usage.jsonl');
        fs.appendFileSync(logPath, JSON.stringify(usage) + '\n');
    }

    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('🚀 Enhanced CROD MCP Server running');
        console.error('🤖 With LLM support and pattern learning');
    }
}

// Run the server
const server = new EnhancedCRODServer();

server.initialize()
    .then(() => server.run())
    .catch(error => {
        console.error('Fatal error:', error);
        process.exit(1);
    });

// Handle shutdown
process.on('SIGINT', async () => {
    console.error('\n👋 Shutting down Enhanced CROD...');
    if (server.brain) {
        await server.brain.shutdown();
    }
    process.exit(0);
});