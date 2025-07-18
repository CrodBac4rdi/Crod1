/**
 * Quality Patterns - Only the GOOD stuff
 * No bullshit "I am CROD" patterns
 */

class QualityPatternManager {
    constructor() {
        // Start with ZERO patterns
        this.patterns = new Map();
        
        // Pattern quality threshold (0-1)
        this.minQuality = 0.7;
        
        // Track pattern effectiveness
        this.effectiveness = new Map();
    }
    
    /**
     * Add a pattern ONLY if it's actually good
     * @param {Object} pattern - Pattern to evaluate
     * @param {Object} validation - Daniel's validation
     * @returns {boolean} Was it added?
     */
    addPattern(pattern, validation) {
        // Daniel must explicitly approve
        if (!validation.danielApproved) {
            console.log(`❌ Pattern rejected - Daniel didn't approve: "${pattern.pattern}"`);
            return false;
        }
        
        // Must have helped Claude
        if (!validation.claudeHelped) {
            console.log(`❌ Pattern rejected - Didn't help Claude: "${pattern.pattern}"`);
            return false;
        }
        
        // Must be specific, not generic bullshit
        const genericBullshit = [
            'i am crod', 'hello', 'please clarify', 
            'i don\'t understand', 'error', 'undefined'
        ];
        
        const isGeneric = genericBullshit.some(bs => 
            pattern.pattern.toLowerCase().includes(bs)
        );
        
        if (isGeneric) {
            console.log(`❌ Pattern rejected - Generic bullshit: "${pattern.pattern}"`);
            return false;
        }
        
        // Calculate quality score
        const quality = this.calculateQuality(pattern, validation);
        
        if (quality < this.minQuality) {
            console.log(`❌ Pattern rejected - Quality too low (${quality}): "${pattern.pattern}"`);
            return false;
        }
        
        // IT'S GOOD! Add it
        const id = `quality_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        this.patterns.set(id, {
            ...pattern,
            quality,
            addedAt: Date.now(),
            danielValidation: validation,
            useCount: 0,
            successCount: 0
        });
        
        console.log(`✅ Quality pattern added (${quality}): "${pattern.pattern}"`);
        return true;
    }
    
    /**
     * Calculate pattern quality
     * @param {Object} pattern - The pattern
     * @param {Object} validation - Validation data
     * @returns {number} Quality score 0-1
     */
    calculateQuality(pattern, validation) {
        let score = 0;
        
        // Daniel's excitement level
        if (validation.danielReaction?.includes('nice')) score += 0.3;
        if (validation.danielReaction?.includes('genau')) score += 0.3;
        if (validation.danielReaction?.includes('perfekt')) score += 0.4;
        
        // Pattern specificity (longer = more specific)
        const wordCount = pattern.pattern.split(' ').length;
        if (wordCount >= 3) score += 0.2;
        if (wordCount >= 5) score += 0.1;
        
        // Has vibe context
        if (pattern.vibe) score += 0.2;
        
        // Has trinity values
        if (pattern.trinity) score += 0.1;
        
        // Cap at 1.0
        return Math.min(1.0, score);
    }
    
    /**
     * Find matching patterns (only quality ones!)
     * @param {Array} tokens - Input tokens
     * @returns {Array} Matching patterns sorted by quality
     */
    findPatterns(tokens) {
        const matches = [];
        
        for (const [id, pattern] of this.patterns) {
            const patternTokens = pattern.pattern.toLowerCase().split(/\s+/);
            let matchScore = 0;
            
            // Calculate match score
            tokens.forEach(token => {
                if (patternTokens.includes(token.toLowerCase())) {
                    matchScore += 1 / patternTokens.length;
                }
            });
            
            if (matchScore > 0) {
                matches.push({
                    ...pattern,
                    matchScore: matchScore * pattern.quality // Combine match and quality
                });
            }
        }
        
        // Sort by combined score
        return matches.sort((a, b) => b.matchScore - a.matchScore);
    }
    
    /**
     * Update pattern effectiveness based on usage
     * @param {string} patternId - Pattern ID
     * @param {boolean} wasEffective - Did it work?
     */
    updateEffectiveness(patternId, wasEffective) {
        const pattern = this.patterns.get(patternId);
        if (!pattern) return;
        
        pattern.useCount++;
        if (wasEffective) pattern.successCount++;
        
        // Recalculate quality based on real usage
        const effectiveness = pattern.successCount / pattern.useCount;
        pattern.quality = pattern.quality * 0.7 + effectiveness * 0.3;
        
        // Remove if quality drops too low
        if (pattern.quality < 0.3 && pattern.useCount > 5) {
            console.log(`🗑️ Removing low quality pattern: "${pattern.pattern}"`);
            this.patterns.delete(patternId);
        }
    }
    
    /**
     * Get statistics
     * @returns {Object} Pattern statistics
     */
    getStats() {
        const patterns = Array.from(this.patterns.values());
        
        return {
            total: patterns.length,
            averageQuality: patterns.reduce((sum, p) => sum + p.quality, 0) / patterns.length || 0,
            mostUsed: patterns.sort((a, b) => b.useCount - a.useCount)[0],
            mostEffective: patterns
                .filter(p => p.useCount > 0)
                .sort((a, b) => (b.successCount/b.useCount) - (a.successCount/a.useCount))[0],
            vibeBreakdown: this.getVibeBreakdown(patterns)
        };
    }
    
    /**
     * Get vibe breakdown
     * @param {Array} patterns - Pattern array
     * @returns {Object} Vibe statistics
     */
    getVibeBreakdown(patterns) {
        const vibes = {};
        
        patterns.forEach(p => {
            const vibe = p.vibe?.category || 'unknown';
            vibes[vibe] = (vibes[vibe] || 0) + 1;
        });
        
        return vibes;
    }
    
    /**
     * Export only the best patterns
     * @param {number} minQuality - Minimum quality threshold
     * @returns {Array} Best patterns
     */
    exportBestPatterns(minQuality = 0.8) {
        return Array.from(this.patterns.values())
            .filter(p => p.quality >= minQuality)
            .sort((a, b) => b.quality - a.quality)
            .map(p => ({
                pattern: p.pattern,
                response: p.response,
                quality: p.quality,
                vibe: p.vibe,
                trinity: p.trinity
            }));
    }
}

module.exports = QualityPatternManager;