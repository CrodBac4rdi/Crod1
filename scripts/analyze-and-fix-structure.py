#!/usr/bin/env python3
"""
Analyze current CROD structure and create proper Docker organization
"""

import os
import json
import subprocess
from pathlib import Path

def run_command(cmd):
    """Execute command and return output"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout, result.stderr, result.returncode

def analyze_structure():
    """Analyze current directory structure"""
    print("🔍 ANALYZING CURRENT CROD STRUCTURE...")
    
    # Find all important directories
    dirs = {
        "elixir": Path("elixir/crod-complete"),
        "javascript": Path("javascript"),
        "python": Path("python"),
        "go": Path("go-bridge"),
        "docker": Path("docker"),
        "scripts": Path("scripts"),
        "data": Path("data"),
    }
    
    status = {}
    for name, path in dirs.items():
        if path.exists():
            file_count = len(list(path.rglob("*")))
            status[name] = {
                "exists": True,
                "files": file_count,
                "path": str(path)
            }
        else:
            status[name] = {"exists": False}
    
    return status

def check_docker_status():
    """Check what's running in Docker"""
    print("\n🐳 CHECKING DOCKER STATUS...")
    
    stdout, _, _ = run_command("docker ps --format json")
    containers = []
    for line in stdout.strip().split('\n'):
        if line:
            containers.append(json.loads(line))
    
    return containers

def create_proper_structure():
    """Create the proper Docker structure"""
    print("\n🏗️ CREATING PROPER DOCKER STRUCTURE...")
    
    structure = {
        "docker/services/elixir": "Elixir/Phoenix master brain",
        "docker/services/javascript": "JavaScript neural brain",
        "docker/services/python": "Python ML brain",
        "docker/services/go": "Go system brain",
        "docker/services/rust": "Rust performance brain",
        "docker/monitoring/prometheus": "Prometheus metrics",
        "docker/monitoring/grafana": "Grafana dashboards",
        "docker/monitoring/jaeger": "Distributed tracing",
        "docker/data/postgres": "PostgreSQL data",
        "docker/data/redis": "Redis data",
        "docker/data/patterns": "Pattern storage",
        "docker/config": "All configuration files",
        "docker/scripts": "Docker-specific scripts",
    }
    
    for path, desc in structure.items():
        Path(path).mkdir(parents=True, exist_ok=True)
        print(f"✅ Created: {path} - {desc}")
    
    return structure

def find_existing_configs():
    """Find all existing docker and config files"""
    print("\n📋 FINDING EXISTING CONFIGURATIONS...")
    
    configs = {}
    
    # Find Dockerfiles
    dockerfiles = list(Path(".").rglob("Dockerfile*"))
    configs["dockerfiles"] = [str(f) for f in dockerfiles]
    
    # Find docker-compose files
    compose_files = list(Path(".").rglob("docker-compose*.yml"))
    configs["compose"] = [str(f) for f in compose_files]
    
    # Find config files
    config_patterns = ["*.toml", "*.yml", "*.yaml", "*.json", "*.conf"]
    config_files = []
    for pattern in config_patterns:
        config_files.extend(list(Path(".").rglob(pattern)))
    configs["configs"] = [str(f) for f in config_files if "node_modules" not in str(f)][:20]
    
    return configs

def main():
    """Main analysis function"""
    print("🧠 CROD DOCKER STRUCTURE ANALYZER")
    print("==================================\n")
    
    # Change to CROD directory
    os.chdir("/home/bacardi/crodidocker")
    
    # Analyze current structure
    current = analyze_structure()
    print("\n📊 CURRENT STRUCTURE:")
    for name, info in current.items():
        if info.get("exists"):
            print(f"✅ {name}: {info['files']} files in {info['path']}")
        else:
            print(f"❌ {name}: NOT FOUND")
    
    # Check Docker status
    containers = check_docker_status()
    print(f"\n🐳 RUNNING CONTAINERS: {len(containers)}")
    for c in containers:
        print(f"   - {c['Names']}: {c['Status']}")
    
    # Find existing configs
    configs = find_existing_configs()
    print(f"\n📄 FOUND CONFIGURATIONS:")
    print(f"   - Dockerfiles: {len(configs['dockerfiles'])}")
    print(f"   - Docker Compose: {len(configs['compose'])}")
    print(f"   - Config Files: {len(configs['configs'])}")
    
    # Create proper structure
    new_structure = create_proper_structure()
    
    # Generate report
    report = {
        "current_structure": current,
        "docker_containers": len(containers),
        "configurations": {
            "dockerfiles": len(configs['dockerfiles']),
            "compose_files": len(configs['compose']),
            "config_files": len(configs['configs'])
        },
        "new_structure_created": list(new_structure.keys()),
        "next_steps": [
            "Move Dockerfiles to docker/services/",
            "Create unified docker-compose.yml",
            "Set up monitoring stack",
            "Configure inter-container networking",
            "Create initialization scripts"
        ]
    }
    
    with open("docker/structure-analysis.json", "w") as f:
        json.dump(report, f, indent=2)
    
    print("\n✅ ANALYSIS COMPLETE!")
    print("📊 Report saved to: docker/structure-analysis.json")
    print("\n🎯 NEXT: Create proper docker-compose.yml with ALL services")

if __name__ == "__main__":
    main()