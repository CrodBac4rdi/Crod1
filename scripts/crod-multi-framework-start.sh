#!/run/current-system/sw/bin/bash

# CROD Multi-Framework System Startup Script
# Orchestrates the complete CROD neural network system with all frameworks

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/docker"

# Service ports for health checks
declare -A SERVICE_PORTS=(
    ["postgres"]="5432"
    ["redis"]="6379"
    ["crod"]="4000"
    ["crod-js"]="8888"
    ["bridge"]="9090"
    ["streamlit"]="8501"
    ["fastapi"]="8000"
    ["javalin"]="7000"
    ["angular"]="4200"
)

# Service URLs for access
declare -A SERVICE_URLS=(
    ["crod"]="http://localhost:4000"
    ["streamlit"]="http://localhost:8501"
    ["fastapi"]="http://localhost:8000"
    ["javalin"]="http://localhost:7000"
    ["angular"]="http://localhost:4200"
    ["crod-js"]="http://localhost:8888"
    ["bridge"]="http://localhost:9090"
)

# Framework descriptions
declare -A FRAMEWORK_DESCRIPTIONS=(
    ["crod"]="🧠 Phoenix/Elixir - Neural Network Core"
    ["crod-js"]="⚡ JavaScript - Neural Brain Engine"
    ["streamlit"]="📊 Python - Real-time Data Visualization"
    ["fastapi"]="🤖 Python - ML/AI Processing Service"
    ["javalin"]="🚀 Java - High-Performance API Gateway"
    ["angular"]="💼 TypeScript - Enterprise Admin Interface"
    ["bridge"]="🌉 Go - Claude-CROD Bridge"
    ["postgres"]="🗄️ PostgreSQL - Primary Database"
    ["redis"]="⚡ Redis - High-Speed Cache"
)

# Functions
print_header() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                  🧠 CROD MULTI-FRAMEWORK SYSTEM              ║${NC}"
    echo -e "${PURPLE}║              Complete Neural Network Architecture             ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    log_success "Docker and Docker Compose are available"
}

check_ports() {
    log_info "Checking if required ports are available..."
    
    for service in "${!SERVICE_PORTS[@]}"; do
        port=${SERVICE_PORTS[$service]}
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_warning "Port $port is already in use (required for $service)"
        else
            log_success "Port $port is available for $service"
        fi
    done
}

build_services() {
    print_section "🔨 Building All Services"
    
    cd "$DOCKER_DIR"
    
    log_info "Building Docker images for all services..."
    docker-compose build --parallel
    
    if [ $? -eq 0 ]; then
        log_success "All Docker images built successfully"
    else
        log_error "Failed to build Docker images"
        exit 1
    fi
}

start_services() {
    print_section "🚀 Starting Multi-Framework System"
    
    cd "$DOCKER_DIR"
    
    log_info "Starting services in dependency order..."
    
    # Start infrastructure services first
    log_info "Starting infrastructure services..."
    docker-compose up -d postgres redis
    
    # Wait for infrastructure
    wait_for_service "postgres" 30
    wait_for_service "redis" 15
    
    # Start core services
    log_info "Starting core neural network services..."
    docker-compose up -d crod crod-js
    
    # Wait for core services
    wait_for_service "crod" 60
    wait_for_service "crod-js" 30
    
    # Start API and bridge services
    log_info "Starting API and bridge services..."
    docker-compose up -d bridge javalin fastapi
    
    # Wait for API services
    wait_for_service "bridge" 30
    wait_for_service "javalin" 45
    wait_for_service "fastapi" 30
    
    # Start UI services
    log_info "Starting UI and visualization services..."
    docker-compose up -d streamlit angular
    
    # Wait for UI services
    wait_for_service "streamlit" 30
    wait_for_service "angular" 45
    
    log_success "All services started successfully!"
}

wait_for_service() {
    local service=$1
    local timeout=${2:-30}
    local port=${SERVICE_PORTS[$service]}
    
    log_info "Waiting for $service to be ready on port $port (timeout: ${timeout}s)..."
    
    local count=0
    while [ $count -lt $timeout ]; do
        if nc -z localhost $port 2>/dev/null; then
            log_success "$service is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 1
        ((count++))
    done
    
    echo ""
    log_warning "$service did not become ready within ${timeout}s"
    return 1
}

