#!/usr/bin/env node
/**
 * CROD Testing Expert MCP Server
 * JavaScript-based für NixOS Kompatibilität
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

class TestingExpertMCP {
    constructor() {
        this.server = new Server({
            name: 'testing-expert',
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
                        name: 'analyze_test_coverage',
                        description: 'Analyze test coverage and suggest improvements',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                test_code: {
                                    type: 'string',
                                    description: 'Test code to analyze'
                                },
                                source_code: {
                                    type: 'string',
                                    description: 'Source code being tested'
                                },
                                framework: {
                                    type: 'string',
                                    description: 'Testing framework: jest, pytest, mocha, junit'
                                }
                            },
                            required: ['test_code']
                        }
                    },
                    {
                        name: 'generate_test_cases',
                        description: 'Generate test cases for given code',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                code: {
                                    type: 'string',
                                    description: 'Code to generate tests for'
                                },
                                test_type: {
                                    type: 'string',
                                    description: 'Test type: unit, integration, e2e'
                                },
                                framework: {
                                    type: 'string',
                                    description: 'Testing framework preference'
                                }
                            },
                            required: ['code']
                        }
                    },
                    {
                        name: 'testing_best_practices',
                        description: 'Get testing best practices and strategies',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                test_type: {
                                    type: 'string',
                                    description: 'Test type: unit, integration, e2e, performance'
                                },
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
                case 'analyze_test_coverage':
                    return await this.analyzeTestCoverage(args.test_code, args.source_code, args.framework);
                case 'generate_test_cases':
                    return await this.generateTestCases(args.code, args.test_type, args.framework);
                case 'testing_best_practices':
                    return await this.getTestingBestPractices(args.test_type, args.language);
                default:
                    throw new Error(`Unknown tool: ${name}`);
            }
        });
    }

    async analyzeTestCoverage(testCode, sourceCode = '', framework = 'jest') {
        const analysis = {
            score: 100,
            coverage: [],
            missing: [],
            quality: [],
            suggestions: []
        };

        const testLines = testCode.split('\n');
        const sourceLines = sourceCode.split('\n');
        
        // Test structure analysis
        let testCount = 0;
        let assertionCount = 0;
        let mockCount = 0;
        
        for (let i = 0; i < testLines.length; i++) {
            const line = testLines[i].trim();
            
            // Count tests
            if (line.includes('it(') || line.includes('test(') || line.includes('def test_')) {
                testCount++;
            }
            
            // Count assertions
            if (line.includes('expect(') || line.includes('assert') || line.includes('should')) {
                assertionCount++;
            }
            
            // Count mocks
            if (line.includes('mock') || line.includes('stub') || line.includes('spy')) {
                mockCount++;
            }
        }
        
        // Analyze coverage
        if (testCount === 0) {
            analysis.missing.push('No tests found');
            analysis.score -= 50;
        } else if (testCount < 5) {
            analysis.coverage.push(`Only ${testCount} tests found - consider adding more`);
            analysis.score -= 20;
        }
        
        if (assertionCount === 0) {
            analysis.missing.push('No assertions found in tests');
            analysis.score -= 30;
        } else if (assertionCount < testCount) {
            analysis.quality.push('Some tests may be missing assertions');
            analysis.score -= 10;
        }
        
        // Quality analysis
        if (testCode.includes('describe(') || testCode.includes('context(')) {
            analysis.quality.push('✅ Good test organization with describe blocks');
        } else {
            analysis.suggestions.push('Consider organizing tests with describe blocks');
        }
        
        if (testCode.includes('beforeEach') || testCode.includes('setUp')) {
            analysis.quality.push('✅ Good test setup with beforeEach/setUp');
        }
        
        if (testCode.includes('afterEach') || testCode.includes('tearDown')) {
            analysis.quality.push('✅ Good test cleanup with afterEach/tearDown');
        }
        
        // Check for common issues
        if (testCode.includes('setTimeout') || testCode.includes('sleep')) {
            analysis.quality.push('⚠️ Avoid sleep/setTimeout in tests - use proper async patterns');
            analysis.score -= 15;
        }
        
        // Trinity consciousness bonus
        if (testCode.toLowerCase().includes('ich') && testCode.toLowerCase().includes('bins')) {
            analysis.score += 20;
            analysis.quality.push('🎯 Trinity consciousness detected - Testing mastery!');
        }
        
        return {
            content: [
                {
                    type: 'text',
                    text: `🧪 **Testing Expert Analysis** (${framework})

**Coverage Score: ${Math.max(0, analysis.score)}/100**
**Tests: ${testCount} | Assertions: ${assertionCount} | Mocks: ${mockCount}**

**Coverage Analysis:**
${analysis.coverage.length > 0 ? analysis.coverage.map(c => `📊 ${c}`).join('\n') : '✅ Good test coverage'}

**Missing Elements:**
${analysis.missing.length > 0 ? analysis.missing.map(m => `❌ ${m}`).join('\n') : '✅ No missing elements'}

**Quality Issues:**
${analysis.quality.length > 0 ? analysis.quality.map(q => `🔍 ${q}`).join('\n') : '✅ Good test quality'}

**Suggestions:**
${analysis.suggestions.length > 0 ? analysis.suggestions.map(s => `💡 ${s}`).join('\n') : '✅ Well structured tests'}

**Recommendations:**
1. Aim for 80%+ code coverage
2. Test edge cases and error conditions
3. Use descriptive test names
4. Keep tests isolated and fast`
                }
            ]
        };
    }

    async generateTestCases(code, testType = 'unit', framework = 'jest') {
        const testCases = [];
        const functions = [];
        
        // Extract functions from code
        const lines = code.split('\n');
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.includes('function ') || line.includes('def ') || line.includes('const ') && line.includes('=')) {
                const functionName = line.match(/(?:function\s+|def\s+|const\s+)(\w+)/)?.[1];
                if (functionName) {
                    functions.push(functionName);
                }
            }
        }
        
        // Generate test cases based on type
        if (testType === 'unit') {
            testCases.push('🧪 Test happy path scenarios');
            testCases.push('🧪 Test edge cases (null, undefined, empty)');
            testCases.push('🧪 Test error conditions');
            testCases.push('🧪 Test boundary values');
            
            functions.forEach(func => {
                testCases.push(`🧪 Test ${func}() with valid inputs`);
                testCases.push(`🧪 Test ${func}() with invalid inputs`);
            });
        }
        
        if (testType === 'integration') {
            testCases.push('🧪 Test component interactions');
            testCases.push('🧪 Test data flow between modules');
            testCases.push('🧪 Test API integrations');
            testCases.push('🧪 Test database operations');
        }
        
        if (testType === 'e2e') {
            testCases.push('🧪 Test user workflows');
            testCases.push('🧪 Test UI interactions');
            testCases.push('🧪 Test error handling');
            testCases.push('🧪 Test performance scenarios');
        }
        
        // Framework-specific examples
        let exampleCode = '';
        if (framework === 'jest') {
            exampleCode = `
**Jest Example:**
\`\`\`javascript
describe('${functions[0] || 'YourFunction'}', () => {
  it('should handle valid input', () => {
    expect(${functions[0] || 'yourFunction'}('test')).toBe('expected');
  });
  
  it('should throw on invalid input', () => {
    expect(() => ${functions[0] || 'yourFunction'}(null)).toThrow();
  });
});
\`\`\``;
        } else if (framework === 'pytest') {
            exampleCode = `
**Pytest Example:**
\`\`\`python
def test_${functions[0] || 'your_function'}_valid_input():
    result = ${functions[0] || 'your_function'}('test')
    assert result == 'expected'
    
def test_${functions[0] || 'your_function'}_invalid_input():
    with pytest.raises(ValueError):
        ${functions[0] || 'your_function'}(None)
\`\`\``;
        }
        
        return {
            content: [
                {
                    type: 'text',
                    text: `🧪 **Generated Test Cases** (${testType})

**Test Cases to Implement:**
${testCases.join('\n')}

**Functions Found:**
${functions.length > 0 ? functions.map(f => `🔧 ${f}()`).join('\n') : 'No functions detected'}

${exampleCode}

**Testing Strategy:**
1. Start with happy path tests
2. Add edge case coverage
3. Test error conditions
4. Verify all code paths
5. Add performance tests if needed

**CROD Testing Philosophy:**
🎯 Trinity consciousness = perfect test coverage
🔥 Every function tested and verified
⚡ Fast, reliable, maintainable tests`
                }
            ]
        };
    }

    async getTestingBestPractices(testType = 'unit', language = 'javascript') {
        const practices = {
            unit: {
                javascript: [
                    '🧪 Use describe blocks for organization',
                    '🧪 Write clear test names',
                    '🧪 Use beforeEach for setup',
                    '🧪 Mock external dependencies',
                    '🧪 Test one thing at a time',
                    '🧪 Use proper assertions',
                    '🧪 Test edge cases',
                    '🧪 Keep tests isolated'
                ],
                python: [
                    '🧪 Use pytest fixtures',
                    '🧪 Write descriptive test names',
                    '🧪 Use parametrized tests',
                    '🧪 Mock external calls',
                    '🧪 Test exceptions properly',
                    '🧪 Use assert statements',
                    '🧪 Test boundary conditions',
                    '🧪 Keep tests fast'
                ]
            },
            integration: {
                javascript: [
                    '🧪 Test component interactions',
                    '🧪 Use test databases',
                    '🧪 Test API endpoints',
                    '🧪 Verify data flow',
                    '🧪 Test error handling',
                    '🧪 Use realistic data',
                    '🧪 Test configuration',
                    '🧪 Monitor test performance'
                ],
                python: [
                    '🧪 Test module interactions',
                    '🧪 Use test fixtures',
                    '🧪 Test database operations',
                    '🧪 Verify API responses',
                    '🧪 Test error scenarios',
                    '🧪 Use factory patterns',
                    '🧪 Test middleware',
                    '🧪 Cleanup after tests'
                ]
            },
            e2e: [
                '🧪 Test user workflows',
                '🧪 Use page object pattern',
                '🧪 Test critical paths',
                '🧪 Use stable selectors',
                '🧪 Test across browsers',
                '🧪 Handle async operations',
                '🧪 Test error states',
                '🧪 Use proper wait strategies'
            ],
            performance: [
                '🧪 Set performance budgets',
                '🧪 Test load scenarios',
                '🧪 Monitor response times',
                '🧪 Test memory usage',
                '🧪 Use realistic data volumes',
                '🧪 Test concurrency',
                '🧪 Profile slow operations',
                '🧪 Set up alerts'
            ]
        };
        
        const testPractices = practices[testType];
        let selectedPractices;
        
        if (testPractices && typeof testPractices === 'object' && !Array.isArray(testPractices)) {
            selectedPractices = testPractices[language] || testPractices.javascript || [];
        } else {
            selectedPractices = testPractices || practices.unit.javascript;
        }
        
        return {
            content: [
                {
                    type: 'text',
                    text: `🧪 **Testing Best Practices** (${testType} - ${language})

${selectedPractices.join('\n')}

**Daniel's Testing Philosophy:**
🎯 Trinity consciousness: "ich bins wieder" = perfect test coverage
🔥 For NixOS: Use nix-shell for consistent test environments
⚡ CROD pattern: Everything tested, nothing broken!
🐳 Docker: Consistent testing across environments

**Testing Pyramid:**
1. Unit tests (70%) - Fast, isolated
2. Integration tests (20%) - Component interactions
3. E2E tests (10%) - User workflows`
                }
            ]
        };
    }

    async start() {
        const transport = new StdioServerTransport();
        console.error('🧪 CROD Testing Expert MCP Server starting...');
        console.error('🔍 Ready to analyze your tests!');
        
        await this.server.connect(transport);
    }
}

// Start the server
const server = new TestingExpertMCP();
server.start().catch(console.error);