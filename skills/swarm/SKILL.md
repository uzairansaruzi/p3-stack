---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
disable-model-invocation: true
---

# Swarm

## Start

Open a todolist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Pick the worker model from the `swarm workers` line in `p3-models.md`, resolved through `orchestrator_capabilities`. If the file or that line is missing, run `setup-p3`. For `inherit-parent`, omit `target` so the workers run on the parent model. If `delegate_task` rejects the target, fall back to the closest valid model of the same family from `orchestrator_capabilities` and say so. For a model race, name each arm's model up front. Pick each child's reasoning level for the job, per the Subagents section of the **p3-mode** skill, and put it in `target.options`.
4. Give each worker its own writable output when it writes. When workers verify or measure commits, each brief names the exact SHAs. A measurement brief also names the method (sample count, what one sample is, order). The worker records both in its result.

## Phase B: Fan out

Spawn all N workers in one turn with `delegate_task`, `mode: "async"`, and the step 3 target, left unset for `inherit-parent`. Give every worker that writes `isolation: "worktree"`, so each has its own checkout and one writer per worktree. When a worker must start from a non-default pushed branch or SHA, its brief opens with `git fetch && git checkout <ref>`, because a worktree starts at the parent commit.

Every brief stands alone. Child agents get only the brief, never the parent's context. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence. A worker that can prove a defect reports `ISSUES` and lists every issue it can prove, not only the first.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Drain per the Subagents section of the **p3-mode** skill: end the turn after the spawn, and read each worker's result with `task_status` when its completion wakes you, until every worker is terminal. Drop a result that does not record the SHAs and method its brief names, and respawn that worker once. After a second miss, record a gap. A gap does not count as a pass. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

## Phase D: Report

Return one consolidated in-chat report with a result table, issue one-liners, gaps or dropouts, and the race rule when used.
