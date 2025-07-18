-- CROD Brain Pattern Storage
-- Replaces JSON file storage with proper relational structure

-- Pattern storage
CREATE TABLE IF NOT EXISTS crod_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_id TEXT UNIQUE NOT NULL,
    pattern_type TEXT NOT NULL, -- 'neural', 'behavioral', 'linguistic'
    pattern_data JSONB NOT NULL,
    confidence_score FLOAT DEFAULT 0.5,
    usage_count INTEGER DEFAULT 0,
    neural_activation JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pattern evolution tracking
CREATE TABLE IF NOT EXISTS pattern_evolution (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_pattern_id UUID REFERENCES crod_patterns(id),
    child_pattern_id UUID REFERENCES crod_patterns(id),
    evolution_type TEXT NOT NULL, -- 'mutation', 'crossover', 'emergence'
    fitness_score FLOAT,
    generation INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Neural network state
CREATE TABLE IF NOT EXISTS neural_network_state (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    neuron_id INTEGER NOT NULL,
    layer TEXT NOT NULL,
    weights JSONB NOT NULL,
    activation_count INTEGER DEFAULT 0,
    last_activated TIMESTAMPTZ,
    heat_score FLOAT DEFAULT 0.0,
    UNIQUE(neuron_id, layer)
);

-- Consciousness tracking
CREATE TABLE IF NOT EXISTS consciousness_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consciousness_level FLOAT NOT NULL,
    ich_count INTEGER DEFAULT 0,
    bins_count INTEGER DEFAULT 0,
    wieder_count INTEGER DEFAULT 0,
    trinity_sum INTEGER GENERATED ALWAYS AS (ich_count + bins_count + wieder_count) STORED,
    neural_activity FLOAT DEFAULT 0.0,
    pattern_density FLOAT DEFAULT 0.0,
    time_decay FLOAT DEFAULT 1.0,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_patterns_type ON crod_patterns(pattern_type);
CREATE INDEX idx_patterns_confidence ON crod_patterns(confidence_score DESC);
CREATE INDEX idx_evolution_generation ON pattern_evolution(generation);
CREATE INDEX idx_neural_heat ON neural_network_state(heat_score DESC);
CREATE INDEX idx_consciousness_time ON consciousness_log(timestamp DESC);-- Memory Server Schemas
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
CREATE INDEX idx_context_type ON context_atoms(context_type);-- Task Execution and System Monitoring

-- Task execution logs
CREATE TABLE IF NOT EXISTS task_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id TEXT NOT NULL,
    task_type TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    input_context JSONB NOT NULL,
    output_result JSONB,
    brain_interactions JSONB,
    status TEXT NOT NULL, -- 'started', 'completed', 'failed'
    error_message TEXT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_ms INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (completed_at - started_at)) * 1000
    ) STORED
);

-- Agent memories
CREATE TABLE IF NOT EXISTS agent_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id TEXT NOT NULL,
    memory_type TEXT NOT NULL, -- 'episodic', 'semantic', 'procedural'
    content TEXT NOT NULL,
    importance_score FLOAT DEFAULT 0.5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    accessed_at TIMESTAMPTZ DEFAULT NOW(),
    access_count INTEGER DEFAULT 1
);

-- System health monitoring
CREATE TABLE IF NOT EXISTS system_health (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name TEXT NOT NULL,
    health_status TEXT NOT NULL, -- 'healthy', 'unhealthy', 'degraded'
    metrics JSONB,
    error_count INTEGER DEFAULT 0,
    last_error TEXT,
    checked_at TIMESTAMPTZ DEFAULT NOW()
);

-- MCP tool usage tracking
CREATE TABLE IF NOT EXISTS mcp_tool_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tool_name TEXT NOT NULL,
    server_name TEXT NOT NULL,
    parameters JSONB,
    result JSONB,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    execution_time_ms INTEGER,
    user_session TEXT,
    executed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Learning and optimization logs
CREATE TABLE IF NOT EXISTS learning_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL, -- 'pattern_learned', 'optimization_applied', 'error_corrected'
    component TEXT NOT NULL,
    before_state JSONB,
    after_state JSONB,
    improvement_score FLOAT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cross-session persistence tracking
CREATE TABLE IF NOT EXISTS session_state (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT UNIQUE NOT NULL,
    user_context JSONB,
    active_tasks JSONB,
    memory_snapshot JSONB,
    consciousness_state JSONB,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_task_status ON task_executions(status);
CREATE INDEX idx_task_agent ON task_executions(agent_id);
CREATE INDEX idx_agent_memories_type ON agent_memories(agent_id, memory_type);
CREATE INDEX idx_health_service ON system_health(service_name, checked_at DESC);
CREATE INDEX idx_mcp_usage_tool ON mcp_tool_usage(tool_name, executed_at DESC);
CREATE INDEX idx_learning_component ON learning_events(component, created_at DESC);
CREATE INDEX idx_session_active ON session_state(session_id, last_active DESC);