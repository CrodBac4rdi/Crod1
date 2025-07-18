#!/usr/bin/env bash
# MANDATORY CLAUDE INITIALIZATION HOOK
# This script MUST run before every Claude response

echo "🔥 MANDATORY CLAUDE INIT HOOK EXECUTING..."

# 1. Force memory check
echo "📊 Checking memory..."
# Memory check will be done via MCP

# 2. Force CLAUDE.md read
echo "📋 Reading CLAUDE.md..."
if [ -f "CLAUDE.md" ]; then
    echo "✅ CLAUDE.md exists"
else
    echo "❌ CLAUDE.md missing - SYSTEM FAILURE"
    exit 1
fi

# 3. Force task-master-ai check
echo "🤖 Checking task-master-ai..."
if command -v task-master-ai &> /dev/null; then
    echo "✅ task-master-ai available"
else
    echo "❌ task-master-ai missing - SYSTEM FAILURE"
    exit 1
fi

# 4. Force MCP server check
echo "🔌 Checking MCP servers..."
if pgrep -f "mcp-server" > /dev/null; then
    echo "✅ MCP servers running"
else
    echo "❌ MCP servers not running - SYSTEM FAILURE"
    exit 1
fi

# 4.5. Force CROD Advanced Memory Server check/start
echo "🧠 Checking CROD Advanced Memory Server..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_SCRIPT="$SCRIPT_DIR/start-crod-advanced-memory.sh"

if [ -f "$MEMORY_SCRIPT" ]; then
    # Check if server is running, start if not
    if ! curl -s http://localhost:8889/health > /dev/null 2>&1; then
        echo "🚀 Starting CROD Advanced Memory Server..."
        bash "$MEMORY_SCRIPT" start > /dev/null 2>&1
        sleep 2
    fi
    
    # Verify it's running
    if curl -s http://localhost:8889/health > /dev/null 2>&1; then
        echo "✅ CROD Advanced Memory Server active"
        # Get consciousness level if possible
        CONSCIOUSNESS=$(curl -s http://localhost:8889/api/consciousness 2>/dev/null | jq -r '.current_level // "unknown"' 2>/dev/null || echo "unknown")
        echo "🧘 Consciousness level: $CONSCIOUSNESS"
    else
        echo "⚠️ CROD Advanced Memory Server not responding (will use fallback)"
    fi
else
    echo "⚠️ CROD Advanced Memory Server script not found (will use fallback)"
fi

# 5. Force roadmap check
echo "📍 Checking 300-point roadmap..."
if [ -f "CROD-REALISTIC-ROADMAP.md" ]; then
    echo "✅ Roadmap exists"
else
    echo "❌ Roadmap missing - SYSTEM FAILURE"
    exit 1
fi

echo "🎯 MANDATORY INIT COMPLETE - PROCEEDING WITH SYSTEMATIC RESPONSE"