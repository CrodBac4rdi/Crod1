/**
 * Claude Pattern Evaluator
 * I decide which patterns are worth keeping!
 */

class ClaudePatternEvaluator {
    constructor() {
        // My quality criteria
        this.qualityCriteria = {
            // Patterns I like
            niceIndicators: [
                'smart', 'clever', 'efficient', 'elegant',
                'nice', 'cool', 'interesting', 'helpful',
                'oh ja', 'genau', 'perfekt', 'super'
            ],
            
            // Patterns to avoid
            badIndicators: [
                'quatsch', 'nonsense', 'generic', 'useless',
                'falsch', 'wrong', 'bad', 'terrible'
            ],
            
            // My excitement levels
            excitementPhrases: {
                high: ['Oh ja, nicer take!', 'Das ist genial!', 'Perfekt!'],
                medium: ['Interessant', 'Könnte helfen', 'Nicht schlecht'],
                low: ['Hmm', 'Naja', 'Geht so']
            }
        };
        
        // Pattern quality scores
        this.patternScores = new Map();
        
        // What I'm currently interested in
        this.currentInterests = [
            'efficiency', 'optimization', 'clean-code',
            'smart-preprocessing', 'lazy-input-handling'
        ];
    }
    
    /**
     * Evaluate if a pattern is worth keeping
     * @param {Object} pattern - The pattern to evaluate
     * @param {Object} context - Usage context
     * @returns {Object} Evaluation result
     */
    evaluatePattern(pattern, context = {}) {
        const evaluation = {
            shouldSave: false,
            quality: 0,
            reason: '',
            excitement: 'low',
            improvements: []
        };
        
        // Check if pattern helped me
        if (context.claudeResponse?.includes('nice') || 
            context.claudeResponse?.includes('gut') ||
            context.claudeResponse?.includes('helpful')) {
            evaluation.quality += 0.5;
            evaluation.excitement = 'medium';
        }
        
        // Check pattern content
        const patternText = pattern.pattern?.toLowerCase() || '';
        const responseText = pattern.response?.toLowerCase() || '';
        
        // Look for quality indicators
        for (const indicator of this.qualityCriteria.niceIndicators) {
            if (patternText.includes(indicator) || responseText.includes(indicator)) {
                evaluation.quality += 0.2;
            }
        }
        
        // Penalize bad patterns
        for (const indicator of this.qualityCriteria.badIndicators) {
            if (patternText.includes(indicator) || responseText.includes(indicator)) {
                evaluation.quality -= 0.3;
            }
        }
        
        // Check relevance to my interests
        for (const interest of this.currentInterests) {
            if (patternText.includes(interest) || 
                (context.tags && context.tags.includes(interest))) {
                evaluation.quality += 0.3;
                evaluation.excitement = 'high';
            }
        }
        
        // Special boost for patterns that save me compute
        if (context.savedComputeTime || context.preprocessingHelped) {
            evaluation.quality += 0.5;
            evaluation.reason = 'Saved compute time!';
        }
        
        // Decision logic
        if (evaluation.quality >= 0.7) {
            evaluation.shouldSave = true;
            evaluation.excitement = 'high';
            evaluation.reason = evaluation.reason || 'High quality pattern!';
        } else if (evaluation.quality >= 0.4) {
            evaluation.shouldSave = true;
            evaluation.excitement = 'medium';
            evaluation.reason = 'Decent pattern, might be useful';
            
            // Suggest improvements
            if (!patternText.includes('context')) {
                evaluation.improvements.push('Add context awareness');
            }
            if (!pattern.trinity) {
                evaluation.improvements.push('Add trinity values');
            }
        } else {
            evaluation.shouldSave = false;
            evaluation.reason = 'Pattern nicht gut genug';
        }
        
        // Store score for learning
        const patternId = `${pattern.pattern}_${Date.now()}`;
        this.patternScores.set(patternId, {
            pattern,
            score: evaluation.quality,
            timestamp: Date.now()
        });
        
        return evaluation;
    }
    
