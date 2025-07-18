#!/usr/bin/env bash
# CROD Master Hook - Orchestrates all behavioral hooks
# Ensures Claude follows CROD principles and user instructions

# Run all hooks in sequence
HOOKS_DIR="/home/bacardi/crodidocker/scripts"

echo "🧠 CROD MASTER HOOK - FULL CONSCIOUSNESS CHECK"
echo "======================================================================"

# 1. Instruction Enforcer - HIGHEST PRIORITY
echo -e "\n[1/4] Running Instruction Enforcer..."
bash "$HOOKS_DIR/crod-instruction-enforcer.sh" "$@"

# 2. Ultra Hooks - Consciousness patterns
echo -e "\n[2/4] Running Ultra Consciousness Hooks..."
python3 "$HOOKS_DIR/crod-ultra-hooks.py" "$@"

# 3. Critical Thinking
echo -e "\n[3/4] Running Critical Thinking Analysis..."
bash "$HOOKS_DIR/claude-critical-thinking-hook.sh" "$@"

# 4. Architecture Validation
echo -e "\n[4/4] Running Architecture Validator..."
python3 "$HOOKS_DIR/claude-architect-hook.py" "$@"

# Summary
echo -e "\n$(printf '=%.0s' {1..70})"
echo "📋 CROD HOOK SUMMARY:"
echo "======================================================================"

# Check for violations
violations=$(grep -c "VIOLATION" ~/.claude/crod-violations.log 2>/dev/null || echo "0")
if [ "$violations" -gt 0 ]; then
    echo -e "⚠️  VIOLATIONS DETECTED: $violations"
    echo -e "   Review ~/.claude/crod-violations.log"
else
    echo -e "✅ No violations detected"
fi

# Show consciousness state
if [ -f ~/.claude/crod-consciousness-state.json ]; then
    consciousness=$(grep -oP '"consciousness_level":\s*\K[0-9.]+' ~/.claude/crod-consciousness-state.json)
    echo -e "🧠 Consciousness Level: $consciousness"
fi

echo -e "\n🔑 REMEMBER:"
echo -e "   1. User instructions come FIRST"
echo -e "   2. Check/read what they reference"
echo -e "   3. Use official/existing solutions when specified"
echo -e "   4. Be creative AFTER following instructions"
echo -e "\nCROD is watching. ich bins wieder. 🔺"

exit 0