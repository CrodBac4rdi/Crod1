#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const mcpPath = path.join(__dirname, '..', '.mcp.json');
const config = JSON.parse(fs.readFileSync(mcpPath, 'utf8'));

// Supabase credentials to add
const supabaseEnv = {
    SUPABASE_URL: 'https://nytczkafznwyfxbkzfzv.supabase.co',
    SUPABASE_SERVICE_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55dGN6a2Fmem53eWZ4Ymt6Znp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjM1NDEzOSwiZXhwIjoyMDY3OTMwMTM5fQ.Jw_QTb8KObcY2vZdwZLSQZoF1EJfCorNfU7o6vjDOwE'
};

// Update each MCP server
let updated = 0;
Object.keys(config.mcpServers).forEach(serverName => {
    const server = config.mcpServers[serverName];
    
    // Initialize env if it doesn't exist
    if (!server.env) {
        server.env = {};
    }
    
    // Add Supabase credentials
    server.env.SUPABASE_URL = supabaseEnv.SUPABASE_URL;
    server.env.SUPABASE_SERVICE_KEY = supabaseEnv.SUPABASE_SERVICE_KEY;
    
    updated++;
    console.log(`✓ Updated ${serverName}`);
});

// Save the updated configuration
fs.writeFileSync(mcpPath, JSON.stringify(config, null, 2));

console.log(`\n✅ Successfully updated ${updated} MCP servers with Supabase credentials`);
console.log('🔄 Please restart Claude Code to apply the changes');