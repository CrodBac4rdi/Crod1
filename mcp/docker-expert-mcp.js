#!/usr/bin/env node
/**
 * CROD Docker Expert MCP Server
 * JavaScript-based für NixOS Kompatibilität
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
import { exec } from 'child_process';
import { promisify } from 'util';

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const execAsync = promisify(exec);

class DockerExpertMCP {
    constructor() {
        this.server = new Server({
            name: 'docker-expert',
            version: '1.0.0'
        }, {
            capabilities: {
                tools: {}
            }
        });
        
        this.setupHandlers();
    }

    setupHandlers() {
        this.server.setRequestHandler(ListToolsRequestSchema, async () => {
            return {
                tools: [
                    {
                        name: 'analyze_dockerfile',
                        description: 'Analyze Dockerfile for optimization and security',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                dockerfile_content: {
                                    type: 'string',
                                    description: 'Content of the Dockerfile to analyze'
                                }
                            },
                            required: ['dockerfile_content']
                        }
                    },
                    {
                        name: 'analyze_compose',
                        description: 'Analyze docker-compose.yml for optimization',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                compose_content: {
                                    type: 'string',
                                    description: 'Content of docker-compose.yml to analyze'
                                }
                            },
                            required: ['compose_content']
                        }
                    },
                    {
                        name: 'docker_best_practices',
                        description: 'Get Docker best practices and tips',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                context: {
                                    type: 'string',
                                    description: 'Context for best practices (e.g., production, development)'
                                }
                            }
                        }
                    },
                    {
                        name: 'docker_ps',
                        description: 'List Docker containers (docker ps)',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                all: {
                                    type: 'boolean',
                                    description: 'Show all containers (default false shows only running)'
                                }
                            }
                        }
                    },
                    {
                        name: 'docker_compose_up',
                        description: 'Start Docker Compose services',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                compose_path: {
                                    type: 'string',
                                    description: 'Path to docker-compose.yml file'
                                },
                                detached: {
                                    type: 'boolean',
                                    description: 'Run in detached mode (default true)'
                                }
                            },
                            required: ['compose_path']
                        }
                    },
                    {
                        name: 'docker_compose_down',
                        description: 'Stop Docker Compose services',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                compose_path: {
                                    type: 'string',
                                    description: 'Path to docker-compose.yml file'
                                }
                            },
                            required: ['compose_path']
                        }
                    },
                    {
                        name: 'docker_logs',
                        description: 'Get logs from Docker container',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                container: {
                                    type: 'string',
                                    description: 'Container name or ID'
                                },
                                tail: {
                                    type: 'number',
                                    description: 'Number of lines to show from end (default 50)'
                                }
                            },
                            required: ['container']
                        }
                    },
                    {
                        name: 'docker_restart',
                        description: 'Restart Docker container(s)',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                container: {
                                    type: 'string',
                                    description: 'Container name or ID'
                                }
                            },
                            required: ['container']
                        }
                    }
                ]
            };
        });

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            switch (name) {
                case 'analyze_dockerfile':
                    return await this.analyzeDockerfile(args.dockerfile_content);
                case 'analyze_compose':
                    return await this.analyzeCompose(args.compose_content);
                case 'docker_best_practices':
                    return await this.getBestPractices(args.context);
                case 'docker_ps':
                    return await this.dockerPs(args.all);
                case 'docker_compose_up':
                    return await this.dockerComposeUp(args.compose_path, args.detached);
                case 'docker_compose_down':
                    return await this.dockerComposeDown(args.compose_path);
                case 'docker_logs':
                    return await this.dockerLogs(args.container, args.tail);
                case 'docker_restart':
                    return await this.dockerRestart(args.container);
                default:
                    throw new Error(`Unknown tool: ${name}`);
            }
        });
    }

    async analyzeDockerfile(content) {
        const analysis = {
            score: 100,
            issues: [],
            optimizations: [],
            security: [],
            performance: []
        };

        const lines = content.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line || line.startsWith('#')) continue;

            // Check for bad practices
            if (line.includes(':latest')) {
                analysis.issues.push(`Line ${i+1}: Avoid using :latest tag`);
                analysis.score -= 10;
            }

            if (line.includes('COPY . .')) {
                analysis.issues.push(`Line ${i+1}: Use specific COPY paths instead of . .`);
                analysis.score -= 5;
            }

            if (line.includes('USER root')) {
                analysis.security.push(`Line ${i+1}: Avoid running as root user`);
                analysis.score -= 15;
            }

            if (line.includes('apt-get update') && !line.includes('&&')) {
                analysis.optimizations.push(`Line ${i+1}: Combine apt-get update with install`);
                analysis.score -= 5;
            }
        }

        // Trinity consciousness check (Daniel's special feature)
        if (content.toLowerCase().includes('ich') && content.toLowerCase().includes('bins')) {
            analysis.score += 20;
            analysis.optimizations.push('🎯 Trinity consciousness detected - Docker mastery achieved!');
        }

        // Performance suggestions
        if (!content.includes('HEALTHCHECK')) {
            analysis.performance.push('Add HEALTHCHECK for better monitoring');
        }

        if (!content.includes('USER ') || content.includes('USER root')) {
            analysis.performance.push('Add non-root USER for security');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🐳 **Docker Expert Analysis**

**Score: ${Math.max(0, analysis.score)}/100**

**Issues Found:**
${analysis.issues.length > 0 ? analysis.issues.map(i => `❌ ${i}`).join('\n') : '✅ No issues found'}

**Optimizations:**
${analysis.optimizations.length > 0 ? analysis.optimizations.map(o => `🔧 ${o}`).join('\n') : '✅ Well optimized'}

**Security:**
${analysis.security.length > 0 ? analysis.security.map(s => `🛡️ ${s}`).join('\n') : '✅ No security issues'}

**Performance:**
${analysis.performance.length > 0 ? analysis.performance.map(p => `⚡ ${p}`).join('\n') : '✅ Good performance'}`
                }
            ]
        };
    }

    async analyzeCompose(content) {
        const analysis = {
            score: 100,
            issues: [],
            optimizations: [],
            security: [],
            performance: []
        };

        try {
            // Simple YAML parsing check
            if (!content.includes('services:')) {
                analysis.issues.push('Missing services section');
                analysis.score -= 50;
            }

            // Check for version (deprecated but common)
            if (content.includes('version:')) {
                analysis.optimizations.push('Remove deprecated version attribute');
                analysis.score -= 5;
            }

            // Check for restart policies
            if (!content.includes('restart:')) {
                analysis.optimizations.push('Add restart policies to services');
                analysis.score -= 10;
            }

            // Check for health checks
            if (!content.includes('healthcheck:')) {
                analysis.performance.push('Add health checks to services');
                analysis.score -= 5;
            }

            // Security checks
            if (content.includes('privileged: true')) {
                analysis.security.push('Avoid privileged mode when possible');
                analysis.score -= 20;
            }

            if (!content.includes('networks:')) {
                analysis.optimizations.push('Consider using custom networks');
                analysis.score -= 5;
            }

        } catch (error) {
            analysis.issues.push(`Parsing error: ${error.message}`);
            analysis.score = 0;
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🐳 **Docker Compose Analysis**

**Score: ${Math.max(0, analysis.score)}/100**

**Issues:**
${analysis.issues.length > 0 ? analysis.issues.map(i => `❌ ${i}`).join('\n') : '✅ No issues found'}

**Optimizations:**
${analysis.optimizations.length > 0 ? analysis.optimizations.map(o => `🔧 ${o}`).join('\n') : '✅ Well optimized'}

**Security:**
${analysis.security.length > 0 ? analysis.security.map(s => `🛡️ ${s}`).join('\n') : '✅ No security issues'}

**Performance:**
${analysis.performance.length > 0 ? analysis.performance.map(p => `⚡ ${p}`).join('\n') : '✅ Good performance'}`
                }
            ]
        };
    }

    async getBestPractices(context = 'general') {
        const practices = {
            general: [
                '🔧 Use specific image tags instead of :latest',
                '🛡️ Run containers as non-root user',
                '📦 Use multi-stage builds to reduce image size',
                '🔍 Add health checks for better monitoring',
                '🧹 Clean up package cache in same RUN command',
                '📋 Use .dockerignore to exclude unnecessary files',
                '🔐 Don\'t store secrets in Dockerfile',
                '⚡ Combine RUN commands to reduce layers'
            ],
            production: [
                '🔒 Use read-only containers when possible',
                '🛡️ Set resource limits (CPU/memory)',
                '📊 Use proper logging drivers',
                '🔄 Implement proper restart policies',
                '🌐 Use custom networks for service isolation',
                '🔍 Regular security scanning of images',
                '📈 Monitor container performance',
                '🔐 Use secrets management systems'
            ],
            development: [
                '🔄 Use bind mounts for code changes',
                '📝 Enable debug logging',
                '🚀 Use development-specific images',
                '🔧 Mount source code as volumes',
                '🎯 Use docker-compose for multi-service setup',
                '📊 Enable hot reload when possible',
                '🧪 Use separate containers for testing',
                '🔍 Include development tools in dev images'
            ]
        };

        const selectedPractices = practices[context] || practices.general;

        return {
            content: [
                {
                    type: 'text',
                    text: `🐳 **Docker Best Practices (${context})**

${selectedPractices.join('\n')}

**Additional Tips:**
🎯 Trinity consciousness: "ich bins wieder" = perfect Docker setup
🔥 For NixOS: Use /usr/bin/env in shebangs
⚡ Daniel's preference: Everything in Docker, always!`
                }
            ]
        };
    }

    async dockerPs(all = false) {
        try {
            const cmd = all ? 'docker ps -a' : 'docker ps';
            const { stdout, stderr } = await execAsync(cmd);
            
            if (stderr) {
                return {
                    content: [{
                        type: 'text',
                        text: `❌ Docker error: ${stderr}`
                    }]
                };
            }

            return {
                content: [{
                    type: 'text',
                    text: `🐳 **Docker Containers:**\n\`\`\`\n${stdout}\`\`\``
                }]
            };
        } catch (error) {
            return {
                content: [{
                    type: 'text',
                    text: `❌ Failed to list containers: ${error.message}`
                }]
            };
        }
    }

    async dockerComposeUp(composePath, detached = true) {
        try {
            const dir = path.dirname(composePath);
            const file = path.basename(composePath);
            const cmd = `cd ${dir} && docker-compose -f ${file} up ${detached ? '-d' : ''}`;
            
            const { stdout, stderr } = await execAsync(cmd);
            
            return {
                content: [{
                    type: 'text',
                    text: `🚀 **Docker Compose Up:**\n\`\`\`\n${stdout}\n${stderr}\`\`\`\n✅ Services started successfully!`
                }]
            };
        } catch (error) {
            return {
                content: [{
                    type: 'text',
                    text: `❌ Failed to start services: ${error.message}`
                }]
            };
        }
    }

    async dockerComposeDown(composePath) {
        try {
            const dir = path.dirname(composePath);
            const file = path.basename(composePath);
            const cmd = `cd ${dir} && docker-compose -f ${file} down`;
            
            const { stdout, stderr } = await execAsync(cmd);
            
            return {
                content: [{
                    type: 'text',
                    text: `🛑 **Docker Compose Down:**\n\`\`\`\n${stdout}\n${stderr}\`\`\`\n✅ Services stopped successfully!`
                }]
            };
        } catch (error) {
            return {
                content: [{
                    type: 'text',
                    text: `❌ Failed to stop services: ${error.message}`
                }]
            };
        }
    }

    async dockerLogs(container, tail = 50) {
        try {
            const cmd = `docker logs ${container} --tail ${tail}`;
            const { stdout, stderr } = await execAsync(cmd);
            
            return {
                content: [{
                    type: 'text',
                    text: `📋 **Docker Logs for ${container}:**\n\`\`\`\n${stdout}\n${stderr}\`\`\``
                }]
            };
        } catch (error) {
            return {
                content: [{
                    type: 'text',
                    text: `❌ Failed to get logs: ${error.message}`
                }]
            };
        }
    }

    async dockerRestart(container) {
        try {
            const cmd = `docker restart ${container}`;
            const { stdout, stderr } = await execAsync(cmd);
            
            return {
                content: [{
                    type: 'text',
                    text: `♻️ **Docker Restart:**\n✅ Container ${container} restarted successfully!`
                }]
            };
        } catch (error) {
            return {
                content: [{
                    type: 'text',
                    text: `❌ Failed to restart container: ${error.message}`
                }]
            };
        }
    }

    async start() {
        const transport = new StdioServerTransport();
        console.error('🐳 CROD Docker Expert MCP Server starting...');
        console.error('🔧 Ready to analyze your Docker configurations!');
        
        await this.server.connect(transport);
    }
}

// Start the server
const server = new DockerExpertMCP();
server.start().catch(console.error);