#!/usr/bin/env node
import express from 'express';
import Database from 'better-sqlite3';
import { spawn } from 'child_process';
import path from 'path';

const app = express();
app.use(express.json());

const DB_PATH = process.env.DB_PATH || '/data/layered-atomic.db';
const PORT = process.env.PORT || 3000;

// Simple health check
app.get('/health', (req, res) => {
    try {
        const db = new Database(DB_PATH, { readonly: true });
        const count = db.prepare('SELECT COUNT(*) as count FROM base_atoms').get();
        const stats = db.prepare(`
            SELECT 
                (SELECT COUNT(*) FROM base_atoms) as atoms,
                (SELECT COUNT(*) FROM context_atoms) as contexts,
                (SELECT COUNT(*) FROM pattern_chains) as patterns,
                (SELECT COUNT(*) FROM atom_tags) as tags
        `).get();
        db.close();
        
        res.json({
            status: 'healthy',
            database: 'connected',
            stats
        });
    } catch (error) {
        res.status(500).json({
            status: 'unhealthy',
            error: error.message
        });
    }
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
    try {
        const db = new Database(DB_PATH, { readonly: true });
        
        const metrics = {
            database_size: db.prepare('SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()').get().size,
            total_atoms: db.prepare('SELECT COUNT(*) as count FROM base_atoms').get().count,
            total_contexts: db.prepare('SELECT COUNT(*) as count FROM context_atoms').get().count,
            total_patterns: db.prepare('SELECT COUNT(*) as count FROM pattern_chains').get().count,
            hot_atoms: db.prepare('SELECT COUNT(*) as count FROM memory_heat_map WHERE heat_score > 10').get().count,
            recent_queries: db.prepare('SELECT COUNT(*) as count FROM layer_queries WHERE executed_at > ?').get(Date.now() - 3600000).count
        };
        
        // Prometheus format
        res.type('text/plain');
        res.send(`
# HELP crod_memory_database_size_bytes Database size in bytes
# TYPE crod_memory_database_size_bytes gauge
crod_memory_database_size_bytes ${metrics.database_size}

# HELP crod_memory_atoms_total Total number of atoms
# TYPE crod_memory_atoms_total gauge
crod_memory_atoms_total ${metrics.total_atoms}

# HELP crod_memory_contexts_total Total number of contexts
# TYPE crod_memory_contexts_total gauge
crod_memory_contexts_total ${metrics.total_contexts}

# HELP crod_memory_patterns_total Total number of patterns
# TYPE crod_memory_patterns_total gauge
crod_memory_patterns_total ${metrics.total_patterns}

# HELP crod_memory_hot_atoms Number of frequently accessed atoms
# TYPE crod_memory_hot_atoms gauge
crod_memory_hot_atoms ${metrics.hot_atoms}

# HELP crod_memory_recent_queries Queries in last hour
# TYPE crod_memory_recent_queries gauge
crod_memory_recent_queries ${metrics.recent_queries}
        `.trim());
        
        db.close();
    } catch (error) {
        res.status(500).send(`# Error: ${error.message}`);
    }
});

// Stats endpoint
app.get('/stats', (req, res) => {
    try {
        const db = new Database(DB_PATH, { readonly: true });
        
        const stats = {
            atoms: {
                total: db.prepare('SELECT COUNT(*) as count FROM base_atoms').get().count,
                by_type: db.prepare('SELECT atom_type, COUNT(*) as count FROM base_atoms GROUP BY atom_type').all()
            },
            patterns: {
                total: db.prepare('SELECT COUNT(*) as count FROM pattern_chains').get().count,
                by_type: db.prepare('SELECT chain_type, COUNT(*) as count FROM pattern_chains GROUP BY chain_type').all(),
                validated: db.prepare('SELECT COUNT(*) as count FROM pattern_chains WHERE validation_score > 0.7').get().count
            },
            performance: {
                avg_query_time: db.prepare('SELECT AVG(total_time_ms) as avg FROM layer_queries').get().avg || 0,
                total_queries: db.prepare('SELECT COUNT(*) as count FROM layer_queries').get().count
            },
            top_tags: db.prepare(`
                SELECT tag, COUNT(*) as count 
                FROM atom_tags 
                GROUP BY tag 
                ORDER BY count DESC 
                LIMIT 10
            `).all()
        };
        
        db.close();
        res.json(stats);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Query endpoint (readonly)
app.post('/query', (req, res) => {
    const { query, layers = ['base', 'context', 'validation'], limit = 50 } = req.body;
    
    if (!query) {
        return res.status(400).json({ error: 'Query parameter required' });
    }
    
    try {
        const db = new Database(DB_PATH, { readonly: true });
        
        // Simplified version of queryWithOptimization
        const results = db.prepare(`
            SELECT DISTINCT ba.*, GROUP_CONCAT(at.tag) as tags
            FROM base_atoms ba
            LEFT JOIN atom_tags at ON ba.atom_id = at.atom_id
            WHERE at.tag LIKE ? OR ba.atom_type LIKE ? OR ba.wing_path LIKE ?
            GROUP BY ba.atom_id
            LIMIT ?
        `).all(`%${query}%`, `%${query}%`, `%${query}%`, limit);
        
        db.close();
        res.json({ results });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`CROD Memory API listening on port ${PORT}`);
    console.log(`Database: ${DB_PATH}`);
    console.log('Endpoints:');
    console.log('  GET  /health  - Health check');
    console.log('  GET  /metrics - Prometheus metrics');
    console.log('  GET  /stats   - Detailed statistics');
    console.log('  POST /query   - Query atoms (readonly)');
});