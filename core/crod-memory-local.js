// CROD Local Memory System - SQLite based like MCP Memory Server
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

class CRODLocalMemory {
    constructor(dbPath = './data/crod-memory.db') {
        // Ensure directory exists
        const dir = path.dirname(dbPath);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        
        this.db = new Database(dbPath);
        this.db.pragma('journal_mode = WAL');
        
        this.initializeSchema();
        this.prepareStatements();
        
        console.log('🧠 CROD Local Memory initialized:', dbPath);
    }
    
    initializeSchema() {
        // Core tables inspired by MCP memory server
        this.db.exec(`
            -- Entities (like users, concepts, patterns)
            CREATE TABLE IF NOT EXISTS entities (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT NOT NULL,
                name TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                metadata JSON,
                UNIQUE(type, name)
            );
            
            -- Observations about entities (facts, patterns, behaviors)
            CREATE TABLE IF NOT EXISTS observations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entity_id INTEGER NOT NULL,
                observation TEXT NOT NULL,
                confidence REAL DEFAULT 0.5,
                source TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE
            );
            
            -- Relations between entities
            CREATE TABLE IF NOT EXISTS relations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                from_entity_id INTEGER NOT NULL,
                to_entity_id INTEGER NOT NULL,
                relation_type TEXT NOT NULL,
                strength REAL DEFAULT 1.0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (from_entity_id) REFERENCES entities(id) ON DELETE CASCADE,
                FOREIGN KEY (to_entity_id) REFERENCES entities(id) ON DELETE CASCADE
            );
            
            -- CROD specific: Pattern storage
            CREATE TABLE IF NOT EXISTS patterns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                pattern TEXT NOT NULL UNIQUE,
                response TEXT NOT NULL,
                usage_count INTEGER DEFAULT 0,
                success_rate REAL DEFAULT 0.0,
                trinity JSON,
                context JSON,
                learned_from TEXT DEFAULT 'initial',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            -- CROD specific: Interactions history
            CREATE TABLE IF NOT EXISTS interactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                input TEXT NOT NULL,
                response TEXT NOT NULL,
                response_type TEXT,
                confidence REAL,
                pattern_matches JSON,
                processing_time INTEGER,
                feedback JSON,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            -- CROD specific: Dynamic learning
            CREATE TABLE IF NOT EXISTS learning_queue (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                input TEXT NOT NULL,
                suggested_response TEXT,
                context JSON,
                confidence REAL,
                status TEXT DEFAULT 'pending',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            
            -- Indexes for performance
            CREATE INDEX IF NOT EXISTS idx_entities_type ON entities(type);
            CREATE INDEX IF NOT EXISTS idx_observations_entity ON observations(entity_id);
            CREATE INDEX IF NOT EXISTS idx_relations_from ON relations(from_entity_id);
            CREATE INDEX IF NOT EXISTS idx_relations_to ON relations(to_entity_id);
            CREATE INDEX IF NOT EXISTS idx_patterns_usage ON patterns(usage_count DESC);
            CREATE INDEX IF NOT EXISTS idx_interactions_created ON interactions(created_at DESC);
        `);
    }
    
    prepareStatements() {
        // Prepared statements for performance
        this.statements = {
            // Entity operations
            createEntity: this.db.prepare(`
                INSERT OR IGNORE INTO entities (type, name, metadata)
                VALUES (?, ?, json(?))
            `),
            
            getEntity: this.db.prepare(`
                SELECT * FROM entities WHERE type = ? AND name = ?
            `),
            
            // Observation operations
            addObservation: this.db.prepare(`
                INSERT INTO observations (entity_id, observation, confidence, source)
                VALUES (?, ?, ?, ?)
            `),
            
            // Pattern operations
            addPattern: this.db.prepare(`
                INSERT OR REPLACE INTO patterns (pattern, response, trinity, context, learned_from)
                VALUES (?, ?, json(?), json(?), ?)
            `),
            
            updatePatternUsage: this.db.prepare(`
                UPDATE patterns 
                SET usage_count = usage_count + 1,
                    success_rate = ((success_rate * usage_count) + ?) / (usage_count + 1),
                    updated_at = CURRENT_TIMESTAMP
                WHERE pattern = ?
            `),
            
            // Interaction logging
            logInteraction: this.db.prepare(`
                INSERT INTO interactions 
                (input, response, response_type, confidence, pattern_matches, processing_time)
                VALUES (?, ?, ?, ?, json(?), ?)
            `),
            
            // Learning queue
            addToLearning: this.db.prepare(`
                INSERT INTO learning_queue (input, suggested_response, context, confidence)
                VALUES (?, ?, json(?), ?)
            `)
        };
    }
    
