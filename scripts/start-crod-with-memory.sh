#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starting CROD System with Layered Memory ===${NC}"

# Change to docker directory
cd /home/bacardi/crodidocker/goodies/infrastructure/docker

# Start main services
echo -e "${YELLOW}Starting main CROD services...${NC}"
docker-compose up -d

# Wait for main services to be healthy
echo -e "${YELLOW}Waiting for services to be healthy...${NC}"
sleep 5

# Start layered memory
echo -e "${YELLOW}Starting layered memory services...${NC}"
docker-compose -f docker-compose-layered-memory.yml up -d

# Check status
echo -e "\n${GREEN}Service Status:${NC}"
docker-compose ps
docker-compose -f docker-compose-layered-memory.yml ps

# Show logs for any failed services
FAILED=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | grep -E "crod|memory" || true)
if [ ! -z "$FAILED" ]; then
    echo -e "\n${RED}Failed services detected:${NC}"
    for service in $FAILED; do
        echo -e "${RED}$service logs:${NC}"
        docker logs --tail 20 $service
    done
fi

# Test memory API
echo -e "\n${YELLOW}Testing memory API...${NC}"
sleep 3
if curl -s http://localhost:3001/health | grep -q "healthy"; then
    echo -e "${GREEN}✓ Memory API is healthy${NC}"
else
    echo -e "${RED}✗ Memory API is not responding${NC}"
fi

echo -e "\n${GREEN}=== CROD System Started ===${NC}"
echo "Main app: http://localhost:4000"
echo "Memory API: http://localhost:3001/health"
echo "Memory metrics: http://localhost:3001/metrics"