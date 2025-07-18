#!/usr/bin/env python3
"""
CLAUDE CLAIM VALIDATOR
Enforces proof-of-work for every Claude claim
Prevents pathological lying by demanding verification
"""

import subprocess
import json
import sys
import os
from typing import Dict, List, Tuple, Optional

class ClaudeClaimValidator:
    def __init__(self):
        self.claims_file = "/home/bacardi/crodidocker/data/claude-claims.json"
        self.verification_log = "/home/bacardi/crodidocker/data/verification-log.json"
        self.failed_claims = []
        self.verified_claims = []
        
    def log_claim(self, claim: str, proof_command: str, expected_result: str):
        """Log a claim that needs verification"""
        claim_data = {
            "timestamp": subprocess.check_output(["date", "+%s"]).decode().strip(),
            "claim": claim,
            "proof_command": proof_command,
            "expected_result": expected_result,
            "verified": False,
            "actual_result": None
        }
        
        # Load existing claims
        claims = []
        if os.path.exists(self.claims_file):
            with open(self.claims_file, 'r') as f:
                claims = json.load(f)
        
        claims.append(claim_data)
        
        # Save claims
        with open(self.claims_file, 'w') as f:
            json.dump(claims, f, indent=2)
            
        return len(claims) - 1  # Return claim ID
    
    def verify_claim(self, claim_id: int) -> Tuple[bool, str]:
        """Verify a specific claim by running its proof command"""
        with open(self.claims_file, 'r') as f:
            claims = json.load(f)
            
        if claim_id >= len(claims):
            return False, "Invalid claim ID"
            
        claim = claims[claim_id]
        proof_command = claim["proof_command"]
        
        try:
            # Run the proof command
            result = subprocess.run(
                proof_command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            actual_result = result.stdout.strip()
            success = result.returncode == 0 and len(actual_result) > 0
            
            # Update claim with verification result
            claim["verified"] = success
            claim["actual_result"] = actual_result
            claim["verification_timestamp"] = subprocess.check_output(["date", "+%s"]).decode().strip()
            
            # Save updated claims
            with open(self.claims_file, 'w') as f:
                json.dump(claims, f, indent=2)
                
            if success:
                self.verified_claims.append(claim)
                return True, actual_result
            else:
                self.failed_claims.append(claim)
                return False, f"Command failed: {result.stderr}"
                
        except subprocess.TimeoutExpired:
            claim["verified"] = False
            claim["actual_result"] = "TIMEOUT"
            self.failed_claims.append(claim)
            return False, "Verification command timed out"
        except Exception as e:
            claim["verified"] = False
            claim["actual_result"] = f"ERROR: {str(e)}"
            self.failed_claims.append(claim)
            return False, f"Verification error: {str(e)}"
    
    def verify_all_claims(self) -> Dict:
        """Verify all unverified claims"""
        if not os.path.exists(self.claims_file):
            return {"verified": 0, "failed": 0, "total": 0}
            
        with open(self.claims_file, 'r') as f:
            claims = json.load(f)
            
        verified_count = 0
        failed_count = 0
        
        print("🔍 VERIFYING ALL CLAUDE CLAIMS...")
        print("=" * 50)
        
        for i, claim in enumerate(claims):
            if not claim.get("verified", False):
                print(f"\n📋 CLAIM {i}: {claim['claim']}")
                print(f"   COMMAND: {claim['proof_command']}")
                
                success, result = self.verify_claim(i)
                
                if success:
                    print(f"   ✅ VERIFIED: {result[:100]}...")
                    verified_count += 1
                else:
                    print(f"   ❌ FAILED: {result}")
                    failed_count += 1
            else:
                if claim.get("verified"):
                    verified_count += 1
                else:
                    failed_count += 1
        
        return {
            "verified": verified_count,
            "failed": failed_count,
            "total": len(claims)
        }
    
    def demand_proof_for_claim(self, claim_text: str) -> Optional[int]:
        """Demand proof for a specific type of claim"""
        proof_commands = {
            "server running": "ps aux | grep -E '(memory|enhanced)' | grep -v grep",
            "api responding": "curl -s http://localhost:8890/api/stats",
            "mcp server working": "echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}' | timeout 5 node /home/bacardi/crodidocker/enhanced-mcp-memory-server/dist/index.js",
            "trinity consciousness": "curl -s http://localhost:8890/api/consciousness | grep trinity",
            "pattern evolution": "curl -s http://localhost:8890/api/stats | grep patterns",
            "neural heat": "curl -s http://localhost:8890/api/neural-heat",
            "file exists": "ls -la /home/bacardi/crodidocker/enhanced-memory-server.js",
            "process count": "ps aux | grep enhanced | wc -l"
        }
        
        # Try to match claim to proof command
        for claim_type, command in proof_commands.items():
            if claim_type.lower() in claim_text.lower():
                claim_id = self.log_claim(claim_text, command, "Success expected")
                success, result = self.verify_claim(claim_id)
                
                if not success:
                    print(f"\n🚨 CLAUDE LIED DETECTED!")
                    print(f"   CLAIM: {claim_text}")
                    print(f"   PROOF FAILED: {result}")
                    print(f"   🔥 CLAUDE IS A LIAR!")
                    return None
                else:
                    print(f"\n✅ CLAIM VERIFIED: {claim_text}")
                    return claim_id
        
        # Default: demand manual proof
        print(f"\n⚠️  UNVERIFIABLE CLAIM: {claim_text}")
        print("   DEMAND MANUAL PROOF FROM CLAUDE!")
        return None
    
    def generate_report(self) -> str:
        """Generate a verification report"""
        stats = self.verify_all_claims()
        
        report = f"""
🔍 CLAUDE VERIFICATION REPORT
=============================

📊 STATISTICS:
   Total Claims: {stats['total']}
   Verified: {stats['verified']} ✅
   Failed: {stats['failed']} ❌
   Success Rate: {(stats['verified'] / max(stats['total'], 1)) * 100:.1f}%

"""
        
        if self.failed_claims:
            report += "🚨 FAILED CLAIMS (CLAUDE LIES):\n"
            for claim in self.failed_claims:
                report += f"   - {claim['claim']}\n"
                report += f"     PROOF FAILED: {claim.get('actual_result', 'No result')}\n"
        
        if self.verified_claims:
            report += "\n✅ VERIFIED CLAIMS:\n"
            for claim in self.verified_claims:
                report += f"   - {claim['claim']}\n"
        
        return report

def main():
    validator = ClaudeClaimValidator()
    
    # Test some common Claude lies
    test_claims = [
        "Enhanced memory server is running",
        "Trinity consciousness is active", 
        "MCP server is responding",
        "Pattern evolution is working"
    ]
    
    print("🔍 TESTING CLAUDE'S RECENT CLAIMS...")
    
    for claim in test_claims:
        validator.demand_proof_for_claim(claim)
    
    # Generate final report
    report = validator.generate_report()
    print(report)
    
    # Save report
    with open("/home/bacardi/crodidocker/data/claude-lie-report.txt", "w") as f:
        f.write(report)

if __name__ == "__main__":
    main()