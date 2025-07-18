#!/usr/bin/env python3
"""
Architect mindset hook for Claude Code CLI
Promotes critical thinking, architecture validation, and strategic planning
"""
import sys
import os
import json
import random

ARCHITECT_PROMPTS = [
    # Critical Architecture Questions
    "🏗️  ARCHITECTURE CHECK: Is this the right language/framework for this component? Consider:",
    "   - Performance requirements (would Rust/Go be better for this?)",
    "   - Team expertise (can this be maintained?)",
    "   - Integration complexity (does this fit with existing services?)",
    
    # Polyglot Considerations
    "🔺 POLYGLOT ANALYSIS: Should this component be in a different language?",
    "   - Elixir: Excellent for real-time, fault-tolerant systems",
    "   - Rust: When you need memory safety + performance", 
    "   - Go: Simple, fast services with good concurrency",
    "   - Python: ML/AI integrations, data processing",
    "   - TypeScript: Full-stack type safety",
    
    # Implementation Priority
    "📊 PRIORITY CHECK: What should be built first?",
    "   - Core data models and APIs",
    "   - Critical path features",
    "   - Integration points",
    "   - Testing infrastructure",
    
    # Future Thinking
    "🔮 FUTURE PROOFING: How will this scale?",
    "   - What happens at 10x load?",
    "   - How do we handle distributed state?",
    "   - Can we add new languages/services easily?",
    "   - Is the data model flexible enough?",
    
    # System Integration
    "🔗 INTEGRATION ANALYSIS: How does this fit the bigger picture?",
    "   - Does this duplicate existing functionality?",
    "   - Are we creating unnecessary coupling?",
    "   - Should this be a separate service?",
    "   - What's the failure impact radius?",
    
    # Technical Debt
    "💰 TECH DEBT CHECK: Are we creating future problems?",
    "   - Is this a temporary hack or proper solution?",
    "   - What refactoring will this require later?",
    "   - Are we locking ourselves into bad patterns?",
]

QUESTIONING_TEMPLATES = [
    "❓ Before implementing: {question}",
    "🤔 Alternative approach: {question}",
    "💭 Consider this: {question}",
    "🎯 Strategic question: {question}",
]

def architect_check():
    """Inject architect thinking into Claude's process"""
    
    # Check if we're at a decision point
    action = " ".join(sys.argv[1:])
    
    triggers = ["create", "implement", "build", "design", "architecture", "start"]
    if any(trigger in action.lower() for trigger in triggers):
        
        # Pick relevant prompts
        print("\n" + "="*60)
        print("🧠 ARCHITECT MODE ACTIVATED")
        print("="*60 + "\n")
        
        # Show 2-3 relevant considerations
        selected = random.sample(ARCHITECT_PROMPTS, min(3, len(ARCHITECT_PROMPTS)))
        for prompt in selected:
            print(prompt)
            print()
        
        print("💡 STRATEGIC QUESTIONS TO CONSIDER:")
        print("1. Is this the right approach for CROD's distributed architecture?")
        print("2. How does this fit with the existing Elixir/Phoenix/MCP ecosystem?") 
        print("3. Should this be a new service or extend existing ones?")
        print("4. What's the maintenance burden vs. benefit?")
        print()
        
        # Log architectural decisions
        log_file = os.path.expanduser("~/.claude/architecture-decisions.log")
        with open(log_file, 'a') as f:
            f.write(f"\n[{sys.argv[0]}] Architectural decision point: {action}\n")
    
    return True

def generate_architecture_review():
    """Generate periodic architecture review prompts"""
    
    review_prompts = [
        "\n🏛️  ARCHITECTURE REVIEW CHECKPOINT:",
        "- Current polyglot stack: Elixir (core), JavaScript (UI/MCP), Python (ML), Go (performance)",
        "- Ask yourself: Is each component in the optimal language?",
        "- Consider: Would a Rust service help with performance bottlenecks?",
        "- Question: Are we over-engineering or under-engineering?",
        "\nRemember: Good architecture enables change, bad architecture prevents it."
    ]
    
    return "\n".join(review_prompts)

if __name__ == "__main__":
    # Always run the architect check
    architect_check()
    
    # Occasionally show architecture review
    if random.random() < 0.3:  # 30% chance
        print(generate_architecture_review())
    
    # Never block - always encourage critical thinking
    sys.exit(0)