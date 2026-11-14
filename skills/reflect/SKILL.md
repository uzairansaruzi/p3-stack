---
name: reflect
description: Delegate three parallel reviewers over the active thread, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
disable-model-invocation: true
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## 1. Locate the active transcript

The transcript is the current T3 thread. Find its id with `t3_thread_search` on the thread's title or the task's first words, or with `t3_thread_list` (newest first), and confirm it by its first user message. If you cannot get the id, use the tight digest described below. Read it with `t3_thread_read`; use `t3_thread_search` to pull exact passages. Do not search across other threads. That crosses workspace boundaries and reads private chats from unrelated projects.

Reviewers get only their brief, never the parent's context. Pass the thread id and tell them to read it with `t3_thread_read`, or pass a tight digest of the session instead.

## 2. Delegate three reviewers in parallel

One turn, three `delegate_task` calls with `mode: "async"`. Reviewers need tool access to look up the tickets, chat threads, and observability traces the transcript references, so do not restrict their tools.

Resolve each model from the role line in `p3-models.md` via `orchestrator_capabilities`. Never hardcode a slug. Set each delegate's effort in `target.options`, plus speed (`fastMode` or `serviceTier`) when the model offers it, per the Subagents section of the **p3-mode** skill.

| Lens | Role line | Prompt template |
|---|---|---|
| Judgment | `reflect judgment, divergent, synthesizer` | `references/judgment-reviewer.md` |
| Tooling | `reflect tooling` | `references/tooling-reviewer.md` |
| Divergent | `reflect judgment, divergent, synthesizer` | `references/divergent-reviewer.md` |

Pass each template verbatim as the brief, substituting the thread id or digest where marked. Drain with `task_status`; reviewers return findings in their task result.

## 3. Synthesize

One `delegate_task` call, model from the `reflect judgment, divergent, synthesizer` line. It spot-verifies citations, which can require tool access. Pass `references/synthesizer.md` verbatim as the brief, with each reviewer's full output inlined where marked. It returns an Accepted / Rejected / Backlog list.

## 4. Structural enforcement check

Move any Accepted item that a lint rule, script, metadata flag, or runtime check would enforce more reliably to Backlog. See the **encode-lessons-in-structure** principle skill.

## 5. Apply

Present the synthesizer's full Accepted / Rejected / Backlog output and wait for explicit approval before applying any Accepted edit. The user picks the subset and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

File each Backlog item to your team's devex or backlog tracker without waiting. Only the Accepted list waits for approval.

Before approval, show each skill's destination, `.agents/skills/<skill>/` or `~/.agents/skills/<skill>/`. After approval, edit the skill there. Never open a PR or push.

Follow each approved row's Routing exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): the parent does it directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): follow the authoring-a-skill playbook and run its draft / test / iterate loop.
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): follow the authoring-a-skill playbook and run its description-optimization loop.
- `new skill via authoring-a-skill: <kebab-name>`: hand creation to the authoring-a-skill playbook. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done.

## 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