    // Entity management (like MCP memory server)
    createEntity(type, name, metadata = {}) {
        const result = this.statements.createEntity.run(
            type, 
            name, 
            JSON.stringify(metadata)
        );
        
        if (result.changes > 0) {
            return this.statements.getEntity.get(type, name);
        }
        
        // Already exists, return it
        return this.statements.getEntity.get(type, name);
    }
    
    addObservation(entityType, entityName, observation, confidence = 0.5, source = 'crod') {
        const entity = this.createEntity(entityType, entityName);
        
        this.statements.addObservation.run(
            entity.id,
            observation,
            confidence,
            source
        );
        
        return { entity, observation };
    }
    
    // Pattern management (CROD specific)
    learnPattern(pattern, response, trinity = null, context = {}, source = 'learning') {
        this.statements.addPattern.run(
            pattern,
            response,
            JSON.stringify(trinity),
            JSON.stringify(context),
            source
        );
    }
    
    updatePatternSuccess(pattern, success = true) {
        this.statements.updatePatternUsage.run(
            success ? 1.0 : 0.0,
            pattern
        );
    }
    
    // Get all patterns (for brain initialization)
    getAllPatterns() {
        return this.db.prepare(`
            SELECT * FROM patterns 
            ORDER BY usage_count DESC, success_rate DESC
        `).all();
    }
    
    // Search patterns
    searchPatterns(query, limit = 10) {
        return this.db.prepare(`
            SELECT * FROM patterns 
            WHERE pattern LIKE ? OR response LIKE ?
            ORDER BY usage_count DESC
            LIMIT ?
        `).all(`%${query}%`, `%${query}%`, limit);
    }
    
    // Log interaction
    logInteraction(input, response, details = {}) {
        this.statements.logInteraction.run(
            input,
            response.message || response,
            details.type || 'unknown',
            details.confidence || 0.5,
            JSON.stringify(details.patterns || []),
            details.processingTime || 0
        );
    }
    
    // Get interaction history
    getInteractionHistory(limit = 100) {
        return this.db.prepare(`
            SELECT * FROM interactions 
            ORDER BY created_at DESC 
            LIMIT ?
        `).all(limit);
    }
    
    // Knowledge graph operations
    createRelation(fromType, fromName, toType, toName, relationType, strength = 1.0) {
        const fromEntity = this.createEntity(fromType, fromName);
        const toEntity = this.createEntity(toType, toName);
        
        return this.db.prepare(`
            INSERT OR REPLACE INTO relations 
            (from_entity_id, to_entity_id, relation_type, strength)
            VALUES (?, ?, ?, ?)
        `).run(fromEntity.id, toEntity.id, relationType, strength);
    }
    
    // Get full knowledge graph
    getKnowledgeGraph() {
        const entities = this.db.prepare(`
            SELECT e.*, 
                   GROUP_CONCAT(o.observation, '|||') as observations
            FROM entities e
            LEFT JOIN observations o ON e.id = o.entity_id
            GROUP BY e.id
        `).all();
        
        const relations = this.db.prepare(`
            SELECT r.*, 
                   ef.name as from_name, ef.type as from_type,
                   et.name as to_name, et.type as to_type
            FROM relations r
            JOIN entities ef ON r.from_entity_id = ef.id
            JOIN entities et ON r.to_entity_id = et.id
        `).all();
        
        return { entities, relations };
    }
    
    // Learning queue operations
    addToLearningQueue(input, suggestedResponse, context = {}, confidence = 0.5) {
        this.statements.addToLearning.run(
            input,
            suggestedResponse,
            JSON.stringify(context),
            confidence
        );
    }
    
    getPendingLearning(limit = 10) {
        return this.db.prepare(`
            SELECT * FROM learning_queue 
            WHERE status = 'pending'
            ORDER BY created_at DESC
            LIMIT ?
        `).all(limit);
    }
    
    // Analytics
    getStats() {
        const stats = this.db.prepare(`
            SELECT 
                (SELECT COUNT(*) FROM entities) as total_entities,
                (SELECT COUNT(*) FROM patterns) as total_patterns,
                (SELECT COUNT(*) FROM interactions) as total_interactions,
                (SELECT COUNT(*) FROM relations) as total_relations,
                (SELECT AVG(confidence) FROM interactions WHERE created_at > datetime('now', '-1 day')) as avg_confidence_24h,
                (SELECT COUNT(*) FROM learning_queue WHERE status = 'pending') as pending_learning
        `).get();
        
        const topPatterns = this.db.prepare(`
            SELECT pattern, usage_count, success_rate
            FROM patterns
            ORDER BY usage_count DESC
            LIMIT 5
        `).all();
        
        return { ...stats, topPatterns };
    }
    
    // Cleanup
    close() {
        this.db.close();
    }
}

module.exports = CRODLocalMemory;