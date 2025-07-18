#!/usr/bin/env node
/**
 * CROD Python Expert MCP Server
 * JavaScript-based für NixOS Kompatibilität
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

class PythonExpertMCP {
    constructor() {
        this.server = new Server({
            name: 'python-expert',
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
                        name: 'analyze_python_code',
                        description: 'Analyze Python code for best practices, performance, and security',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                code: {
                                    type: 'string',
                                    description: 'Python code to analyze'
                                },
                                filename: {
                                    type: 'string',
                                    description: 'Optional filename for context'
                                }
                            },
                            required: ['code']
                        }
                    },
                    {
                        name: 'python_best_practices',
                        description: 'Get Python best practices and patterns',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                category: {
                                    type: 'string',
                                    description: 'Category: general, performance, security, testing, async'
                                }
                            }
                        }
                    },
                    {
                        name: 'suggest_improvements',
                        description: 'Suggest specific improvements for Python code',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                code: {
                                    type: 'string',
                                    description: 'Python code to improve'
                                },
                                focus: {
                                    type: 'string',
                                    description: 'Focus area: performance, readability, security, pythonic'
                                }
                            },
                            required: ['code']
                        }
                    }
                ]
            };
        });

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            switch (name) {
                case 'analyze_python_code':
                    return await this.analyzePythonCode(args.code, args.filename);
                case 'python_best_practices':
                    return await this.getPythonBestPractices(args.category);
                case 'suggest_improvements':
                    return await this.suggestImprovements(args.code, args.focus);
                default:
                    throw new Error(`Unknown tool: ${name}`);
            }
        });
    }

    async analyzePythonCode(code, filename = 'unknown') {
        const analysis = {
            score: 100,
            issues: [],
            suggestions: [],
            security: [],
            performance: [],
            style: []
        };

        const lines = code.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line || line.startsWith('#')) continue;

            // Check for common issues
            if (line.includes('import *')) {
                analysis.issues.push(`Line ${i+1}: Avoid wildcard imports`);
                analysis.score -= 10;
            }

            if (line.includes('eval(') || line.includes('exec(')) {
                analysis.security.push(`Line ${i+1}: Avoid eval() and exec() - security risk`);
                analysis.score -= 20;
            }

            if (line.includes('print(') && !line.includes('# debug')) {
                analysis.style.push(`Line ${i+1}: Consider using logging instead of print`);
                analysis.score -= 3;
            }

            if (line.includes('except:') && !line.includes('except ')) {
                analysis.issues.push(`Line ${i+1}: Use specific exception types`);
                analysis.score -= 8;
            }

            if (line.includes('== True') || line.includes('== False')) {
                analysis.style.push(`Line ${i+1}: Use 'is True' or 'is False' for boolean comparison`);
                analysis.score -= 5;
            }

            if (line.includes('len(') && line.includes(') == 0')) {
                analysis.style.push(`Line ${i+1}: Use 'if not sequence:' instead of 'len(sequence) == 0'`);
                analysis.score -= 3;
            }
        }

        // Check for missing docstrings
        if (code.includes('def ') && !code.includes('"""') && !code.includes("'''")) {
            analysis.suggestions.push('Add docstrings to functions');
            analysis.score -= 5;
        }

        // Check for type hints
        if (code.includes('def ') && !code.includes(': ') && !code.includes('->')) {
            analysis.suggestions.push('Consider adding type hints');
            analysis.score -= 5;
        }

        // Performance checks
        if (code.includes('for ') && code.includes('.append(')) {
            analysis.performance.push('Consider using list comprehensions for better performance');
        }

        // Trinity consciousness check
        if (code.toLowerCase().includes('ich') && code.toLowerCase().includes('bins')) {
            analysis.score += 20;
            analysis.suggestions.push('🎯 Trinity consciousness detected - Python mastery achieved!');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🐍 **Python Expert Analysis** (${filename})

**Score: ${Math.max(0, analysis.score)}/100**

**Issues:**
${analysis.issues.length > 0 ? analysis.issues.map(i => `❌ ${i}`).join('\n') : '✅ No issues found'}

**Suggestions:**
${analysis.suggestions.length > 0 ? analysis.suggestions.map(s => `💡 ${s}`).join('\n') : '✅ Well written'}

**Security:**
${analysis.security.length > 0 ? analysis.security.map(s => `🛡️ ${s}`).join('\n') : '✅ No security issues'}

**Performance:**
${analysis.performance.length > 0 ? analysis.performance.map(p => `⚡ ${p}`).join('\n') : '✅ Good performance'}

**Style:**
${analysis.style.length > 0 ? analysis.style.map(s => `🎨 ${s}`).join('\n') : '✅ Good style'}`
                }
            ]
        };
    }

    async getPythonBestPractices(category = 'general') {
        const practices = {
            general: [
                '🐍 Use descriptive variable names',
                '📝 Write docstrings for all functions',
                '🔍 Use type hints for better code clarity',
                '🚫 Avoid wildcard imports (from module import *)',
                '📋 Follow PEP 8 style guidelines',
                '🔒 Use specific exception types',
                '⚡ Use list comprehensions for simple loops',
                '🎯 Keep functions small and focused'
            ],
            performance: [
                '⚡ Use list comprehensions instead of loops',
                '📊 Use generators for memory efficiency',
                '🔄 Cache expensive function results',
                '📈 Profile before optimizing',
                '🗂️ Use appropriate data structures',
                '💾 Avoid premature optimization',
                '🔧 Use built-in functions when possible',
                '📦 Consider using NumPy for numerical operations'
            ],
            security: [
                '🛡️ Never use eval() or exec() with user input',
                '🔐 Validate all user inputs',
                '🔒 Use secrets module for sensitive data',
                '🚫 Avoid pickle for untrusted data',
                '📋 Use parameterized queries for databases',
                '🔍 Regularly update dependencies',
                '⚠️ Handle exceptions properly',
                '🔐 Use HTTPS for network requests'
            ],
            testing: [
                '🧪 Write unit tests for all functions',
                '📋 Use pytest for testing framework',
                '🔍 Aim for high test coverage',
                '🧩 Use mocking for external dependencies',
                '📊 Test edge cases and error conditions',
                '🔄 Use fixtures for test data',
                '⚡ Keep tests fast and isolated',
                '📈 Use continuous integration'
            ],
            async: [
                '🔄 Use async/await for I/O operations',
                '⚡ Use asyncio for concurrent operations',
                '🛡️ Handle exceptions in async functions',
                '🔒 Use context managers properly',
                '📊 Monitor async performance',
                '🔧 Use asyncio.gather for parallel tasks',
                '💾 Be careful with shared state',
                '🎯 Use appropriate async libraries'
            ]
        };

        const selectedPractices = practices[category] || practices.general;

        return {
            content: [
                {
                    type: 'text',
                    text: `🐍 **Python Best Practices (${category})**

${selectedPractices.join('\n')}

**Daniel's Python Setup:**
🎯 Trinity consciousness: "ich bins wieder" = perfect Python code
🔥 For NixOS: Use nix-shell for Python environments
⚡ CROD pattern: Everything tested and documented!`
                }
            ]
        };
    }

    async suggestImprovements(code, focus = 'general') {
        const improvements = [];

        // Performance improvements
        if (focus === 'performance' || focus === 'general') {
            if (code.includes('for ') && code.includes('.append(')) {
                improvements.push('🚀 Replace for loop with list comprehension');
            }
            if (code.includes('range(len(')) {
                improvements.push('🔄 Use enumerate() instead of range(len())');
            }
        }

        // Readability improvements
        if (focus === 'readability' || focus === 'general') {
            if (!code.includes('"""') && code.includes('def ')) {
                improvements.push('📝 Add docstrings to functions');
            }
            if (code.includes('lambda ') && code.length > 100) {
                improvements.push('🔧 Consider replacing lambda with named function');
            }
        }

        // Security improvements
        if (focus === 'security' || focus === 'general') {
            if (code.includes('eval(') || code.includes('exec(')) {
                improvements.push('🛡️ Replace eval/exec with safer alternatives');
            }
            if (code.includes('pickle.loads(')) {
                improvements.push('🔒 Use JSON instead of pickle for untrusted data');
            }
        }

        // Pythonic improvements
        if (focus === 'pythonic' || focus === 'general') {
            if (code.includes('len(') && code.includes(') == 0')) {
                improvements.push('🐍 Use "if not sequence:" instead of "len(sequence) == 0"');
            }
            if (code.includes('== True') || code.includes('== False')) {
                improvements.push('✨ Use "is True" or "is False" for boolean comparison');
            }
        }

        if (improvements.length === 0) {
            improvements.push('✅ Code looks good! No major improvements needed.');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🐍 **Python Improvement Suggestions** (${focus})

${improvements.join('\n')}

**Next Steps:**
1. Apply suggested improvements
2. Run tests to ensure functionality
3. Use linting tools (pylint, flake8)
4. Consider performance profiling if needed`
                }
            ]
        };
    }

    async start() {
        const transport = new StdioServerTransport();
        console.error('🐍 CROD Python Expert MCP Server starting...');
        console.error('🔧 Ready to analyze your Python code!');
        
        await this.server.connect(transport);
    }
}

// Start the server
const server = new PythonExpertMCP();
server.start().catch(console.error);