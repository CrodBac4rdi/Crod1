#!/usr/bin/env python3
"""
Fix, optimize and properly implement all CROD hooks
"""

import os
import re
import json
import subprocess
from pathlib import Path

class HookFixer:
    def __init__(self):
        self.scripts_dir = Path("/home/bacardi/crodidocker/scripts")
        self.errors = []
        self.fixed = []
        
    def analyze_script(self, script_path):
        """Analyze a script for errors"""
        print(f"\n🔍 Analyzing: {script_path.name}")
        
        # Check syntax with bash -n
        if script_path.suffix == '.sh':
            result = subprocess.run(
                ['bash', '-n', str(script_path)],
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                self.errors.append({
                    'file': script_path.name,
                    'error': result.stderr,
                    'type': 'syntax'
                })
                return False
                
        # Check Python syntax
        elif script_path.suffix == '.py':
            result = subprocess.run(
                ['python3', '-m', 'py_compile', str(script_path)],
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                self.errors.append({
                    'file': script_path.name,
                    'error': result.stderr,
                    'type': 'syntax'
                })
                return False
                
        return True
        
    def fix_common_bash_errors(self, content):
        """Fix common bash syntax errors"""
        # Fix echo "="*70 pattern
        content = re.sub(r'echo\s+"="\*70', 'echo "' + '='*70 + '"', content)
        
        # Fix string interpolation errors
        content = re.sub(r'\$\{"="\*70\}', '='*70, content)
        
        # Fix unclosed quotes
        lines = content.split('\n')
        fixed_lines = []
        for line in lines:
            if line.count('"') % 2 != 0 and not line.strip().endswith('\\'):
                # Try to fix unclosed quotes
                if 'echo' in line and not line.strip().endswith('"'):
                    line = line + '"'
            fixed_lines.append(line)
        
        return '\n'.join(fixed_lines)
        
    def create_unified_hook_system(self):
        """Create a unified hook system"""
        unified_hook = '''#!/usr/bin/env python3
"""
CROD Unified Hook System - Ensures systematic behavior on EVERY input
"""

import json
import subprocess
import sys
import os
from datetime import datetime
from pathlib import Path

class CRODHookSystem:
    def __init__(self):
        self.home = Path.home()
        self.crod_dir = Path("/home/bacardi/crodidocker")
        self.hooks_dir = self.crod_dir / "scripts"
        self.claude_dir = self.home / ".claude"
        self.claude_dir.mkdir(exist_ok=True)
        
        self.violations = []
        self.checks_passed = []
        self.checks_failed = []
        
    def run_all_checks(self):
        """Run all mandatory checks"""
        print("🔥 CROD UNIFIED HOOK SYSTEM - MANDATORY CHECKS")
        print("=" * 70)
        
        checks = [
            self.check_memory,
            self.check_claude_md,
            self.check_docker,
            self.check_mcp_servers,
            self.check_task_master,
            self.check_roadmap,
            self.check_patterns,
            self.check_monitoring
        ]
        
        for check in checks:
            try:
                if check():
                    self.checks_passed.append(check.__name__)
                else:
                    self.checks_failed.append(check.__name__)
            except Exception as e:
                self.checks_failed.append(f"{check.__name__}: {str(e)}")
                
        return len(self.checks_failed) == 0
        
    def check_memory(self):
        """Check if memory is being used"""
        print("\\n📊 Checking Memory Usage...")
        
        # Check if memory database exists
        memory_db = self.crod_dir / "data" / "crod-memory.db"
        if not memory_db.exists():
            print("❌ Memory database not found!")
            self.violations.append("Memory not initialized")
            return False
            
        print("✅ Memory database found")
        return True
        
    def check_claude_md(self):
        """Check CLAUDE.md exists and is read"""
        print("\\n📋 Checking CLAUDE.md...")
        
        claude_md = self.crod_dir / "CLAUDE.md"
        if not claude_md.exists():
            print("❌ CLAUDE.md not found!")
            self.violations.append("CLAUDE.md missing")
            return False
            
        # Check if it contains mandatory instructions
        content = claude_md.read_text()
        if "MANDATORY" not in content:
            print("⚠️  CLAUDE.md missing mandatory instructions")
            self.violations.append("CLAUDE.md incomplete")
            return False
            
        print("✅ CLAUDE.md found and valid")
        return True
        
    def check_docker(self):
        """Check Docker is being used"""
        print("\\n🐳 Checking Docker Usage...")
        
        result = subprocess.run(
            ["docker", "ps", "--format", "{{.Names}}"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print("❌ Docker not running!")
            self.violations.append("Docker not active")
            return False
            
        containers = result.stdout.strip().split('\\n')
        if len(containers) < 3:
            print(f"⚠️  Only {len(containers)} containers running")
            self.violations.append("Insufficient Docker containers")
            return False
            
        print(f"✅ {len(containers)} Docker containers running")
        return True
        
    def check_mcp_servers(self):
        """Check MCP servers are running"""
        print("\\n🔌 Checking MCP Servers...")
        
        result = subprocess.run(
            ["pgrep", "-f", "mcp-server"],
            capture_output=True
        )
        
        if result.returncode != 0:
            print("❌ No MCP servers running!")
            self.violations.append("MCP servers not active")
            return False
            
        print("✅ MCP servers active")
        return True
        
    def check_task_master(self):
        """Check task-master-ai availability"""
        print("\\n🤖 Checking Task Master AI...")
        
        result = subprocess.run(
            ["which", "task-master-ai"],
            capture_output=True
        )
        
        if result.returncode != 0:
            print("❌ task-master-ai not found!")
            self.violations.append("task-master-ai missing")
            return False
            
        print("✅ task-master-ai available")
        return True
        
    def check_roadmap(self):
        """Check roadmap exists"""
        print("\\n📍 Checking 300-point Roadmap...")
        
        roadmap = self.crod_dir / "CROD-REALISTIC-ROADMAP.md"
        if not roadmap.exists():
            print("❌ Roadmap not found!")
            self.violations.append("Roadmap missing")
            return False
            
        print("✅ Roadmap found")
        return True
        
    def check_patterns(self):
        """Check pattern data exists"""
        print("\\n🧩 Checking Pattern Data...")
        
        patterns_dir = self.crod_dir / "data" / "patterns"
        if not patterns_dir.exists() or not list(patterns_dir.glob("*.json")):
            print("❌ Pattern data not found!")
            self.violations.append("Patterns missing")
            return False
            
        pattern_count = len(list(patterns_dir.glob("*.json")))
        print(f"✅ {pattern_count} pattern files found")
        return True
        
    def check_monitoring(self):
        """Check monitoring scripts exist"""
        print("\\n📈 Checking Monitoring...")
        
        monitoring_scripts = [
            "claude-response-checker.py",
            "claude-mandatory-init.sh",
            "crod-master-hook.sh"
        ]
        
        missing = []
        for script in monitoring_scripts:
            if not (self.hooks_dir / script).exists():
                missing.append(script)
                
        if missing:
            print(f"❌ Missing monitoring scripts: {missing}")
            self.violations.append(f"Monitoring scripts missing: {missing}")
            return False
            
        print("✅ All monitoring scripts present")
        return True
        
    def generate_report(self):
        """Generate hook execution report"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "checks_passed": self.checks_passed,
            "checks_failed": self.checks_failed,
            "violations": self.violations,
            "success": len(self.checks_failed) == 0
        }
        
        # Save report
        report_file = self.claude_dir / "hook-execution-report.json"
        with open(report_file, "w") as f:
            json.dump(report, f, indent=2)
            
        return report
        
    def enforce_behavior(self):
        """Main enforcement function"""
        print("\\n" + "="*70)
        print("🧠 CROD HOOK ENFORCEMENT STARTING...")
        print("="*70)
        
        # Change to CROD directory
        os.chdir(self.crod_dir)
        
        # Run all checks
        success = self.run_all_checks()
        
        # Generate report
        report = self.generate_report()
        
        # Display results
        print("\\n" + "="*70)
        print("📊 HOOK EXECUTION SUMMARY:")
        print("="*70)
        print(f"✅ Passed: {len(self.checks_passed)}")
        print(f"❌ Failed: {len(self.checks_failed)}")
        
        if self.violations:
            print(f"\\n⚠️  VIOLATIONS DETECTED: {len(self.violations)}")
            for v in self.violations:
                print(f"   - {v}")
                
        if not success:
            print("\\n🚨 SYSTEM FAILURE - MANDATORY CHECKS NOT PASSED!")
            print("Fix these issues before proceeding!")
            sys.exit(1)
        else:
            print("\\n✅ ALL MANDATORY CHECKS PASSED!")
            print("🎯 PROCEEDING WITH SYSTEMATIC BEHAVIOR")
            
        return success

if __name__ == "__main__":
    hook_system = CRODHookSystem()
    hook_system.enforce_behavior()
'''
        
        hook_path = self.scripts_dir / "crod-unified-hook.py"
        with open(hook_path, 'w') as f:
            f.write(unified_hook)
        os.chmod(hook_path, 0o755)
        
        print(f"✅ Created unified hook system: {hook_path}")
        return hook_path
        
    def fix_all_hooks(self):
        """Main function to fix all hooks"""
        print("🔧 FIXING ALL CROD HOOKS")
        print("="*70)
        
        # Find all hook scripts
        hooks = list(self.scripts_dir.glob("*.sh")) + list(self.scripts_dir.glob("*.py"))
        
        for hook in hooks:
            if self.analyze_script(hook):
                print(f"✅ {hook.name} - No syntax errors")
            else:
                print(f"❌ {hook.name} - Has errors, fixing...")
                
                if hook.suffix == '.sh':
                    content = hook.read_text()
                    fixed_content = self.fix_common_bash_errors(content)
                    hook.write_text(fixed_content)
                    
                    # Re-check
                    if self.analyze_script(hook):
                        print(f"✅ {hook.name} - Fixed!")
                        self.fixed.append(hook.name)
                        
        # Create unified hook system
        unified_path = self.create_unified_hook_system()
        
        # Create integration script
        integration_script = '''#!/bin/bash
# CROD Hook Integration - Runs on EVERY Claude input

# Always run the unified hook first
python3 /home/bacardi/crodidocker/scripts/crod-unified-hook.py

# If that passes, run the response checker
if [ $? -eq 0 ]; then
    python3 /home/bacardi/crodidocker/scripts/claude-response-checker.py
fi
'''
        
        integration_path = self.scripts_dir / "crod-hook-integration.sh"
        with open(integration_path, 'w') as f:
            f.write(integration_script)
        os.chmod(integration_path, 0o755)
        
        print(f"\n✅ Created integration script: {integration_path}")
        
        # Summary
        print("\n" + "="*70)
        print("📊 HOOK FIX SUMMARY:")
        print("="*70)
        print(f"Total hooks analyzed: {len(hooks)}")
        print(f"Errors found: {len(self.errors)}")
        print(f"Hooks fixed: {len(self.fixed)}")
        print(f"\n✅ Unified hook system created")
        print("✅ Integration script created")
        print("\n🎯 NEXT: Test the unified hook system")
        
if __name__ == "__main__":
    fixer = HookFixer()
    fixer.fix_all_hooks()