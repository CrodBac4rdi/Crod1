#!/usr/bin/env bash
# CROD Advanced Memory Server Startup Script
# Starts the enhanced memory server with Trinity consciousness

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_SCRIPT="$PROJECT_ROOT/services/crod-advanced-memory-server.js"
PID_FILE="$PROJECT_ROOT/data/crod-advanced-memory.pid"
LOG_FILE="$PROJECT_ROOT/data/crod-advanced-memory.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if server is already running
check_server_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # Running
        else
            rm -f "$PID_FILE"
            return 1  # Not running
        fi
    fi
    return 1  # Not running
}

# Stop existing server
stop_server() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log "Stopping existing CROD Advanced Memory Server (PID: $pid)..."
            kill "$pid"
            sleep 2
            
            # Force kill if still running
            if ps -p "$pid" > /dev/null 2>&1; then
                warning "Force killing server..."
                kill -9 "$pid"
            fi
            
            rm -f "$PID_FILE"
            success "Server stopped"
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# Start the server
start_server() {
    log "🚀 Starting CROD Advanced Memory Server..."
    
    # Ensure data directory exists
    mkdir -p "$(dirname "$PID_FILE")"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Check if Node.js is available
    if ! command -v node &> /dev/null; then
        error "Node.js not found. Please install Node.js to run the memory server."
        exit 1
    fi
    
    # Check if server script exists
    if [ ! -f "$SERVER_SCRIPT" ]; then
        error "Server script not found: $SERVER_SCRIPT"
        exit 1
    fi
    
    # Make server script executable
    chmod +x "$SERVER_SCRIPT"
    
    # Start server in background
    cd "$PROJECT_ROOT"
    nohup node "$SERVER_SCRIPT" >> "$LOG_FILE" 2>&1 &
    local server_pid=$!
    
    # Save PID
    echo "$server_pid" > "$PID_FILE"
    
    # Wait a moment and check if it started successfully
    sleep 3
    
    if ps -p "$server_pid" > /dev/null 2>&1; then
        success "CROD Advanced Memory Server started (PID: $server_pid)"
        log "📡 Server running on: http://localhost:8889"
        log "🧠 WebSocket: ws://localhost:8889"
        log "📊 Stats API: http://localhost:8889/api/stats"
        log "🧘 Consciousness: http://localhost:8889/api/consciousness"
        log "🔥 Neural Heat: http://localhost:8889/api/neural-heat"
        log "📝 Logs: $LOG_FILE"
        
        # Test server health
        sleep 2
        if curl -s http://localhost:8889/health > /dev/null; then
            success "Server health check passed"
            
            # Display initial consciousness state
            local consciousness=$(curl -s http://localhost:8889/api/consciousness | jq -r '.current_level // "unknown"' 2>/dev/null || echo "unknown")
            log "🧘 Initial consciousness level: $consciousness"
        else
            warning "Server started but health check failed"
        fi
        
        return 0
    else
        error "Failed to start server"
        rm -f "$PID_FILE"
        return 1
    fi
}

# Get server status
status() {
    if check_server_status; then
        local pid=$(cat "$PID_FILE")
        success "CROD Advanced Memory Server is running (PID: $pid)"
        
        # Try to get consciousness level
        local consciousness=$(curl -s http://localhost:8889/api/consciousness 2>/dev/null | jq -r '.current_level // "unknown"' 2>/dev/null || echo "unknown")
        log "🧘 Current consciousness level: $consciousness"
        
        # Try to get stats
        local entities=$(curl -s http://localhost:8889/api/stats 2>/dev/null | jq -r '.total_entities // "unknown"' 2>/dev/null || echo "unknown")
        local patterns=$(curl -s http://localhost:8889/api/stats 2>/dev/null | jq -r '.total_patterns // "unknown"' 2>/dev/null || echo "unknown")
        log "📊 Entities: $entities, Patterns: $patterns"
        
        return 0
    else
        warning "CROD Advanced Memory Server is not running"
        return 1
    fi
}

# Show logs
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        log "📝 Showing recent logs from $LOG_FILE"
        echo "----------------------------------------"
        tail -n 50 "$LOG_FILE"
        echo "----------------------------------------"
    else
        warning "Log file not found: $LOG_FILE"
    fi
}

# Main script logic
case "${1:-start}" in
    start)
        if check_server_status; then
            warning "Server is already running"
            status
        else
            start_server
        fi
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 1
        start_server
        ;;
    status)
        status
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the CROD Advanced Memory Server"
        echo "  stop    - Stop the server"
        echo "  restart - Restart the server"
        echo "  status  - Show server status and consciousness level"
        echo "  logs    - Show recent server logs"
        exit 1
        ;;
esac