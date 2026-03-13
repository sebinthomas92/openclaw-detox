# 🧹 openclaw-detox

[![Claude Skill](https://img.shields.io/badge/Claude-Skill-orange?logo=anthropic&logoColor=white)](https://github.com/sebinthomas92/openclaw-detox) [![OpenClaw](https://img.shields.io/badge/OpenClaw-Compatible-blue)](https://docs.openclaw.ai) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **A Claude Skill for [OpenClaw](https://docs.openclaw.ai)** — Install with `openclaw skills install openclaw-detox.skill` or drop the folder into your skills directory.

**Your agent system is poisoned. This is the cure.**

Your OpenClaw agents are lying to you. They say "done" when nothing happened. They forget corrections you gave them 10 minutes ago. Their health scores say 94% while critical stuff is failing underneath. And every config you imported from someone else's setup made it worse.

This skill detoxes your system — replacing documentation-based rules (48% compliance) with mechanical enforcement (~100% compliance).


---

## What It Fixes

| Symptom | Diagnosis | Cure |
|---------|-----------|------|
| "I told my agent to stop doing X. It did X again next session." | Corrections vanish between sessions | `decisions.md` — persistent decisions log, loaded every boot |
| "Agent said task complete. Nothing actually changed." | Phantom progress — reported before saved | Write-first-speak-second protocol |
| "Health score shows 94% but everything is broken." | Stale scores averaging away critical failures | 3-layer health scoring + hard gates + integrity multiplier |
| "Agent says file doesn't exist. It absolutely does." | Checked wrong path, hallucinated the rest | Workspace inventory — anti-hallucination audit |
| "I wrote the rule in 3 files. Agent violated it in the same session." | Rules as docs = suggestions | Enforcement scripts (docs → mechanical gates) |
| "New rule broke 3 things that were working." | No testing before enforcement | Advisory mode — test rules before deploying |
| "Config edit broke everything, no way to roll back." | No snapshots before changes | Snapshot-before-edit protocol |

---

## Quick Start

### Install

```bash
# Option 1: Install as OpenClaw skill
openclaw skills install openclaw-detox.skill

# Option 2: Clone and copy to your skills directory
git clone https://github.com/sebinthomas92/openclaw-detox.git
cp -r openclaw-detox /path/to/your/skills/
```

### Run the Full Detox

```bash
# Step 1: How sick is your system? (Health score with hard gates)
bash scripts/health-score.sh --workspace ~/your-workspace

# Step 2: What actually exists? (Anti-hallucination inventory)
bash scripts/workspace-inventory.sh ~/your-workspace

# Step 3: Which rules are being followed? (Enforcement audit)
bash scripts/enforce-check.sh ~/your-workspace

# Step 4: Bootstrap your decisions log (stop forgetting corrections)
python3 scripts/decisions-init.py --workspace ~/your-workspace
```

Or just tell your agent: *"Run a system detox"*

---

## The Detox Protocol

### Phase 1: Stop Forgetting (Day 1)

**Create `decisions.md`** — the single highest-impact fix.

Every time you tell your agent "stop doing X" or "always do Y," it goes in this file immediately. Loaded at every session start. If it's not in the file, it didn't happen.

```bash
python3 scripts/decisions-init.py --workspace ~/your-workspace
```

Then add it to your boot sequence in AGENTS.md:

```markdown
## Every Session
1. Read SOUL.md
2. Read USER.md  
3. Read decisions.md  ← THIS CHANGES EVERYTHING
4. Read MEMORY.md
```

### Phase 2: Stop Lying (Day 2-3)

**Write first, speak second.** Agents must save work to disk *before* reporting "done" in chat. If the session dies between "done" and the actual save, the work reappears as undone next session. Flip the order.

**Evidence gates.** No task is "done" without:
- What changed
- Where (file path, URL, or commit hash)
- Proof it works

No receipts? Not done. Like a kid saying they brushed their teeth — you want to see those pearly whites.

**Structured reports.** Replace "things look good" with pass/fail per system:

```bash
bash scripts/health-score.sh
```

### Phase 3: Stop Breaking (Day 4-5)

**Advisory mode.** Before enforcing any new rule, run it in log-only mode for 24 hours. See what would break. Fix conflicts before going live.

**Snapshot everything.** Before editing any critical file:
```bash
cp AGENTS.md AGENTS.md.bak-$(date +%s)
```

**Handoff contracts.** Every agent-to-agent task must include: From, To, Task, Context, Deliverable, Deadline, Evidence required.

### Phase 4: Enforce Mechanically (Ongoing)

The insight that changes everything:

> **Rules in docs = ~48% compliance. Rules as scripts = ~100%.**

Every time a rule gets violated twice, stop adding more documentation. Convert it into a script that mechanically checks or enforces it.

```bash
bash scripts/enforce-check.sh ~/your-workspace
```

---

## Health Score Explained

Three layers, because single scores lie:

| Layer | Purpose |
|-------|---------|
| **Letter Grade** (A-F) | Quick readability |
| **Category Scores** | Where problems are (Gates, Infra, Memory, Agents) |
| **Hard Gates** | Critical checks that can't be averaged away |

**The integrity multiplier** — the secret weapon:

- All gates pass → score × 1.0 *(normal)*
- 3+ warnings → score × 0.67 *(degraded)*  
- Any critical gate fails → score × 0.33 *(your system is lying to you)*

This catches the most dangerous failure: high activity + broken integrity looking like a healthy system.

---

## Scripts

| Script | What It Does |
|--------|-------------|
| `health-score.sh` | Grades your system A-F with hard gates that can't be gamed |
| `workspace-inventory.sh` | Counts what's real on disk — repos, skills, configs, memory files |
| `enforce-check.sh` | Measures rule compliance (%) — are your rules being followed? |
| `decisions-init.py` | Scans your existing files and bootstraps a `decisions.md` |

---

## The Core Problem

> *"I didn't fail from a lack of plans. I failed from gaps between what I planned and what was actually enforced at runtime."*

Every OpenClaw system eventually hits this wall. You write beautiful rules. Your agents cite those rules. Then they violate them in the same session. You correct them. They forget by next session. You import someone else's config thinking it'll help. It makes everything worse.

**The unlock is not better prompts. The unlock is operational mechanics.**

This skill is the operational mechanics.

---


## License

MIT — do whatever you want with it.
