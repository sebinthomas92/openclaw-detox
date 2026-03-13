#!/bin/bash
# workspace-inventory.sh — Anti-hallucination tool for OpenClaw workspaces
# Counts what actually exists on disk so agents don't make false claims
#
# Usage: bash workspace-inventory.sh [workspace_path]

set -euo pipefail

WORKSPACE="${1:-$(pwd)}"
HOME_DIR=$(eval echo ~)

echo "=== WORKSPACE INVENTORY ==="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M %Z')"
echo "Workspace: $WORKSPACE"
echo ""

# 1. Git repos
echo "--- GIT REPOS ---"
find "$HOME_DIR" -maxdepth 4 -name ".git" -type d 2>/dev/null | while read gitdir; do
    REPO_DIR=$(dirname "$gitdir")
    BRANCH=$(cd "$REPO_DIR" && git branch --show-current 2>/dev/null || echo "?")
    LAST=$(cd "$REPO_DIR" && git log -1 --format="%h %s" 2>/dev/null || echo "?")
    echo "  $REPO_DIR [${BRANCH}] → $LAST"
done
echo ""

# 2. Duplicate repo check
echo "--- DUPLICATE REPO CHECK ---"
DUPES=$(find "$HOME_DIR" -maxdepth 5 -name ".git" -type d 2>/dev/null | while read gitdir; do
    REPO_DIR=$(dirname "$gitdir")
    REMOTE=$(cd "$REPO_DIR" && git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE" ]; then
        echo "$REMOTE|$REPO_DIR"
    fi
done | sort | awk -F'|' '
{
    repos[$1] = repos[$1] ? repos[$1] "|" $2 : $2
    count[$1]++
}
END {
    found=0
    for (r in count) {
        if (count[r] > 1) {
            printf "  ⚠️ %s (%d copies): %s\n", r, count[r], repos[r]
            found=1
        }
    }
    if (!found) print "  ✅ No duplicates"
}')
echo "$DUPES"
echo ""

# 3. Memory files
echo "--- MEMORY FILES ---"
if [ -d "$WORKSPACE/memory" ]; then
    TOTAL=$(find "$WORKSPACE/memory" -name "*.md" -type f 2>/dev/null | wc -l)
    RECENT=$(find "$WORKSPACE/memory" -name "*.md" -type f -mtime -1 2>/dev/null | wc -l)
    OLDEST=$(find "$WORKSPACE/memory" -name "20*.md" -type f 2>/dev/null | sort | head -1 | xargs basename 2>/dev/null || echo "none")
    NEWEST=$(find "$WORKSPACE/memory" -name "20*.md" -type f 2>/dev/null | sort | tail -1 | xargs basename 2>/dev/null || echo "none")
    echo "  Total: $TOTAL | Modified <24h: $RECENT"
    echo "  Date range: $OLDEST → $NEWEST"
else
    echo "  No memory/ directory found"
fi
echo ""

# 4. Skills
echo "--- SKILLS ---"
BUNDLED=$(ls -d "$HOME_DIR/.npm-global/lib/node_modules/openclaw/skills"/*/ 2>/dev/null | wc -l)
echo "  Bundled: $BUNDLED"
if [ -d "$WORKSPACE/skills" ]; then
    CUSTOM=$(ls -d "$WORKSPACE/skills"/*/ 2>/dev/null | wc -l)
    echo "  Custom: $CUSTOM"
else
    echo "  Custom: 0 (no skills/ directory)"
fi
echo ""

# 5. Config files
echo "--- KEY FILES ---"
for f in MEMORY.md AGENTS.md SOUL.md USER.md HEARTBEAT.md decisions.md TOOLS.md; do
    if [ -f "$WORKSPACE/$f" ]; then
        SIZE=$(wc -l < "$WORKSPACE/$f")
        MOD=$(stat -c%Y "$WORKSPACE/$f" 2>/dev/null || echo 0)
        AGE=$(( ($(date +%s) - MOD) / 3600 ))
        echo "  ✅ $f (${SIZE} lines, ${AGE}h ago)"
    else
        echo "  ❌ $f — MISSING"
    fi
done
echo ""

# 6. Disk usage
echo "--- DISK USAGE ---"
du -sh "$WORKSPACE" 2>/dev/null | awk '{print "  Workspace: " $1}'
du -sh "$HOME_DIR/.openclaw" 2>/dev/null | awk '{print "  .openclaw: " $1}'
DISK_PCT=$(df / --output=pcent | tail -1 | tr -d ' %')
DISK_AVAIL=$(df -h / --output=avail | tail -1 | tr -d ' ')
echo "  System disk: ${DISK_PCT}% used (${DISK_AVAIL} free)"

echo ""
echo "=== END INVENTORY ==="
