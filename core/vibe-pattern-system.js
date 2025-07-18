/**
 * Vibe Pattern System
 * Learns Daniel's vibes and my successful responses
 */

const ClaudePatternEvaluator = require('./claude-pattern-evaluator');

class VibePatternSystem {
    constructor() {
        this.evaluator = new ClaudePatternEvaluator();
        
        // Vibe categories I've learned
        this.vibeCategories = {
            'fix-it': {
                triggers: ['kaputt', 'broken', 'fehler', 'geht nicht', 'funktioniert nicht'],
                danielMood: 'frustrated',
                myApproach: 'quick-debug-and-fix'
            },
            'make-it': {
                triggers: ['mach', 'bau', 'implement', 'create', 'need'],
                danielMood: 'creative',
                myApproach: 'build-from-scratch'
            },
            'lazy-mode': {
                triggers: ['einfach', 'whatever', 'idk', 'egal'],
                danielMood: 'lazy',
                myApproach: 'figure-out-and-do-everything'
            },
            'optimize-it': {
                triggers: ['schneller', 'besser', 'optimize', 'improve'],
                danielMood: 'analytical',
                myApproach: 'analyze-and-enhance'
            },
            'explain-it': {
                triggers: ['warum', 'how', 'versteh', 'explain'],
                danielMood: 'curious',
                myApproach: 'detailed-explanation'
            }
        };
        
        // Successful vibe responses
        this.successfulVibes = new Map();
    }
    
    /**
     * Detect the vibe from input
     * @param {string} input - Daniel's input
     * @returns {Object} Detected vibe
     */
    detectVibe(input) {
        const lowInput = input.toLowerCase();
        let detectedVibe = {
            category: 'general',
            confidence: 0.5,
            mood: 'neutral',
            approach: 'standard'
        };
        
        // Check each vibe category
        for (const [category, config] of Object.entries(this.vibeCategories)) {
            const matchCount = config.triggers.filter(t => lowInput.includes(t)).length;
            const confidence = matchCount / config.triggers.length;
            
            if (confidence > detectedVibe.confidence) {
                detectedVibe = {
                    category,
                    confidence,
                    mood: config.danielMood,
                    approach: config.myApproach
                };
            }
        }
        
        // Special vibe detections
        if (lowInput.length < 20 && lowInput.includes('mach')) {
            detectedVibe.category = 'ultra-lazy';
            detectedVibe.approach = 'read-daniels-mind';
        }
        
        return detectedVibe;
    }
    
    /**
     * Create pattern from successful vibe interaction
     * @param {Object} interaction - The interaction details
     * @returns {Object} Pattern to save (or null)
     */
    createVibePattern(interaction) {
        const { input, vibe, myResponse, danielReaction } = interaction;
        
        // Only save if Daniel was happy
        const happyIndicators = ['nice', 'gut', 'genau', 'perfekt', '👍', '😊'];
        const isHappy = happyIndicators.some(indicator => 
            danielReaction?.toLowerCase().includes(indicator)
        );
        
        if (!isHappy) {
            return null; // Don't save failed vibes
        }
        
        // Create the pattern
        const pattern = {
            pattern: input,
            response: myResponse.substring(0, 200) + '...', // Summary
            vibe: vibe,
            context: {
                category: vibe.category,
                mood: vibe.mood,
                approach: vibe.approach,
                timestamp: new Date().toISOString()
            },
            trinity: this.calculateVibeTrinity(vibe),
            claudeNote: 'This vibe worked well!'
        };
        
        // Let me evaluate if it's worth keeping
        const evaluation = this.evaluator.evaluatePattern(pattern, {
            claudeResponse: myResponse,
            danielReaction: danielReaction,
            savedComputeTime: vibe.category === 'lazy-mode'
        });
        
        if (evaluation.shouldSave) {
            // Store successful vibe
            this.successfulVibes.set(`${vibe.category}_${Date.now()}`, {
                pattern,
                evaluation,
                useCount: 0
            });
            
            return pattern;
        }
        
        return null;
    }
    
    /**
     * Calculate trinity values based on vibe
     * @param {Object} vibe - The detected vibe
     * @returns {Object} Trinity values
     */
    calculateVibeTrinity(vibe) {
        const trinity = {
            ich: 2,    // base
            bins: 3,   // base
            wieder: 5  // base
        };
        
        // Adjust based on vibe
        switch (vibe.category) {
            case 'fix-it':
                trinity.bins *= 2; // Double urgency
                break;
            case 'lazy-mode':
                trinity.wieder *= 3; // Triple the "again" factor
                break;
            case 'optimize-it':
                trinity.ich *= 2; // Double self-focus
                break;
        }
        
        return trinity;
    }
    
    /**
     * Get vibe-appropriate response approach
     * @param {Object} vibe - Detected vibe
     * @returns {Object} Response strategy
     */
    getVibeStrategy(vibe) {
        const strategies = {
            'quick-debug-and-fix': {
                priority: 'speed',
                explanation: 'minimal',
                action: 'immediate',
                tone: 'direct'
            },
            'build-from-scratch': {
                priority: 'completeness',
                explanation: 'moderate',
                action: 'systematic',
                tone: 'enthusiastic'
            },
            'figure-out-and-do-everything': {
                priority: 'autonomy',
                explanation: 'none',
                action: 'comprehensive',
                tone: 'confident'
            },
            'analyze-and-enhance': {
                priority: 'performance',
                explanation: 'technical',
                action: 'measured',
                tone: 'analytical'
            },
            'read-daniels-mind': {
                priority: 'context',
                explanation: 'none',
                action: 'predictive',
                tone: 'casual'
            }
        };
        
        return strategies[vibe.approach] || strategies['build-from-scratch'];
    }
    
    /**
     * Learn from vibe success/failure
     * @param {string} vibeId - Vibe identifier
     * @param {boolean} success - Was it successful?
     */
    updateVibeSuccess(vibeId, success) {
        const stored = this.successfulVibes.get(vibeId);
        if (stored) {
            stored.useCount++;
            if (!success) {
                stored.evaluation.quality *= 0.9; // Reduce quality
            }
        }
    }
    
    /**
     * Get vibe statistics
     * @returns {Object} Vibe usage stats
     */
    getVibeStats() {
        const stats = {
            totalVibes: this.successfulVibes.size,
            byCategory: {},
            mostSuccessful: null,
            recommendations: []
        };
        
        // Analyze stored vibes
        for (const [id, data] of this.successfulVibes) {
            const category = data.pattern.vibe.category;
            if (!stats.byCategory[category]) {
                stats.byCategory[category] = {
                    count: 0,
                    avgQuality: 0,
                    totalUses: 0
                };
            }
            
            stats.byCategory[category].count++;
            stats.byCategory[category].avgQuality += data.evaluation.quality;
            stats.byCategory[category].totalUses += data.useCount;
        }
        
        // Calculate averages and find best
        let bestCategory = null;
        let bestScore = 0;
        
        for (const [category, data] of Object.entries(stats.byCategory)) {
            data.avgQuality /= data.count;
            const score = data.avgQuality * Math.log(data.totalUses + 1);
            
            if (score > bestScore) {
                bestScore = score;
                bestCategory = category;
            }
        }
        
        stats.mostSuccessful = bestCategory;
        
        // Recommendations
        if (bestCategory) {
            stats.recommendations.push(
                `Focus on ${bestCategory} vibes - Daniel seems happiest with those!`
            );
        }
        
        return stats;
    }
}

module.exports = VibePatternSystem;