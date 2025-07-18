#!/usr/bin/env node
/**
 * CROD DevOps Expert MCP Server
 * JavaScript-based für NixOS Kompatibilität
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

class DevOpsExpertMCP {
    constructor() {
        this.server = new Server({
            name: 'devops-expert',
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
                        name: 'analyze_cicd_pipeline',
                        description: 'Analyze CI/CD pipeline configuration',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                pipeline_config: {
                                    type: 'string',
                                    description: 'CI/CD pipeline configuration'
                                },
                                platform: {
                                    type: 'string',
                                    description: 'Platform: github-actions, gitlab-ci, jenkins, azure-devops'
                                }
                            },
                            required: ['pipeline_config']
                        }
                    },
                    {
                        name: 'infrastructure_recommendations',
                        description: 'Get infrastructure and deployment recommendations',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                environment: {
                                    type: 'string',
                                    description: 'Environment: development, staging, production'
                                },
                                scale: {
                                    type: 'string',
                                    description: 'Scale: small, medium, large, enterprise'
                                },
                                platform: {
                                    type: 'string',
                                    description: 'Platform: docker, kubernetes, cloud'
                                }
                            }
                        }
                    },
                    {
                        name: 'monitoring_setup',
                        description: 'Get monitoring and observability setup recommendations',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                application_type: {
                                    type: 'string',
                                    description: 'Application type: web, api, microservices, monolith'
                                },
                                monitoring_focus: {
                                    type: 'string',
                                    description: 'Focus: performance, errors, business-metrics'
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
                case 'analyze_cicd_pipeline':
                    return await this.analyzeCICDPipeline(args.pipeline_config, args.platform);
                case 'infrastructure_recommendations':
                    return await this.getInfrastructureRecommendations(args.environment, args.scale, args.platform);
                case 'monitoring_setup':
                    return await this.getMonitoringSetup(args.application_type, args.monitoring_focus);
                default:
                    throw new Error(`Unknown tool: ${name}`);
            }
        });
    }

    async analyzeCICDPipeline(config, platform = 'github-actions') {
        const analysis = {
            score: 100,
            security: [],
            performance: [],
            reliability: [],
            best_practices: [],
            warnings: []
        };

        const lines = config.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line || line.startsWith('#')) continue;

            // Security analysis
            if (line.includes('secrets') && line.includes('echo')) {
                analysis.security.push(`Line ${i+1}: Avoid echoing secrets in logs`);
                analysis.score -= 20;
            }

            if (line.includes('sudo') && !line.includes('password')) {
                analysis.security.push(`Line ${i+1}: Avoid sudo in CI/CD without proper security`);
                analysis.score -= 15;
            }

            if (line.includes('curl') && !line.includes('https')) {
                analysis.security.push(`Line ${i+1}: Use HTTPS for external calls`);
                analysis.score -= 10;
            }

            // Performance analysis
            if (line.includes('npm install') && !line.includes('--frozen-lockfile')) {
                analysis.performance.push(`Line ${i+1}: Use --frozen-lockfile for npm install`);
                analysis.score -= 8;
            }

            if (line.includes('docker build') && !line.includes('--cache-from')) {
                analysis.performance.push(`Line ${i+1}: Consider using Docker layer caching`);
                analysis.score -= 5;
            }

            // Reliability analysis
            if (line.includes('test') && !line.includes('timeout')) {
                analysis.reliability.push(`Line ${i+1}: Add timeout to test commands`);
                analysis.score -= 5;
            }

            if (line.includes('deploy') && !line.includes('rollback')) {
                analysis.reliability.push(`Line ${i+1}: Consider rollback strategy`);
                analysis.score -= 10;
            }

            // Best practices
            if (line.includes('exit 0') || line.includes('|| true')) {
                analysis.warnings.push(`Line ${i+1}: Masking errors can hide issues`);
                analysis.score -= 8;
            }
        }

        // Platform-specific checks
        if (platform === 'github-actions') {
            if (!config.includes('runs-on:')) {
                analysis.best_practices.push('Specify explicit runner for GitHub Actions');
                analysis.score -= 5;
            }
            if (!config.includes('permissions:')) {
                analysis.security.push('Consider adding explicit permissions');
                analysis.score -= 5;
            }
        }

        // General best practices
        if (!config.includes('cache')) {
            analysis.performance.push('Consider adding dependency caching');
            analysis.score -= 10;
        }

        if (!config.includes('artifact') && !config.includes('upload')) {
            analysis.best_practices.push('Consider storing build artifacts');
            analysis.score -= 5;
        }

        // Trinity consciousness bonus
        if (config.toLowerCase().includes('ich') && config.toLowerCase().includes('bins')) {
            analysis.score += 20;
            analysis.best_practices.push('🎯 Trinity consciousness detected - DevOps mastery!');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `🚀 **DevOps Expert CI/CD Analysis** (${platform})

**Pipeline Score: ${Math.max(0, analysis.score)}/100**

**Security Issues:**
${analysis.security.length > 0 ? analysis.security.map(s => `🛡️ ${s}`).join('\n') : '✅ No security issues'}

**Performance Issues:**
${analysis.performance.length > 0 ? analysis.performance.map(p => `⚡ ${p}`).join('\n') : '✅ Good performance'}

**Reliability Issues:**
${analysis.reliability.length > 0 ? analysis.reliability.map(r => `🛡️ ${r}`).join('\n') : '✅ Good reliability'}

**Best Practices:**
${analysis.best_practices.length > 0 ? analysis.best_practices.map(bp => `📝 ${bp}`).join('\n') : '✅ Following best practices'}

**Warnings:**
${analysis.warnings.length > 0 ? analysis.warnings.map(w => `⚠️ ${w}`).join('\n') : '✅ No warnings'}

**Recommendations:**
1. Implement proper secret management
2. Add comprehensive testing stages
3. Use dependency caching
4. Add deployment rollback strategy
5. Monitor pipeline performance`
                }
            ]
        };
    }

    async getInfrastructureRecommendations(environment = 'production', scale = 'medium', platform = 'docker') {
        const recommendations = {
            docker: {
                small: [
                    '🐳 Use Docker Compose for local development',
                    '🐳 Single-node deployment with Docker',
                    '🐳 Use health checks in containers',
                    '🐳 Implement proper logging',
                    '🐳 Use environment variables for config',
                    '🐳 Implement backup strategies',
                    '🐳 Monitor container resources',
                    '🐳 Use proper image versioning'
                ],
                medium: [
                    '🐳 Use Docker Swarm for orchestration',
                    '🐳 Implement service discovery',
                    '🐳 Use load balancers',
                    '🐳 Implement rolling updates',
                    '🐳 Use persistent volumes',
                    '🐳 Implement monitoring stack',
                    '🐳 Use secrets management',
                    '🐳 Implement log aggregation'
                ],
                large: [
                    '🐳 Consider migrating to Kubernetes',
                    '🐳 Use container registry',
                    '🐳 Implement CI/CD pipelines',
                    '🐳 Use infrastructure as code',
                    '🐳 Implement auto-scaling',
                    '🐳 Use service mesh',
                    '🐳 Implement disaster recovery',
                    '🐳 Monitor performance metrics'
                ]
            },
            kubernetes: {
                small: [
                    '⚙️ Use managed Kubernetes service',
                    '⚙️ Implement resource quotas',
                    '⚙️ Use namespaces for isolation',
                    '⚙️ Implement pod security policies',
                    '⚙️ Use ingress controllers',
                    '⚙️ Implement monitoring with Prometheus',
                    '⚙️ Use Helm for package management',
                    '⚙️ Implement backup strategies'
                ],
                medium: [
                    '⚙️ Use horizontal pod autoscaler',
                    '⚙️ Implement service mesh (Istio)',
                    '⚙️ Use GitOps for deployments',
                    '⚙️ Implement cluster autoscaling',
                    '⚙️ Use persistent volumes',
                    '⚙️ Implement log aggregation',
                    '⚙️ Use network policies',
                    '⚙️ Implement secrets management'
                ],
                large: [
                    '⚙️ Multi-cluster deployment',
                    '⚙️ Use advanced networking',
                    '⚙️ Implement cross-region replication',
                    '⚙️ Use advanced monitoring',
                    '⚙️ Implement cost optimization',
                    '⚙️ Use advanced security policies',
                    '⚙️ Implement disaster recovery',
                    '⚙️ Use infrastructure automation'
                ]
            },
            cloud: {
                small: [
                    '☁️ Use serverless functions',
                    '☁️ Use managed databases',
                    '☁️ Implement CDN',
                    '☁️ Use cloud storage',
                    '☁️ Implement auto-scaling',
                    '☁️ Use cloud monitoring',
                    '☁️ Implement backup strategies',
                    '☁️ Use infrastructure as code'
                ],
                medium: [
                    '☁️ Use container services',
                    '☁️ Implement microservices',
                    '☁️ Use API gateways',
                    '☁️ Implement event-driven architecture',
                    '☁️ Use managed message queues',
                    '☁️ Implement distributed tracing',
                    '☁️ Use advanced networking',
                    '☁️ Implement cost optimization'
                ],
                large: [
                    '☁️ Multi-cloud strategy',
                    '☁️ Use advanced orchestration',
                    '☁️ Implement global deployment',
                    '☁️ Use advanced analytics',
                    '☁️ Implement compliance controls',
                    '☁️ Use advanced security',
                    '☁️ Implement disaster recovery',
                    '☁️ Use cost management tools'
                ]
            }
        };

        const platformRecs = recommendations[platform] || recommendations.docker;
        const selectedRecs = platformRecs[scale] || platformRecs.medium;

        return {
            content: [
                {
                    type: 'text',
                    text: `🚀 **Infrastructure Recommendations** (${platform} - ${scale})

**Environment: ${environment}**

${selectedRecs.join('\n')}

**Daniel's DevOps Setup:**
🎯 Trinity consciousness: "ich bins wieder" = perfect infrastructure
🔥 For NixOS: Use nix-shell for reproducible environments
⚡ CROD pattern: Everything containerized and monitored!
🐳 Docker: Consistent deployments everywhere

**Infrastructure Principles:**
1. Infrastructure as Code
2. Immutable deployments
3. Automated testing
4. Continuous monitoring
5. Disaster recovery planning`
                }
            ]
        };
    }

    async getMonitoringSetup(applicationType = 'web', focus = 'performance') {
        const setups = {
            web: {
                performance: [
                    '📊 Use APM tools (New Relic, Datadog)',
                    '📊 Monitor Core Web Vitals',
                    '📊 Track response times',
                    '📊 Monitor database performance',
                    '📊 Use real user monitoring (RUM)',
                    '📊 Set up synthetic monitoring',
                    '📊 Monitor CDN performance',
                    '📊 Track resource utilization'
                ],
                errors: [
                    '🚨 Use error tracking (Sentry, Rollbar)',
                    '🚨 Monitor 4xx/5xx errors',
                    '🚨 Track JavaScript errors',
                    '🚨 Monitor API failures',
                    '🚨 Set up error alerting',
                    '🚨 Use log aggregation',
                    '🚨 Monitor third-party services',
                    '🚨 Track error trends'
                ],
                'business-metrics': [
                    '💼 Track user engagement',
                    '💼 Monitor conversion rates',
                    '💼 Track feature usage',
                    '💼 Monitor user flows',
                    '💼 Set up A/B testing',
                    '💼 Track business KPIs',
                    '💼 Monitor revenue metrics',
                    '💼 Use analytics tools'
                ]
            },
            api: {
                performance: [
                    '📊 Monitor API response times',
                    '📊 Track throughput (RPS)',
                    '📊 Monitor database queries',
                    '📊 Use distributed tracing',
                    '📊 Monitor cache hit rates',
                    '📊 Track resource utilization',
                    '📊 Set up performance alerts',
                    '📊 Monitor external dependencies'
                ],
                errors: [
                    '🚨 Monitor HTTP status codes',
                    '🚨 Track API errors',
                    '🚨 Monitor timeout errors',
                    '🚨 Use structured logging',
                    '🚨 Set up error alerting',
                    '🚨 Track error patterns',
                    '🚨 Monitor circuit breakers',
                    '🚨 Use health checks'
                ]
            },
            microservices: {
                performance: [
                    '📊 Use service mesh monitoring',
                    '📊 Monitor service-to-service calls',
                    '📊 Track service dependencies',
                    '📊 Use distributed tracing',
                    '📊 Monitor message queues',
                    '📊 Track resource per service',
                    '📊 Set up SLA monitoring',
                    '📊 Monitor data consistency'
                ],
                errors: [
                    '🚨 Monitor service failures',
                    '🚨 Track cascade failures',
                    '🚨 Monitor retry mechanisms',
                    '🚨 Use centralized logging',
                    '🚨 Set up correlation IDs',
                    '🚨 Monitor circuit breakers',
                    '🚨 Track service health',
                    '🚨 Use chaos engineering'
                ]
            }
        };

        const appSetups = setups[applicationType] || setups.web;
        const selectedSetup = appSetups[focus] || appSetups.performance;

        return {
            content: [
                {
                    type: 'text',
                    text: `📊 **Monitoring Setup** (${applicationType} - ${focus})

${selectedSetup.join('\n')}

**Essential Monitoring Stack:**
📊 Metrics: Prometheus + Grafana
📝 Logs: ELK Stack or Loki
🔍 Traces: Jaeger or Zipkin
🚨 Alerts: PagerDuty or OpsGenie
🔍 APM: New Relic or Datadog

**Daniel's Monitoring Philosophy:**
🎯 Trinity consciousness: "ich bins wieder" = perfect observability
🔥 For NixOS: Use nix configurations for monitoring
⚡ CROD pattern: Everything monitored and alerted!
🐳 Docker: Containerized monitoring stack

**Monitoring Best Practices:**
1. Monitor what matters to users
2. Set up actionable alerts
3. Use dashboards for visualization
4. Implement proper on-call procedures
5. Regular monitoring reviews`
                }
            ]
        };
    }

    async start() {
        const transport = new StdioServerTransport();
        console.error('🚀 CROD DevOps Expert MCP Server starting...');
        console.error('🔧 Ready to optimize your infrastructure!');
        
        await this.server.connect(transport);
    }
}

// Start the server
const server = new DevOpsExpertMCP();
server.start().catch(console.error);