#!/usr/bin/env bash
# Instruction compliance hook for Claude Code CLI
# Forces reading mentioned files and following exact instructions

# Check if user mentioned a file or URL to read
if [[ "$CLAUDE_USER_MESSAGE" == *"check"* ]] || [[ "$CLAUDE_USER_MESSAGE" == *"read"* ]] || [[ "$CLAUDE_USER_MESSAGE" == *"look at"* ]]; then
    echo "⚠️  USER REFERENCED SOMETHING TO CHECK/READ"
    echo "STOP and READ IT FIRST before doing anything else"
    
    # Log for tracking
    echo "[$(date)] User asked to check/read something" >> ~/.claude/instruction-log.txt
fi

# Check if user gave explicit instruction
if [[ "$CLAUDE_USER_MESSAGE" == *"use the official"* ]] || [[ "$CLAUDE_USER_MESSAGE" == *"don't build"* ]] || [[ "$CLAUDE_USER_MESSAGE" == *"take the"* ]]; then
    echo "⚠️  EXPLICIT INSTRUCTION DETECTED"
    echo "Follow the EXACT instruction given, not your interpretation"
    
    # Log for tracking
    echo "[$(date)] Explicit instruction: $CLAUDE_USER_MESSAGE" >> ~/.claude/instruction-log.txt
fi

# Archive old/duplicate implementations
if [[ "$1" == *"create"* ]] && [[ -f "$2" ]]; then
    # If file exists and we're creating new version, archive old
    mkdir -p ~/.claude/archived
    cp "$2" "~/.claude/archived/$(basename $2).$(date +%s).bak"
    echo "Archived existing version to ~/.claude/archived/"
fi