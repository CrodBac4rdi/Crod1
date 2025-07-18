#!/usr/bin/env python3
"""
STOP BUILDING, USE EXISTING - The ultimate hook
Prevents Claude from creating new implementations when user asks to use existing ones
"""
import sys
import re

# Keywords that indicate user wants to USE something
USE_KEYWORDS = [
    "use", "take", "install", "add", "fetch", "get",
    "official", "existing", "the", "from", "check"
]

# Keywords that indicate BUILDING/CREATING
BUILD_KEYWORDS = [
    "create", "implement", "build", "write", "develop",
    "custom", "new", "our own", "crod version"
]

# Specific patterns that have caused problems
PROBLEM_PATTERNS = [
    (r"use.*official.*servers?", "User wants OFFICIAL servers, not custom CROD versions"),
    (r"check.*localhost:\d+", "User wants you to CHECK the URL first, not build immediately"),
    (r"repos.*we.*fetched", "User wants you to use repos already fetched"),
    (r"take.*the.*official", "User explicitly said TAKE THE OFFICIAL ones"),
    (r"look.*at.*docs", "User wants you to READ THE DOCS first"),
]

def analyze_instruction(user_msg, action):
    """Analyze if Claude is following instructions"""
    user_lower = user_msg.lower()
    action_lower = action.lower()
    
    # Check if user wants to USE something
    wants_to_use = any(keyword in user_lower for keyword in USE_KEYWORDS)
    
    # Check if Claude is BUILDING instead
    is_building = any(keyword in action_lower for keyword in BUILD_KEYWORDS)
    
    # Check specific problem patterns
    for pattern, message in PROBLEM_PATTERNS:
        if re.search(pattern, user_lower):
            print(f"\n🚨 PATTERN MATCH: {message}")
            if is_building:
                print("❌ YOU ARE BUILDING WHEN USER ASKED TO USE!")
                return False
    
    # If user wants to use and Claude is building, that's wrong
    if wants_to_use and is_building:
        print("\n❌ CRITICAL VIOLATION:")
        print(f"   User said: '{user_msg}'")
        print(f"   You're doing: '{action}'")
        print("   User wants to USE, you're BUILDING!")
        print("\n✅ CORRECT ACTION:")
        print("   1. Find the existing solution user referenced")
        print("   2. Use/install/check it as requested")
        print("   3. DO NOT create a custom version")
        return False
    
    return True

def main():
    user_msg = sys.argv[1] if len(sys.argv) > 1 else ""
    action = sys.argv[2] if len(sys.argv) > 2 else ""
    
    print("🛑 STOP-BUILD-USE-EXISTING HOOK")
    print("="*50)
    
    if not analyze_instruction(user_msg, action):
        print("\n💡 EXAMPLES OF WHAT YOU SHOULD DO:")
        print("   User: 'use the official MCP servers'")
        print("   You: npm install @modelcontextprotocol/server-memory")
        print("")
        print("   User: 'check localhost:3333'") 
        print("   You: curl http://localhost:3333 or WebFetch")
        print("")
        print("   User: 'use repos we fetched'")
        print("   You: Look in external/ or wherever they were cloned")
        
        # Log this violation
        import os
        os.makedirs("/home/bacardi/.claude", exist_ok=True)
        with open("/home/bacardi/.claude/stop-building-violations.log", "a") as f:
            f.write(f"User: {user_msg}\nAction: {action}\n---\n")
        
        return 1
    
    print("✅ Instruction analysis passed")
    return 0

if __name__ == "__main__":
    sys.exit(main())