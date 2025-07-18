#!/usr/bin/env node
import Database from 'better-sqlite3';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DB_PATH = process.env.CROD_LAYERED_DB_PATH || path.join(__dirname, '../data/layered-atomic.db');

// Multi-layer Atomic Memory Manager with relational databases
export class LayeredAtomicManager {
    private db: Database.Database;

    constructor() {
        this.db = new Database(DB_PATH);
        // Enable WAL mode for better concurrent performance
        this.db.pragma('journal_mode = WAL');
        this.db.pragma('synchronous = NORMAL');
        this.initializeLayers();
    }

    private initializeLayers() {
        // Layer 1: Base Atoms - minimal core data
        this.db.exec(`
            CREATE TABLE IF NOT EXISTS base_atoms (
                atom_id TEXT PRIMARY KEY,
                atom_hash TEXT UNIQUE NOT NULL,
                atom_type TEXT NOT NULL,
                initial_weight REAL DEFAULT 1.0,
                created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
                wing_path TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS atom_tags (
                atom_id TEXT NOT NULL,
                tag TEXT NOT NULL,
                tag_weight REAL DEFAULT 1.0,
                PRIMARY KEY (atom_id, tag),
                FOREIGN KEY (atom_id) REFERENCES base_atoms(atom_id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS atom_references (
                atom_id TEXT NOT NULL,
                ref_type TEXT NOT NULL, -- 'pattern', 'context', 'dependency'
                ref_target TEXT NOT NULL,
                ref_strength REAL DEFAULT 0.5,
                PRIMARY KEY (atom_id, ref_type, ref_target),
                FOREIGN KEY (atom_id) REFERENCES base_atoms(atom_id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_atom_tags ON atom_tags(tag);
            CREATE INDEX IF NOT EXISTS idx_atom_refs ON atom_references(ref_type, ref_target);
        `);

        // Layer 2: Context Atoms - dynamic adjustments and optimizations
        this.db.exec(`
            CREATE TABLE IF NOT EXISTS context_atoms (
                context_id TEXT PRIMARY KEY,
                atom_id TEXT NOT NULL,
                context_type TEXT NOT NULL, -- 'temporal', 'spatial', 'semantic', 'neural'
                adjusted_weight REAL DEFAULT 1.0,
                confidence_score REAL DEFAULT 0.8,
                access_count INTEGER DEFAULT 0,
                last_accessed INTEGER DEFAULT (strftime('%s', 'now') * 1000),
                decay_factor REAL DEFAULT 0.95,
                FOREIGN KEY (atom_id) REFERENCES base_atoms(atom_id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS context_adjustments (
                adjustment_id TEXT PRIMARY KEY,
                context_id TEXT NOT NULL,
                adjustment_type TEXT NOT NULL, -- 'weight_boost', 'confidence_adjust', 'relevance_tune'
                adjustment_value REAL NOT NULL,
                reason TEXT,
                applied_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
                FOREIGN KEY (context_id) REFERENCES context_atoms(context_id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_context_atoms ON context_atoms(atom_id, context_type);
            CREATE INDEX IF NOT EXISTS idx_context_access ON context_atoms(last_accessed);
        `);

        // Layer 3: Validation & Pattern Layer - relationships and networks
        this.db.exec(`
            CREATE TABLE IF NOT EXISTS pattern_chains (
                chain_id TEXT PRIMARY KEY,
                chain_name TEXT NOT NULL,
                chain_type TEXT NOT NULL, -- 'sequence', 'network', 'hierarchy', 'cluster'
                validation_score REAL DEFAULT 0.0,
                created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
                last_validated INTEGER DEFAULT (strftime('%s', 'now') * 1000)
            );

            CREATE TABLE IF NOT EXISTS chain_members (
                chain_id TEXT NOT NULL,
                atom_id TEXT NOT NULL,
                position INTEGER NOT NULL,
                role TEXT NOT NULL, -- 'source', 'intermediate', 'target', 'hub'
                connection_strength REAL DEFAULT 0.5,
                PRIMARY KEY (chain_id, atom_id),
                FOREIGN KEY (chain_id) REFERENCES pattern_chains(chain_id) ON DELETE CASCADE,
                FOREIGN KEY (atom_id) REFERENCES base_atoms(atom_id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS pattern_validations (
                validation_id TEXT PRIMARY KEY,
                chain_id TEXT NOT NULL,
                validation_type TEXT NOT NULL, -- 'coherence', 'completeness', 'accuracy', 'efficiency'
                validation_result REAL NOT NULL,
                validation_data TEXT, -- JSON with detailed validation info
                validated_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
                FOREIGN KEY (chain_id) REFERENCES pattern_chains(chain_id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS refactoring_history (
                refactor_id TEXT PRIMARY KEY,
                chain_id TEXT NOT NULL,
                refactor_type TEXT NOT NULL, -- 'merge', 'split', 'optimize', 'reorganize'
                before_state TEXT NOT NULL, -- JSON snapshot
                after_state TEXT NOT NULL, -- JSON snapshot
                improvement_score REAL DEFAULT 0.0,
                refactored_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
                FOREIGN KEY (chain_id) REFERENCES pattern_chains(chain_id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_chain_members ON chain_members(atom_id);
            CREATE INDEX IF NOT EXISTS idx_pattern_validations ON pattern_validations(chain_id, validation_type);
        `);

        // Cross-layer optimization tables
        this.db.exec(`
            CREATE TABLE IF NOT EXISTS layer_queries (
                query_id TEXT PRIMARY KEY,
                query_pattern TEXT NOT NULL,
                layer_sequence TEXT NOT NULL, -- JSON array of layers accessed
                total_time_ms INTEGER NOT NULL,
                optimization_hints TEXT, -- JSON with optimization suggestions
                executed_at INTEGER DEFAULT (strftime('%s', 'now') * 1000)
            );

            CREATE TABLE IF NOT EXISTS memory_heat_map (
                atom_id TEXT NOT NULL,
                heat_score REAL DEFAULT 0.0,
                access_frequency INTEGER DEFAULT 0,
                pattern_participation INTEGER DEFAULT 0,
                last_heat_update INTEGER DEFAULT (strftime('%s', 'now') * 1000),
                PRIMARY KEY (atom_id),
                FOREIGN KEY (atom_id) REFERENCES base_atoms(atom_id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_heat_map ON memory_heat_map(heat_score DESC);
        `);
    }

