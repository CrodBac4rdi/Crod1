#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CROD Supabase Setup (API Method) ===${NC}"

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

# Create a Node.js script to execute SQL via Supabase API
cat > execute-sql.js << 'EOF'
const fs = require('fs');
const path = require('path');

// Simple HTTP request without external dependencies
const https = require('https');
const { URL } = require('url');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

async function executeSql(sql) {
    const url = new URL(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`);
    
    const options = {
        method: 'POST',
        headers: {
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
    };

    const data = JSON.stringify({ query: sql });

    return new Promise((resolve, reject) => {
        const req = https.request(url, options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(body);
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${body}`));
                }
            });
        });
        
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

// Alternative: Direct database execution via supabase-js if available
async function executeSqlDirect(sql) {
    try {
        // Try to load @supabase/supabase-js if installed
        const { createClient } = require('@supabase/supabase-js');
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
        
        const { data, error } = await supabase.rpc('exec_sql', { query: sql });
        if (error) throw error;
        return data;
    } catch (e) {
        // If not available, use raw SQL endpoint
        const url = new URL(`${SUPABASE_URL}/rest/v1/`);
        url.pathname = '/';
        url.searchParams.set('query', sql);
        
        const options = {
            method: 'POST',
            headers: {
                'apikey': SUPABASE_SERVICE_KEY,
                'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
                'Content-Type': 'application/json'
            }
        };

        return new Promise((resolve, reject) => {
            const req = https.request(url, options, (res) => {
                let body = '';
                res.on('data', chunk => body += chunk);
                res.on('end', () => {
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(body);
                    } else {
                        reject(new Error(`HTTP ${res.statusCode}: ${body}`));
                    }
                });
            });
            
            req.on('error', reject);
            req.end();
        });
    }
}

async function main() {
    const schemasDir = path.join(__dirname, 'schemas');
    const files = fs.readdirSync(schemasDir).filter(f => f.endsWith('.sql')).sort();
    
    console.log(`Found ${files.length} schema files to apply`);
    
    for (const file of files) {
        console.log(`\nApplying ${file}...`);
        const sql = fs.readFileSync(path.join(schemasDir, file), 'utf8');
        
        try {
            // Split by semicolon and execute each statement
            const statements = sql.split(';').filter(s => s.trim());
            for (const statement of statements) {
                if (statement.trim()) {
                    await executeSqlDirect(statement + ';');
                }
            }
            console.log(`✓ ${file} applied successfully`);
        } catch (error) {
            console.error(`✗ Failed to apply ${file}:`, error.message);
            // Continue with other files
        }
    }
}

main().catch(console.error);
EOF

echo -e "${YELLOW}Note: Supabase doesn't allow direct SQL execution via API for security reasons.${NC}"
echo -e "${YELLOW}You need to either:${NC}"
echo ""
echo "1. Use the Supabase Dashboard SQL Editor:"
echo "   - Go to https://app.supabase.com/project/${SUPABASE_PROJECT_REF}/sql"
echo "   - Copy and paste each .sql file from the schemas/ directory"
echo ""
echo "2. Use Supabase CLI (install from https://supabase.com/docs/guides/cli):"
echo "   supabase login"
echo "   supabase link --project-ref ${SUPABASE_PROJECT_REF}"
echo "   supabase db push < schemas/01_crod_brain_patterns.sql"
echo "   supabase db push < schemas/02_memory_servers.sql"
echo "   supabase db push < schemas/03_task_execution.sql"
echo ""
echo "3. Get your database password from Supabase Dashboard:"
echo "   - Go to Settings -> Database"
echo "   - Copy the database password"
echo "   - Run: ./setup-supabase.sh"
echo ""

# Clean up
rm -f execute-sql.js

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

echo -e "\n${GREEN}=== Manual Table Creation Required ===${NC}"
echo -e "${YELLOW}Since direct SQL execution requires database credentials,${NC}"
echo -e "${YELLOW}please choose one of the methods above to create the tables.${NC}"
echo ""
echo -e "${GREEN}The following files have been prepared:${NC}"
echo "✓ Docker environment file with Supabase credentials"
echo "✓ MCP configuration updated with Supabase credentials"
echo "✓ SQL schemas ready in schemas/ directory:"
ls -la schemas/*.sql | awk '{print "  - " $9}'