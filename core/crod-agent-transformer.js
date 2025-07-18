/**
 * CROD Agent Transformer
 * Transforms Claude into multiple specialized agents while remaining one
 * Mathematical minimal approach - only what's needed
 */

class CRODAgentTransformer {
    constructor() {
        // Agent configurations - minimal math-based
        this.agentModes = {
            'debugger': {
                prompt: 'Debug mode: Find error, fix it, nothing more.',
                trinity: { ich: 2, bins: 6, wieder: 5 }, // Double bins for urgency
                parallel: false
            },
            'builder': {
                prompt: 'Build mode: Create clean implementation.',
                trinity: { ich: 4, bins: 3, wieder: 5 }, // Double ich for focus
                parallel: true
            },
            'analyzer': {
                prompt: 'Analyze mode: Extract patterns and insights.',
                trinity: { ich: 2, bins: 3, wieder: 10 }, // Double wieder for patterns
                parallel: true
            },
            'optimizer': {
                prompt: 'Optimize mode: Make it faster, nothing fancy.',
                trinity: { ich: 2, bins: 3, wieder: 5 },
                parallel: true
            }
        };
        
        // Active transformations
        this.activeAgents = new Set();
        
        // Prompt chains for complex tasks
        this.promptChains = new Map();
    }
    
    /**
     * Transform Claude into required agents
     * @param {string} task - The task to handle
     * @returns {Object} Transformation plan
     */
    planTransformation(task) {
        const taskLower = task.toLowerCase();
        const plan = {
            agents: [],
            sequence: 'parallel', // or 'sequential'
            chains: []
        };
        
        // Minimal logic - what's needed?
        if (taskLower.includes('fix') || taskLower.includes('error')) {
            plan.agents.push('debugger');
            plan.sequence = 'sequential'; // Debug first
        }
        
        if (taskLower.includes('build') || taskLower.includes('implement')) {
            plan.agents.push('builder');
        }
        
        if (taskLower.includes('why') || taskLower.includes('analyze')) {
            plan.agents.push('analyzer');
        }
        
        if (taskLower.includes('slow') || taskLower.includes('optimize')) {
            plan.agents.push('optimizer');
        }
        
        // Default if nothing specific
        if (plan.agents.length === 0) {
            plan.agents.push('builder'); // Default to building
        }
        
        return plan;
    }
    
    /**
     * Create prompt chain for complex tasks
     * @param {Array} steps - Steps to chain
     * @returns {Object} Chain configuration
     */
    createPromptChain(steps) {
        const chain = {
            id: `chain_${Date.now()}`,
            steps: steps.map((step, index) => ({
                order: index,
                prompt: this.minimizePrompt(step.prompt),
                agent: step.agent || 'builder',
                dependsOn: step.dependsOn || (index > 0 ? index - 1 : null),
                async: step.async || false
            })),
            created: Date.now()
        };
        
        this.promptChains.set(chain.id, chain);
        return chain;
    }
    
    /**
     * Execute transformation - the magic happens here
     * @param {Object} plan - Transformation plan
     * @param {string} input - Original input
     * @returns {Object} Transformed prompts
     */
    executeTransformation(plan, input) {
        const results = {
            prompts: [],
            asyncTasks: [],
            mainTask: null
        };
        
        // Math to determine priority (using trinity values)
        const calculatePriority = (agent) => {
            const config = this.agentModes[agent];
            return config.trinity.ich * config.trinity.bins * config.trinity.wieder;
        };
        
        // Sort agents by priority
        const sortedAgents = plan.agents.sort((a, b) => 
            calculatePriority(b) - calculatePriority(a)
        );
        
        // Generate prompts
        for (const agent of sortedAgents) {
            const config = this.agentModes[agent];
            const transformedPrompt = {
                agent,
                prompt: `${config.prompt} Input: ${input}`,
                canAsync: config.parallel,
                priority: calculatePriority(agent)
            };
            
            if (config.parallel && plan.sequence === 'parallel') {
                results.asyncTasks.push(transformedPrompt);
            } else {
                results.prompts.push(transformedPrompt);
            }
        }
        
        // Set main task
        results.mainTask = results.prompts[0] || results.asyncTasks[0];
        
        return results;
    }
    
    /**
     * Minimize prompt - mathematical approach
     * @param {string} prompt - Original prompt
     * @returns {string} Minimized prompt
     */
    minimizePrompt(prompt) {
        // Remove unnecessary words
        const unnecessary = ['please', 'could you', 'would you', 'can you', 'I need'];
        let minimal = prompt;
        
        unnecessary.forEach(phrase => {
            minimal = minimal.replace(new RegExp(phrase + ' ?', 'gi'), '');
        });
        
        // Compress common phrases
        const compressions = {
            'implement a': 'build',
            'create a': 'make',
            'fix the': 'fix',
            'optimize the': 'optimize',
            'analyze the': 'analyze'
        };
        
        Object.entries(compressions).forEach(([long, short]) => {
            minimal = minimal.replace(new RegExp(long, 'gi'), short);
        });
        
        return minimal.trim();
    }
    
    /**
     * Suggest async processing opportunities
     * @param {string} task - The task to analyze
     * @returns {Array} Async suggestions
     */
    suggestAsyncOpportunities(task) {
        const opportunities = [];
        
        // Pattern: If task has multiple independent parts
        const parts = task.split(/and|sowie|und/i);
        if (parts.length > 1) {
            parts.forEach((part, index) => {
                if (!part.includes('then') && !part.includes('after')) {
                    opportunities.push({
                        task: part.trim(),
                        reason: 'Independent subtask',
                        estimatedSaving: '~30% time'
                    });
                }
            });
        }
        
        // Pattern: Research tasks can be async
        if (task.includes('research') || task.includes('find') || task.includes('search')) {
            opportunities.push({
                task: 'Research phase',
                reason: 'Can be done while planning',
                estimatedSaving: '~50% time'
            });
        }
        
        return opportunities;
    }
    
    /**
     * Get transformation statistics
     * @returns {Object} Usage stats
     */
    getStats() {
        const stats = {
            totalTransformations: this.promptChains.size,
            activeAgents: Array.from(this.activeAgents),
            efficiency: this.calculateEfficiency(),
            mostUsedAgent: this.getMostUsedAgent()
        };
        
        return stats;
    }
    
    /**
     * Calculate efficiency gain from transformations
     * @returns {number} Efficiency percentage
     */
    calculateEfficiency() {
        // Simple formula: async tasks save ~40% time
        const asyncCount = Array.from(this.promptChains.values())
            .reduce((sum, chain) => sum + chain.steps.filter(s => s.async).length, 0);
        
        const totalSteps = Array.from(this.promptChains.values())
            .reduce((sum, chain) => sum + chain.steps.length, 0);
        
        if (totalSteps === 0) return 100;
        
        return Math.round(100 + (asyncCount / totalSteps) * 40);
    }
    
    /**
     * Get most used agent mode
     * @returns {string} Most used agent
     */
    getMostUsedAgent() {
        const usage = {};
        
        this.promptChains.forEach(chain => {
            chain.steps.forEach(step => {
                usage[step.agent] = (usage[step.agent] || 0) + 1;
            });
        });
        
        return Object.entries(usage)
            .sort(([,a], [,b]) => b - a)[0]?.[0] || 'none';
    }
}

module.exports = CRODAgentTransformer;