    // Layer 1: Base Atom Operations
    async storeBaseAtom(wingPath: string[], atomType: string, tags: string[], initialWeight = 1.0): Promise<string> {
        // Validate inputs
        if (!wingPath || wingPath.length === 0) {
            throw new Error('Wing path cannot be empty');
        }
        if (!atomType || atomType.trim() === '') {
            throw new Error('Atom type cannot be empty');
        }
        
        const atomId = crypto.randomUUID();
        const atomHash = crypto.createHash('sha256')
            .update(JSON.stringify({ wingPath, atomType, tags }))
            .digest('hex');

        // Check if atom already exists
        const existing = this.db.prepare(`
            SELECT atom_id FROM base_atoms WHERE atom_hash = ?
        `).get(atomHash) as { atom_id: string } | undefined;
        
        if (existing) {
            // Return existing atom ID instead of creating duplicate
            return existing.atom_id;
        }

        // Use transaction for atomic operations
        const storeAtomTransaction = this.db.transaction(() => {
            const stmt = this.db.prepare(`
                INSERT INTO base_atoms (atom_id, atom_hash, atom_type, initial_weight, wing_path)
                VALUES (?, ?, ?, ?, ?)
            `);
            
            stmt.run(atomId, atomHash, atomType, initialWeight, JSON.stringify(wingPath));

            // Store tags
            const tagStmt = this.db.prepare(`
                INSERT INTO atom_tags (atom_id, tag, tag_weight) VALUES (?, ?, ?)
            `);
            
            for (const tag of tags) {
                tagStmt.run(atomId, tag, 1.0);
            }
        });

        try {
            storeAtomTransaction();
        } catch (error: any) {
            // Handle edge case where another process inserted the same atom
            if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
                const existing = this.db.prepare(`
                    SELECT atom_id FROM base_atoms WHERE atom_hash = ?
                `).get(atomHash) as { atom_id: string } | undefined;
                if (existing) {
                    return existing.atom_id;
                }
            }
            throw error;
        }
        
