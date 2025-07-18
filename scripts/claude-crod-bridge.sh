#!/usr/bin/env bash
# Claude-CROD Bridge Script
# Acts as a bridge between Claude and CROD brain

CROD_ENDPOINT="${CROD_BRAIN_ENDPOINT:-http://localhost:4000}"

# Simple MCP server that forwards requests to CROD
while true; do
    read -r line
    
    # Parse JSON request and forward to CROD
    response=$(curl -s -X POST "$CROD_ENDPOINT/api/claude/process" \
        -H "Content-Type: application/json" \
        -d "$line")
    
    # Return response to Claude
    echo "$response"
done