#!/usr/bin/env node
/**
 * CROD Database Expert MCP Server
 * JavaScript-based für NixOS Kompatibilität
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

class DatabaseExpertMCP {
    constructor() {
        this.server = new Server({
            name: 'database-expert',
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
                        name: 'analyze_sql',
                        description: 'Analyze SQL queries for optimization and security',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                query: {
                                    type: 'string',
                                    description: 'SQL query to analyze'
                                },
                                database_type: {
                                    type: 'string',
                                    description: 'Database type: postgresql, mysql, sqlite'
                                }
                            },
                            required: ['query']
                        }
                    },
                    {
                        name: 'database_best_practices',
                        description: 'Get database best practices',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                database_type: {
                                    type: 'string',
                                    description: 'Database type: postgresql, mysql, sqlite, general'
                                },
                                context: {
                                    type: 'string',
                                    description: 'Context: performance, security, design'
                                }
                            }
                        }
                    },
                    {
                        name: 'optimize_query',
                        description: 'Suggest query optimizations',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                query: {
                                    type: 'string',
                                    description: 'SQL query to optimize'
                                },
                                performance_issue: {
                                    type: 'string',
                                    description: 'Specific performance issue'
                                }
                            },
                            required: ['query']
                        }
                    }
                ]
            };
        });

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            switch (name) {
                case 'analyze_sql':
                    return await this.analyzeSQL(args.query, args.database_type);
                case 'database_best_practices':
                    return await this.getDatabaseBestPractices(args.database_type, args.context);
                case 'optimize_query':
                    return await this.optimizeQuery(args.query, args.performance_issue);
                default:
                    throw new Error(`Unknown tool: ${name}`);
            }
        });
    }

    async analyzeSQL(query, databaseType = 'postgresql') {
        const analysis = {
            score: 100,
            performance: [],
            security: [],
            optimization: [],
            warnings: [],
            complexity: 'LOW'
        };

        const normalizedQuery = query.toLowerCase().trim();
        
        // Security analysis
        if (normalizedQuery.includes('select *')) {
            analysis.security.push('Avoid SELECT * - specify needed columns');
            analysis.score -= 15;
        }

        if (normalizedQuery.includes("'") && normalizedQuery.includes('+')) {
            analysis.security.push('Possible SQL injection risk - use parameterized queries');
            analysis.score -= 25;
        }

        if (normalizedQuery.includes('drop ') || normalizedQuery.includes('delete ') || normalizedQuery.includes('truncate ')) {
            analysis.warnings.push('Destructive operation detected - ensure proper safeguards');
            analysis.score -= 10;
        }

        // Performance analysis
        if (normalizedQuery.includes('order by') && !normalizedQuery.includes('limit')) {
            analysis.performance.push('ORDER BY without LIMIT can be expensive');
            analysis.score -= 10;
        }

        if (normalizedQuery.includes('like') && normalizedQuery.includes('%')) {
            analysis.performance.push('Leading wildcard in LIKE can prevent index usage');
            analysis.score -= 10;
        }

        if (normalizedQuery.includes('or ')) {
            analysis.performance.push('OR conditions can prevent efficient index usage');
            analysis.score -= 8;
        }

        if (normalizedQuery.includes('union') && !normalizedQuery.includes('union all')) {
            analysis.performance.push('UNION without ALL removes duplicates (expensive)');
            analysis.score -= 5;
        }

        // Complexity analysis
        const subqueryCount = (normalizedQuery.match(/\(/g) || []).length;
        const joinCount = (normalizedQuery.match(/join/g) || []).length;
        
        if (subqueryCount > 2 || joinCount > 3) {
            analysis.complexity = 'HIGH';
            analysis.optimization.push('Consider breaking down complex query');
            analysis.score -= 15;
        } else if (subqueryCount > 1 || joinCount > 1) {
            analysis.complexity = 'MEDIUM';
        }

        // Database-specific checks
        if (databaseType === 'postgresql') {
            if (normalizedQuery.includes('ilike')) {
                analysis.optimization.push('Consider using full-text search for complex text queries');
            }
        }

        if (databaseType === 'mysql') {
            if (normalizedQuery.includes('group by') && !normalizedQuery.includes('order by')) {
                analysis.optimization.push('MySQL may sort GROUP BY results - consider explicit ORDER BY');
            }
        }

        // Trinity consciousness bonus
        if (query.toLowerCase().includes('ich') && query.toLowerCase().includes('bins')) {
            analysis.score += 20;
            analysis.optimization.push('🎯 Trinity consciousness detected - Database mastery achieved!');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `📊 **Database Expert Analysis** (${databaseType})

**Performance Score: ${Math.max(0, analysis.score)}/100**
**Complexity: ${analysis.complexity}**

**Security Issues:**
${analysis.security.length > 0 ? analysis.security.map(s => `🛡️ ${s}`).join('\n') : '✅ No security issues'}

**Performance Issues:**
${analysis.performance.length > 0 ? analysis.performance.map(p => `⚡ ${p}`).join('\n') : '✅ Good performance'}

**Optimization Suggestions:**
${analysis.optimization.length > 0 ? analysis.optimization.map(o => `🔧 ${o}`).join('\n') : '✅ Well optimized'}

**Warnings:**
${analysis.warnings.length > 0 ? analysis.warnings.map(w => `⚠️ ${w}`).join('\n') : '✅ No warnings'}

**Recommendations:**
1. Add appropriate indexes
2. Consider query execution plan
3. Test with realistic data volumes
4. Monitor query performance`
                }
            ]
        };
    }

    async getDatabaseBestPractices(databaseType = 'general', context = 'general') {
        const practices = {
            postgresql: {
                performance: [
                    '📊 Use EXPLAIN ANALYZE for query planning',
                    '📊 Create appropriate indexes',
                    '📊 Use connection pooling',
                    '📊 Consider materialized views',
                    '📊 Use VACUUM and ANALYZE regularly',
                    '📊 Monitor slow query log',
                    '📊 Use prepared statements',
                    '📊 Consider partitioning large tables'
                ],
                security: [
                    '🔒 Use row-level security (RLS)',
                    '🔒 Create database users with minimal privileges',
                    '🔒 Use SSL/TLS for connections',
                    '🔒 Encrypt sensitive data at rest',
                    '🔒 Regular security updates',
                    '🔒 Use parameterized queries',
                    '🔒 Monitor database access logs',
                    '🔒 Implement backup encryption'
                ],
                design: [
                    '🏗️ Use proper data types',
                    '🏗️ Implement foreign key constraints',
                    '🏗️ Use normalized design',
                    '🏗️ Create proper indexes',
                    '🏗️ Use transactions appropriately',
                    '🏗️ Document database schema',
                    '🏗️ Use CHECK constraints',
                    '🏗️ Consider JSONB for flexible data'
                ]
            },
            general: {
                performance: [
                    '⚡ Index frequently queried columns',
                    '⚡ Use appropriate data types',
                    '⚡ Avoid SELECT * in production',
                    '⚡ Use LIMIT for large result sets',
                    '⚡ Monitor slow queries',
                    '⚡ Use connection pooling',
                    '⚡ Consider read replicas',
                    '⚡ Regular database maintenance'
                ],
                security: [
                    '🔒 Use parameterized queries',
                    '🔒 Validate all inputs',
                    '🔒 Encrypt sensitive data',
                    '🔒 Use SSL connections',
                    '🔒 Regular backups',
                    '🔒 Monitor access logs',
                    '🔒 Use minimal privileges',
                    '🔒 Keep software updated'
                ],
                design: [
                    '🏗️ Plan schema carefully',
                    '🏗️ Use foreign key constraints',
                    '🏗️ Normalize data structure',
                    '🏗️ Document relationships',
                    '🏗️ Use appropriate indexes',
                    '🏗️ Consider data lifecycle',
                    '🏗️ Plan for scalability',
                    '🏗️ Use consistent naming'
                ]
            }
        };

        const dbPractices = practices[databaseType] || practices.general;
        const selectedPractices = dbPractices[context] || dbPractices.performance;

        return {
            content: [
                {
                    type: 'text',
                    text: `📊 **Database Best Practices** (${databaseType} - ${context})

${selectedPractices.join('\n')}

**Daniel's Database Setup:**
🎯 Trinity consciousness: "ich bins wieder" = perfect database design
🔥 For NixOS: Use PostgreSQL with proper configuration
⚡ CROD pattern: Everything indexed and optimized!
🐳 Docker: Consistent database environments`
                }
            ]
        };
    }

    async optimizeQuery(query, performanceIssue = '') {
        const optimizations = [];
        const normalizedQuery = query.toLowerCase();

        // General optimizations
        if (normalizedQuery.includes('select *')) {
            optimizations.push('📊 Replace SELECT * with specific columns');
        }

        if (normalizedQuery.includes('order by') && !normalizedQuery.includes('limit')) {
            optimizations.push('⚡ Add LIMIT to ORDER BY queries');
        }

        if (normalizedQuery.includes('like') && normalizedQuery.includes("'%")) {
            optimizations.push('🔍 Use full-text search for complex text queries');
        }

        if (normalizedQuery.includes('or ')) {
            optimizations.push('🔧 Consider using UNION instead of OR');
        }

        if (normalizedQuery.includes('in (')) {
            optimizations.push('📊 Consider using JOIN instead of IN subquery');
        }

        // Performance issue specific optimizations
        if (performanceIssue.includes('slow')) {
            optimizations.push('📊 Add indexes on WHERE clause columns');
            optimizations.push('📊 Use EXPLAIN to analyze query plan');
        }

        if (performanceIssue.includes('memory')) {
            optimizations.push('💾 Use streaming for large result sets');
            optimizations.push('💾 Consider pagination');
        }

        if (performanceIssue.includes('lock')) {
            optimizations.push('🔒 Use appropriate isolation levels');
            optimizations.push('🔒 Consider read-only transactions');
        }

        if (optimizations.length === 0) {
            optimizations.push('✅ Query looks well optimized');
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `📊 **Query Optimization Suggestions**

**Issue:** ${performanceIssue || 'General optimization'}

**Optimizations:**
${optimizations.join('\n')}

**Implementation Steps:**
1. Analyze current query execution plan
2. Add necessary indexes
3. Test with realistic data volumes
4. Monitor performance improvements
5. Consider query refactoring if needed

**Monitoring:**
📊 Track query execution time
📊 Monitor index usage
📊 Watch for lock contention
📊 Set up slow query alerts`
                }
            ]
        };
    }

    async start() {
        const transport = new StdioServerTransport();
        console.error('📊 CROD Database Expert MCP Server starting...');
        console.error('📝 Ready to optimize your database queries!');
        
        await this.server.connect(transport);
    }
}

// Start the server
const server = new DatabaseExpertMCP();
server.start().catch(console.error);