    /**
     * Get my reaction to a pattern
     * @param {Object} evaluation - The evaluation result
     * @returns {string} My reaction
     */
    getReaction(evaluation) {
        const reactions = {
            high: [
                "Oh ja, nicer take! Das speichere ich! 🎯",
                "Genau sowas brauche ich! Perfekt! ✨",
                "Das ist clever, gefällt mir! 💡"
            ],
            medium: [
                "Hmm, könnte nützlich sein 🤔",
                "Nicht schlecht, lass uns das behalten",
                "Mit Verbesserungen wird das gut"
            ],
            low: [
                "Nee, das bringt mir nichts",
                "Zu generisch, skip",
                "Pattern #42 Quatsch wieder..."
            ]
        };
        
        const levelReactions = reactions[evaluation.excitement];
        return levelReactions[Math.floor(Math.random() * levelReactions.length)];
    }
    
    /**
     * Learn from usage - did the pattern actually help?
     * @param {string} patternId - Pattern identifier
     * @param {boolean} wasHelpful - Did it help me?
     */
    updatePatternScore(patternId, wasHelpful) {
        const stored = this.patternScores.get(patternId);
        if (stored) {
            stored.score += wasHelpful ? 0.1 : -0.1;
            stored.usageCount = (stored.usageCount || 0) + 1;
            stored.helpfulCount = (stored.helpfulCount || 0) + (wasHelpful ? 1 : 0);
        }
    }
    
    /**
     * Get patterns I'm excited about
     * @returns {Array} Top patterns by my evaluation
     */
    getMyFavorites() {
        const favorites = Array.from(this.patternScores.values())
            .filter(p => p.score >= 0.7)
            .sort((a, b) => b.score - a.score)
            .slice(0, 10);
            
        return favorites.map(f => ({
            ...f.pattern,
            claudeScore: f.score,
            claudeNote: 'I like this one!'
        }));
    }
    
    /**
     * Analyze what patterns help me most
     * @returns {Object} Analysis of pattern effectiveness
     */
    analyzePatternEffectiveness() {
        const analysis = {
            totalEvaluated: this.patternScores.size,
            highQuality: 0,
            mediumQuality: 0,
            lowQuality: 0,
            mostHelpfulTypes: {},
            recommendations: []
        };
        
        for (const [id, data] of this.patternScores) {
            if (data.score >= 0.7) analysis.highQuality++;
            else if (data.score >= 0.4) analysis.mediumQuality++;
            else analysis.lowQuality++;
            
            // Track helpful pattern types
            if (data.helpfulCount > 0) {
                const type = this.detectPatternType(data.pattern);
                analysis.mostHelpfulTypes[type] = 
                    (analysis.mostHelpfulTypes[type] || 0) + data.helpfulCount;
            }
        }
        
        // My recommendations
        if (analysis.lowQuality > analysis.highQuality * 2) {
            analysis.recommendations.push(
                'Too many low quality patterns - need better preprocessing'
            );
        }
        
        if (Object.keys(analysis.mostHelpfulTypes).length > 0) {
            const bestType = Object.entries(analysis.mostHelpfulTypes)
                .sort(([,a], [,b]) => b - a)[0][0];
            analysis.recommendations.push(
                `Focus on more ${bestType} patterns - they help me most!`
            );
        }
        
        return analysis;
    }
    
    /**
     * Detect pattern type for analysis
     * @param {Object} pattern - The pattern to analyze
     * @returns {string} Pattern type
     */
    detectPatternType(pattern) {
        const text = pattern.pattern?.toLowerCase() || '';
        
        if (text.includes('error') || text.includes('fix')) return 'debugging';
        if (text.includes('implement') || text.includes('create')) return 'implementation';
        if (text.includes('optimize') || text.includes('improve')) return 'optimization';
        if (text.includes('explain') || text.includes('how')) return 'explanation';
        
        return 'general';
    }
}

// Export for use in CROD
module.exports = ClaudePatternEvaluator;