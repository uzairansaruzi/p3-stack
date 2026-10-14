---
name: principle-guard-the-context-window
description: "Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Route bulk to delegated tasks; keep summaries in the main thread, not raw payloads."
disable-model-invocation: true
---

# Guard the Context Window

The context window is finite and non-renewable within a session. Every token should be worth its cost.

**Why:** Context overflow degrades reasoning quality, creates compression artifacts, and halts progress.

**Pattern:**
- **Guard every worker too.** Moving bulk to a child does not make it free. Give each worker a bounded question, the file paths it needs, and a compact report contract. Its own reads and results must stay within that scope.
- **Keep bulk in artifacts.** Write full logs, traces, and generated data to files. Return a summary with the result, relevant measurements or failures, and artifact paths. Read targeted sections when the summary leaves a specific question unanswered.
- **Avoid repeated reads.** Reuse facts and skills already loaded in the current conversation. A fresh worker still needs its own instructions. Pass paths and a small handoff, not the parent's transcript or every sibling report.
- **Keep frequently used content inline.** Templates and references used on every invocation belong in the skill file, not in separate files that cost a read each time.
- **Size phases and cap scope.** Limit files and turns per phase. Count child work in the parent's budget. Read the [shared usage policy](../p3-mode/references/usage-policy.md) before spawning or running a long tool.
