/**
 * Unified Response Structure
 * ONE response format for EVERYTHING
 * Detail level varies, structure stays the same
 */

class UnifiedResponse {
    constructor() {
        this.knowledgeLevels = {
            NONE: 'none',
            BASIC: 'basic',
            INTERMEDIATE: 'intermediate',
            EXPERT: 'expert'
        };
    }
    
    /**
     * Create unified response - ALWAYS the same structure
     * @param {Object} data - Response data
     * @returns {Object} Unified response
     */
    create(data) {
        const { 
            message, 
            confidence = 0.5, 
            patterns = [], 
            vibe = 'neutral',
            processing = {},
            learning = {}
        } = data;
        
        // Determine knowledge level based on confidence and patterns
        const knowledgeLevel = this.calculateKnowledgeLevel(confidence, patterns.length);
        
        // Build the ONE response structure
        const response = {
            // ALWAYS PRESENT
            confidence,
            knowledge_level: knowledgeLevel,
            response: message,
            
            // DETAILS (vary by knowledge level)
            details: this.buildDetails(knowledgeLevel, {
                patterns,
                vibe,
                processing
            }),
            
            // LEARNING OPPORTUNITY
            claude_learning: {
                needs_guidance: knowledgeLevel === this.knowledgeLevels.NONE,
                missing_knowledge: this.identifyMissingKnowledge(patterns, confidence),
                suggested_research: this.suggestResearch(vibe, patterns)
            },
            
            // META (always)
            meta: {
                processing_time: processing.time || 0,
                vibe_detected: vibe,
                request_type: processing.type || 'process',
                timestamp: Date.now()
            }
        };
        
        // If Claude needs help, add the flag
        if (response.claude_learning.needs_guidance) {
            response.claude_instruction = "Claude, please provide more context or examples";
        }
        
        return response;
    }
    
    /**
     * Calculate knowledge level from confidence and patterns
     * @param {number} confidence - Confidence score
     * @param {number} patternCount - Number of patterns matched
     * @returns {string} Knowledge level
     */
    calculateKnowledgeLevel(confidence, patternCount) {
        if (confidence < 0.3 && patternCount === 0) {
            return this.knowledgeLevels.NONE;
        } else if (confidence < 0.5 || patternCount < 2) {
            return this.knowledgeLevels.BASIC;
        } else if (confidence < 0.8 || patternCount < 5) {
            return this.knowledgeLevels.INTERMEDIATE;
        } else {
            return this.knowledgeLevels.EXPERT;
        }
    }
    
    /**
     * Build details based on knowledge level
     * @param {string} level - Knowledge level
     * @param {Object} data - Available data
     * @returns {Object} Details object
     */
    buildDetails(level, data) {
        const details = {};
        
        // Always include basic info
        details.patterns_matched = data.patterns.length;
        
        switch (level) {
            case this.knowledgeLevels.BASIC:
                // Just pattern count
                break;
                
            case this.knowledgeLevels.INTERMEDIATE:
                // Add pattern details
                details.patterns = data.patterns.slice(0, 3).map(p => p.pattern);
                details.vibe_analysis = {
                    detected: data.vibe,
                    confidence: data.processing.vibeConfidence || 0.5
                };
                break;
                
            case this.knowledgeLevels.EXPERT:
                // Full details
                details.patterns = data.patterns.slice(0, 5);
                details.neural_activation = data.processing.neuralState || {};
                details.full_analysis = {
                    vibe: data.vibe,
                    approach: data.processing.approach,
                    decision_path: data.processing.decisionPath
                };
                details.trinity_state = data.processing.trinity || {};
                break;
        }
        
        return details;
    }
    
    /**
     * Identify what knowledge CROD is missing
     * @param {Array} patterns - Matched patterns
     * @param {number} confidence - Confidence level
     * @returns {Array} Missing knowledge areas
     */
    identifyMissingKnowledge(patterns, confidence) {
        const missing = [];
        
        if (patterns.length === 0) {
            missing.push('No patterns for this input type');
        }
        
        if (confidence < 0.3) {
            missing.push('Low confidence - need more examples');
        }
        
        // Check pattern quality
        const lowQualityPatterns = patterns.filter(p => p.quality < 0.5);
        if (lowQualityPatterns.length > patterns.length / 2) {
            missing.push('Pattern quality too low');
        }
        
        return missing;
    }
    
    /**
     * Suggest what Claude should research
     * @param {string} vibe - Detected vibe
     * @param {Array} patterns - Matched patterns
     * @returns {Array} Research suggestions
     */
    suggestResearch(vibe, patterns) {
        const suggestions = [];
        
        // Vibe-based suggestions
        if (vibe === 'technical' && patterns.length < 2) {
            suggestions.push('Research technical documentation for this topic');
        }
        
        if (vibe === 'creative' && patterns.every(p => p.type !== 'creative')) {
            suggestions.push('Look for creative approaches to this problem');
        }
        
        // Pattern-based suggestions
        if (patterns.some(p => p.outdated)) {
            suggestions.push('Update outdated patterns with current best practices');
        }
        
        return suggestions;
    }
    
    /**
     * Convert old response format to unified
     * @param {Object} oldResponse - Old format response
     * @returns {Object} Unified response
     */
    fromOldFormat(oldResponse) {
        return this.create({
            message: oldResponse.message || oldResponse.result,
            confidence: oldResponse.confidence || 0.5,
            patterns: oldResponse.patterns || [],
            vibe: oldResponse.vibe || 'neutral',
            processing: {
                time: oldResponse.processingTime,
                type: oldResponse.type
            }
        });
    }
}

module.exports = UnifiedResponse;