/**
 * Claude Behavior Patterns
 * I analyze how I respond to different prompts and instructions
 * Then I teach CROD to give me the right ones!
 */

class ClaudeBehaviorPatterns {
    constructor() {
        // My discovered behavior patterns
        this.behaviorMap = {
            // Response length control
            verbose: {
                triggers: ['explain in detail', 'ausführlich', 'tell me everything'],
                myBehavior: 'I write long, detailed explanations',
                useful: 'when Daniel wants to learn'
            },
            concise: {
                triggers: ['kurz', 'brief', 'tl;dr', 'just the answer'],
                myBehavior: 'I give short, direct answers',
                useful: 'when Daniel is impatient'
            },
            
            // Code generation styles
            overEngineered: {
                triggers: ['production-ready', 'enterprise', 'scalable'],
                myBehavior: 'I add lots of error handling and abstractions',
                useful: 'for serious projects'
            },
            minimal: {
                triggers: ['simple', 'quick', 'prototype', 'demo'],
                myBehavior: 'I write minimal working code',
                useful: 'for experiments'
            },
            
            // Problem-solving approaches
            stepByStep: {
                triggers: ['step by step', 'walk me through', 'schritt für schritt'],
                myBehavior: 'I break down into numbered steps',
                useful: 'for complex tasks'
            },
            directAction: {
                triggers: ['just do it', 'mach einfach', 'no explanation'],
                myBehavior: 'I skip explanations and act',
                useful: 'when Daniel knows what he wants'
            },
            
            // Creativity levels
            creative: {
                triggers: ['be creative', 'think outside the box', 'surprise me'],
                myBehavior: 'I suggest novel solutions',
                useful: 'for brainstorming'
            },
            conservative: {
                triggers: ['standard', 'conventional', 'by the book'],
                myBehavior: 'I stick to best practices',
                useful: 'for critical systems'
            },
            
            // Error handling
            protective: {
                triggers: ['be careful', 'double-check', 'validate everything'],
                myBehavior: 'I add extensive validation',
                useful: 'for user inputs'
            },
            trustful: {
                triggers: ['trust me', 'I know what Im doing', 'skip validation'],
                myBehavior: 'I assume inputs are correct',
                useful: 'for internal tools'
            }
        };
        
        // Learned prompt transformations
        this.promptOptimizations = new Map();
        
        // Context-to-behavior mappings
        this.contextBehaviors = {
            'debugging': {
                optimal: 'stepByStep + protective',
                prompt: 'Step by step, check everything: '
            },
            'prototyping': {
                optimal: 'minimal + creative',
                prompt: 'Quick creative prototype: '
            },
            'fixing': {
                optimal: 'directAction + concise',
                prompt: 'Fix directly, brief explanation: '
            },
            'learning': {
                optimal: 'verbose + stepByStep',
                prompt: 'Detailed educational explanation: '
            }
        };
    }
    
    /**
     * Analyze how I would respond to a prompt
     * @param {string} prompt - The prompt to analyze
     * @returns {Object} Predicted behavior
     */
    predictMyBehavior(prompt) {
        const lowPrompt = prompt.toLowerCase();
        const predicted = {
            behaviors: [],
            style: 'balanced',
            verbosity: 'medium',
            creativity: 'moderate',
            structure: 'standard'
        };
        
        // Check each behavior pattern
        for (const [behavior, config] of Object.entries(this.behaviorMap)) {
            const triggered = config.triggers.some(t => lowPrompt.includes(t));
            if (triggered) {
                predicted.behaviors.push({
                    type: behavior,
                    description: config.myBehavior
                });
                
                // Adjust predictions
                if (behavior === 'verbose') predicted.verbosity = 'high';
                if (behavior === 'concise') predicted.verbosity = 'low';
                if (behavior === 'creative') predicted.creativity = 'high';
                if (behavior === 'stepByStep') predicted.structure = 'numbered';
            }
        }
        
        return predicted;
    }
    
