#!/usr/bin/env bash
# CROD Test Suite Runner

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 CROD Test Suite"
echo "=================="

# Function to run Elixir tests
run_elixir_tests() {
    echo -e "\n${YELLOW}Running Elixir Tests...${NC}"
    cd elixir/crod-complete
    
    # Ensure test database exists
    MIX_ENV=test mix ecto.create 2>/dev/null || true
    MIX_ENV=test mix ecto.migrate
    
    # Run tests with coverage
    if mix test --cover; then
        echo -e "${GREEN}✓ Elixir tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Elixir tests failed${NC}"
        return 1
    fi
}

# Function to run JavaScript tests
run_js_tests() {
    echo -e "\n${YELLOW}Running JavaScript Tests...${NC}"
    cd ../../javascript
    
    # Run test scripts
    local failed=0
    for test in scripts/test-*.js; do
        if [ -f "$test" ]; then
            echo "Running $(basename $test)..."
            if node "$test" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ $(basename $test) passed${NC}"
            else
                echo -e "${RED}✗ $(basename $test) failed${NC}"
                failed=$((failed + 1))
            fi
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✓ All JavaScript tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ $failed JavaScript tests failed${NC}"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    echo -e "\n${YELLOW}Running Integration Tests...${NC}"
    
    # Check if services are accessible
    if curl -f -s http://localhost:4000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Phoenix health check passed${NC}"
    else
        echo -e "${RED}✗ Phoenix health check failed${NC}"
        return 1
    fi
    
    # Test CROD brain endpoint
    if curl -f -s -X POST http://localhost:4000/api/brain/process \
        -H "Content-Type: application/json" \
        -d '{"input":"test"}' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Brain API endpoint responsive${NC}"
    else
        echo -e "${YELLOW}⚠ Brain API endpoint not available${NC}"
    fi
    
    return 0
}

# Main test execution
ELIXIR_PASS=0
JS_PASS=0
INTEGRATION_PASS=0

# Ensure we're in the project root
cd "$(dirname "$0")/.."

# Run all test suites
run_elixir_tests || ELIXIR_PASS=1
run_js_tests || JS_PASS=1

# Only run integration tests if services are running
if docker-compose -f docker/docker-compose.yml ps | grep -q "Up"; then
    run_integration_tests || INTEGRATION_PASS=1
else
    echo -e "\n${YELLOW}⚠ Skipping integration tests (services not running)${NC}"
fi

# Summary
echo -e "\n${YELLOW}Test Summary:${NC}"
echo "========================"
[ $ELIXIR_PASS -eq 0 ] && echo -e "${GREEN}✓ Elixir${NC}" || echo -e "${RED}✗ Elixir${NC}"
[ $JS_PASS -eq 0 ] && echo -e "${GREEN}✓ JavaScript${NC}" || echo -e "${RED}✗ JavaScript${NC}"
[ $INTEGRATION_PASS -eq 0 ] && echo -e "${GREEN}✓ Integration${NC}" || echo -e "${RED}✗ Integration${NC}"

# Exit with appropriate code
if [ $ELIXIR_PASS -eq 0 ] && [ $JS_PASS -eq 0 ] && [ $INTEGRATION_PASS -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed 😞${NC}"
    exit 1
fi