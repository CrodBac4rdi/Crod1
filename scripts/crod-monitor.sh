#!/usr/bin/env bash
# CROD Monitoring Script - Real-time system health monitoring

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
ELIXIR_URL="http://localhost:4000/health"
JS_URL="http://localhost:8888/health"
MONITOR_INTERVAL=5

echo "🧠 CROD System Monitor"
echo "====================="

# Function to check service health
check_service() {
    local name=$1
    local url=$2
    
    if curl -f -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name: Online"
        curl -s "$url" | jq '.' 2>/dev/null || echo "  (No detailed status)"
    else
        echo -e "${RED}✗${NC} $name: Offline"
    fi
}

# Function to check Docker containers
check_containers() {
    echo -e "\n📦 Docker Containers:"
    docker-compose -f docker/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
}

# Function to show resource usage
show_resources() {
    echo -e "\n💾 Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(crod|postgres)" || true
}

# Function to tail logs
show_recent_logs() {
    echo -e "\n📋 Recent Logs:"
    docker-compose -f docker/docker-compose.yml logs --tail=5 --no-log-prefix 2>/dev/null | grep -E "(error|Error|ERROR|warning|Warning)" || echo "  No recent errors"
}

# Main monitoring loop
while true; do
    clear
    echo "🧠 CROD System Monitor - $(date)"
    echo "========================================"
    
    echo -e "\n🌐 Service Health:"
    check_service "Elixir/Phoenix" "$ELIXIR_URL"
    check_service "JavaScript Brain" "$JS_URL"
    
    check_containers
    show_resources
    show_recent_logs
    
    echo -e "\n\nPress Ctrl+C to exit. Refreshing in ${MONITOR_INTERVAL}s..."
    sleep $MONITOR_INTERVAL
done