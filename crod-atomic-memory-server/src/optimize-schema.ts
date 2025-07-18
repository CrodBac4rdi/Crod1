#!/usr/bin/env node
import Database from 'better-sqlite3';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DB_PATH = process.env.CROD_LAYERED_DB_PATH || path.join(__dirname, '../data/layered-atomic.db');

// Optimize the database schema
function optimizeSchema() {
    console.log("=== OPTIMIZING CROD LAYERED MEMORY SCHEMA ===\n");
    
    const db = new Database(DB_PATH);
    
    try {
        // Enable optimizations
        db.pragma('auto_vacuum = INCREMENTAL');
        db.pragma('optimize');
        
        // Add missing indexes
        console.log("1. Adding performance indexes...");
        
        const newIndexes = [
            {
                name: 'idx_context_confidence',
                sql: 'CREATE INDEX IF NOT EXISTS idx_context_confidence ON context_atoms(confidence_score DESC)'
            },
            {
                name: 'idx_atom_type',
                sql: 'CREATE INDEX IF NOT EXISTS idx_atom_type ON base_atoms(atom_type)'
            },
            {
                name: 'idx_chain_validation',
                sql: 'CREATE INDEX IF NOT EXISTS idx_chain_validation ON pattern_chains(validation_score DESC)'
            },
            {
                name: 'idx_query_time',
                sql: 'CREATE INDEX IF NOT EXISTS idx_query_time ON layer_queries(total_time_ms)'
            },
            {
                name: 'idx_adjustment_time',
                sql: 'CREATE INDEX IF NOT EXISTS idx_adjustment_time ON context_adjustments(applied_at DESC)'
            }
        ];
        
        newIndexes.forEach(idx => {
            db.prepare(idx.sql).run();
            console.log(`  ✓ ${idx.name}`);
        });
        
        // Add triggers for automatic cleanup
        console.log("\n2. Adding maintenance triggers...");
        
        // Trigger to clean up old query logs
        db.prepare(`
            CREATE TRIGGER IF NOT EXISTS cleanup_old_queries
            AFTER INSERT ON layer_queries
            BEGIN
                DELETE FROM layer_queries 
                WHERE executed_at < (strftime('%s', 'now') - 7 * 24 * 3600) * 1000;
            END;
        `).run();
        console.log("  ✓ Query log cleanup trigger");
        
        // Trigger to update heat map
        db.prepare(`
            CREATE TRIGGER IF NOT EXISTS update_heat_on_context_access
            AFTER UPDATE OF last_accessed ON context_atoms
            BEGIN
                UPDATE memory_heat_map 
                SET heat_score = heat_score * 0.95 + 1.0,
                    access_frequency = access_frequency + 1,
                    last_heat_update = strftime('%s', 'now') * 1000
                WHERE atom_id = NEW.atom_id;
            END;
        `).run();
        console.log("  ✓ Heat map update trigger");
        
        // Add views for common queries
        console.log("\n3. Creating optimized views...");
        
        db.prepare(`
            CREATE VIEW IF NOT EXISTS v_atom_summary AS
            SELECT 
                ba.atom_id,
                ba.atom_type,
                ba.wing_path,
                ba.initial_weight,
                GROUP_CONCAT(at.tag) as tags,
                COUNT(DISTINCT ar.ref_target) as ref_count,
                COALESCE(ca.adjusted_weight, ba.initial_weight) as current_weight,
                COALESCE(ca.confidence_score, 0.8) as confidence,
                COALESCE(mh.heat_score, 0) as heat_score
            FROM base_atoms ba
            LEFT JOIN atom_tags at ON ba.atom_id = at.atom_id
            LEFT JOIN atom_references ar ON ba.atom_id = ar.atom_id
            LEFT JOIN context_atoms ca ON ba.atom_id = ca.atom_id
            LEFT JOIN memory_heat_map mh ON ba.atom_id = mh.atom_id
            GROUP BY ba.atom_id
        `).run();
        console.log("  ✓ Atom summary view");
        
        db.prepare(`
            CREATE VIEW IF NOT EXISTS v_pattern_summary AS
            SELECT 
                pc.chain_id,
                pc.chain_name,
                pc.chain_type,
                pc.validation_score,
                COUNT(cm.atom_id) as member_count,
                MAX(pv.validated_at) as last_validated
            FROM pattern_chains pc
            LEFT JOIN chain_members cm ON pc.chain_id = cm.chain_id
            LEFT JOIN pattern_validations pv ON pc.chain_id = pv.chain_id
            GROUP BY pc.chain_id
        `).run();
        console.log("  ✓ Pattern summary view");
        
        // Add full-text search virtual table
        console.log("\n4. Setting up full-text search...");
        
        db.prepare(`
            CREATE VIRTUAL TABLE IF NOT EXISTS atom_search 
            USING fts5(
                atom_id UNINDEXED,
                content,
                tags,
                wing_path,
                content=base_atoms,
                tokenize='trigram'
            )
        `).run();
        
        // Populate FTS table
        db.prepare(`
            INSERT OR REPLACE INTO atom_search (atom_id, content, tags, wing_path)
            SELECT 
                ba.atom_id,
                ba.atom_type || ' ' || COALESCE(GROUP_CONCAT(at.tag, ' '), ''),
                COALESCE(GROUP_CONCAT(at.tag, ' '), ''),
                ba.wing_path
            FROM base_atoms ba
            LEFT JOIN atom_tags at ON ba.atom_id = at.atom_id
            GROUP BY ba.atom_id
        `).run();
        console.log("  ✓ Full-text search index created");
        
        // Analyze tables for query optimizer
        console.log("\n5. Analyzing tables...");
        db.prepare('ANALYZE').run();
        console.log("  ✓ Statistics updated");
        
        // Vacuum to reclaim space
        console.log("\n6. Vacuuming database...");
        const beforeSize = db.prepare('SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()').get() as {size: number};
        db.prepare('VACUUM').run();
        const afterSize = db.prepare('SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()').get() as {size: number};
        
        const saved = beforeSize.size - afterSize.size;
        if (saved > 0) {
            console.log(`  ✓ Reclaimed ${(saved / 1024).toFixed(2)} KB`);
        } else {
            console.log("  ✓ Database already optimized");
        }
        
        // Add stored procedures (as views since SQLite doesn't support true procedures)
        console.log("\n7. Adding helper procedures...");
        
        // Procedure to get related atoms
        db.prepare(`
            CREATE VIEW IF NOT EXISTS v_get_related_atoms AS
            SELECT 
                ar1.atom_id as source_atom,
                ar2.atom_id as related_atom,
                ar1.ref_type as connection_type,
                ar1.ref_strength + COALESCE(ar2.ref_strength, 0) as combined_strength
            FROM atom_references ar1
            LEFT JOIN atom_references ar2 
                ON ar1.ref_target = ar2.atom_id 
                OR ar2.ref_target = ar1.atom_id
        `).run();
        console.log("  ✓ Related atoms view");
        
        console.log("\n=== OPTIMIZATION COMPLETE ===");
        
        // Report final stats
        const stats = db.prepare(`
            SELECT 
                (SELECT COUNT(*) FROM sqlite_master WHERE type='index') as indexes,
                (SELECT COUNT(*) FROM sqlite_master WHERE type='trigger') as triggers,
                (SELECT COUNT(*) FROM sqlite_master WHERE type='view') as views,
                (SELECT page_count * page_size FROM pragma_page_count(), pragma_page_size()) as size
        `).get() as {indexes: number, triggers: number, views: number, size: number};
        
        console.log(`\nDatabase stats:`);
        console.log(`  Indexes: ${stats.indexes}`);
        console.log(`  Triggers: ${stats.triggers}`);
        console.log(`  Views: ${stats.views}`);
        console.log(`  Size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
        
    } catch (error) {
        console.error("❌ Error:", error);
    } finally {
        db.close();
    }
}

// Run optimization
optimizeSchema();