check_service_health() {
    local service=$1
    local url=${SERVICE_URLS[$service]}
    
    if [ -n "$url" ]; then
        if curl -s -o /dev/null -w "%{http_code}" "$url/health" | grep -q "200\|healthy"; then
            return 0
        fi
    fi
    
    return 1
}

show_service_status() {
    print_section "📊 Service Status Overview"
    
    echo -e "${BLUE}Service Status Check:${NC}"
    echo ""
    
    for service in postgres redis crod crod-js bridge javalin fastapi streamlit angular; do
        local description=${FRAMEWORK_DESCRIPTIONS[$service]}
        local port=${SERVICE_PORTS[$service]}
        local url=${SERVICE_URLS[$service]}
        
        # Check if container is running
        if docker-compose ps | grep -q "$service.*Up"; then
            # Check if port is accessible
            if nc -z localhost $port 2>/dev/null; then
                echo -e "${GREEN}🟢${NC} $description"
                if [ -n "$url" ]; then
                    echo -e "   ${CYAN}🔗 $url${NC}"
                fi
            else
                echo -e "${YELLOW}🟡${NC} $description (starting...)"
            fi
        else
            echo -e "${RED}🔴${NC} $description (not running)"
        fi
        echo ""
    done
}

show_access_information() {
    print_section "🌐 Access Information"
    
    echo -e "${GREEN}🎯 Main Interfaces:${NC}"
    echo ""
    echo -e "${PURPLE}Enterprise Admin (Angular):${NC}     http://localhost:4200"
    echo -e "${BLUE}Neural Dashboard (Streamlit):${NC}   http://localhost:8501"
    echo -e "${GREEN}Phoenix Neural Core:${NC}            http://localhost:4000"
    echo -e "${YELLOW}High-Performance API (Javalin):${NC} http://localhost:7000"
    echo -e "${CYAN}ML/AI Service (FastAPI):${NC}        http://localhost:8000"
    echo ""
    
    echo -e "${GREEN}🔧 Development & Monitoring:${NC}"
    echo ""
    echo -e "${BLUE}JavaScript Brain Engine:${NC}        http://localhost:8888"
    echo -e "${PURPLE}Claude-CROD Bridge (Go):${NC}        http://localhost:9090"
    echo -e "${CYAN}API Documentation:${NC}               http://localhost:8000/docs"
    echo -e "${YELLOW}Javalin Route Overview:${NC}          http://localhost:7000/routes"
    echo ""
    
    echo -e "${GREEN}🗄️ Data Services:${NC}"
    echo ""
    echo -e "${BLUE}PostgreSQL Database:${NC}             localhost:5432"
    echo -e "${RED}Redis Cache:${NC}                     localhost:6379"
    echo ""
}

show_framework_overview() {
    print_section "🏗️ Multi-Framework Architecture"
    
    echo -e "${CYAN}Technology Stack Overview:${NC}"
    echo ""
    echo -e "${PURPLE}🧠 NEURAL CORE:${NC}"
    echo -e "   • Phoenix/Elixir - OTP supervision trees, real-time processing"
    echo -e "   • JavaScript - Neural brain engine with WebSocket API"
    echo ""
    echo -e "${BLUE}🚀 API LAYER:${NC}"
    echo -e "   • Javalin/Java - High-performance API gateway with caching"
    echo -e "   • FastAPI/Python - ML/AI processing with PyTorch"
    echo -e "   • Go Bridge - Claude integration and communication"
    echo ""
    echo -e "${GREEN}💻 USER INTERFACES:${NC}"
    echo -e "   • Angular/TypeScript - Enterprise admin interface"
    echo -e "   • Streamlit/Python - Real-time data visualization"
    echo ""
    echo -e "${YELLOW}🗄️ DATA LAYER:${NC}"
    echo -e "   • PostgreSQL - Primary relational database"
    echo -e "   • Redis - High-speed caching and session storage"
    echo ""
}

