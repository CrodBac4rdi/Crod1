-- Task Execution and System Monitoring

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