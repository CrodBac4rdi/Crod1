-- Memory Server Schemas
-- For all 3 memory server types

-- 1. Basic Knowledge Graph (MCP Memory Server)
CREATE TABLE IF NOT EXISTS knowledge_entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    entity_type TEXT NOT NULL,
    observations TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS knowledge_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_entity TEXT NOT NULL,
    to_entity TEXT NOT NULL,
    relation_type TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(from_entity, to_entity, relation_type)
);

-- 2. Enhanced Memory with Trinity Consciousness
CREATE TABLE IF NOT EXISTS enhanced_memory_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_type TEXT NOT NULL,
    entry_data JSONB NOT NULL,
    consciousness_level FLOAT DEFAULT 0.0,
    trinity_scores JSONB, -- {ich: 2, bins: 3, wieder: 5}
    pattern_confidence FLOAT DEFAULT 0.5,
    heat_score FLOAT DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Layered Atomic Memory (already in SQLite, but for cloud sync)
CREATE TABLE IF NOT EXISTS base_atoms (
    atom_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atom_hash TEXT UNIQUE NOT NULL,
    atom_type TEXT NOT NULL,
    initial_weight FLOAT DEFAULT 1.0,
    wing_path JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS atom_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atom_id UUID REFERENCES base_atoms(atom_id) ON DELETE CASCADE,
    tag TEXT NOT NULL,
    tag_weight FLOAT DEFAULT 1.0,
    UNIQUE(atom_id, tag)
);

CREATE TABLE IF NOT EXISTS atom_references (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atom_id UUID REFERENCES base_atoms(atom_id) ON DELETE CASCADE,
    ref_type TEXT NOT NULL,
    ref_target TEXT NOT NULL,
    ref_strength FLOAT DEFAULT 0.5,
    UNIQUE(atom_id, ref_type, ref_target)
);

CREATE TABLE IF NOT EXISTS context_atoms (
    context_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atom_id UUID REFERENCES base_atoms(atom_id) ON DELETE CASCADE,
    context_type TEXT NOT NULL,
    adjusted_weight FLOAT DEFAULT 1.0,
    confidence_score FLOAT DEFAULT 0.8,
    access_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMPTZ DEFAULT NOW(),
    decay_factor FLOAT DEFAULT 0.95
);

CREATE TABLE IF NOT EXISTS pattern_chains (
    chain_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chain_name TEXT NOT NULL,
    chain_type TEXT NOT NULL,
    validation_score FLOAT DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_validated TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chain_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chain_id UUID REFERENCES pattern_chains(chain_id) ON DELETE CASCADE,
    atom_id UUID REFERENCES base_atoms(atom_id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    role TEXT NOT NULL,
    connection_strength FLOAT DEFAULT 0.5,
    UNIQUE(chain_id, atom_id)
);

-- Indexes for all memory types
CREATE INDEX idx_entities_type ON knowledge_entities(entity_type);
CREATE INDEX idx_relations_from ON knowledge_relations(from_entity);
CREATE INDEX idx_relations_to ON knowledge_relations(to_entity);
CREATE INDEX idx_enhanced_heat ON enhanced_memory_entries(heat_score DESC);
CREATE INDEX idx_atoms_type ON base_atoms(atom_type);
CREATE INDEX idx_tags_tag ON atom_tags(tag);
CREATE INDEX idx_context_type ON context_atoms(context_type);