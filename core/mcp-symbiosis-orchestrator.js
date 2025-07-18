/**
 * MCP Symbiosis Orchestrator
 * Elevates MCP usage by creating intelligent workflows across ALL servers
 * Makes CROD and Memory persistent, orchestrates everything else
 */

const WebSocket = require('ws');
const { spawn } = require('child_process');

class MCPSymbiosisOrchestrator {
    constructor() {
        // Persistent services (should always run)
        this.persistentServices = {
            crodBrain: {
                name: 'CROD Brain',
                port: 8888,
                process: null,
                ws: null,
                status: 'offline'
            },
            crodMemory: {
                name: 'CROD Memory',
                port: 8889,
                process: null,
                status: 'offline'
            }
        };
        
        // On-demand MCP servers
        this.mcpServers = {
            filesystem: { 
                name: 'filesystem',
                capabilities: ['read', 'write', 'watch', 'analyze']
            },
            git: {
                name: 'git',
                capabilities: ['commit', 'diff', 'branch', 'history']
            },
            time: {
                name: 'time',
                capabilities: ['schedule', 'remind', 'track']
            },
            sequentialThinking: {
                name: 'sequential-thinking',
                capabilities: ['plan', 'decompose', 'chain']
            },
            crodSupabase: {
                name: 'crod-supabase',
                capabilities: ['persist', 'query', 'analyze']
            }
        };
        
        // Workflow patterns
        this.workflows = new Map();
        this.activeWorkflows = new Map();
        
        // Event system for coordination
        this.events = [];
        this.subscribers = new Set();
    }
    
    /**
     * Initialize persistent services
     */
    async initialize() {
        console.log('🚀 Initializing MCP Symbiosis Orchestrator...\n');
        
        // Start persistent services
        await this.startPersistentServices();
        
        // Register core workflows
        this.registerCoreWorkflows();
        
        console.log('\n✅ MCP Symbiosis ready!');
    }
    
    /**
     * Start persistent services that should always run
     */
    async startPersistentServices() {
        // Start CROD Brain
        console.log('▶️  Starting CROD Brain (persistent)...');
        this.persistentServices.crodBrain.process = spawn('node', [
            '/home/daniel/Schreibtisch/CROD-MINIMAL/core/crod-brain.js'
        ], {
            detached: true,
            stdio: 'pipe'
        });
        
        // Wait for WebSocket
        await this.waitForWebSocket(8888);
        this.persistentServices.crodBrain.ws = new WebSocket('ws://localhost:8888');
        this.persistentServices.crodBrain.status = 'online';
        console.log('✅ CROD Brain online');
        
        // Start Memory as persistent WebSocket service
        console.log('▶️  Starting Memory Service (persistent)...');
        // TODO: Convert memory MCP to persistent WebSocket
        console.log('⚠️  Memory needs conversion to persistent service');
    }
    
