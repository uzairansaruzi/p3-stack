# p3-stack contributor guide

p3-stack adapts [pstack](https://github.com/cursor/plugins/tree/main/pstack) by poteto for T3 Code. Same skills, same language, rewired to T3's native orchestration.

A skill reads as if it were written for T3 Code first. Keep pstack's sentences verbatim wherever they still apply. Replace every Cursor mechanism with the T3 Code equivalent below.

## Delegated workers

For a single-file porting assignment, the delegated brief names exactly one file. Write only that file, create parent directories as needed, and run no git commands. Report its path, line count, and changes to pstack's version. Other assignments use an outcome-sized scope with explicit write and git permissions.

## Cursor to T3 Code map

| pstack | p3-stack |
|---|---|
| `Task` tool, `subagent_type`, `run_in_background` | `delegate_task` with a self-contained brief; `mode: "async"` for background work; `task_status` to drain; `task_cancel` to stop |
| Model slugs (`claude-opus-5-5-max`, `grok-4.7-xhigh-fast`, `gpt-5.6-sol-max`) | Named roles resolved from `orchestrator_capabilities` by `setup-p3` (role names below). Never hardcode a slug. |
| "cloud agent", `environment: "cloud"`, `cloud_base_branch` | A delegated child task. Prepare its checkout and name the absolute path in the brief. `t3_thread_launch` requires an explicit user request for a separate top-level conversation. |
| "each worker gets its own worktree or branch" | Prepare isolated checkouts with the available worktree tooling, then use `delegate_task` with each checkout path and base ref in its brief. One writer per worktree. |
| `/loop`, poll loops, `scripts/watch-pr` | `watch_pull_request`: T3 watches the PR and wakes the thread on checks finishing, new comments, or conflicts. Arm it, end the turn, triage on wake. For other cadences use `schedule_task`. |
| Hourly audit ticks, recurring runs | `schedule_task` with `{"type":"interval","everyMs":...}` or `{"type":"fixed_time","timeOfDay":...,"weekdays":[...]}`; `run_scheduled_task_now` for an immediate run. |
| Stack bookkeeping with `gt`, manual PR lists | `link_pull_request` for every layer, immediately; `list_thread_pull_requests` returns the stack bottom to top. |
| `agent-transcripts/*.jsonl` mining | `t3_thread_read`, `t3_thread_search`; `t3_queue_list`/`t3_queue_read`/`t3_queue_edit`/`t3_queue_reorder`/`t3_queue_cancel`/`t3_queue_promote_to_steer` for queued input. |
| `AskQuestion` | Ask plainly in the thread. `t3_pending_request_list`/`t3_pending_request_read`/`t3_pending_request_respond` answer questions in other threads. |
| `control-ui`, `control-cli` (from cursor-team-kit) | `preview_*` browser tools and `device_*` simulator tools; `preview_recording_start`/`preview_recording_stop` and `device_screenshot` for evidence; `browser.preview` shows a file to the user. |
| `~/.cursor/rules/pstack-models.mdc`, `/add-plugin` | `setup-p3` writes `p3-models.md`; install is a symlink of `skills/*` into `~/.agents/skills/` (see README). |
| `poteto-mode`, `poteto-agent`, `poteto-help`, `setup-pstack` | `p3-mode`, `agents/p3-agent.md`, `p3-help`, `setup-p3`. |
| Cursor custom modes ("press option+enter") | Skills are invoked by name (`/p3-mode`). No mode toggles. |

Everything else in pstack transfers as written: the principles, the playbook shapes, the brief template, the reply style, the autonomy rules. Adopt it.

## Role names

Code work reads its line in `p3-models.md`: `feature, refactoring`, `bug-fix`, `perf-issue`, `hillclimb`. Prose and judgment read `judgment and prose`; the hardest changes read `hardest tasks`.

Panels and investigators: `how explorer`, `how explainer`, `why investigators`, `why synthesizer`, `arena runners`, `arena cross-judge pool`, `swarm workers`, `architect runners`, `interrogate reviewers`, `reflect tooling`, `reflect judgment, divergent, synthesizer`.

Keep these names exactly.

## Writing rules

- Thin over complete. Keep the shortest file that still changes behavior. Cut Cursor-only edge-case protocol and forge-specific branches before cutting any rule.
- pstack's voice: terse, declarative, lowercase-friendly, no filler.
- Frontmatter: `name`, one-line `description`, `disable-model-invocation: true` where the source has it. Drop Cursor UI fields (`icon`, `color`, `mode`, `reminder`).
- Use T3 tool names exactly: `delegate_task`, `task_status`, `watch_pull_request`, `link_pull_request`, `schedule_task`, `t3_thread_launch`, `t3_thread_read`, `t3_thread_search`, `preview_*`, `device_*`.
- Delegation briefs are self-contained. T3 child agents get only the brief, never the parent's context. Say this where pstack says "every brief stands alone".
- Never bullet a Cursor tool into a skill, even as a fallback.

## Layout

- `skills/<name>/SKILL.md` is a skill. `skills/principle-*/SKILL.md` are the short principles.
- `skills/p3-mode/SKILL.md` is the mode router; its playbooks live in `skills/p3-mode/playbooks/`.
- `agents/` holds prompt briefs for delegated roles (`p3-agent.md`, `comment-sicko.md`), not harness agent definitions.

## T3 tool quick reference

- Delegation: `delegate_task`, `task_status`, `task_cancel`, `orchestrator_capabilities`
- Threads: `t3_thread_launch`, `create_threads`, `t3_thread_list`, `t3_thread_read`, `t3_thread_search`, `t3_thread_send`, `t3_thread_wait`, `t3_thread_fork`, `t3_thread_merge_back`, `t3_thread_interrupt`, `t3_thread_organize`, `t3_thread_update`, `t3_thread_configure`
- Worktrees: `t3_worktree_status`, `t3_worktree_list`, `t3_worktree_handoff`
- Pull requests: `link_pull_request`, `list_thread_pull_requests`, `watch_pull_request`, `unwatch_pull_request`, `unlink_pull_request`
- Schedules: `schedule_task`, `list_scheduled_tasks`, `update_scheduled_task`, `delete_scheduled_task`, `run_scheduled_task_now`
- Queue: `t3_queue_list`, `t3_queue_read`, `t3_queue_edit`, `t3_queue_reorder`, `t3_queue_cancel`, `t3_queue_promote_to_steer`
- Preview: `preview_open`, `preview_navigate`, `preview_snapshot`, `preview_click`, `preview_type`, `preview_press`, `preview_scroll`, `preview_wait_for`, `preview_status`, `preview_resize`, `preview_set_appearance`, `preview_recording_start`, `preview_recording_stop`, `t3_preview_list`, `t3_preview_close`
- Devices: `device_list`, `device_open`, `device_screenshot`, `device_close`
- Pending requests: `t3_pending_request_list`, `t3_pending_request_read`, `t3_pending_request_respond`

## Definition of done for a skill

1. Every step names a T3 mechanism or a vendor-neutral habit. Grep for `Cursor`, `Task tool`, `subagent_type`, `cloud agent`, `.cursor`, `agent-transcripts`, `AskQuestion`, `icon:`, `claude-`, `grok-`, `gpt-`, `/loop`. None may remain.
2. It is shorter than the pstack source unless the T3 rewrite genuinely needs the lines.
3. Frontmatter matches the rules above, and references to other skills resolve to files in this repo.
