#!/bin/bash
# health-score.sh — System health score with hard gates + integrity multiplier
# 3-layer scoring: letter grade → category scores → hard gates
# Hard gate failure = whole system degraded regardless of other scores
#
# Usage: bash health-score.sh [--workspace /path/to/workspace]

set -euo pipefail

# Parse workspace arg
WORKSPACE="${1:-$(pwd)}"
if [ "$1" = "--workspace" ] 2>/dev/null; then
    WORKSPACE="${2:-$(pwd)}"
fi

# Auto-detect workspace
if [ ! -f "$WORKSPACE/MEMORY.md" ] && [ ! -f "$WORKSPACE/AGENTS.md" ]; then
    for candidate in ~/clawd ~/workspace .; do
        if [ -f "$candidate/MEMORY.md" ] || [ -f "$candidate/AGENTS.md" ]; then
            WORKSPACE="$candidate"
            break
        fi
    done
fi

SCORE=0
MAX_SCORE=0
CRITICAL_FAIL=0
WARNINGS=0
DETAILS=""

add_check() {
    local category="$1" name="$2" status="$3" detail="$4" weight="${5:-1}"
    MAX_SCORE=$((MAX_SCORE + weight))
    if [ "$status" = "pass" ]; then
        SCORE=$((SCORE + weight))
        DETAILS="$DETAILS\n  ✅ [$category] $name — $detail"
    elif [ "$status" = "warn" ]; then
        SCORE=$((SCORE + weight / 2))
        WARNINGS=$((WARNINGS + 1))
        DETAILS="$DETAILS\n  ⚠️ [$category] $name — $detail"
    elif [ "$status" = "critical" ]; then
        CRITICAL_FAIL=$((CRITICAL_FAIL + 1))
        DETAILS="$DETAILS\n  ❌ [$category] $name — CRITICAL: $detail"
    else
        DETAILS="$DETAILS\n  ❌ [$category] $name — $detail"
    fi
}

echo "=== SYSTEM HEALTH SCORE ==="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M %Z')"
echo "Workspace: $WORKSPACE"
echo ""

# ===== HARD GATES (critical failures tank everything) =====

# Gate 1: Gateway running
if systemctl --user is-active openclaw-gateway &>/dev/null; then
    add_check "GATE" "Gateway" "pass" "Running" 3
elif pgrep -f "openclaw" &>/dev/null; then
    add_check "GATE" "Gateway" "pass" "Running (process found)" 3
else
    add_check "GATE" "Gateway" "critical" "DOWN — all comms dead" 3
fi

# Gate 2: Disk space
DISK_AVAIL_KB=$(df / --output=avail | tail -1 | tr -d ' ')
DISK_PCT=$(df / --output=pcent | tail -1 | tr -d ' %')
DISK_AVAIL_GB=$((DISK_AVAIL_KB / 1048576))
if [ "$DISK_AVAIL_KB" -lt 2097152 ]; then
    add_check "GATE" "Disk Space" "critical" "${DISK_PCT}% used, ${DISK_AVAIL_GB}GB free" 3
elif [ "$DISK_PCT" -gt 85 ]; then
    add_check "GATE" "Disk Space" "warn" "${DISK_PCT}% used, ${DISK_AVAIL_GB}GB free" 3
else
    add_check "GATE" "Disk Space" "pass" "${DISK_PCT}% used, ${DISK_AVAIL_GB}GB free" 3
fi

# Gate 3: decisions.md exists
if [ -f "$WORKSPACE/decisions.md" ]; then
    DECISIONS_COUNT=$(grep -c "^\- \*\*\[" "$WORKSPACE/decisions.md" 2>/dev/null || echo 0)
    add_check "GATE" "Decisions File" "pass" "Exists (${DECISIONS_COUNT} entries)" 2
else
    add_check "GATE" "Decisions File" "critical" "MISSING — corrections vanish between sessions" 2
fi

# ===== INFRASTRUCTURE =====

# Git cleanliness
if [ -d "$WORKSPACE/.git" ]; then
    UNCOMMITTED=$(cd "$WORKSPACE" && git status --porcelain 2>/dev/null | wc -l)
    if [ "$UNCOMMITTED" -gt 20 ]; then
        add_check "INFRA" "Git Cleanliness" "warn" "${UNCOMMITTED} uncommitted changes" 1
    else
        add_check "INFRA" "Git Cleanliness" "pass" "${UNCOMMITTED} uncommitted" 1
    fi
else
    add_check "INFRA" "Git Cleanliness" "warn" "Not a git repo — no version control" 1
fi

# ===== MEMORY & CONTEXT =====

# Today's memory log
TODAY=$(date '+%Y-%m-%d')
if [ -f "$WORKSPACE/memory/${TODAY}.md" ]; then
    add_check "MEMORY" "Daily Log" "pass" "${TODAY}.md exists" 2
else
    add_check "MEMORY" "Daily Log" "warn" "No log for ${TODAY}" 2
fi

# Recent activity
RECENT_LOGS=$(find "$WORKSPACE/memory" -name "20*.md" -mtime -3 2>/dev/null | wc -l)
if [ "$RECENT_LOGS" -gt 0 ]; then
    add_check "MEMORY" "Recent Activity" "pass" "${RECENT_LOGS} logs in last 3 days" 1
else
    add_check "MEMORY" "Recent Activity" "critical" "No logs in 3 days — possible amnesia" 1
fi

# FEEDBACK-LOG or shared corrections
if [ -f "$WORKSPACE/shared-context/FEEDBACK-LOG.md" ] || [ -f "$WORKSPACE/FEEDBACK-LOG.md" ]; then
    add_check "MEMORY" "Feedback Log" "pass" "Exists" 1
else
    add_check "MEMORY" "Feedback Log" "warn" "No feedback log — corrections not shared" 1
fi

# ===== CALCULATE SCORE =====

echo "--- DETAILS ---"
echo -e "$DETAILS"
echo ""

# Raw percentage
if [ "$MAX_SCORE" -gt 0 ]; then
    RAW_PCT=$((SCORE * 100 / MAX_SCORE))
else
    RAW_PCT=0
fi

# Integrity multiplier
if [ "$CRITICAL_FAIL" -gt 0 ]; then
    FINAL_PCT=$((RAW_PCT * 33 / 100))
    MULT_LABEL="❌ CRITICAL (x0.33)"
elif [ "$WARNINGS" -gt 2 ]; then
    FINAL_PCT=$((RAW_PCT * 67 / 100))
    MULT_LABEL="⚠️ WARNING (x0.67)"
else
    FINAL_PCT=$RAW_PCT
    MULT_LABEL="✅ HEALTHY (x1.0)"
fi

# Letter grade
if [ "$FINAL_PCT" -ge 90 ]; then GRADE="A"
elif [ "$FINAL_PCT" -ge 80 ]; then GRADE="B"
elif [ "$FINAL_PCT" -ge 70 ]; then GRADE="C"
elif [ "$FINAL_PCT" -ge 50 ]; then GRADE="D"
else GRADE="F"
fi

echo "--- SCORE ---"
echo "  Raw: ${SCORE}/${MAX_SCORE} (${RAW_PCT}%)"
echo "  Integrity: ${MULT_LABEL}"
echo "  Final: ${FINAL_PCT}% — Grade ${GRADE}"

if [ "$CRITICAL_FAIL" -gt 0 ]; then
    echo ""
    echo "🚨 ${CRITICAL_FAIL} CRITICAL GATE(S) FAILED"
fi

echo ""
echo "=== END ==="