    /**
     * Register core symbiotic workflows
     */
    registerCoreWorkflows() {
        // Workflow 1: Code Change Analysis
        this.registerWorkflow('code-change-analysis', {
            description: 'Analyze code changes with full context',
            triggers: ['file modified', 'git commit', 'manual'],
            steps: [
                {
                    service: 'filesystem',
                    action: 'detect-changes',
                    params: { watch: true }
                },
                {
                    service: 'git',
                    action: 'diff',
                    params: { context: 10 }
                },
                {
                    service: 'crodBrain',
                    action: 'analyze-impact',
                    params: { includeVibe: true }
                },
                {
                    service: 'memory',
                    action: 'find-similar-changes',
                    params: { limit: 5 }
                },
                {
                    service: 'sequentialThinking',
                    action: 'suggest-next-steps',
                    params: { based_on: 'analysis' }
                }
            ],
            customizable: true
        });
        
        // Workflow 2: Learning from Mistakes
        this.registerWorkflow('learn-from-mistake', {
            description: 'When something goes wrong, learn deeply',
            triggers: ['error', 'test failure', 'daniel frustration'],
            steps: [
                {
                    service: 'crodBrain',
                    action: 'detect-mood',
                    params: { sensitivity: 'high' }
                },
                {
                    service: 'git',
                    action: 'get-recent-changes',
                    params: { since: '1 hour ago' }
                },
                {
                    service: 'filesystem',
                    action: 'analyze-error-context',
                    params: { include: ['logs', 'stacktrace'] }
                },
                {
                    service: 'memory',
                    action: 'store-mistake-pattern',
                    params: { priority: 'high' }
                },
                {
                    service: 'crodSupabase',
                    action: 'persist-learning',
                    params: { category: 'mistakes' }
                }
            ],
            customizable: true
        });
        
        // Workflow 3: Continuous Context Building
        this.registerWorkflow('context-building', {
            description: 'Build deep understanding continuously',
            triggers: ['always', 'background'],
            steps: [
                {
                    service: 'filesystem',
                    action: 'scan-project-structure',
                    params: { deep: true }
                },
                {
                    service: 'git',
                    action: 'analyze-commit-patterns',
                    params: { lookback: '30 days' }
                },
                {
                    service: 'memory',
                    action: 'build-knowledge-graph',
                    params: { incremental: true }
                },
                {
                    service: 'time',
                    action: 'track-development-patterns',
                    params: { granularity: 'hourly' }
                }
            ],
            customizable: true,
            background: true
        });
        
        // Workflow 4: Symbiotic Decision Making
        this.registerWorkflow('symbiotic-decision', {
            description: 'CROD preprocesses, Claude decides, both learn',
            triggers: ['complex input', 'uncertainty'],
            steps: [
                {
                    service: 'crodBrain',
                    action: 'preprocess',
                    params: { mode: 'semantic' }
                },
                {
                    service: 'memory',
                    action: 'get-relevant-context',
                    params: { threshold: 0.7 }
                },
                {
                    service: 'sequentialThinking',
                    action: 'decompose-problem',
                    params: { max_depth: 3 }
                },
                {
                    parallel: [
                        {
                            service: 'crodBrain',
                            action: 'suggest-approaches',
                            params: { count: 3 }
                        },
                        {
                            service: 'filesystem',
                            action: 'find-similar-solutions',
                            params: { in: 'codebase' }
                        }
                    ]
                },
                {
                    service: 'memory',
                    action: 'store-decision-process',
                    params: { include_reasoning: true }
                }
            ],
            customizable: true
        });
    }
    
    /**
     * Register a workflow
     */
    registerWorkflow(name, config) {
        this.workflows.set(name, {
            ...config,
            id: `workflow_${name}_${Date.now()}`
        });
    }
    
    /**
     * Execute workflow with on-the-fly customization
     */
    async executeWorkflow(name, customizations = {}) {
        const workflow = this.workflows.get(name);
        if (!workflow) throw new Error(`Unknown workflow: ${name}`);
        
        // Apply customizations
        const customized = this.applyCustomizations(workflow, customizations);
        
        // Create workflow instance
        const instance = {
            id: `instance_${Date.now()}`,
            workflow: name,
            status: 'running',
            results: [],
            startTime: Date.now()
        };
        
        this.activeWorkflows.set(instance.id, instance);
        
        // Execute steps
        for (const step of customized.steps) {
            if (step.parallel) {
                // Execute parallel steps
                const results = await Promise.all(
                    step.parallel.map(s => this.executeStep(s))
                );
                instance.results.push({ parallel: results });
            } else {
                // Execute sequential step
                const result = await this.executeStep(step);
                instance.results.push(result);
                
                // Allow dynamic modification based on results
                if (customizations.onStepComplete) {
                    const modification = await customizations.onStepComplete(step, result);
                    if (modification) {
                        customized.steps = this.modifyWorkflow(customized.steps, modification);
                    }
                }
            }
        }
        
        instance.status = 'completed';
        instance.endTime = Date.now();
        
        return instance;
    }
    