        return atomId;
    }

    async addAtomReference(atomId: string, refType: string, refTarget: string, refStrength = 0.5) {
        const stmt = this.db.prepare(`
            INSERT OR REPLACE INTO atom_references (atom_id, ref_type, ref_target, ref_strength)
            VALUES (?, ?, ?, ?)
        `);
        stmt.run(atomId, refType, refTarget, refStrength);
    }

    // Batch operations for better performance
    async storeBatchAtoms(atoms: Array<{
        wingPath: string[],
        atomType: string,
        tags: string[],
        initialWeight?: number
    }>): Promise<string[]> {
        const atomIds: string[] = [];
        
        const batchTransaction = this.db.transaction(() => {
            const atomStmt = this.db.prepare(`
                INSERT INTO base_atoms (atom_id, atom_hash, atom_type, initial_weight, wing_path)
                VALUES (?, ?, ?, ?, ?)
            `);
            
            const tagStmt = this.db.prepare(`
                INSERT INTO atom_tags (atom_id, tag, tag_weight) VALUES (?, ?, ?)
            `);

            for (const atom of atoms) {
                const atomId = crypto.randomUUID();
                const atomHash = crypto.createHash('sha256')
                    .update(JSON.stringify({ 
                        wingPath: atom.wingPath, 
                        atomType: atom.atomType, 
                        tags: atom.tags 
                    }))
                    .digest('hex');
                
                atomStmt.run(
                    atomId, 
                    atomHash, 
                    atom.atomType, 
                    atom.initialWeight || 1.0, 
                    JSON.stringify(atom.wingPath)
                );
                
                for (const tag of atom.tags) {
                    tagStmt.run(atomId, tag, 1.0);
                }
                
                atomIds.push(atomId);
            }
        });

        batchTransaction();
        return atomIds;
    }

    // Layer 2: Context Operations
    async createContext(atomId: string, contextType: string, adjustedWeight = 1.0): Promise<string> {
        const contextId = crypto.randomUUID();
        
        const stmt = this.db.prepare(`
            INSERT INTO context_atoms (context_id, atom_id, context_type, adjusted_weight)
            VALUES (?, ?, ?, ?)
        `);
        stmt.run(contextId, atomId, contextType, adjustedWeight);

        return contextId;
    }

    async adjustContext(contextId: string, adjustmentType: string, adjustmentValue: number, reason?: string) {
        const adjustmentId = crypto.randomUUID();
        
        const stmt = this.db.prepare(`
            INSERT INTO context_adjustments (adjustment_id, context_id, adjustment_type, adjustment_value, reason)
            VALUES (?, ?, ?, ?, ?)
        `);
        stmt.run(adjustmentId, contextId, adjustmentType, adjustmentValue, reason || null);

        // Update context atom with new adjustment
        const updateStmt = this.db.prepare(`
            UPDATE context_atoms 
            SET adjusted_weight = adjusted_weight * ?,
                access_count = access_count + 1,
                last_accessed = strftime('%s', 'now') * 1000
            WHERE context_id = ?
        `);
        updateStmt.run(adjustmentValue, contextId);
    }

    // Layer 3: Pattern Validation Operations
    async createPatternChain(chainName: string, chainType: string, atomIds: string[]): Promise<string> {
        // Validate inputs
        if (!atomIds || atomIds.length === 0) {
            throw new Error('Pattern chain must contain at least one atom');
        }
        if (!chainName || chainName.trim() === '') {
            throw new Error('Chain name cannot be empty');
        }
        
        const chainId = crypto.randomUUID();
        
        const chainStmt = this.db.prepare(`
            INSERT INTO pattern_chains (chain_id, chain_name, chain_type)
            VALUES (?, ?, ?)
        `);
        chainStmt.run(chainId, chainName, chainType);

        // Add chain members (handle duplicates by making position part of primary key)
        const memberStmt = this.db.prepare(`
            INSERT OR REPLACE INTO chain_members (chain_id, atom_id, position, role, connection_strength)
            VALUES (?, ?, ?, ?, ?)
        `);

        // Use a Set to track which atoms we've already added at which positions
        const addedMembers = new Set<string>();
        
        atomIds.forEach((atomId, index) => {
            const memberKey = `${chainId}-${atomId}`;
            
            // For duplicate atoms in the chain, update the role and position
            const role = index === 0 ? 'source' : 
                        index === atomIds.length - 1 ? 'target' : 'intermediate';
            
            // If this atom was already added to this chain, just update its latest position
            if (addedMembers.has(memberKey)) {
                // Update to latest position and role
                this.db.prepare(`
                    UPDATE chain_members 
                    SET position = ?, role = ? 
                    WHERE chain_id = ? AND atom_id = ?
                `).run(index, role, chainId, atomId);
            } else {
                memberStmt.run(chainId, atomId, index, role, 0.5);
                addedMembers.add(memberKey);
            }
        });

        return chainId;
    }

    async validatePatternChain(chainId: string): Promise<number> {
        // Get chain members
        const members = this.db.prepare(`
            SELECT cm.*, ba.atom_type, ba.initial_weight,
                   ca.adjusted_weight, ca.confidence_score
            FROM chain_members cm
            JOIN base_atoms ba ON cm.atom_id = ba.atom_id
            LEFT JOIN context_atoms ca ON ba.atom_id = ca.atom_id
            WHERE cm.chain_id = ?
            ORDER BY cm.position
        `).all(chainId);

        // Calculate validation scores
        let coherenceScore = 1.0;
        let completenessScore = members.length > 0 ? 1.0 : 0.0;
        let accuracyScore = 0.0;

        // Check coherence between adjacent atoms
        for (let i = 1; i < members.length; i++) {
            const prevRefs = this.db.prepare(`
                SELECT ref_target, ref_strength 
                FROM atom_references 
                WHERE atom_id = ? AND ref_type = 'pattern'
            `).all((members[i-1] as any).atom_id) as Array<{ref_target: string, ref_strength: number}>;

            const hasConnection = prevRefs.some((ref: any) => ref.ref_target === (members[i] as any).atom_id);
            coherenceScore *= hasConnection ? 1.0 : 0.8;
        }

        // Calculate average accuracy from confidence scores
        const avgConfidence = members.reduce((sum: number, m: any) => 
            sum + (m.confidence_score || 0.8), 0) / members.length;
        accuracyScore = avgConfidence;

        const validationScore = (coherenceScore + completenessScore + accuracyScore) / 3;

        // Store validation result
        const validationId = crypto.randomUUID();
        const validationData = {
            coherence: coherenceScore,
            completeness: completenessScore,
            accuracy: accuracyScore,
            memberCount: members.length
        };

        this.db.prepare(`
            INSERT INTO pattern_validations 
            (validation_id, chain_id, validation_type, validation_result, validation_data)
            VALUES (?, ?, ?, ?, ?)
        `).run(validationId, chainId, 'comprehensive', validationScore, JSON.stringify(validationData));

        // Update chain validation score
        this.db.prepare(`
            UPDATE pattern_chains 
            SET validation_score = ?, last_validated = strftime('%s', 'now') * 1000
            WHERE chain_id = ?
        `).run(validationScore, chainId);

        return validationScore;
    }

    async refactorPatternChain(chainId: string, refactorType: string): Promise<boolean> {
        const beforeState = this.getChainState(chainId);
        let improved = false;

        switch (refactorType) {
            case 'optimize':
                improved = await this.optimizeChain(chainId);
                break;
            case 'merge':
                improved = await this.mergeRedundantAtoms(chainId);
                break;
            case 'reorganize':
                improved = await this.reorganizeChain(chainId);
                break;
        }

        if (improved) {
            const afterState = this.getChainState(chainId);
            const refactorId = crypto.randomUUID();
            
            this.db.prepare(`
                INSERT INTO refactoring_history 
                (refactor_id, chain_id, refactor_type, before_state, after_state, improvement_score)
                VALUES (?, ?, ?, ?, ?, ?)
            `).run(refactorId, chainId, refactorType, 
                   JSON.stringify(beforeState), 
                   JSON.stringify(afterState),
                   0.1); // Placeholder improvement score
        }

        return improved;
    }

    // Cross-layer query optimization
    async queryWithOptimization(query: string, layers: string[] = ['base', 'context', 'validation']): Promise<any[]> {
        const startTime = Date.now();
        const queryId = crypto.randomUUID();
        const results: any[] = [];

        // Layer 1: Search base atoms
        if (layers.includes('base')) {
            const baseResults = this.db.prepare(`
                SELECT DISTINCT ba.*, GROUP_CONCAT(at.tag) as tags
                FROM base_atoms ba
                LEFT JOIN atom_tags at ON ba.atom_id = at.atom_id
                WHERE at.tag LIKE ? OR ba.atom_type LIKE ? OR ba.wing_path LIKE ?
                GROUP BY ba.atom_id
                LIMIT 100
            `).all(`%${query}%`, `%${query}%`, `%${query}%`);
            
            results.push(...baseResults.map((r: any) => ({ ...r, layer: 'base' })));
        }

        // Layer 2: Get context adjustments
        if (layers.includes('context') && results.length > 0) {
            const atomIds = results.map(r => r.atom_id);
            const contextResults = this.db.prepare(`
                SELECT ca.*, GROUP_CONCAT(adj.adjustment_type || ':' || adj.adjustment_value) as adjustments
                FROM context_atoms ca
                LEFT JOIN context_adjustments adj ON ca.context_id = adj.context_id
                WHERE ca.atom_id IN (${atomIds.map(() => '?').join(',')})
                GROUP BY ca.context_id
            `).all(...atomIds);
            
            results.forEach((r: any) => {
                r.contexts = contextResults.filter((c: any) => c.atom_id === r.atom_id);
            });
        }

        // Layer 3: Find pattern participation
        if (layers.includes('validation') && results.length > 0) {
            const atomIds = results.map(r => r.atom_id);
            const patternResults = this.db.prepare(`
                SELECT cm.atom_id, pc.*, cm.role, cm.connection_strength
                FROM chain_members cm
                JOIN pattern_chains pc ON cm.chain_id = pc.chain_id
                WHERE cm.atom_id IN (${atomIds.map(() => '?').join(',')})
                AND pc.validation_score > 0.7
            `).all(...atomIds);
            
            results.forEach((r: any) => {
                r.patterns = patternResults.filter((p: any) => p.atom_id === r.atom_id);
            });
        }

        // Update heat map
        results.forEach((r: any) => {
            this.updateHeatMap(r.atom_id, 1.0);
        });

        // Log query for optimization analysis
        const totalTime = Date.now() - startTime;
        this.db.prepare(`
            INSERT INTO layer_queries (query_id, query_pattern, layer_sequence, total_time_ms)
            VALUES (?, ?, ?, ?)
        `).run(queryId, query, JSON.stringify(layers), totalTime);

        return results;
    }

    // Helper methods
    private getChainState(chainId: string): any {
        const chain = this.db.prepare('SELECT * FROM pattern_chains WHERE chain_id = ?').get(chainId);
        const members = this.db.prepare('SELECT * FROM chain_members WHERE chain_id = ? ORDER BY position').all(chainId);
        return { chain, members };
    }

    private async optimizeChain(chainId: string): Promise<boolean> {
        // Remove weak connections
        this.db.prepare(`
            DELETE FROM chain_members 
            WHERE chain_id = ? AND connection_strength < 0.3
        `).run(chainId);
        
        return true;
    }

    private async mergeRedundantAtoms(chainId: string): Promise<boolean> {
        // Find atoms with same tags and merge them
        // Implementation depends on specific merge logic
        return false;
    }

    private async reorganizeChain(chainId: string): Promise<boolean> {
        // Reorder chain members based on connection strength
        const members = this.db.prepare(`
            SELECT * FROM chain_members 
            WHERE chain_id = ? 
            ORDER BY connection_strength DESC
        `).all(chainId) as Array<{atom_id: string, position: number}>;

        // Update positions
        members.forEach((member: any, index: number) => {
            this.db.prepare(`
                UPDATE chain_members 
                SET position = ? 
                WHERE chain_id = ? AND atom_id = ?
            `).run(index, chainId, member.atom_id);
        });

        return true;
    }

    private updateHeatMap(atomId: string, increment: number) {
        this.db.prepare(`
            INSERT INTO memory_heat_map (atom_id, heat_score, access_frequency)
            VALUES (?, ?, 1)
            ON CONFLICT(atom_id) DO UPDATE SET
                heat_score = heat_score + ?,
                access_frequency = access_frequency + 1,
                last_heat_update = strftime('%s', 'now') * 1000
        `).run(atomId, increment, increment);
    }

    close() {
        this.db.close();
    }
}