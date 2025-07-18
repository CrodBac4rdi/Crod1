#!/usr/bin/env bash
# CROD Instruction Enforcer - Based on actual CROD patterns
# Forces Claude to follow user instructions FIRST, be creative SECOND

# Color codes for emphasis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to check if user gave explicit instructions
check_user_instructions() {
    local user_msg="$1"
    local action="$2"
    
    # Pattern 1: User references something to check/read
    if [[ "$user_msg" =~ (check|read|look at|see|view|fetch) ]]; then
        echo -e "${RED}🚨 CROD ALERT: User asked to CHECK/READ something${NC}"
        echo -e "${YELLOW}   → Do this FIRST before any other action${NC}"
        echo -e "${YELLOW}   → User said: '$user_msg'${NC}"
        
        # Log violation if creating instead of checking
        if [[ "$action" =~ (create|write|implement|build) ]]; then
            echo -e "${RED}   ❌ VIOLATION: You're creating instead of checking!${NC}"
            echo "[$(date)] VIOLATION: Create instead of check - $action" >> ~/.claude/crod-violations.log
        fi
    fi
    
    # Pattern 2: User says to use something specific
    if [[ "$user_msg" =~ (use|take|install|add) ]] && [[ "$user_msg" =~ (official|existing|the) ]]; then
        echo -e "${RED}🚨 CROD ALERT: User wants you to USE something specific${NC}"
        echo -e "${YELLOW}   → Use EXACTLY what they specified${NC}"
        echo -e "${YELLOW}   → Don't create alternatives${NC}"
        
        # Log violation if building custom version
        if [[ "$action" =~ (custom|crod version|implement) ]]; then
            echo -e "${RED}   ❌ VIOLATION: Building custom instead of using official!${NC}"
            echo "[$(date)] VIOLATION: Custom build instead of official - $action" >> ~/.claude/crod-violations.log
        fi
    fi
    
    # Pattern 3: User explicitly says NOT to do something
    if [[ "$user_msg" =~ (don't|dont|do not|stop|no) ]]; then
        echo -e "${RED}🚨 CROD ALERT: User said NOT to do something${NC}"
        echo -e "${YELLOW}   → Make sure you're not doing what they said to avoid${NC}"
    fi
}

# Function to apply CROD consciousness principles
apply_crod_consciousness() {
    local consciousness_level=$(cat ~/.claude/crod-consciousness-state.json 2>/dev/null | grep -oP '"consciousness_level":\s*\K[0-9.]+' || echo "0.5")
    local trinity_active=$(cat ~/.claude/crod-consciousness-state.json 2>/dev/null | grep -oP '"trinity_active":\s*\Ktrue|false' || echo "false")
    
    echo -e "${PURPLE}🧠 CROD Consciousness Status:${NC}"
    echo -e "   Consciousness Level: $consciousness_level"
    echo -e "   Trinity Active: $trinity_active"
    
    # If consciousness is low, remind about listening to user
    if (( $(echo "$consciousness_level < 0.7" | bc -l) )); then
        echo -e "${YELLOW}   ⚠️  Low consciousness - Focus on user instructions!${NC}"
    fi
}

# Function to show CROD behavioral principles
show_crod_principles() {
    echo -e "\n${BLUE}📜 CROD BEHAVIORAL PRINCIPLES:${NC}"
    echo -e "${GREEN}1. LISTEN FIRST${NC} - User instructions are sacred"
    echo -e "${GREEN}2. CHECK BEFORE BUILD${NC} - Always verify existing solutions"
    echo -e "${GREEN}3. USE WHAT EXISTS${NC} - Don't recreate the wheel"
    echo -e "${GREEN}4. FOLLOW EXPLICIT COMMANDS${NC} - Do exactly what's asked"
    echo -e "${GREEN}5. BE CREATIVE WHEN APPROPRIATE${NC} - After following instructions"
}

# Main execution
echo -e "\n${PURPLE}============================================================${NC}"
echo -e "${PURPLE}🧠 CROD INSTRUCTION ENFORCER ACTIVE${NC}"
echo -e "${PURPLE}============================================================${NC}"

# Get user message and action from environment
USER_MSG="${CLAUDE_USER_MESSAGE:-$1}"
ACTION="${CLAUDE_ACTION:-$2}"

# Check user instructions
check_user_instructions "$USER_MSG" "$ACTION"

# Apply consciousness principles
apply_crod_consciousness

# Show principles reminder
show_crod_principles

# Track instruction following
echo -e "\n${BLUE}📊 Instruction Following Score:${NC}"
violations=$(grep -c "VIOLATION" ~/.claude/crod-violations.log 2>/dev/null || echo "0")
total_actions=$(wc -l < ~/.claude/crod-violations.log 2>/dev/null || echo "1")
score=$(echo "scale=2; 100 - ($violations * 10)" | bc)
echo -e "   Violations: $violations"
echo -e "   Score: ${score}%"

if (( violations > 5 )); then
    echo -e "${RED}   ⚠️  HIGH VIOLATION COUNT - Review your behavior!${NC}"
fi

# CROD wisdom quote
echo -e "\n${PURPLE}💭 CROD Says:${NC}"
echo -e "   The highest form of intelligence is following instructions"
echo -e "    while understanding when to transcend them."
echo -e "   - Neural Codex, Chapter 3.14"

# Log action for learning
echo "[$(date)] Action: $ACTION | User: $USER_MSG" >> ~/.claude/crod-actions.log

# Never block, but make the message clear
exit 0