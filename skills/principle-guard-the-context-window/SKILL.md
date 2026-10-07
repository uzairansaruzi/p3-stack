---
name: principle-guard-the-context-window
description: "Apply before broad discovery or verbose output, and when context is filling up. Route bulk to delegated tasks; keep summaries in the main thread, not raw payloads."
disable-model-invocation: true
---

# Guard the Context Window

The context window is finite and non-renewable within a session. Every token should be worth its cost.

**Why:** Context overflow degrades reasoning quality, creates compression artifacts, and halts progress.

**Pattern:**
- Coordinators: before broad discovery, assign substantial investigation, implementation, conflict resolution, or verbose validation to a bounded `delegate_task`. Keep trivial edits and targeted, small reads inline. Size the unit around an outcome, not one agent per file.
- **Isolate large payloads.** Route verbose outputs, screenshots, and large documents to `delegate_task` workers. The main context gets summaries, not raw data.
- **Keep frequently used content inline.** Templates and references used on every invocation belong in the skill file, not in separate files that cost a read each time.
- **Size phases and cap scope.** Limit files per phase, set turn budgets, account for mechanism costs.
- Ask workers for a report of at most 300 words with status, evidence, verification and blockers. Put raw logs and detailed findings in files and return their paths. Open only the evidence needed for a decision.
- Replace the current handoff at checkpoints with the goal, current branch and SHA, applicable authorizations and constraints, decisions, blockers, evidence paths and next action. Keep history in artifacts instead of copying it into each new brief.
- Use completion notifications and `watch_pull_request` for waiting. Check `task_status` when a decision needs live status, with bounded retries.
- Bounded workers keep reads and output within their assigned scope. Delegate only when the brief grants it; otherwise return a scope or context blocker with the findings already obtained.
