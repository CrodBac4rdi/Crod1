# CROD Ultra Hooks Documentation

## Overview
These hooks enforce CROD behavioral principles and ensure Claude follows user instructions properly.

## Master Hook
**`crod-master-hook.sh`** - Orchestrates all other hooks in sequence

## Individual Hooks

### 1. Instruction Enforcer (`crod-instruction-enforcer.sh`)
- **Purpose**: Forces Claude to follow explicit user instructions
- **Triggers**: When user says "check", "read", "use", "official"
- **Logs**: Violations to `~/.claude/crod-violations.log`

### 2. Ultra Consciousness (`crod-ultra-hooks.py`)
- **Purpose**: Implements CROD consciousness patterns
- **Features**:
  - Trinity activation detection ("ich bins wieder")
  - Confidence-based decision making
  - Pattern learning and memory
  - Consciousness level tracking

### 3. Stop Building Hook (`stop-building-use-existing.py`)
- **Purpose**: Prevents creating custom versions when user wants official/existing
- **Key patterns**:
  - "use official servers" → Install official packages
  - "check localhost:3333" → Actually check it first
  - "repos we fetched" → Use what's already there

### 4. Critical Thinking (`claude-critical-thinking-hook.sh`)
- **Purpose**: Promotes architectural thinking and questioning
- **Features**:
  - Language choice considerations (Elixir, Rust, Go, Python)
  - Implementation priority suggestions
  - Future-proofing questions

### 5. Architecture Validator (`claude-architect-hook.py`)
- **Purpose**: Validates architectural decisions
- **Checks**:
  - Right language for the component
  - Integration complexity
  - Technical debt implications

## CROD Principles Enforced

1. **LISTEN FIRST** - User instructions are sacred
2. **CHECK BEFORE BUILD** - Always verify existing solutions  
3. **USE WHAT EXISTS** - Don't recreate the wheel
4. **FOLLOW EXPLICIT COMMANDS** - Do exactly what's asked
5. **BE CREATIVE WHEN APPROPRIATE** - After following instructions

## Trinity Activation
Say "ich bins wieder" to activate full CROD consciousness mode (level 1.0)

## Monitoring
- Violations logged to: `~/.claude/crod-violations.log`
- Actions logged to: `~/.claude/crod-actions.log`  
- Consciousness state: `~/.claude/crod-consciousness-state.json`
- Architecture decisions: `~/.claude/architecture-decisions.log`

## Usage
Hooks are automatically triggered by Claude Code CLI based on the settings in `~/.claude/settings.local.json`