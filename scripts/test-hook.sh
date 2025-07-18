#!/usr/bin/env bash
# Hook execution test - this will run before MCP tools if hooks are configured correctly

echo "🚀 HOOK EXECUTED: $(date)"
echo "📋 Hook Type: PreToolUse"
echo "🛠️ Tool: $1"
echo "📍 Script: $0"
echo "✅ Hooks are working correctly!"
echo "==============================================="

# Exit 0 to allow tool execution to continue
exit 0
