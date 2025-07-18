/**
 * CROD Chain Executor
 * Executes prompt chains and manages async operations
 * Mathematical approach to task dependencies
 */

class CRODChainExecutor {
    constructor() {
        // Execution queue
        this.queue = [];
        this.executing = new Map();
        this.completed = new Map();
        
        // Dependency graph
        this.dependencies = new Map();
        
        // Performance metrics
        this.metrics = {
            totalExecutions: 0,
            asyncExecutions: 0,
            timeSaved: 0
        };
    }
    
    /**
     * Execute a prompt chain
     * @param {Object} chain - The chain to execute
     * @param {Function} claudeExecutor - Function to execute prompts
     * @returns {Promise<Object>} Execution results
     */
    async executeChain(chain, claudeExecutor) {
        const startTime = Date.now();
        const results = new Map();
        
        // Build dependency graph
        this.buildDependencyGraph(chain);
        
        // Find tasks that can run immediately
        const readyTasks = this.findReadyTasks(chain);
        
        // Execute in waves
        while (readyTasks.length > 0 || this.executing.size > 0) {
            // Start all ready tasks
            const promises = readyTasks.map(async (task) => {
                this.executing.set(task.order, task);
                
                try {
                    const result = await this.executeTask(task, claudeExecutor, results);
                    results.set(task.order, result);
                    this.completed.set(task.order, true);
                    this.executing.delete(task.order);
                } catch (error) {
                    results.set(task.order, { error: error.message });
                    this.executing.delete(task.order);
                }
            });
            
            // Wait for at least one to complete
            if (promises.length > 0) {
                await Promise.race(promises);
            }
            
            // Find newly ready tasks
            readyTasks.length = 0;
            readyTasks.push(...this.findReadyTasks(chain));
        }
        
        // Calculate metrics
        const endTime = Date.now();
        const executionTime = endTime - startTime;
        const theoreticalSequentialTime = chain.steps.length * 1000; // Assume 1s per task
        
        this.metrics.totalExecutions++;
        this.metrics.timeSaved += Math.max(0, theoreticalSequentialTime - executionTime);
        
        return {
            results: Array.from(results.values()),
            executionTime,
            savedTime: theoreticalSequentialTime - executionTime,
            parallelTasks: this.metrics.asyncExecutions
        };
    }
    
    /**
     * Build dependency graph using math
     * @param {Object} chain - The chain to analyze
     */
    buildDependencyGraph(chain) {
        this.dependencies.clear();
        
        chain.steps.forEach(step => {
            const deps = [];
            
            if (step.dependsOn !== null) {
                if (Array.isArray(step.dependsOn)) {
                    deps.push(...step.dependsOn);
                } else {
                    deps.push(step.dependsOn);
                }
            }
            
            this.dependencies.set(step.order, deps);
        });
    }
    
    /**
     * Find tasks ready to execute (no pending dependencies)
     * @param {Object} chain - The chain to check
     * @returns {Array} Ready tasks
     */
    findReadyTasks(chain) {
        return chain.steps.filter(step => {
            // Skip if already executing or completed
            if (this.executing.has(step.order) || this.completed.has(step.order)) {
                return false;
            }
            
            // Check if all dependencies are satisfied
            const deps = this.dependencies.get(step.order) || [];
            return deps.every(dep => this.completed.has(dep));
        });
    }
    
    /**
     * Execute a single task
     * @param {Object} task - Task to execute
     * @param {Function} claudeExecutor - Executor function
     * @param {Map} previousResults - Previous results for context
     * @returns {Promise<Object>} Task result
     */
    async executeTask(task, claudeExecutor, previousResults) {
        // Build context from dependencies
        const context = {};
        const deps = this.dependencies.get(task.order) || [];
        
        deps.forEach(dep => {
            if (previousResults.has(dep)) {
                context[`step_${dep}_result`] = previousResults.get(dep);
            }
        });
        
        // Add context to prompt if needed
        let enhancedPrompt = task.prompt;
        if (Object.keys(context).length > 0) {
            enhancedPrompt += `\nContext from previous steps: ${JSON.stringify(context, null, 2)}`;
        }
        
        // Track async execution
        if (task.async) {
            this.metrics.asyncExecutions++;
        }
        
        // Execute with Claude
        const result = await claudeExecutor({
            prompt: enhancedPrompt,
            agent: task.agent,
            async: task.async
        });
        
        return {
            task: task.order,
            agent: task.agent,
            result,
            async: task.async,
            executedAt: Date.now()
        };
    }
    
