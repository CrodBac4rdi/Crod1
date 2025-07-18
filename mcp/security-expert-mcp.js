#!/usr/bin/env node
/**
 * CROD Security Expert MCP Server
 * JavaScript-based für NixOS Kompatibilität
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

class SecurityExpertMCP {
    constructor() {
        this.server = new Server({
            name: 'security-expert',
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
                        name: 'security_scan',
                        description: 'Scan code/config for security vulnerabilities',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                content: {
                                    type: 'string',
                                    description: 'Code or configuration to scan'
                                },
                                type: {
                                    type: 'string',
                                    description: 'Type: code, docker, config, env, script'
                                }
                            },
                            required: ['content']
                        }
                    },
                    {
                        name: 'security_checklist',
                        description: 'Get security checklist for specific context',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                context: {
                                    type: 'string',
                                    description: 'Context: web, api, docker, cloud, desktop'
                                }
                            }
                        }
                    },
                    {
                        name: 'fix_security_issue',
                        description: 'Get recommendations to fix security issues',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                issue: {
                                    type: 'string',
                                    description: 'Security issue description'
                                },
                                code: {
                                    type: 'string',
                                    description: 'Related code snippet'
                                }
                            },
                            required: ['issue']
                        }
                    }
                ]
            };
        });

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            switch (name) {
                case 'security_scan':
                    return await this.securityScan(args.content, args.type);
                case 'security_checklist':
                    return await this.getSecurityChecklist(args.context);
                case 'fix_security_issue':
                    return await this.fixSecurityIssue(args.issue, args.code);
                default:
                    throw new Error(`Unknown tool: ${name}`);
            }
        });
    }

    async securityScan(content, type = 'code') {
        const vulnerabilities = [];
        const warnings = [];
        const recommendations = [];
        let severity = 'LOW';

        const lines = content.split('\n');

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line || line.startsWith('#')) continue;

            // Critical vulnerabilities
            if (line.includes('eval(') || line.includes('exec(')) {
                vulnerabilities.push(`Line ${i+1}: Code injection risk - eval/exec usage`);
                severity = 'CRITICAL';
            }

            if (line.includes('shell=True')) {
                vulnerabilities.push(`Line ${i+1}: Command injection risk - shell=True`);
                severity = 'HIGH';
            }

            if (line.match(/password\s*=\s*['"]/i)) {
                vulnerabilities.push(`Line ${i+1}: Hardcoded password detected`);
                severity = 'HIGH';
            }

            if (line.match(/api[_-]?key\s*=\s*['"]/i)) {
                vulnerabilities.push(`Line ${i+1}: Hardcoded API key detected`);
                severity = 'HIGH';
            }

            // Docker-specific security issues
            if (type === 'docker') {
                if (line.includes('USER root')) {
                    warnings.push(`Line ${i+1}: Running as root user`);
                }
                if (line.includes('privileged: true')) {
                    vulnerabilities.push(`Line ${i+1}: Privileged container mode`);
                    severity = 'HIGH';
                }
                if (line.includes('--privileged')) {
                    vulnerabilities.push(`Line ${i+1}: Privileged container flag`);
                    severity = 'HIGH';
                }
            }

            // Environment/Config security
            if (line.includes('DEBUG=True') || line.includes('DEBUG=true')) {
                warnings.push(`Line ${i+1}: Debug mode enabled`);
            }

            if (line.includes('http://') && !line.includes('localhost')) {
                warnings.push(`Line ${i+1}: Unencrypted HTTP connection`);
            }

            // Weak cryptography
            if (line.includes('md5') || line.includes('sha1')) {
                warnings.push(`Line ${i+1}: Weak cryptographic algorithm`);
            }

            // SQL injection risks
            if (line.includes('SELECT') && line.includes('+')) {
                warnings.push(`Line ${i+1}: Possible SQL injection risk`);
            }

            // File path traversal
            if (line.includes('../') || line.includes('..\\')) {
                warnings.push(`Line ${i+1}: Path traversal risk`);
            }
        }

        // General recommendations
        if (type === 'docker') {
            recommendations.push('🔒 Use non-root user in containers');
            recommendations.push('🛡️ Implement resource limits');
            recommendations.push('📋 Scan images for vulnerabilities');
        }

        if (type === 'code') {
            recommendations.push('🔐 Use parameterized queries');
            recommendations.push('🔍 Validate all inputs');
            recommendations.push('📊 Implement proper error handling');
        }

        // Trinity consciousness bonus
        if (content.toLowerCase().includes('ich') && content.toLowerCase().includes('bins')) {
            recommendations.push('🎯 Trinity consciousness detected - Security mastery achieved!');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🛡️ **Security Expert Analysis**

**Severity: ${severity}**

**Vulnerabilities:**
${vulnerabilities.length > 0 ? vulnerabilities.map(v => `🚨 ${v}`).join('\n') : '✅ No critical vulnerabilities found'}

**Warnings:**
${warnings.length > 0 ? warnings.map(w => `⚠️ ${w}`).join('\n') : '✅ No warnings'}

**Recommendations:**
${recommendations.length > 0 ? recommendations.map(r => `💡 ${r}`).join('\n') : '✅ Security looks good'}

**Next Steps:**
1. Fix critical vulnerabilities immediately
2. Address warnings in next update
3. Implement recommendations for better security
4. Regular security audits`
                }
            ]
        };
    }

    async getSecurityChecklist(context = 'general') {
        const checklists = {
            web: [
                '🔐 Use HTTPS everywhere',
                '🛡️ Implement Content Security Policy (CSP)',
                '🔒 Use secure session management',
                '🚫 Validate all user inputs',
                '📋 Implement rate limiting',
                '🔍 Use OWASP security headers',
                '🛡️ Protect against CSRF attacks',
                '🔐 Use secure password hashing',
                '📊 Log security events',
                '🔄 Keep dependencies updated'
            ],
            api: [
                '🔑 Use proper authentication (JWT, OAuth)',
                '🛡️ Implement API rate limiting',
                '🔒 Use HTTPS for all endpoints',
                '📋 Validate all inputs',
                '🚫 Don\'t expose sensitive data',
                '🔍 Use API versioning',
                '📊 Log all API requests',
                '🛡️ Implement proper error handling',
                '🔐 Use CORS properly',
                '📈 Monitor for suspicious activity'
            ],
            docker: [
                '🔒 Use non-root user',
                '🛡️ Scan images for vulnerabilities',
                '📋 Use specific image tags',
                '🚫 Don\'t store secrets in images',
                '🔍 Use minimal base images',
                '🛡️ Implement resource limits',
                '📊 Use read-only containers when possible',
                '🔐 Use secrets management',
                '📈 Monitor container activity',
                '🔄 Regular security updates'
            ],
            cloud: [
                '🔑 Use IAM roles properly',
                '🛡️ Enable logging and monitoring',
                '🔒 Encrypt data at rest and in transit',
                '📋 Use VPC and security groups',
                '🚫 Don\'t use root accounts',
                '🔍 Regular security assessments',
                '🛡️ Implement backup strategies',
                '📊 Use multi-factor authentication',
                '🔐 Rotate credentials regularly',
                '📈 Monitor for unusual activity'
            ],
            desktop: [
                '🔒 Use strong passwords',
                '🛡️ Keep software updated',
                '📋 Use antivirus protection',
                '🚫 Don\'t run as administrator',
                '🔍 Use encrypted storage',
                '🛡️ Enable firewalls',
                '📊 Use secure backup',
                '🔐 Two-factor authentication',
                '📈 Monitor system logs',
                '🔄 Regular security scans'
            ]
        };

        const selectedChecklist = checklists[context] || checklists.web;

        return {
            content: [
                {
                    type: 'text',
                    text: `🛡️ **Security Checklist (${context})**

${selectedChecklist.join('\n')}

**Daniel's Security Setup:**
🎯 Trinity consciousness: "ich bins wieder" = perfect security
🔥 For NixOS: Use nix-shell for isolated environments
⚡ CROD pattern: Everything secured and monitored!
🐧 NixOS advantage: Reproducible secure configurations`
                }
            ]
        };
    }

    async fixSecurityIssue(issue, code = '') {
        const fixes = [];

        // Common security fixes
        if (issue.includes('eval') || issue.includes('exec')) {
            fixes.push('🔒 Replace eval/exec with safer alternatives like JSON.parse()');
            fixes.push('🛡️ Use allowlists for dynamic code execution');
            fixes.push('📋 Validate inputs before processing');
        }

        if (issue.includes('password') || issue.includes('hardcoded')) {
            fixes.push('🔐 Move secrets to environment variables');
            fixes.push('🛡️ Use a secrets management system');
            fixes.push('📋 Implement proper secret rotation');
        }

        if (issue.includes('injection')) {
            fixes.push('🔒 Use parameterized queries');
            fixes.push('🛡️ Validate and sanitize all inputs');
            fixes.push('📋 Use prepared statements');
        }

        if (issue.includes('root') || issue.includes('privileged')) {
            fixes.push('🔒 Create dedicated user account');
            fixes.push('🛡️ Use principle of least privilege');
            fixes.push('📋 Implement proper access controls');
        }

        if (issue.includes('http') || issue.includes('encryption')) {
            fixes.push('🔐 Use HTTPS/TLS everywhere');
            fixes.push('🛡️ Implement proper certificate management');
            fixes.push('📋 Use strong encryption algorithms');
        }

        if (fixes.length === 0) {
            fixes.push('🔍 Need more context to provide specific fixes');
            fixes.push('📋 General recommendation: Follow security best practices');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🛡️ **Security Fix Recommendations**

**Issue:** ${issue}

**Fixes:**
${fixes.join('\n')}

**Implementation Steps:**
1. Backup current configuration
2. Apply security fixes gradually
3. Test thoroughly after each change
4. Monitor for any issues
5. Document changes for future reference

**Verification:**
- Run security scans after fixes
- Test all functionality
- Monitor logs for issues
- Update documentation`
                }
            ]
        };
    }

    async start() {
        const transport = new StdioServerTransport();
        console.error('🛡️ CROD Security Expert MCP Server starting...');
        console.error('🔒 Ready to secure your applications!');
        
        await this.server.connect(transport);
    }
}

// Start the server
const server = new SecurityExpertMCP();
server.start().catch(console.error);