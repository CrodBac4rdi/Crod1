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
CREATE INDEX idx_consciousness_time ON consciousness_log(timestamp DESC);