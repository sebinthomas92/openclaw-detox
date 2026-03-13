---
name: openclaw-hardening
description: Harden an OpenClaw agent system against the most common reliability failures — phantom progress, vanishing corrections, lying health scores, sloppy handoffs, and rules that agents cite but violate. Use when the user wants to audit, harden, or improve reliability of their OpenClaw setup. Also use when they mention "system audit," "agent reliability," "my agent keeps forgetting," "agent says done but nothing happened," "health check," "system score," or "stop my agents from lying." Based on 28 documented failure modes from real production OpenClaw systems.
---

# OpenClaw System Hardening

Stop your agent system from lying to you. This skill implements mechanical fixes for the most common OpenClaw reliability failures.

## What This Fixes

| Problem | Solution | Script |
|---------|----------|--------|
| Corrections vanish between sessions | `decisions.md` — persistent decisions log | `scripts/decisions-init.py` |
| "Done" with no proof | Evidence gates on task completion | Process rule |
| Agent says done, work reappears | Write-first-speak-second rule | Process rule |
| Health score lies while things break | 3-layer scoring + hard gates + integrity multiplier | `scripts/health-score.sh` |
| Agent claims files don't exist | Workspace inventory (anti-hallucination) | `scripts/workspace-inventory.sh` |
| Rules violated in same session they're cited | Enforcement checks (scripts > docs) | `scripts/enforce-check.sh` |
| Sloppy agent-to-agent handoffs | Handoff contract template | Process rule |
| New rules break existing behavior | Advisory mode (test before enforce) | Process rule |
| Config edits with no rollback | Snapshot-before-edit protocol | Process rule |

## Quick Start (Full Audit)

Run all checks in sequence:

```bash
# 1. Health score — how healthy is your system right now?
bash scripts/health-score.sh --workspace ~/your-workspace

# 2. Workspace inventory — what actually exists on disk?
bash scripts/workspace-inventory.sh ~/your-workspace

# 3. Enforcement checks — which rules are being followed?
bash scripts/enforce-check.sh ~/your-workspace
```

Review results. Fix critical gates first, then warnings.

## Implementation Guide

### Phase 1: Stop Forgetting (Day 1)

**Create decisions.md** — the single most impactful fix.

```bash
python3 scripts/decisions-init.py --workspace ~/your-workspace
```

This scans existing memory files for decisions and creates a structured `decisions.md`. Review the auto-discovered decisions and organize them into sections.

Then add `decisions.md` to your session boot sequence in AGENTS.md:

```markdown
## Every Session
1. Read SOUL.md
2. Read USER.md
3. Read decisions.md ← ADD THIS (before MEMORY.md)
4. Read memory/YYYY-MM-DD.md
5. Read MEMORY.md
```

**Rule:** Every time the user says "stop doing X" or "always do Y" — write it to `decisions.md` immediately. If it's not in the file, it didn't happen.

Template: See `references/decisions-template.md`

### Phase 2: Stop Lying (Day 2-3)

**Add "Write First, Speak Second" to AGENTS.md and any shared feedback log:**

```markdown
## Write First, Speak Second (MANDATORY)
Always persist state to disk BEFORE reporting completion in chat.
1. Save/commit the actual work
2. Mark task done in tracking
3. THEN report "done" in chat
```

**Add evidence requirements for task completion:**

Every "done" claim must include:
- What changed (brief description)
- Where (file paths, URLs, or commit hash)
- Proof it works (test result, screenshot, curl output)

No proof = not done.

**Add structured reporting.** Replace narrative status updates with pass/fail:

```bash
bash scripts/health-score.sh
```

Never accept "things look good" as a status report. Require explicit pass/fail per system.

### Phase 3: Stop Breaking (Day 4-5)

**Advisory mode for new rules.** Before enforcing any new rule:

1. Announce as "advisory only" — log what WOULD happen
2. Run 24 hours in advisory mode
3. Review what would have broken
4. Only then enforce

**Snapshot before editing critical files:**

```bash
cp AGENTS.md AGENTS.md.bak-$(date +%s)
cp decisions.md decisions.md.bak-$(date +%s)
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-$(date +%s)
```

**Handoff contracts for multi-agent systems.** Every agent-to-agent task must include:

- From / To / Task / Context / Deliverable / Deadline / Evidence required

### Phase 4: Enforce Mechanically (Ongoing)

Run enforcement checks regularly:

```bash
bash scripts/enforce-check.sh ~/your-workspace
```

**The key insight:** Rules in docs = ~48% compliance. Rules backed by scripts = ~100%.

Every time a rule is violated twice, convert it from documentation into a script that mechanically checks or enforces it.

## Health Score Explained

The health score uses 3 layers:

1. **Letter grade** (A-F) — quick readability
2. **Category scores** — where problems are (Gates, Infrastructure, Memory, Agents)
3. **Hard gates** — critical checks that can't be averaged away

**Integrity multiplier:**
- All gates pass → score × 1.0 (normal)
- 3+ warnings → score × 0.67 (degraded)
- Any critical gate fails → score × 0.33 (system is lying to you)

This catches the most dangerous failure mode: high activity with broken integrity showing as a good score.

## Reference

For the complete list of 28 failure modes and the fix order, see `references/28-mistakes.md`.
