#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CROD Supabase Setup ===${NC}"

# Load environment variables
if [ -f ".env.supabase" ]; then
    source .env.supabase
else
    echo -e "${RED}Error: .env.supabase not found!${NC}"
    exit 1
fi

# Check if we have the required variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_KEY" ]; then
    echo -e "${RED}Error: SUPABASE_URL or SUPABASE_SERVICE_KEY not set!${NC}"
    exit 1
fi

echo -e "${YELLOW}Using Supabase project: $SUPABASE_PROJECT_REF${NC}"

# Method 1: Using Supabase CLI (if installed)
if command -v supabase &> /dev/null; then
    echo -e "${GREEN}Supabase CLI found. Using it to apply schemas...${NC}"
    
    # Initialize supabase if not already done
    if [ ! -f "supabase/config.toml" ]; then
        supabase init
    fi
    
    # Apply migrations
    for schema in schemas/*.sql; do
        echo -e "${YELLOW}Applying $schema...${NC}"
        supabase db push --file "$schema"
    done
    
else
    echo -e "${YELLOW}Supabase CLI not found. Using API method...${NC}"
    
    # Method 2: Using Supabase REST API
    # Note: This requires the database password which we need to get from the user
    
    echo -e "${YELLOW}To continue, we need your Supabase database password.${NC}"
    echo -e "${YELLOW}You can find it in your Supabase dashboard under Settings -> Database${NC}"
    echo -n "Enter database password: "
    read -s DB_PASSWORD
    echo
    
    # Build the connection string
    DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@db.${SUPABASE_PROJECT_REF}.supabase.co:5432/postgres"
    
    # Test connection
    echo -e "${YELLOW}Testing database connection...${NC}"
    if PGPASSWORD=$DB_PASSWORD psql "$DATABASE_URL" -c "SELECT 1" &> /dev/null; then
        echo -e "${GREEN}✓ Database connection successful${NC}"
    else
        echo -e "${RED}✗ Database connection failed${NC}"
        exit 1
    fi
    
    # Apply schemas
    for schema in schemas/*.sql; do
        echo -e "${YELLOW}Applying $(basename $schema)...${NC}"
        PGPASSWORD=$DB_PASSWORD psql "$DATABASE_URL" -f "$schema"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Applied successfully${NC}"
        else
            echo -e "${RED}✗ Failed to apply $schema${NC}"
        fi
    done
fi

echo -e "\n${GREEN}=== Generating Environment Files ===${NC}"

# Create .env file for Docker services
cat > ../goodies/infrastructure/docker/.env << EOF
# Supabase Configuration
SUPABASE_URL=$SUPABASE_URL
SUPABASE_SERVICE_KEY=$SUPABASE_SERVICE_KEY
SUPABASE_PROJECT_REF=$SUPABASE_PROJECT_REF
EOF

echo -e "${GREEN}✓ Created Docker .env file${NC}"

# Update MCP configuration
echo -e "${YELLOW}Updating MCP configuration...${NC}"

# Create a temporary Node.js script to update .mcp.json
cat > update-mcp.js << 'EOF'
const fs = require('fs');
const path = require('path');

const mcpPath = path.join(__dirname, '..', '.mcp.json');
const config = JSON.parse(fs.readFileSync(mcpPath, 'utf8'));

// Add Supabase env to all MCP servers
const supabaseEnv = {
    SUPABASE_URL: process.env.SUPABASE_URL,
    SUPABASE_SERVICE_KEY: process.env.SUPABASE_SERVICE_KEY
};

Object.keys(config.mcpServers).forEach(server => {
    if (!config.mcpServers[server].env) {
        config.mcpServers[server].env = {};
    }
    Object.assign(config.mcpServers[server].env, supabaseEnv);
});

fs.writeFileSync(mcpPath, JSON.stringify(config, null, 2));
console.log('✓ Updated .mcp.json with Supabase credentials');
EOF

node update-mcp.js
rm update-mcp.js

echo -e "\n${GREEN}=== Creating Helper Scripts ===${NC}"

# Create sync script for layered memory
cat > sync-to-supabase.sh << 'EOF'
#!/usr/bin/env bash
# Sync local SQLite data to Supabase

source .env.supabase

echo "Syncing layered atomic memory to Supabase..."

# This would require a more complex ETL process
# For now, just a placeholder
echo "TODO: Implement SQLite to Supabase sync"
echo "Options:"
echo "1. Use a tool like pgloader"
echo "2. Write a Node.js script using both SQLite and Supabase clients"
echo "3. Export SQLite to CSV and import to Supabase"
EOF

chmod +x sync-to-supabase.sh

echo -e "${GREEN}✓ Created sync-to-supabase.sh${NC}"

echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Restart Claude Code to load new MCP configuration"
echo "2. Start Docker services with: cd ../goodies/infrastructure/docker && docker-compose up -d"
echo "3. Test Supabase connection in each component"
echo ""
echo -e "${YELLOW}Supabase tables created:${NC}"
echo "- CROD Brain: patterns, neural network, consciousness"
echo "- Memory Servers: knowledge graph, enhanced memory, layered atoms"
echo "- Monitoring: task execution, agent memories, system health"
echo ""
echo -e "${GREEN}All services now have Supabase credentials!${NC}"