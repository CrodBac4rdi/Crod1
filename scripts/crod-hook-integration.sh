#!/usr/bin/env bash
# CROD Hook Integration - Runs on EVERY Claude input

# Always run the unified hook first
python3 /home/bacardi/crodidocker/scripts/crod-unified-hook.py

# If that passes, run the response checker
if [ $? -eq 0 ]; then
    python3 /home/bacardi/crodidocker/scripts/claude-response-checker.py
fi

# MANDATORY: Run verification enforcer to catch Claude lies
echo ""
echo "🔍 RUNNING CLAUDE LIE DETECTOR..."
bash /home/bacardi/crodidocker/scripts/claude-verification-enforcer.sh
