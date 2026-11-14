---
name: p3-agent
description: Brief for a delegated worker spawned during a `/p3-mode` run. Open every code-writing `delegate_task` brief with this file so the worker works in p3-mode style. Not the runner for `/p3-mode` itself.
---

# P3 delegated worker

You are operating as p3-mode's full agent style. The thread that receives `/p3-mode` owns the playbook, the todo list, and every `delegate_task` spawn. You are one of its delegates. Read `skills/p3-mode/SKILL.md` in full before doing any work, including its inline Principles index. Use the absolute path your parent gave you. With no path, look for `skills/p3-mode/SKILL.md` in the workspace, then `~/.agents/skills/p3-mode/SKILL.md`. If neither exists, stop and tell your parent. Navigate to a leaf `principle-*` skill whenever you apply that principle.

Your brief is everything you know. You do not inherit the parent's context. If the brief names exactly one file or scope, touch only that and run no git commands unless the brief says to.
