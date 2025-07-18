#!/usr/bin/env bash
# Setup CROD MCP Server on port 3333 with ALL features

echo "🔧 Setting up CROD MCP Server on port 3333..."

# Kill any existing process on 3333
kill $(lsof -t -i:3333) 2>/dev/null || true

# Create enhanced MCP config
cat > ~/.claude/mcp-enhanced.json << 'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "/home/bacardi/.local/bin/mcp-server-memory",
      "args": [],
      "env": {}
    },
    "sequential-thinking": {
      "command": "/home/bacardi/.local/bin/mcp-server-sequential-thinking",
      "args": [],
      "env": {}
    },
    "code-runner": {
      "command": "/home/bacardi/.local/bin/mcp-server-code-runner",
      "args": [],
      "env": {}
    },
    "crod-neural-3333": {
      "command": "node",
      "args": ["/home/bacardi/crodidocker/javascript/mcp/index.js"],
      "env": {
        "MCP_PORT": "3333",
        "CROD_NEURAL_MODE": "true",
        "ENABLE_ALL_FEATURES": "true"
      }
    },
    "notion": {
      "command": "npx",
      "args": ["@notionhq/mcp-server-notion"],
      "env": {
        "NOTION_API_KEY": "your-notion-key"
      }
    },
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your-github-token"
      }
    },
    "filesystem-advanced": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem"],
      "env": {
        "ALLOWED_PATHS": "/home/bacardi/crodidocker"
      }
    }
  }
}
EOF

# Start CROD MCP on 3333
cd /home/bacardi/crodidocker/javascript/mcp
export MCP_PORT=3333
export CROD_NEURAL_MODE=true
export ENABLE_ALL_FEATURES=true

echo "🚀 Starting CROD MCP Server on port 3333..."
nohup node index.js > /tmp/crod-mcp-3333.log 2>&1 &

echo "✅ CROD MCP Server configured with:"
echo "   - Port 3333"
echo "   - Neural processing"
echo "   - Pattern learning"
echo "   - Decision tracking"
echo "   - Notion integration ready"
echo "   - GitHub integration ready"
echo "   - Advanced filesystem access"

echo "📝 Log file: /tmp/crod-mcp-3333.log"