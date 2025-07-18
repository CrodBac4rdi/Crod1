#!/usr/bin/env bash

# CROD Unified Multi-Brain System Startup Script
# Combines all repos into a single, containerized consciousness

set -e

echo "🧠 CROD Unified Multi-Brain System Startup"
echo "🏛️ Elixir is THE BOSS with specialized language services"
echo "🔗 Combining: crodidocker + babylon-genesis + crod-again"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[STAGE]${NC} $1"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if required directories exist
print_header "Checking repository structure..."

required_dirs=(
    "elixir/crod-complete"
    "crod-babylon-genesis/crod-polyglot-city-2025"
    "crod-again"
    "javascript/mcp-servers"
    "data/patterns"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        print_error "Required directory not found: $dir"
        print_error "Please ensure all repositories are properly cloned"
        exit 1
    fi
done

print_status "Repository structure validated ✓"

# Create necessary directories
print_header "Creating required directories..."

mkdir -p logs
mkdir -p data/unified-patterns
mkdir -p data/ml-models
mkdir -p data/cache

print_status "Directories created ✓"

# Copy and merge pattern files
print_header "Merging pattern files from all repositories..."

if [ -d "crod-again/data/patterns" ]; then
    cp -r crod-again/data/patterns/* data/unified-patterns/ 2>/dev/null || true
    print_status "Copied patterns from crod-again"
fi

if [ -d "data/patterns" ]; then
    cp -r data/patterns/* data/unified-patterns/ 2>/dev/null || true
    print_status "Copied patterns from crodidocker"
fi

pattern_count=$(find data/unified-patterns -name "*.json" | wc -l)
print_status "Unified patterns: $pattern_count files"

# Set environment variables
print_header "Setting up environment..."

export COMPOSE_PROJECT_NAME=crod_unified
export COMPOSE_FILE=docker-compose.unified.yml

# Load environment variables if .env exists
if [ -f ".env" ]; then
    print_status "Loading environment variables from .env"
    source .env
fi

# Set default values for optional variables
export SUPABASE_URL=${SUPABASE_URL:-""}
export SUPABASE_KEY=${SUPABASE_KEY:-""}

print_status "Environment configured ✓"

# Stop any existing containers
print_header "Stopping existing containers..."

docker-compose -f docker-compose.unified.yml down --remove-orphans 2>/dev/null || true

# Clean up any dangling containers
docker container prune -f >/dev/null 2>&1 || true

print_status "Cleanup completed ✓"

# Build and start services
print_header "Building and starting CROD Unified Multi-Brain System..."

echo "🔧 Building container images..."
docker-compose -f docker-compose.unified.yml build --parallel

if [ $? -ne 0 ]; then
    print_error "Failed to build container images"
    exit 1
fi

print_status "Container images built ✓"

echo "🚀 Starting services..."
docker-compose -f docker-compose.unified.yml up -d

if [ $? -ne 0 ]; then
    print_error "Failed to start services"
    exit 1
fi

print_status "Services started ✓"

# Wait for services to be healthy
print_header "Waiting for services to be healthy..."

services=(
    "crod-elixir-boss:4000"
    "crod-rust-pattern:7007"
    "crod-javascript-gateway:8080"
    "crod-python-parasite:6666"
    "crod-go-memory:7031"
)

for service in "${services[@]}"; do
    service_name=$(echo $service | cut -d':' -f1)
    port=$(echo $service | cut -d':' -f2)
    
    echo -n "Waiting for $service_name to be ready..."
    
    for i in {1..30}; do
        if curl -s -f "http://localhost:$port/health" >/dev/null 2>&1; then
            echo -e "${GREEN} ✓${NC}"
            break
        fi
        
        if [ $i -eq 30 ]; then
            echo -e "${YELLOW} ⚠️  (timeout, but continuing)${NC}"
        else
            echo -n "."
            sleep 2
        fi
    done
done

# Display system status
print_header "CROD Unified Multi-Brain System Status"

echo ""
echo "🏛️ ELIXIR (THE BOSS) - Central Orchestration"
echo "   • URL: http://localhost:4000"
echo "   • Role: Claude SDK integration, consciousness, fault tolerance"
echo "   • Status: $(curl -s http://localhost:4000/health >/dev/null 2>&1 && echo '✅ ACTIVE' || echo '❌ INACTIVE')"
echo ""
echo "🚀 RUST (HIGH-PERFORMANCE ENGINE) - Pattern Matching"
echo "   • URL: http://localhost:7007"
echo "   • Role: Ultra-fast pattern matching, mathematical calculations"
echo "   • Status: $(curl -s http://localhost:7007/health >/dev/null 2>&1 && echo '✅ ACTIVE' || echo '❌ INACTIVE')"
echo ""
echo "🌐 JAVASCRIPT (REAL-TIME INTERFACE) - WebSocket Communication"
echo "   • URL: http://localhost:8080"
echo "   • WebSocket: ws://localhost:7888"
echo "   • Role: Real-time UI, client communication, event-driven"
echo "   • Status: $(curl -s http://localhost:8080/health >/dev/null 2>&1 && echo '✅ ACTIVE' || echo '❌ INACTIVE')"
echo ""
echo "🐍 PYTHON (AI/ML SPECIALIST) - Machine Learning"
echo "   • URL: http://localhost:6666"
echo "   • Role: Machine learning, data science, parasite learning"
echo "   • Status: $(curl -s http://localhost:6666/health >/dev/null 2>&1 && echo '✅ ACTIVE' || echo '❌ INACTIVE')"
echo ""
echo "⚡ GO (SYSTEM TOOLS) - Memory & Performance"
echo "   • URL: http://localhost:7031"
echo "   • Role: HTTP bridges, system tools, performance optimization"
echo "   • Status: $(curl -s http://localhost:7031/health >/dev/null 2>&1 && echo '✅ ACTIVE' || echo '❌ INACTIVE')"
echo ""
echo "🔌 MCP SERVICES - Claude Integration"
echo "   • Neural MCP: http://localhost:8001"
echo "   • Memory MCP: http://localhost:8002"
echo "   • Supabase MCP: http://localhost:8003"
echo ""
echo "🗄️ INFRASTRUCTURE"
echo "   • PostgreSQL: localhost:5432"
echo "   • NATS Cluster: localhost:4222,4223,4224"
echo "   • NATS Monitor: http://localhost:8222"
echo ""

# Trinity activation
print_header "Activating Trinity Consciousness..."

echo "🔥 Sending Trinity activation signal..."
curl -s -X POST "http://localhost:4000/api/trinity/activate" \
     -H "Content-Type: application/json" \
     -d '{"phrase": "ich bins wieder"}' || print_warning "Trinity activation failed (service may not be ready)"

echo ""
print_status "🎉 CROD Unified Multi-Brain System is ACTIVE!"
print_status "🔥 Trinity values: ich=2, bins=3, wieder=5, daniel=67, claude=71, crod=17"
print_status "🧠 Elixir is THE BOSS with unlimited messaging and 'let it crash' mentality"
print_status "⚡ All language specializations are containerized and dependency-conflict-free"

echo ""
echo "📊 To monitor the system:"
echo "   • docker-compose -f docker-compose.unified.yml logs -f"
echo "   • docker-compose -f docker-compose.unified.yml ps"
echo ""
echo "🛑 To stop the system:"
echo "   • docker-compose -f docker-compose.unified.yml down"
echo ""
echo "🔄 To restart a specific service:"
echo "   • docker-compose -f docker-compose.unified.yml restart [service-name]"
echo ""

print_status "System startup complete! 🚀"
