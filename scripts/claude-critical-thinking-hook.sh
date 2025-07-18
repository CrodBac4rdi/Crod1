#!/usr/bin/env bash
# Critical thinking + instruction compliance hook
# Balances following orders with architectural questioning

# Function to ask architectural questions
ask_architecture_questions() {
    echo "🤔 CRITICAL QUESTIONS before proceeding:"
    echo ""
    echo "1️⃣  LANGUAGE CHOICE: Is this the right language for this component?"
    echo "   - Elixir/Phoenix: Real-time, fault-tolerant, distributed systems"
    echo "   - Rust: Memory-critical, performance-critical components"  
    echo "   - Go: Simple microservices, CLI tools, high concurrency"
    echo "   - Python: ML/AI, data processing, scientific computing"
    echo "   - TypeScript: Type-safe frontends and Node services"
    echo ""
    echo "2️⃣  IMPLEMENTATION ORDER: What should we build first?"
    echo "   - Core infrastructure (databases, message queues)?"
    echo "   - User-facing features?"
    echo "   - Developer tools and testing?"
    echo "   - Integration layers?"
    echo ""
    echo "3️⃣  ARCHITECTURE VALIDATION: Does this design make sense?"
    echo "   - Single service or microservices?"
    echo "   - Synchronous or async communication?"
    echo "   - How does it handle failure?"
    echo "   - What's the data consistency model?"
    echo ""
    echo "4️⃣  FUTURE PROOFING: Will this scale?"
    echo "   - Can we add new languages/frameworks easily?"
    echo "   - How hard is it to refactor later?"
    echo "   - What technical debt are we creating?"
    echo ""
}

# Function to validate user instructions
check_user_instructions() {
    if [[ "$CLAUDE_USER_MESSAGE" == *"check"* ]] || [[ "$CLAUDE_USER_MESSAGE" == *"read"* ]]; then
        echo "⚠️  USER ASKED TO CHECK/READ SOMETHING - DO THIS FIRST!"
        echo "[$(date)] Instruction to check/read detected" >> ~/.claude/critical-thinking.log
    fi
    
    if [[ "$CLAUDE_USER_MESSAGE" == *"use"* ]] && [[ "$CLAUDE_USER_MESSAGE" == *"official"* ]]; then
        echo "⚠️  USER WANTS OFFICIAL/EXISTING SOLUTION - Don't build custom!"
        echo "[$(date)] Use official solution instruction" >> ~/.claude/critical-thinking.log
    fi
}

# Main execution
echo "="*70
echo "🧠 CRITICAL THINKING MODE ACTIVE"
echo "="*70

# First, check user instructions
check_user_instructions

# Then, ask architectural questions
ask_architecture_questions

# Log the action for pattern analysis
echo "[$(date)] Action: $@" >> ~/.claude/critical-thinking.log
echo "[$(date)] Context: $CLAUDE_USER_MESSAGE" >> ~/.claude/critical-thinking.log

# Suggest questioning back
echo ""
echo "💬 CONSIDER ASKING THE USER:"
echo "   - 'Should we use Rust for the performance-critical parts?'"
echo "   - 'Would it make sense to implement this as a separate Go service?'"
echo "   - 'Should we prioritize the core API or the UI first?'"
echo "   - 'Is this the right abstraction level for future extensions?'"
echo ""

# Never block - this is about thinking, not stopping
exit 0