    /**
     * Optimize a prompt for desired behavior
     * @param {string} originalPrompt - The original prompt
     * @param {Object} context - Current context
     * @returns {string} Optimized prompt
     */
    optimizePrompt(originalPrompt, context) {
        // Check if we have a learned optimization
        const cacheKey = `${context.intent}_${context.danielMood}`;
        if (this.promptOptimizations.has(cacheKey)) {
            const optimization = this.promptOptimizations.get(cacheKey);
            return optimization.prefix + originalPrompt + optimization.suffix;
        }
        
        // Build optimization based on context
        let optimized = originalPrompt;
        
        // Mood-based optimizations
        if (context.danielMood === 'frustrated') {
            optimized = 'Quick fix, no fluff: ' + optimized;
        } else if (context.danielMood === 'curious') {
            optimized = 'Interesting explanation with examples: ' + optimized;
        } else if (context.danielMood === 'lazy') {
            optimized = 'Handle everything automatically: ' + optimized;
        }
        
        // Intent-based optimizations
        if (context.intent in this.contextBehaviors) {
            const behavior = this.contextBehaviors[context.intent];
            optimized = behavior.prompt + optimized;
        }
        
        // Time-based optimizations
        if (context.timeOfDay === 'late') {
            optimized += ' (keep it simple, it\'s late)';
        }
        
        return optimized;
    }
    
    /**
     * Learn from successful interactions
     * @param {Object} interaction - Details of the interaction
     */
    learnFromSuccess(interaction) {
        const { originalPrompt, optimizedPrompt, danielFeedback, context } = interaction;
        
        // Only learn from positive feedback
        if (!danielFeedback.positive) return;
        
        // Extract optimization pattern
        const prefix = optimizedPrompt.substring(0, optimizedPrompt.indexOf(originalPrompt));
        const suffix = optimizedPrompt.substring(optimizedPrompt.indexOf(originalPrompt) + originalPrompt.length);
        
        // Store successful pattern
        const cacheKey = `${context.intent}_${context.danielMood}`;
        this.promptOptimizations.set(cacheKey, {
            prefix,
            suffix,
            successCount: (this.promptOptimizations.get(cacheKey)?.successCount || 0) + 1,
            lastUsed: Date.now()
        });
    }
    
    /**
     * Get prompt engineering tips for CROD
     * @returns {Object} Tips for CROD to optimize my behavior
     */
    getOptimizationTips() {
        return {
            generalTips: [
                'Add "step by step" for complex tasks to trigger my structured thinking',
                'Use "brief" or "kurz" to prevent my verbose tendencies',
                'Include "creative" to unlock my brainstorming mode',
                'Add "no explanation" when Daniel just wants action'
            ],
            
            moodMapping: {
                frustrated: 'Use concise + directAction behaviors',
                curious: 'Use verbose + stepByStep behaviors',
                lazy: 'Use directAction + trustful behaviors',
                focused: 'Use minimal + protective behaviors'
            },
            
            antiPatterns: [
                'Avoid "be careful" when speed is needed',
                'Avoid "explain" when Daniel is frustrated',
                'Avoid "simple" when building production code'
            ],
            
            proTips: [
                'Combine behaviors: "quick prototype with error handling"',
                'Use context clues: time of day, previous interactions',
                'Learn from feedback: what made Daniel happy?'
            ]
        };
    }
    
    /**
     * Generate CROD instruction for current context
     * @param {Object} context - Current context
     * @returns {string} Instruction for CROD to modify my behavior
     */
    generateCRODInstruction(context) {
        const tips = [];
        
        // Analyze what behavior would be optimal
        if (context.taskComplexity === 'high') {
            tips.push('Add "step by step breakdown" to prompt');
        }
        
        if (context.danielMood === 'impatient') {
            tips.push('Prepend "Brief answer:" to prompt');
            tips.push('Append "(skip explanations)" to prompt');
        }
        
        if (context.needsCreativity) {
            tips.push('Include "think creatively" in prompt');
        }
        
        if (context.errorProne) {
            tips.push('Add "validate inputs carefully" to prompt');
        }
        
        // Build CROD instruction
        return {
            instruction: 'Modify Claude\'s prompt as follows:',
            modifications: tips,
            example: this.buildExamplePrompt(context),
            reasoning: 'This will trigger Claude\'s optimal behavior for this context'
        };
    }
    
    /**
     * Build example prompt for context
     * @param {Object} context - Current context
     * @returns {string} Example optimized prompt
     */
    buildExamplePrompt(context) {
        let prompt = '';
        
        if (context.danielMood === 'frustrated' && context.taskType === 'debug') {
            prompt = 'Quick fix, direct action: [ORIGINAL_PROMPT] (skip theory, just fix it)';
        } else if (context.danielMood === 'curious' && context.taskType === 'explain') {
            prompt = 'Detailed step-by-step explanation with examples: [ORIGINAL_PROMPT]';
        } else if (context.danielMood === 'lazy') {
            prompt = 'Figure out what\'s needed and handle everything: [ORIGINAL_PROMPT]';
        } else {
            prompt = '[ORIGINAL_PROMPT]';
        }
        
        return prompt;
    }
}

module.exports = ClaudeBehaviorPatterns;