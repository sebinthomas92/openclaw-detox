#!/bin/bash
# enforce-check.sh — Run all enforcement checks
# Returns summary of which rules are being followed vs violated
#
# Usage: bash enforce-check.sh [workspace_path]

set -euo pipefail

WORKSPACE="${1:-$(pwd)}"
TODAY=$(date '+%Y-%m-%d')
PASS=0
FAIL=0
WARN=0

check() {
    local name="$1" status="$2" detail="$3"
    if [ "$status" = "pass" ]; then
        echo "  ✅ $name — $detail"
        PASS=$((PASS + 1))
    elif [ "$status" = "warn" ]; then
        echo "  ⚠️ $name — $detail"
        WARN=$((WARN + 1))
    else
        echo "  ❌ $name — $detail"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== ENFORCEMENT CHECKS ==="
echo "Workspace: $WORKSPACE"
echo ""

# 1. Memory saved today?
if [ -f "$WORKSPACE/memory/${TODAY}.md" ]; then
    check "Daily Memory" "pass" "${TODAY}.md exists"
else
    check "Daily Memory" "fail" "No daily log for ${TODAY}"
fi

# 2. decisions.md loaded in boot sequence?
if [ -f "$WORKSPACE/decisions.md" ]; then
    if [ -f "$WORKSPACE/AGENTS.md" ] && grep -q "decisions.md" "$WORKSPACE/AGENTS.md" 2>/dev/null; then
        check "Decisions in Boot" "pass" "decisions.md referenced in AGENTS.md"
    else
        check "Decisions in Boot" "fail" "decisions.md exists but not in boot sequence"
    fi
else
    check "Decisions in Boot" "fail" "decisions.md missing entirely"
fi

# 3. Git has recent commits?
if [ -d "$WORKSPACE/.git" ]; then
    LAST_COMMIT_AGE=$(cd "$WORKSPACE" && git log -1 --format="%ct" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    HOURS_AGO=$(( (NOW - LAST_COMMIT_AGE) / 3600 ))
    if [ "$HOURS_AGO" -lt 24 ]; then
        check "Git Commits" "pass" "Last commit ${HOURS_AGO}h ago"
    elif [ "$HOURS_AGO" -lt 72 ]; then
        check "Git Commits" "warn" "Last commit ${HOURS_AGO}h ago"
    else
        check "Git Commits" "fail" "Last commit ${HOURS_AGO}h ago — stale"
    fi
fi

# 4. Workspace on GitHub?
if [ -d "$WORKSPACE/.git" ]; then
    REMOTE=$(cd "$WORKSPACE" && git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE" ]; then
        check "Git Remote" "pass" "Remote: $REMOTE"
    else
        check "Git Remote" "warn" "No remote — workspace not backed up to GitHub"
    fi
fi

# 5. FEEDBACK-LOG exists?
if [ -f "$WORKSPACE/shared-context/FEEDBACK-LOG.md" ] || [ -f "$WORKSPACE/FEEDBACK-LOG.md" ]; then
    check "Feedback Log" "pass" "Corrections file exists"
else
    check "Feedback Log" "warn" "No feedback log — corrections not persisted"
fi

# 6. Config backup exists today?
OPENCLAW_DIR="$HOME/.openclaw"
if [ -d "$OPENCLAW_DIR" ]; then
    TODAY_BACKUPS=$(find "$OPENCLAW_DIR" -name "openclaw.json.bak-*" -newer "$OPENCLAW_DIR/openclaw.json" 2>/dev/null | wc -l)
    TOTAL_BACKUPS=$(find "$OPENCLAW_DIR" -name "openclaw.json.bak-*" -o -name "openclaw.master*" 2>/dev/null | wc -l)
    if [ "$TOTAL_BACKUPS" -gt 0 ]; then
        check "Config Backups" "pass" "${TOTAL_BACKUPS} backup(s) found"
    else
        check "Config Backups" "warn" "No config backups — risky"
    fi
fi

# 7. Write-first-speak-second in AGENTS.md?
if [ -f "$WORKSPACE/AGENTS.md" ] && grep -qi "write first.*speak second\|persist.*before.*reporting" "$WORKSPACE/AGENTS.md" 2>/dev/null; then
    check "Write-First Rule" "pass" "Documented in AGENTS.md"
else
    check "Write-First Rule" "warn" "Not documented — phantom progress risk"
fi

echo ""
echo "--- SUMMARY ---"
echo "  Pass: $PASS | Warn: $WARN | Fail: $FAIL"
TOTAL=$((PASS + WARN + FAIL))
if [ "$TOTAL" -gt 0 ]; then
    PCT=$((PASS * 100 / TOTAL))
    echo "  Compliance: ${PCT}%"
fi
echo ""
echo "=== END ==="
