#!/usr/bin/env python3
"""
Initialize decisions.md — a persistent decisions log for OpenClaw agents.
Scans existing memory files, AGENTS.md, and MEMORY.md for decisions and redirects,
then creates a structured decisions.md file.

Usage:
    python3 decisions-init.py [--workspace /path/to/workspace]

Default workspace: current directory (should be your OpenClaw workspace root)
"""

import os
import sys
import re
import argparse
from datetime import datetime

def find_workspace(path=None):
    """Find the OpenClaw workspace root."""
    if path:
        return path
    # Try current dir, then common locations
    for candidate in [os.getcwd(), os.path.expanduser("~/clawd"), os.path.expanduser("~/workspace")]:
        if os.path.exists(os.path.join(candidate, "MEMORY.md")) or os.path.exists(os.path.join(candidate, "AGENTS.md")):
            return candidate
    return os.getcwd()

def scan_for_decisions(workspace):
    """Scan memory files for decision-like patterns."""
    decisions = []
    patterns = [
        r'\*\*\[(\d{4}-\d{2}-\d{2})\].*?\*\*',  # **[2026-03-03] Some decision**
        r'(?:decided|preference|always|never|stop|disabled|enabled|switched|changed to)',
    ]
    
    files_to_scan = []
    # MEMORY.md
    mem = os.path.join(workspace, "MEMORY.md")
    if os.path.exists(mem):
        files_to_scan.append(mem)
    # AGENTS.md
    agents = os.path.join(workspace, "AGENTS.md")
    if os.path.exists(agents):
        files_to_scan.append(agents)
    # Memory dir
    memdir = os.path.join(workspace, "memory")
    if os.path.isdir(memdir):
        for f in os.listdir(memdir):
            if f.endswith(".md"):
                files_to_scan.append(os.path.join(memdir, f))
    # Shared context
    shared = os.path.join(workspace, "shared-context")
    if os.path.isdir(shared):
        for f in os.listdir(shared):
            if f.endswith(".md"):
                files_to_scan.append(os.path.join(shared, f))
    
    for fpath in files_to_scan:
        try:
            with open(fpath) as f:
                for line in f:
                    if re.search(patterns[0], line):
                        decisions.append(line.strip())
        except Exception:
            pass
    
    return decisions

def create_decisions_file(workspace, decisions):
    """Create the decisions.md file."""
    output = os.path.join(workspace, "decisions.md")
    
    content = f"""# decisions.md — Standing Decisions & Redirects

*Loaded at every session start. If a correction isn't here, it didn't happen.*
*Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}*

---

## System & Infrastructure

*(Add system-level decisions here: model preferences, tool configs, etc.)*

## Business & Strategy

*(Add business decisions here: priorities, what's deprioritized, etc.)*

## Content & Communication

*(Add style/format decisions here: tone, formatting rules, etc.)*

## Delegation & Work

*(Add workflow decisions here: who does what, process rules, etc.)*

## Deprioritized / Stopped

*(Add "don't do this" and "stopped" decisions here)*

---

## Auto-discovered Decisions

*The following were found in your existing files. Review and move to the correct section above:*

"""
    for d in decisions:
        content += f"{d}\n"
    
    content += """
---

*Add every redirect, "stop doing that", and "not now" here immediately with a date.*
*If it's not in this file, it didn't happen.*
"""
    
    with open(output, 'w') as f:
        f.write(content)
    
    print(f"✅ Created {output}")
    print(f"   Found {len(decisions)} potential decisions from existing files")
    print(f"   Review and organize them into the correct sections above")

def main():
    parser = argparse.ArgumentParser(description="Initialize decisions.md for OpenClaw")
    parser.add_argument("--workspace", "-w", help="Path to OpenClaw workspace root")
    args = parser.parse_args()
    
    workspace = find_workspace(args.workspace)
    print(f"Workspace: {workspace}")
    
    if os.path.exists(os.path.join(workspace, "decisions.md")):
        print("⚠️  decisions.md already exists. Delete it first or use --workspace to target a different location.")
        sys.exit(1)
    
    decisions = scan_for_decisions(workspace)
    create_decisions_file(workspace, decisions)

if __name__ == "__main__":
    main()
