# Supabase Setup Instructions for CROD System

## ✅ What's Been Done

1. **Created SQL Schemas** (3 files in `schemas/` directory):
   - `01_crod_brain_patterns.sql` - Pattern storage, neural network state, consciousness tracking
   - `02_memory_servers.sql` - All 3 memory server types (knowledge graph, enhanced, layered atomic)
   - `03_task_execution.sql` - Task logs, agent memories, system health monitoring

2. **Updated Configuration**:
   - All 14 MCP servers now have Supabase credentials
   - Docker environment file created with Supabase credentials
   - Combined schema file created for easy copy-paste

## 🚀 Next Steps - Create Tables in Supabase

Choose ONE of these methods:

### Option 1: Supabase Dashboard (Easiest)
1. Go to: https://app.supabase.com/project/nytczkafznwyfxbkzfzv/sql
2. Copy the content from `combined-schema.sql`
3. Paste into the SQL editor
4. Click "Run" to create all tables

### Option 2: Supabase CLI
```bash
# Install Supabase CLI first
npm install -g supabase

# Login and link project
supabase login
supabase link --project-ref nytczkafznwyfxbkzfzv

# Apply schemas
supabase db push < schemas/01_crod_brain_patterns.sql
supabase db push < schemas/02_memory_servers.sql
supabase db push < schemas/03_task_execution.sql
```

### Option 3: Direct Database Connection
1. Get your database password from: https://app.supabase.com/project/nytczkafznwyfxbkzfzv/settings/database
2. Run: `./setup-supabase.sh`
3. Enter the password when prompted

## 📋 Tables That Will Be Created

### CROD Brain Tables:
- `crod_patterns` - AI pattern storage
- `pattern_evolution` - Pattern learning tracking
- `neural_network_state` - Neural network weights
- `consciousness_log` - Trinity consciousness tracking

### Memory Server Tables:
- `knowledge_entities` & `knowledge_relations` - Basic knowledge graph
- `enhanced_memory_entries` - Trinity-enhanced memories
- `base_atoms`, `atom_tags`, `atom_references` - Layered atomic memory
- `context_atoms`, `pattern_chains`, `chain_members` - Context layers

### Monitoring Tables:
- `task_executions` - Task execution logs
- `agent_memories` - Agent memory storage
- `system_health` - Service health monitoring
- `mcp_tool_usage` - MCP tool tracking
- `learning_events` - Learning/optimization tracking
- `session_state` - Cross-session persistence

## 🔄 After Creating Tables

1. **Restart Claude Code** to load the new MCP configuration
2. **Restart Docker services**:
   ```bash
   cd ../goodies/infrastructure/docker
   docker-compose down
   docker-compose up -d
   ```
3. **Test the connection** - The MCP servers will now use Supabase

## 🔍 Verification

To verify tables were created:
1. Go to: https://app.supabase.com/project/nytczkafznwyfxbkzfzv/editor
2. Check the table list on the left
3. You should see all tables listed above

## 💡 Additional Notes

- All services now have Supabase credentials via environment variables
- The layered memory server can sync SQLite data to Supabase (future implementation)
- Each component can now persist data to the cloud
- Real-time subscriptions can be added for live updates

Your Supabase project URL: https://nytczkafznwyfxbkzfzv.supabase.co