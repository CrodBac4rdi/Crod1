/**
 * MCP Persistent Wrapper
 * Makes stateful MCP servers truly persistent
 */

const WebSocket = require('ws');
const { spawn } = require('child_process');
const http = require('http');

class MCPPersistentWrapper {
    constructor() {
        // Core persistent services
        this.services = {
            crodBrain: {
                type: 'websocket',
                port: 8888,
                path: '/home/daniel/Schreibtisch/CROD-MINIMAL/core/crod-brain.js',
                process: null,
                ws: null,
                state: {}
            },
            crodMemory: {
                type: 'http',
                port: 8889,
                path: '/home/daniel/Schreibtisch/CROD-MINIMAL/mcp-memory/persistent-server.js',
                process: null,
                state: {}
            },
            crodOrchestrator: {
                type: 'http',
                port: 8890,
                path: '/home/daniel/Schreibtisch/CROD-MINIMAL/core/workflow-server.js',
                process: null,
                state: {}
            }
        };
        
        // MCP tool mappings to persistent services
        this.toolMappings = {
            'mcp__crod-memory__*': 'crodMemory',
            'mcp__crod-brain__*': 'crodBrain',
            'mcp__orchestrator__*': 'crodOrchestrator'
        };
    }
    
    /**
     * Start all persistent services
     */
    async startAll() {
        console.log('🚀 Starting Persistent MCP Services...\n');
        
        for (const [name, config] of Object.entries(this.services)) {
            await this.startService(name, config);
        }
        
        console.log('\n✅ All persistent services running!');
        this.printStatus();
    }
    
    /**
     * Start individual service
     */
    async startService(name, config) {
        console.log(`▶️  Starting ${name}...`);
        
        // Check if already running
        if (await this.isRunning(config.port)) {
            console.log(`✅ ${name} already running on port ${config.port}`);
            return;
        }
        
        // Start process
        config.process = spawn('node', [config.path], {
            detached: true,
            stdio: ['ignore', 'pipe', 'pipe'],
            env: { ...process.env, MCP_PERSISTENT: 'true' }
        });
        
        // Log output
        config.process.stdout.on('data', (data) => {
            console.log(`[${name}] ${data.toString().trim()}`);
        });
        
        config.process.stderr.on('data', (data) => {
            console.error(`[${name}] ERROR: ${data.toString().trim()}`);
        });
        
        // Wait for service to be ready
        await this.waitForService(config);
        
        // Connect WebSocket if needed
        if (config.type === 'websocket') {
            config.ws = new WebSocket(`ws://localhost:${config.port}`);
            await this.waitForWebSocket(config.ws);
        }
        
        console.log(`✅ ${name} running on port ${config.port}`);
    }
    
    /**
     * Route MCP tool calls to persistent services
     */
    async routeToolCall(toolName, params) {
        // Find which service handles this tool
        let serviceName = null;
        for (const [pattern, service] of Object.entries(this.toolMappings)) {
            if (toolName.match(pattern.replace('*', '.*'))) {
                serviceName = service;
                break;
            }
        }
        
        if (!serviceName) {
            throw new Error(`No service mapping for tool: ${toolName}`);
        }
        
        const service = this.services[serviceName];
        
        // Route based on service type
        if (service.type === 'websocket') {
            return await this.callWebSocketService(service, toolName, params);
        } else {
            return await this.callHttpService(service, toolName, params);
        }
    }
    
    /**
     * Call WebSocket service
     */
    async callWebSocketService(service, toolName, params) {
        return new Promise((resolve, reject) => {
            const messageId = `msg_${Date.now()}_${Math.random()}`;
            
            const handler = (data) => {
                const response = JSON.parse(data.toString());
                if (response.id === messageId) {
                    service.ws.removeListener('message', handler);
                    if (response.error) {
                        reject(new Error(response.error));
                    } else {
                        resolve(response.result);
                    }
                }
            };
            
            service.ws.on('message', handler);
            
            service.ws.send(JSON.stringify({
                id: messageId,
                tool: toolName,
                params
            }));
            
            // Timeout
            setTimeout(() => {
                service.ws.removeListener('message', handler);
                reject(new Error('Service timeout'));
            }, 5000);
        });
    }
    
    /**
     * Call HTTP service
     */
    async callHttpService(service, toolName, params) {
        const response = await fetch(`http://localhost:${service.port}/tool`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ tool: toolName, params })
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${await response.text()}`);
        }
        
        return await response.json();
    }
    
    /**
     * Get service status
     */
    async getStatus() {
        const status = {};
        
        for (const [name, config] of Object.entries(this.services)) {
            status[name] = {
                running: await this.isRunning(config.port),
                port: config.port,
                type: config.type,
                state: config.state
            };
        }
        
        return status;
    }
    
    /**
     * Print status table
     */
    printStatus() {
        console.log('\n📊 Persistent MCP Services:');
        console.log('┌─────────────────┬──────┬───────────┬─────────┐');
        console.log('│ Service         │ Port │ Type      │ Status  │');
        console.log('├─────────────────┼──────┼───────────┼─────────┤');
        
        for (const [name, config] of Object.entries(this.services)) {
            const status = config.process ? '✅ Online' : '❌ Offline';
            console.log(`│ ${name.padEnd(15)} │ ${config.port} │ ${config.type.padEnd(9)} │ ${status} │`);
        }
        
        console.log('└─────────────────┴──────┴───────────┴─────────┘');
    }
    
    // Helper methods
    async isRunning(port) {
        return new Promise((resolve) => {
            const server = http.createServer();
            server.once('error', (err) => {
                if (err.code === 'EADDRINUSE') {
                    resolve(true);
                } else {
                    resolve(false);
                }
            });
            server.once('listening', () => {
                server.close();
                resolve(false);
            });
            server.listen(port);
        });
    }
    
    async waitForService(config, timeout = 10000) {
        const start = Date.now();
        while (Date.now() - start < timeout) {
            if (await this.isRunning(config.port)) {
                return;
            }
            await new Promise(r => setTimeout(r, 100));
        }
        throw new Error(`Service did not start on port ${config.port}`);
    }
    
    async waitForWebSocket(ws) {
        return new Promise((resolve, reject) => {
            ws.once('open', resolve);
            ws.once('error', reject);
        });
    }
    
    /**
     * Graceful shutdown
     */
    async shutdown() {
        console.log('\n🛑 Shutting down persistent services...');
        
        for (const [name, config] of Object.entries(this.services)) {
            if (config.process) {
                console.log(`  Stopping ${name}...`);
                config.process.kill('SIGTERM');
                config.process = null;
            }
            if (config.ws) {
                config.ws.close();
                config.ws = null;
            }
        }
        
        console.log('✅ All services stopped');
    }
}

// Export for use in MCP
module.exports = MCPPersistentWrapper;

// If run directly, start all services
if (require.main === module) {
    const wrapper = new MCPPersistentWrapper();
    
    wrapper.startAll().catch(console.error);
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
        await wrapper.shutdown();
        process.exit(0);
    });
    
    process.on('SIGTERM', async () => {
        await wrapper.shutdown();
        process.exit(0);
    });
}