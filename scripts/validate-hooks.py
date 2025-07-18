#!/usr/bin/env python3
"""
Validate that all hooks are properly integrated and working
"""

import subprocess
import json
import sys
from pathlib import Path
from datetime import datetime

def validate_hook_files():
    """Check all hook files exist and are executable"""
    print("📁 Validating Hook Files...")
    
    required_hooks = {
        "scripts/crod-unified-hook.py": "Unified system checker",
        "scripts/claude-response-checker.py": "Response plan enforcer",
        "scripts/claude-mandatory-init.sh": "Mandatory initialization",
        "scripts/crod-hook-integration.sh": "Integration runner",
        "scripts/crod-master-hook.sh": "Master orchestrator",
        "scripts/crod-instruction-enforcer.sh": "Instruction compliance"
    }
    
    all_exist = True
    for hook, desc in required_hooks.items():
        path = Path(hook)
        if path.exists():
            if path.stat().st_mode & 0o111:
                print(f"✅ {hook} - {desc}")
            else:
                print(f"⚠️  {hook} - Not executable")
                all_exist = False
        else:
            print(f"❌ {hook} - MISSING")
            all_exist = False
            
    return all_exist

def validate_claude_md():
    """Check CLAUDE.md configurations"""
    print("\n📋 Validating CLAUDE.md Files...")
    
    # Check global CLAUDE.md
    global_claude = Path.home() / ".claude" / "CLAUDE.md"
    if global_claude.exists():
        content = global_claude.read_text()
        if "crod-hook-integration.sh" in content:
            print("✅ Global CLAUDE.md - Hook integration configured")
        else:
            print("❌ Global CLAUDE.md - Missing hook integration")
            return False
    else:
        print("❌ Global CLAUDE.md - NOT FOUND")
        return False
        
    # Check project CLAUDE.md
    project_claude = Path("/home/bacardi/crodidocker/CLAUDE.md")
    if project_claude.exists():
        content = project_claude.read_text()
        if "MANDATORY" in content:
            print("✅ Project CLAUDE.md - Mandatory behavior configured")
        else:
            print("❌ Project CLAUDE.md - Missing mandatory section")
            return False
    else:
        print("❌ Project CLAUDE.md - NOT FOUND")
        return False
        
    return True

def validate_hook_execution():
    """Test actual hook execution"""
    print("\n🧪 Validating Hook Execution...")
    
    # Test unified hook
    result = subprocess.run(
        ["python3", "scripts/crod-unified-hook.py"],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print("✅ Unified hook - All checks passed")
    else:
        print("❌ Unified hook - Some checks failed")
        return False
        
    # Test integration
    result = subprocess.run(
        ["bash", "scripts/crod-hook-integration.sh"],
        capture_output=True,
        text=True
    )
    
    if "SYSTEMATIC BEHAVIOR ENFORCED" in result.stdout:
        print("✅ Hook integration - Working properly")
    else:
        print("❌ Hook integration - Not working")
        return False
        
    return True

def generate_validation_report():
    """Generate comprehensive validation report"""
    report = {
        "timestamp": datetime.now().isoformat(),
        "validation_status": {
            "hook_files": validate_hook_files(),
            "claude_md": validate_claude_md(),
            "hook_execution": validate_hook_execution()
        },
        "recommendations": []
    }
    
    # Add recommendations
    if not report["validation_status"]["hook_files"]:
        report["recommendations"].append("Fix missing or non-executable hook files")
    if not report["validation_status"]["claude_md"]:
        report["recommendations"].append("Update CLAUDE.md files with proper configuration")
    if not report["validation_status"]["hook_execution"]:
        report["recommendations"].append("Debug failing hook executions")
        
    # Save report
    report_path = Path("scripts/hook-validation-report.json")
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)
        
    return report

def main():
    """Main validation function"""
    print("🔍 CROD HOOK SYSTEM VALIDATION")
    print("=" * 70)
    
    # Change to project directory
    import os
    os.chdir("/home/bacardi/crodidocker")
    
    # Generate report
    report = generate_validation_report()
    
    # Display summary
    print("\n" + "=" * 70)
    print("📊 VALIDATION SUMMARY:")
    print("=" * 70)
    
    all_valid = all(report["validation_status"].values())
    
    if all_valid:
        print("✅ ALL HOOKS PROPERLY IMPLEMENTED AND WORKING!")
        print("🎯 System ready for enforced systematic behavior")
    else:
        print("❌ SOME VALIDATION CHECKS FAILED")
        print("\n📋 Recommendations:")
        for rec in report["recommendations"]:
            print(f"   - {rec}")
            
    print(f"\n📄 Full report saved to: scripts/hook-validation-report.json")
    
    return 0 if all_valid else 1

if __name__ == "__main__":
    sys.exit(main())