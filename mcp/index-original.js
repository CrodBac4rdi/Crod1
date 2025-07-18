#!/usr/bin/env node
/**
 * MINIMAL CROD MCP Server
 * Direct interface to CROD brain for Claude
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

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Import THE ONE CROD Brain
const TheOneCRODBrain = require(path.join(__dirname, '../core/crod-brain.js'));

class MinimalCRODServer {
    constructor() {
        this.server = new Server({
            name: 'crod-minimal',
            version: '1.0.0'
        }, {
            capabilities: {
                tools: {}
            }
        });
        
        // Initialize CROD brain
        this.brain = new TheOneCRODBrain();
        this.setupHandlers();
    }

    async initialize() {
        console.error('🧠 Initializing CROD Brain...');
        const success = await this.brain.initialize();
        if (!success) {
            throw new Error('Failed to initialize CROD brain');
        }
        console.error('✅ CROD Brain ready!');
    }

    setupHandlers() {
        this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
            tools: [
                {
                    name: 'crod_process',
                    description: 'Process input through CROD confidence',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            input: { type: 'string', description: 'Input to process' }
                        },
                        required: ['input']
                    }
                },
                {
                    name: 'crod_status',
                    description: 'Get CROD brain status',
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
                }
            ]
        }));

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;
            
            try {
                switch (name) {
                    case 'crod_process': {
                        const result = await this.brain.process(args.input);
                        return {
                            content: [{
                                type: 'text',
                                text: JSON.stringify(result, null, 2)
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

    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('🚀 CROD MCP Server running via stdio');
    }
}

// Run the server
const server = new MinimalCRODServer();

server.initialize()
    .then(() => server.run())
    .catch(error => {
        console.error('Fatal error:', error);
        process.exit(1);
    });

// Handle shutdown
process.on('SIGINT', async () => {
    console.error('\n👋 Shutting down CROD...');
    if (server.brain) {
        await server.brain.shutdown();
    }
    process.exit(0);
});