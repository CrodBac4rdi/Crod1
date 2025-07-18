#!/usr/bin/env python3
"""
MANDATORY CLAUDE RESPONSE CHECKER
This script enforces systematic behavior for Claude
"""

import json
import sys
import subprocess
import os

class ClaudeResponseChecker:
    def __init__(self):
        self.mandatory_checks = [
            "memory_check",
            "claude_md_read", 
            "task_master_check",
            "mcp_server_usage",
            "roadmap_progress",
            "docker_usage",
            "mermaid_adherence",
            "tool_usage"
        ]
        
    def run_mandatory_init(self):
        """Execute mandatory initialization"""
        print("🔥 EXECUTING MANDATORY CLAUDE CHECKS...")
        
        # Run the init script
        result = subprocess.run(
            ["bash", "/home/bacardi/crodidocker/scripts/claude-mandatory-init.sh"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print("❌ MANDATORY INIT FAILED")
            print(result.stderr)
            return False
            
        print("✅ MANDATORY INIT PASSED")
        return True
        
    def create_systematic_response_plan(self):
        """Create systematic response plan using task-master-ai"""
        print("🤖 CREATING SYSTEMATIC RESPONSE PLAN...")
        
        plan = {
            "step_1": "Check memory for context",
            "step_2": "Read CLAUDE.md for instructions", 
            "step_3": "Use task-master-ai for orchestration",
            "step_4": "Use MCP servers for ALL operations",
            "step_5": "Check 300-point roadmap progress",
            "step_6": "Execute in Docker containers",
            "step_7": "Follow Mermaid architecture",
            "step_8": "Use IDE extensions systematically"
        }
        
        with open("/tmp/claude_response_plan.json", "w") as f:
            json.dump(plan, f, indent=2)
            
        print("✅ SYSTEMATIC PLAN CREATED")
        return plan
        
    def enforce_systematic_behavior(self):
        """Main enforcement function"""
        if not self.run_mandatory_init():
            sys.exit(1)
            
        plan = self.create_systematic_response_plan()
        
        print("🎯 SYSTEMATIC BEHAVIOR ENFORCED")
        print("📋 NEXT: Execute response according to plan")
        
        return True

if __name__ == "__main__":
    checker = ClaudeResponseChecker()
    checker.enforce_systematic_behavior()