    /**
     * Apply on-the-fly customizations
     */
    applyCustomizations(workflow, customizations) {
        const customized = JSON.parse(JSON.stringify(workflow));
        
        // Add steps
        if (customizations.addSteps) {
            customizations.addSteps.forEach(step => {
                const position = step.after || customized.steps.length;
                customized.steps.splice(position, 0, step);
            });
        }
        
        // Remove steps
        if (customizations.removeSteps) {
            customized.steps = customized.steps.filter(
                step => !customizations.removeSteps.includes(step.action)
            );
        }
        
        // Modify parameters
        if (customizations.modifyParams) {
            customized.steps.forEach(step => {
                if (customizations.modifyParams[step.action]) {
                    Object.assign(step.params, customizations.modifyParams[step.action]);
                }
            });
        }
        
        return customized;
    }
    
    /**
     * Execute a single step
     */
    async executeStep(step) {
        console.log(`📍 Executing: ${step.service}.${step.action}`);
        
        // Route to appropriate service
        switch(step.service) {
            case 'crodBrain':
                return await this.executeCrodStep(step);
            case 'memory':
                return await this.executeMemoryStep(step);
            case 'filesystem':
                return await this.executeFilesystemStep(step);
            case 'git':
                return await this.executeGitStep(step);
            case 'time':
                return await this.executeTimeStep(step);
            case 'sequentialThinking':
                return await this.executeThinkingStep(step);
            case 'crodSupabase':
                return await this.executeSupabaseStep(step);
            default:
                throw new Error(`Unknown service: ${step.service}`);
        }
    }
    
    /**
     * Create dynamic workflow based on context
     */
    createDynamicWorkflow(context) {
        const steps = [];
        
        // Analyze context to build workflow
        if (context.hasError) {
            steps.push({
                service: 'filesystem',
                action: 'get-error-context',
                params: { lines: 20 }
            });
        }
        
        if (context.isComplexTask) {
            steps.push({
                service: 'sequentialThinking',
                action: 'decompose',
                params: { max_steps: 10 }
            });
        }
        
        // Always include CROD preprocessing
        steps.unshift({
            service: 'crodBrain',
            action: 'preprocess',
            params: { context }
        });
        
        // Always store learnings
        steps.push({
            service: 'memory',
            action: 'store-interaction',
            params: { include_workflow: true }
        });
        
        return {
            name: 'dynamic',
            steps,
            customizable: true
        };
    }
    
    /**
     * Get workflow suggestions based on input
     */
    suggestWorkflows(input) {
        const suggestions = [];
        
        // Analyze input to suggest workflows
        if (input.includes('error') || input.includes('broken')) {
            suggestions.push('learn-from-mistake');
        }
        
        if (input.includes('analyze') || input.includes('understand')) {
            suggestions.push('code-change-analysis');
        }
        
        if (input.includes('help') || input.includes('?')) {
            suggestions.push('symbiotic-decision');
        }
        
        // Always suggest dynamic workflow
        suggestions.push({
            type: 'dynamic',
            description: 'Create custom workflow for this specific task'
        });
        
        return suggestions;
    }
    
    // Helper methods
    async waitForWebSocket(port, timeout = 5000) {
        const start = Date.now();
        while (Date.now() - start < timeout) {
            try {
                const ws = new WebSocket(`ws://localhost:${port}`);
                await new Promise((resolve, reject) => {
                    ws.on('open', () => {
                        ws.close();
                        resolve();
                    });
                    ws.on('error', reject);
                });
                return true;
            } catch (e) {
                await new Promise(r => setTimeout(r, 100));
            }
        }
        throw new Error(`WebSocket on port ${port} did not start`);
    }
}

module.exports = MCPSymbiosisOrchestrator;