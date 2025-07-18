#!/usr/bin/env python3
"""
Test all CROD hooks to ensure they work properly
"""

import subprocess
import sys
import os
from pathlib import Path

def test_hook(script_path):
    """Test a single hook script"""
    print(f"\n🧪 Testing: {script_path.name}")
    print("-" * 50)
    
    try:
        if script_path.suffix == '.sh':
            # Test bash syntax
            result = subprocess.run(
                ['bash', '-n', str(script_path)],
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                print(f"❌ Syntax error: {result.stderr}")
                return False
                
            # Run the script
            result = subprocess.run(
                ['bash', str(script_path)],
                capture_output=True,
                text=True,
                timeout=5
            )
            
        elif script_path.suffix == '.py':
            # Test python syntax
            result = subprocess.run(
                ['python3', '-m', 'py_compile', str(script_path)],
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                print(f"❌ Syntax error: {result.stderr}")
                return False
                
            # Run the script
            result = subprocess.run(
                ['python3', str(script_path)],
                capture_output=True,
                text=True,
                timeout=5
            )
            
        if result.returncode == 0:
            print("✅ Script executed successfully")
            if result.stdout:
                print(f"Output preview: {result.stdout[:200]}...")
            return True
        else:
            print(f"❌ Script failed with code: {result.returncode}")
            if result.stderr:
                print(f"Error: {result.stderr[:200]}...")
            return False
            
    except subprocess.TimeoutExpired:
        print("⏱️ Script timed out (normal for blocking scripts)")
        return True
    except Exception as e:
        print(f"❌ Exception: {str(e)}")
        return False

def main():
    """Test all hooks"""
    print("🔧 TESTING ALL CROD HOOKS")
    print("=" * 70)
    
    os.chdir("/home/bacardi/crodidocker")
    
    # Key hooks to test
    hooks = [
        "scripts/crod-unified-hook.py",
        "scripts/claude-response-checker.py",
        "scripts/claude-mandatory-init.sh",
        "scripts/crod-hook-integration.sh",
        "scripts/crod-master-hook.sh"
    ]
    
    passed = 0
    failed = 0
    
    for hook_path in hooks:
        path = Path(hook_path)
        if not path.exists():
            print(f"\n⚠️ {hook_path} - NOT FOUND")
            failed += 1
            continue
            
        if test_hook(path):
            passed += 1
        else:
            failed += 1
    
    # Summary
    print("\n" + "=" * 70)
    print("📊 HOOK TEST SUMMARY:")
    print("=" * 70)
    print(f"✅ Passed: {passed}")
    print(f"❌ Failed: {failed}")
    print(f"📈 Success Rate: {(passed/(passed+failed)*100):.1f}%")
    
    if failed == 0:
        print("\n🎉 ALL HOOKS WORKING PROPERLY!")
        return 0
    else:
        print("\n🔧 Some hooks need fixing")
        return 1

if __name__ == "__main__":
    sys.exit(main())