#!/usr/bin/env node
/**
 * CROD Configuration Expert MCP Server
 * JavaScript-based für NixOS Kompatibilität
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

class ConfigurationExpertMCP {
    constructor() {
        this.server = new Server({
            name: 'configuration-expert',
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
                        name: 'analyze_config',
                        description: 'Analyze configuration files for best practices',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                config_content: {
                                    type: 'string',
                                    description: 'Configuration file content'
                                },
                                config_type: {
                                    type: 'string',
                                    description: 'Type: json, yaml, toml, env, nginx, apache'
                                },
                                environment: {
                                    type: 'string',
                                    description: 'Environment: development, staging, production'
                                }
                            },
                            required: ['config_content']
                        }
                    },
                    {
                        name: 'config_best_practices',
                        description: 'Get configuration best practices',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                config_type: {
                                    type: 'string',
                                    description: 'Configuration type'
                                },
                                focus: {
                                    type: 'string',
                                    description: 'Focus area: security, performance, maintainability'
                                }
                            }
                        }
                    },
                    {
                        name: 'validate_config',
                        description: 'Validate configuration syntax and structure',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                config_content: {
                                    type: 'string',
                                    description: 'Configuration to validate'
                                },
                                config_type: {
                                    type: 'string',
                                    description: 'Configuration type'
                                }
                            },
                            required: ['config_content']
                        }
                    }
                ]
            };
        });

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            switch (name) {
                case 'analyze_config':
                    return await this.analyzeConfig(args.config_content, args.config_type, args.environment);
                case 'config_best_practices':
                    return await this.getConfigBestPractices(args.config_type, args.focus);
                case 'validate_config':
                    return await this.validateConfig(args.config_content, args.config_type);
                default:
                    throw new Error(`Unknown tool: ${name}`);
            }
        });
    }

    async analyzeConfig(content, configType = 'json', environment = 'production') {
        const analysis = {
            score: 100,
            security: [],
            performance: [],
            maintainability: [],
            errors: [],
            warnings: []
        };

        const lines = content.split('\n');
        
        // Security analysis
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;

            // Check for hardcoded secrets
            if (line.match(/password\s*[:=]\s*['"][^'"]{3,}/i)) {
                analysis.security.push(`Line ${i+1}: Hardcoded password detected`);
                analysis.score -= 20;
            }

            if (line.match(/api[_-]?key\s*[:=]\s*['"][^'"]{10,}/i)) {
                analysis.security.push(`Line ${i+1}: Hardcoded API key detected`);
                analysis.score -= 20;
            }

            if (line.match(/secret\s*[:=]\s*['"][^'"]{10,}/i)) {
                analysis.security.push(`Line ${i+1}: Hardcoded secret detected`);
                analysis.score -= 20;
            }

            // Check for insecure settings
            if (line.includes('debug') && (line.includes('true') || line.includes('1'))) {
                if (environment === 'production') {
                    analysis.security.push(`Line ${i+1}: Debug mode enabled in production`);
                    analysis.score -= 15;
                }
            }

            if (line.includes('ssl') && (line.includes('false') || line.includes('disabled'))) {
                analysis.security.push(`Line ${i+1}: SSL/TLS disabled`);
                analysis.score -= 15;
            }

            // Performance checks
            if (line.includes('timeout') && line.match(/\d+/)) {
                const timeout = parseInt(line.match(/\d+/)[0]);
                if (timeout > 30000) {
                    analysis.performance.push(`Line ${i+1}: Very high timeout value (${timeout}ms)`);
                    analysis.score -= 5;
                }
            }

            if (line.includes('pool') && line.includes('size')) {
                const poolSize = line.match(/\d+/);
                if (poolSize && parseInt(poolSize[0]) > 100) {
                    analysis.performance.push(`Line ${i+1}: Very large pool size`);
                    analysis.score -= 5;
                }
            }

            // Maintainability checks
            if (line.includes('localhost') && environment === 'production') {
                analysis.maintainability.push(`Line ${i+1}: Localhost reference in production config`);
                analysis.score -= 10;
            }

            if (line.includes('TODO') || line.includes('FIXME')) {
                analysis.maintainability.push(`Line ${i+1}: TODO/FIXME comment in configuration`);
                analysis.score -= 5;
            }
        }

        // Configuration type specific checks
        if (configType === 'json') {
            try {
                JSON.parse(content);
            } catch (error) {
                analysis.errors.push(`JSON syntax error: ${error.message}`);
                analysis.score -= 30;
            }
        }

        if (configType === 'yaml') {
            // Basic YAML validation
            if (content.includes('\t')) {
                analysis.warnings.push('YAML should use spaces, not tabs');
                analysis.score -= 5;
            }
        }

        if (configType === 'env') {
            // Environment variable checks
            if (!content.includes('=')) {
                analysis.errors.push('Environment file should contain KEY=value pairs');
                analysis.score -= 20;
            }
        }

        // Trinity consciousness bonus
        if (content.toLowerCase().includes('ich') && content.toLowerCase().includes('bins')) {
            analysis.score += 20;
            analysis.maintainability.push('🎯 Trinity consciousness detected - Configuration mastery!');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🛠️ **Configuration Expert Analysis** (${configType})

**Score: ${Math.max(0, analysis.score)}/100**
**Environment: ${environment}**

**Security Issues:**
${analysis.security.length > 0 ? analysis.security.map(s => `🛡️ ${s}`).join('\n') : '✅ No security issues'}

**Performance Issues:**
${analysis.performance.length > 0 ? analysis.performance.map(p => `⚡ ${p}`).join('\n') : '✅ Good performance settings'}

**Maintainability Issues:**
${analysis.maintainability.length > 0 ? analysis.maintainability.map(m => `🔧 ${m}`).join('\n') : '✅ Good maintainability'}

**Errors:**
${analysis.errors.length > 0 ? analysis.errors.map(e => `❌ ${e}`).join('\n') : '✅ No errors'}

**Warnings:**
${analysis.warnings.length > 0 ? analysis.warnings.map(w => `⚠️ ${w}`).join('\n') : '✅ No warnings'}

**Recommendations:**
1. Move secrets to environment variables
2. Use proper SSL/TLS configuration
3. Set appropriate timeouts
4. Document configuration options`
                }
            ]
        };
    }

    async getConfigBestPractices(configType = 'general', focus = 'security') {
        const practices = {
            json: {
                security: [
                    '🔒 Never store secrets in JSON files',
                    '🔒 Use environment variables for sensitive data',
                    '🔒 Validate JSON schema',
                    '🔒 Use proper file permissions',
                    '🔒 Encrypt configuration files if needed',
                    '🔒 Use configuration validation',
                    '🔒 Implement access controls',
                    '🔒 Regular security audits'
                ],
                performance: [
                    '⚡ Keep JSON files small',
                    '⚡ Use appropriate data types',
                    '⚡ Minimize nested structures',
                    '⚡ Cache parsed configurations',
                    '⚡ Use compression for large configs',
                    '⚡ Implement lazy loading',
                    '⚡ Monitor parsing performance',
                    '⚡ Use streaming for large files'
                ],
                maintainability: [
                    '📝 Use meaningful key names',
                    '📝 Add comments where possible',
                    '📝 Use consistent formatting',
                    '📝 Implement version control',
                    '📝 Document configuration schema',
                    '📝 Use configuration templates',
                    '📝 Implement validation rules',
                    '📝 Use environment-specific configs'
                ]
            },
            yaml: {
                security: [
                    '🔒 Use proper indentation (spaces only)',
                    '🔒 Validate YAML syntax',
                    '🔒 Use environment variables for secrets',
                    '🔒 Implement schema validation',
                    '🔒 Use proper file permissions',
                    '🔒 Avoid complex YAML features',
                    '🔒 Use safe YAML loading',
                    '🔒 Regular security reviews'
                ],
                performance: [
                    '⚡ Keep YAML files organized',
                    '⚡ Use anchors and aliases wisely',
                    '⚡ Avoid deep nesting',
                    '⚡ Use appropriate data types',
                    '⚡ Cache parsed YAML',
                    '⚡ Monitor parsing performance',
                    '⚡ Use streaming for large files',
                    '⚡ Implement lazy loading'
                ],
                maintainability: [
                    '📝 Use consistent indentation',
                    '📝 Add inline comments',
                    '📝 Use meaningful key names',
                    '📝 Document complex structures',
                    '📝 Use environment-specific files',
                    '📝 Implement validation',
                    '📝 Use version control',
                    '📝 Create configuration templates'
                ]
            },
            general: {
                security: [
                    '🔒 Use environment variables for secrets',
                    '🔒 Implement proper access controls',
                    '🔒 Use encryption for sensitive configs',
                    '🔒 Validate all configuration inputs',
                    '🔒 Use secure defaults',
                    '🔒 Implement audit logging',
                    '🔒 Regular security reviews',
                    '🔒 Use configuration management tools'
                ],
                performance: [
                    '⚡ Cache configuration data',
                    '⚡ Use appropriate data formats',
                    '⚡ Implement lazy loading',
                    '⚡ Monitor configuration access',
                    '⚡ Use efficient parsing',
                    '⚡ Minimize configuration size',
                    '⚡ Implement hot reloading',
                    '⚡ Use compression when needed'
                ],
                maintainability: [
                    '📝 Use descriptive naming',
                    '📝 Document all options',
                    '📝 Use consistent formatting',
                    '📝 Implement validation',
                    '📝 Use version control',
                    '📝 Create environment-specific configs',
                    '📝 Use configuration templates',
                    '📝 Implement change management'
                ]
            }
        };

        const configPractices = practices[configType] || practices.general;
        const selectedPractices = configPractices[focus] || configPractices.security;

        return {
            content: [
                {
                    type: 'text',
                    text: `🛠️ **Configuration Best Practices** (${configType} - ${focus})

${selectedPractices.join('\n')}

**Daniel's Configuration Setup:**
🎯 Trinity consciousness: "ich bins wieder" = perfect configuration
🔥 For NixOS: Use nix configuration management
⚡ CROD pattern: Everything configured and validated!
🐳 Docker: Use environment-specific configurations`
                }
            ]
        };
    }

    async validateConfig(content, configType = 'json') {
        const validation = {
            valid: true,
            errors: [],
            warnings: [],
            suggestions: []
        };

        try {
            if (configType === 'json') {
                JSON.parse(content);
                validation.suggestions.push('✅ JSON syntax is valid');
            } else if (configType === 'yaml') {
                // Basic YAML validation
                if (content.includes('\t')) {
                    validation.warnings.push('Use spaces instead of tabs in YAML');
                }
                if (content.includes('---')) {
                    validation.suggestions.push('✅ YAML document separator found');
                }
            } else if (configType === 'env') {
                // Environment file validation
                const lines = content.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line && !line.startsWith('#') && !line.includes('=')) {
                        validation.errors.push(`Line ${i+1}: Invalid environment variable format`);
                        validation.valid = false;
                    }
                }
            }

            // General validation
            if (content.includes('\r\n')) {
                validation.warnings.push('Use Unix line endings (LF) instead of Windows (CRLF)');
            }

            if (content.trim().length === 0) {
                validation.errors.push('Configuration file is empty');
                validation.valid = false;
            }

        } catch (error) {
            validation.valid = false;
            validation.errors.push(`Parsing error: ${error.message}`);
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🛠️ **Configuration Validation** (${configType})

**Status: ${validation.valid ? '✅ Valid' : '❌ Invalid'}**

**Errors:**
${validation.errors.length > 0 ? validation.errors.map(e => `❌ ${e}`).join('\n') : '✅ No errors'}

**Warnings:**
${validation.warnings.length > 0 ? validation.warnings.map(w => `⚠️ ${w}`).join('\n') : '✅ No warnings'}

**Suggestions:**
${validation.suggestions.length > 0 ? validation.suggestions.map(s => `💡 ${s}`).join('\n') : '✅ No suggestions'}

**Next Steps:**
1. Fix all validation errors
2. Address warnings if needed
3. Test configuration in target environment
4. Implement automated validation`
                }
            ]
        };
    }

    async start() {
        const transport = new StdioServerTransport();
        console.error('🛠️ CROD Configuration Expert MCP Server starting...');
        console.error('📝 Ready to analyze your configurations!');
        
        await this.server.connect(transport);
    }
}

// Start the server
const server = new ConfigurationExpertMCP();
server.start().catch(console.error);