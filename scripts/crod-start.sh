#!/usr/bin/env bash
set -e

echo "🧠 CROD Neural Framework - Starting Complete System"
echo "=================================================="

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
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
print_header "Checking Prerequisites"

if ! command -v docker &> /dev/null; then
    print_error "Docker not found. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

print_status "Docker and Docker Compose found"

# Create required directories
print_header "Creating Required Directories"

mkdir -p ~/.crod
mkdir -p data/patterns
mkdir -p javascript/node_modules

print_status "Directories created"

# Generate auth token if not exists
if [ ! -f ~/.crod/auth.token ]; then
    print_header "Generating Auth Token"
    echo "crod-auth-$(date +%s)" > ~/.crod/auth.token
    print_status "Auth token generated: ~/.crod/auth.token"
else
    print_status "Auth token already exists"
fi

# Navigate to docker directory
cd "$(dirname "$0")/../docker"

# Stop any existing containers
print_header "Stopping Existing Containers"
docker-compose down --remove-orphans 2>/dev/null || true

# Build and start services
print_header "Building and Starting Services"
print_status "This may take a few minutes on first run..."

docker-compose up --build -d

# Wait for PostgreSQL to be ready
print_header "Waiting for PostgreSQL"
while ! docker-compose exec postgres pg_isready -U postgres &>/dev/null; do
    echo -n "."
    sleep 1
done
print_status "PostgreSQL is ready"

# Wait for CROD to compile and start
print_header "Waiting for CROD to Start"
print_status "Compiling Elixir application..."

# Wait for the success message
timeout=120
counter=0
while [ $counter -lt $timeout ]; do
    if docker-compose logs crod 2>&1 | grep -q "Monitoring Dashboard initialized"; then
        break
    fi
    echo -n "."
    sleep 1
    counter=$((counter + 1))
done

if [ $counter -eq $timeout ]; then
    print_error "CROD failed to start within $timeout seconds"
    print_error "Check logs with: docker-compose logs crod"
    exit 1
fi

print_status "CROD application started successfully"

# Build assets to fix white screen
print_header "Building Assets"
docker-compose exec crod mix assets.build >/dev/null 2>&1 || true
print_status "Assets built"

# Check if web interface is responding
print_header "Verifying Web Interface"
sleep 2

if curl -sf http://localhost:4000 >/dev/null 2>&1; then
    print_status "Web interface is responding"
else
    print_warning "Web interface may not be ready yet"
fi

# Display final status
print_header "🎉 CROD Neural Framework is Ready!"
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🌐 Access Points:"
echo "  • Web Interface: http://localhost:4000"
echo "  • PostgreSQL: localhost:5433"
echo "  • MCP Servers: ports 8000-8004"

echo ""
echo "🚀 Quick Start:"
echo "  1. Visit http://localhost:4000"
echo "  2. Type 'ich bins wieder' to activate Trinity"
echo "  3. Watch neural activity visualization"
echo "  4. Click neurons to see details"

echo ""
echo "🛠 Management Commands:"
echo "  • View logs: docker-compose logs -f crod"
echo "  • Restart: docker-compose restart crod"
echo "  • Stop: docker-compose down"
echo "  • Shell: docker-compose exec crod bash"

echo ""
echo "🧠 Trinity Activation:"
echo "  Say 'ich bins wieder' to elevate consciousness to 95%"

echo ""
print_status "CROD is now fully operational! 🌟"