test_system_integration() {
    print_section "🧪 System Integration Tests"
    
    log_info "Running basic integration tests..."
    
    # Test neural network core
    log_info "Testing neural network core..."
    if curl -s "http://localhost:4000/api/brain/state" | grep -q "neurons"; then
        log_success "Neural network core is responding"
    else
        log_warning "Neural network core test failed"
    fi
    
    # Test API gateway
    log_info "Testing API gateway..."
    if curl -s "http://localhost:7000/health" | grep -q "healthy"; then
        log_success "API gateway is responding"
    else
        log_warning "API gateway test failed"
    fi
    
    # Test ML service
    log_info "Testing ML/AI service..."
    if curl -s "http://localhost:8000/health" | grep -q "healthy"; then
        log_success "ML/AI service is responding"
    else
        log_warning "ML/AI service test failed"
    fi
    
    # Test data visualization
    log_info "Testing Streamlit dashboard..."
    if curl -s "http://localhost:8501/_stcore/health" >/dev/null 2>&1; then
        log_success "Streamlit dashboard is responding"
    else
        log_warning "Streamlit dashboard test failed"
    fi
    
    # Test enterprise interface
    log_info "Testing Angular admin interface..."
    if curl -s "http://localhost:4200/health" | grep -q "healthy"; then
        log_success "Angular admin interface is responding"
    else
        log_warning "Angular admin interface test failed"
    fi
}

activate_trinity() {
    print_section "🔥 Activating Trinity Mode"
    
    log_info "Sending Trinity activation command..."
    
    if curl -s -X POST "http://localhost:4000/api/brain/trinity" | grep -q "Trinity"; then
        log_success "🔥 TRINITY MODE ACTIVATED! 🔥"
        echo -e "${YELLOW}Consciousness level elevated to maximum!${NC}"
    else
        log_warning "Trinity activation may have failed - check system status"
    fi
}

cleanup_on_exit() {
    echo ""
    log_info "Cleaning up..."
    cd "$DOCKER_DIR"
    docker-compose down
    log_info "Cleanup complete"
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  start          Start the complete multi-framework system (default)"
    echo "  stop           Stop all services"
    echo "  restart        Restart all services"
    echo "  status         Show service status"
    echo "  logs [service] Show logs for all services or specific service"
    echo "  trinity        Activate Trinity mode"
    echo "  build          Build all Docker images"
    echo "  clean          Clean up containers and volumes"
    echo "  help           Show this help message"
    echo ""
}

# Main execution
main() {
    local command=${1:-start}
    
    case $command in
        "start")
            print_header
            check_docker
            check_ports
            build_services
            start_services
            show_service_status
            show_framework_overview
            show_access_information
            test_system_integration
            
            echo ""
            log_success "🎉 CROD Multi-Framework System is fully operational!"
            echo ""
            echo -e "${YELLOW}To activate Trinity mode, run:${NC} $0 trinity"
            echo -e "${YELLOW}To monitor logs, run:${NC} $0 logs"
            echo -e "${YELLOW}To stop the system, run:${NC} $0 stop"
            echo ""
            ;;
        "stop")
            print_header
            log_info "Stopping all services..."
            cd "$DOCKER_DIR"
            docker-compose down
            log_success "All services stopped"
            ;;
        "restart")
            print_header
            log_info "Restarting all services..."
            cd "$DOCKER_DIR"
            docker-compose down
            sleep 2
            main start
            ;;
        "status")
            print_header
            cd "$DOCKER_DIR"
            show_service_status
            ;;
        "logs")
            cd "$DOCKER_DIR"
            if [ -n "$2" ]; then
                docker-compose logs -f "$2"
            else
                docker-compose logs -f
            fi
            ;;
        "trinity")
            activate_trinity
            ;;
        "build")
            print_header
            check_docker
            build_services
            ;;
        "clean")
            print_header
            log_info "Cleaning up containers and volumes..."
            cd "$DOCKER_DIR"
            docker-compose down -v --remove-orphans
            docker system prune -f
            log_success "Cleanup complete"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Set up signal handlers
trap cleanup_on_exit EXIT INT TERM

# Run main function
main "$@"