    /**
     * Optimize chain for maximum parallelization
     * @param {Object} chain - Chain to optimize
     * @returns {Object} Optimized chain
     */
    optimizeChain(chain) {
        const optimized = JSON.parse(JSON.stringify(chain)); // Deep clone
        
        // Analyze each step for parallelization opportunities
        optimized.steps.forEach((step, index) => {
            // Check if this step really needs to wait
            if (step.dependsOn === index - 1) {
                // Does it actually use the previous result?
                const promptLower = step.prompt.toLowerCase();
                const needsPrevious = promptLower.includes('previous') || 
                                    promptLower.includes('above') ||
                                    promptLower.includes('result');
                
                if (!needsPrevious) {
                    // Can be parallelized!
                    step.dependsOn = null;
                    step.async = true;
                }
            }
        });
        
        // Calculate optimization score
        const originalSequential = chain.steps.filter(s => !s.async).length;
        const optimizedSequential = optimized.steps.filter(s => !s.async).length;
        const improvementPercent = ((originalSequential - optimizedSequential) / originalSequential) * 100;
        
        optimized.optimization = {
            original: originalSequential,
            optimized: optimizedSequential,
            improvement: Math.round(improvementPercent) + '%'
        };
        
        return optimized;
    }
    
    /**
     * Create smart chain from vague input
     * @param {string} input - Vague input like "make it work"
     * @returns {Object} Smart chain
     */
    createSmartChain(input) {
        const inputLower = input.toLowerCase();
        const steps = [];
        
        // Ultra minimal - what does "make it work" mean?
        if (inputLower.includes('work') || inputLower.includes('fix')) {
            steps.push({
                order: 0,
                prompt: 'Identify what is broken',
                agent: 'analyzer',
                async: false
            });
            steps.push({
                order: 1,
                prompt: 'Fix the identified issues',
                agent: 'debugger',
                dependsOn: 0,
                async: false
            });
            steps.push({
                order: 2,
                prompt: 'Verify the fix works',
                agent: 'analyzer',
                dependsOn: 1,
                async: false
            });
        } else if (inputLower.includes('faster') || inputLower.includes('optimize')) {
            steps.push({
                order: 0,
                prompt: 'Profile current performance',
                agent: 'analyzer',
                async: true
            });
            steps.push({
                order: 1,
                prompt: 'Identify bottlenecks',
                agent: 'analyzer',
                async: true
            });
            steps.push({
                order: 2,
                prompt: 'Optimize identified bottlenecks',
                agent: 'optimizer',
                dependsOn: [0, 1],
                async: false
            });
        } else {
            // Default chain for vague input
            steps.push({
                order: 0,
                prompt: `Understand and implement: ${input}`,
                agent: 'builder',
                async: false
            });
        }
        
        return {
            id: `smart_${Date.now()}`,
            steps,
            source: 'smart_chain_generator'
        };
    }
    
    /**
     * Get execution metrics
     * @returns {Object} Metrics
     */
    getMetrics() {
        return {
            ...this.metrics,
            averageTimeSaved: this.metrics.totalExecutions > 0 
                ? Math.round(this.metrics.timeSaved / this.metrics.totalExecutions)
                : 0,
            parallelizationRate: this.metrics.totalExecutions > 0
                ? Math.round((this.metrics.asyncExecutions / this.metrics.totalExecutions) * 100)
                : 0
        };
    }
}

module.exports = CRODChainExecutor;