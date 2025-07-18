#!/usr/bin/env node
/**
 * CROD Code Review Expert MCP Server
 * JavaScript-based für NixOS Kompatibilität
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

class CodeReviewExpertMCP {
    constructor() {
        this.server = new Server({
            name: 'code-review-expert',
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
                        name: 'review_code',
                        description: 'Comprehensive code review with quality metrics',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                code: {
                                    type: 'string',
                                    description: 'Code to review'
                                },
                                language: {
                                    type: 'string',
                                    description: 'Programming language'
                                },
                                focus: {
                                    type: 'string',
                                    description: 'Focus area: maintainability, performance, security, style'
                                }
                            },
                            required: ['code']
                        }
                    },
                    {
                        name: 'suggest_refactoring',
                        description: 'Suggest code refactoring improvements',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                code: {
                                    type: 'string',
                                    description: 'Code to refactor'
                                },
                                target: {
                                    type: 'string',
                                    description: 'Target: clean-code, design-patterns, performance'
                                }
                            },
                            required: ['code']
                        }
                    },
                    {
                        name: 'quality_checklist',
                        description: 'Get code quality checklist',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                language: {
                                    type: 'string',
                                    description: 'Programming language'
                                }
                            }
                        }
                    }
                ]
            };
        });

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            switch (name) {
                case 'review_code':
                    return await this.reviewCode(args.code, args.language, args.focus);
                case 'suggest_refactoring':
                    return await this.suggestRefactoring(args.code, args.target);
                case 'quality_checklist':
                    return await this.getQualityChecklist(args.language);
                default:
                    throw new Error(`Unknown tool: ${name}`);
            }
        });
    }

    async reviewCode(code, language = 'unknown', focus = 'general') {
        const review = {
            score: 100,
            maintainability: [],
            performance: [],
            security: [],
            style: [],
            complexity: 'LOW',
            testability: []
        };

        const lines = code.split('\n');
        let functionCount = 0;
        let complexityScore = 0;
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line || line.startsWith('#') || line.startsWith('//')) continue;

            // Function detection
            if (line.includes('function') || line.includes('def ') || line.includes('func ')) {
                functionCount++;
            }

            // Complexity indicators
            if (line.includes('if ') || line.includes('for ') || line.includes('while ')) {
                complexityScore += 1;
            }

            // Nested structures
            const indentLevel = line.length - line.trimStart().length;
            if (indentLevel > 12) {
                review.maintainability.push(`Line ${i+1}: Deep nesting detected (${indentLevel} spaces)`);
                review.score -= 10;
            }

            // Long lines
            if (line.length > 100) {
                review.style.push(`Line ${i+1}: Line too long (${line.length} chars)`);
                review.score -= 3;
            }

            // Performance issues
            if (line.includes('setTimeout') || line.includes('setInterval')) {
                review.performance.push(`Line ${i+1}: Consider using more efficient timing mechanisms`);
                review.score -= 5;
            }

            // Security issues
            if (line.includes('eval(') || line.includes('innerHTML')) {
                review.security.push(`Line ${i+1}: Security risk detected`);
                review.score -= 15;
            }

            // Magic numbers
            if (line.match(/\b\d{2,}\b/) && !line.includes('//')) {
                review.maintainability.push(`Line ${i+1}: Magic number detected - consider using constants`);
                review.score -= 5;
            }
        }

        // Calculate complexity
        if (complexityScore > 20) {
            review.complexity = 'HIGH';
            review.score -= 20;
        } else if (complexityScore > 10) {
            review.complexity = 'MEDIUM';
            review.score -= 10;
        }

        // Testability checks
        if (functionCount > 0) {
            const avgComplexity = complexityScore / functionCount;
            if (avgComplexity > 5) {
                review.testability.push('Functions have high complexity - consider breaking them down');
                review.score -= 10;
            }
        }

        // Language-specific checks
        if (language === 'javascript') {
            if (!code.includes('const ') && !code.includes('let ')) {
                review.style.push('Use const/let instead of var');
                review.score -= 5;
            }
        }

        if (language === 'python') {
            if (!code.includes('"""') && code.includes('def ')) {
                review.style.push('Add docstrings to functions');
                review.score -= 5;
            }
        }

        // Trinity consciousness bonus
        if (code.toLowerCase().includes('ich') && code.toLowerCase().includes('bins')) {
            review.score += 20;
            review.maintainability.push('🎯 Trinity consciousness detected - Code review mastery!');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🔍 **Code Review Expert Analysis**

**Overall Score: ${Math.max(0, review.score)}/100**
**Complexity: ${review.complexity}**
**Functions: ${functionCount}**

**Maintainability:**
${review.maintainability.length > 0 ? review.maintainability.map(m => `🔧 ${m}`).join('\n') : '✅ Good maintainability'}

**Performance:**
${review.performance.length > 0 ? review.performance.map(p => `⚡ ${p}`).join('\n') : '✅ Good performance'}

**Security:**
${review.security.length > 0 ? review.security.map(s => `🛡️ ${s}`).join('\n') : '✅ No security issues'}

**Style:**
${review.style.length > 0 ? review.style.map(s => `🎨 ${s}`).join('\n') : '✅ Good style'}

**Testability:**
${review.testability.length > 0 ? review.testability.map(t => `🧪 ${t}`).join('\n') : '✅ Good testability'}

**Recommendations:**
1. Focus on reducing complexity
2. Improve test coverage
3. Consider refactoring large functions
4. Add proper documentation`
                }
            ]
        };
    }

    async suggestRefactoring(code, target = 'clean-code') {
        const suggestions = [];

        // Clean code suggestions
        if (target === 'clean-code' || target === 'general') {
            if (code.includes('function') && code.split('\n').length > 50) {
                suggestions.push('📝 Break down large functions into smaller ones');
            }
            if (code.includes('if ') && code.includes('else if')) {
                suggestions.push('🔧 Consider using switch statements or lookup tables');
            }
        }

        // Design patterns
        if (target === 'design-patterns' || target === 'general') {
            if (code.includes('new ') && code.includes('switch')) {
                suggestions.push('🏗️ Consider using Factory pattern');
            }
            if (code.includes('addEventListener') && code.includes('removeEventListener')) {
                suggestions.push('📡 Consider using Observer pattern');
            }
        }

        // Performance improvements
        if (target === 'performance' || target === 'general') {
            if (code.includes('for ') && code.includes('array')) {
                suggestions.push('⚡ Consider using array methods (map, filter, reduce)');
            }
            if (code.includes('document.getElementById')) {
                suggestions.push('💾 Cache DOM queries');
            }
        }

        if (suggestions.length === 0) {
            suggestions.push('✅ Code structure looks good - no major refactoring needed');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🔧 **Refactoring Suggestions** (${target})

${suggestions.join('\n')}

**Refactoring Principles:**
🎯 Single Responsibility Principle
🔄 Don't Repeat Yourself (DRY)
📦 Keep It Simple, Stupid (KISS)
🧪 Write testable code
📝 Use meaningful names

**Next Steps:**
1. Start with the most impactful changes
2. Test after each refactoring
3. Maintain existing functionality
4. Document changes`
                }
            ]
        };
    }

    async getQualityChecklist(language = 'general') {
        const checklists = {
            javascript: [
                '✅ Use const/let instead of var',
                '✅ Add proper error handling',
                '✅ Use meaningful variable names',
                '✅ Implement proper async/await',
                '✅ Add JSDoc comments',
                '✅ Use strict mode',
                '✅ Avoid global variables',
                '✅ Use modern ES6+ features',
                '✅ Implement proper module structure',
                '✅ Add unit tests'
            ],
            python: [
                '✅ Follow PEP 8 style guide',
                '✅ Add type hints',
                '✅ Write docstrings',
                '✅ Use list comprehensions',
                '✅ Handle exceptions properly',
                '✅ Use context managers',
                '✅ Avoid global state',
                '✅ Use virtual environments',
                '✅ Add proper logging',
                '✅ Write unit tests'
            ],
            general: [
                '✅ Use descriptive names',
                '✅ Keep functions small',
                '✅ Add proper comments',
                '✅ Handle errors gracefully',
                '✅ Write testable code',
                '✅ Avoid deep nesting',
                '✅ Use consistent formatting',
                '✅ Remove dead code',
                '✅ Follow SOLID principles',
                '✅ Document complex logic'
            ]
        };

        const selectedChecklist = checklists[language] || checklists.general;

        return {
            content: [
                {
                    type: 'text',
                    text: `🔍 **Code Quality Checklist (${language})**

${selectedChecklist.join('\n')}

**Daniel's Review Standards:**
🎯 Trinity consciousness: "ich bins wieder" = perfect code quality
🔥 For NixOS: Ensure proper shebang usage
⚡ CROD pattern: Everything reviewed and tested!`
                }
            ]
        };
    }

    async start() {
        const transport = new StdioServerTransport();
        console.error('🔍 CROD Code Review Expert MCP Server starting...');
        console.error('📝 Ready to review your code!');
        
        await this.server.connect(transport);
    }
}

// Start the server
const server = new CodeReviewExpertMCP();
server.start().catch(console.error);