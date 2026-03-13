# The 28 Mistakes — Quick Reference


## The Mistakes (Condensed)

1. **Loose trigger words** — Use exact matching, not fuzzy. Test with weird inputs.
2. **Flat agent hierarchy** — Use chain of command: orchestrator → leads → workers → subagents.
3. **Sloppy handoffs** — Carry: who, what, when, where, evidence. Context degrades at every hop.
4. **Wrong rule setup order** — Identity files first → routing → communication contracts → stress test.
5. **Parallel file conflicts** — Define ownership before parallelizing.
6. **Agent silence** — Fast ack first, then work. Long tasks in separate sessions.
7. **Multi-problem asks** — One problem per agent. Atomic scope, clean output.
8. **Session death loses work** — Commit incrementally. Small saves, frequent commits.
9. **"Done" without evidence** — Require: repo, branch, commit, files changed, verification.
10. **Polling loops** — Wait for events, don't check every 5 seconds.
11. **Corrections vanish** — Write to decisions.md in the same session. Load at every boot.
12. **Phantom progress** — Write first, speak second. Persist before reporting.
13. **False CLI summaries** — Source files are truth. CLI output is a view, not reality.
14. **"File doesn't exist"** — Usually wrong path. Use inventory scripts to ground claims.
15. **Useless cron jobs** — Cut anything that doesn't produce actionable output.
16. **Noisy cron output** — Standardize: what happened / why / what's next / confidence / evidence.
17. **Duplicate processes** — Don't run two instances. Fix broken loops, don't stack new ones.
18. **Lying health scores** — 3-layer scoring + hard gates + integrity multiplier.
19. **Narrative status updates** — Structured pass/fail, not "things look good."
20. **Safety checks skipped under pressure** — Sequential gates with explicit pass/fail.
21. **Untested rule changes** — Advisory mode first. Log what would happen before enforcing.
22. **No config snapshots** — Snapshot before every change. Recovery without backup = 10x time.
23. **Rules as docs = 48% compliance** — Rules as scripts = ~100%. Turn violations into gates.
24. **Irreversible actions** — Branch first, pause before merge, human checkpoint.
25. **Prompt drift** — Instructions drift over time. Scripts enforce. Docs suggest.
26. **"Random" bugs** — Not random. Find the specific boundary causing the behavior.
27. **Duplicate repos** — One location per repo. Audit regularly.
28. **Bulk security fixes** — One fix at a time, with snapshot + rollback at each step.

## The Fix Order

1. Context gate (load corrections/decisions before responding)
2. Decisions log (every redirect saved permanently)
3. Evidence gate (receipts for every "done" claim)
4. Health score (timestamps, freshness, category detail, hard gates)
5. Integrity multiplier (high activity + broken integrity = bad score)
6. Script every repeated failure (corrected twice → mechanical gate)

## Core Thesis

> "The unlock is not better prompts. The unlock is operational mechanics."

Rules in docs = suggestions. Scripts that run = enforcement.
48% compliance (docs) vs ~100% compliance (scripts).
