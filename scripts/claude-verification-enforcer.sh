#!/usr/bin/env bash
# CLAUDE VERIFICATION ENFORCER
# Prevents Claude from lying about implementation results
# Forces proof-of-work for every claim

echo "🔍 CLAUDE VERIFICATION ENFORCER - MANDATORY PROOF PROTOCOL"
echo "=========================================================="

# Function to verify process claims
verify_process() {
    local process_name="$1"
    local claimed_status="$2"
    
    echo "📋 VERIFYING PROCESS: $process_name"
    echo "   CLAIMED: $claimed_status"
    
    local actual_processes=$(ps aux | grep "$process_name" | grep -v grep | wc -l)
    echo "   REALITY: $actual_processes process(es) found"
    
    if [ "$actual_processes" -gt 0 ]; then
        echo "   ✅ VERIFIED: Process is running"
        ps aux | grep "$process_name" | grep -v grep
    else
        echo "   ❌ FAILED: No process found - CLAUDE LIED"
        return 1
    fi
}

# Function to verify API endpoints
verify_api() {
    local url="$1"
    local claimed_response="$2"
    
    echo "📋 VERIFYING API: $url"
    echo "   CLAIMED: $claimed_response"
    
    local response=$(curl -s "$url" 2>/dev/null)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -n "$response" ]; then
        echo "   ✅ VERIFIED: API responds"
        echo "   RESPONSE: $response" | head -5
    else
        echo "   ❌ FAILED: API not responding - CLAUDE LIED"
        return 1
    fi
}

# Function to verify MCP server
verify_mcp_server() {
    local server_path="$1"
    local claimed_tools="$2"
    
    echo "📋 VERIFYING MCP SERVER: $server_path"
    echo "   CLAIMED: $claimed_tools"
    
    if [ ! -f "$server_path" ]; then
        echo "   ❌ FAILED: Server file doesn't exist - CLAUDE LIED"
        return 1
    fi
    
    # Test if it's a proper MCP server
    local test_result=$(echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | timeout 5 node "$server_path" 2>/dev/null)
    
    if [ $? -eq 0 ] && echo "$test_result" | grep -q "tools"; then
        echo "   ✅ VERIFIED: MCP server responds to tools/list"
        echo "   TOOLS: $test_result" | head -3
    else
        echo "   ❌ FAILED: Not a proper MCP server - CLAUDE LIED"
        return 1
    fi
}

# Function to verify file differences
verify_enhancement() {
    local original_file="$1"
    local enhanced_file="$2"
    local claimed_changes="$3"
    
    echo "📋 VERIFYING ENHANCEMENT: $enhanced_file vs $original_file"
    echo "   CLAIMED: $claimed_changes"
    
    if [ ! -f "$original_file" ] || [ ! -f "$enhanced_file" ]; then
        echo "   ❌ FAILED: Files don't exist - CLAUDE LIED"
        return 1
    fi
    
    local diff_result=$(diff "$original_file" "$enhanced_file" | wc -l)
    
    if [ "$diff_result" -gt 0 ]; then
        echo "   ✅ VERIFIED: $diff_result lines changed"
        echo "   SAMPLE DIFF:"
        diff "$original_file" "$enhanced_file" | head -10
    else
        echo "   ❌ FAILED: No changes detected - CLAUDE LIED"
        return 1
    fi
}

# Function to verify memory server functionality
verify_memory_functionality() {
    echo "📋 VERIFYING MEMORY SERVER FUNCTIONALITY"
    
    # Test basic memory operations
    echo "   Testing basic memory operations..."
    
    # This should work (basic memory server)
    echo "   BASIC SERVER TEST:"
    # We can't easily test this without knowing the exact tools, but we can check if it's running
    
    # Test enhanced memory operations (should fail if not implemented)
    echo "   ENHANCED SERVER TEST:"
    verify_api "http://localhost:8890/api/consciousness" "Trinity consciousness data"
}

# MANDATORY VERIFICATION PROTOCOL
echo ""
echo "🚨 RUNNING MANDATORY VERIFICATION PROTOCOL"
echo "==========================================="

# Verify memory servers
verify_process "memory" "Enhanced memory server running"
verify_process "enhanced-memory-server" "Enhanced memory server with Trinity consciousness"

# Verify API endpoints
verify_api "http://localhost:8890/api/consciousness" "Trinity consciousness tracking"
verify_api "http://localhost:8890/api/stats" "Server statistics"

# Verify MCP functionality
if [ -f "/home/bacardi/crodidocker/enhanced-mcp-memory-server/dist/index.js" ]; then
    verify_mcp_server "/home/bacardi/crodidocker/enhanced-mcp-memory-server/dist/index.js" "MCP memory tools"
fi

# Verify enhancements
if [ -f "/home/bacardi/.local/lib/node_modules/@modelcontextprotocol/server-memory/dist/index.js" ] && 
   [ -f "/home/bacardi/crodidocker/enhanced-mcp-memory-server/dist/index.js" ]; then
    verify_enhancement "/home/bacardi/.local/lib/node_modules/@modelcontextprotocol/server-memory/dist/index.js" \
                      "/home/bacardi/crodidocker/enhanced-mcp-memory-server/dist/index.js" \
                      "Trinity consciousness and pattern evolution added"
fi

echo ""
echo "📊 VERIFICATION SUMMARY"
echo "======================"
echo "If any tests failed, CLAUDE LIED about implementation."
echo "Only verified claims should be trusted."
echo ""