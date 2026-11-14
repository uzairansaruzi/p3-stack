# p3-stack

p3-stack is [pstack](https://github.com/cursor/plugins/tree/main/pstack) rebuilt for T3 Code, synced to upstream `c742dd6` (see [UPSTREAM.md](UPSTREAM.md)). Same engineering discipline, native T3 orchestration.

pstack is poteto's answer to AI slop code. It turns an agent into an engineering team: one mode skill that routes to playbooks, principles that ground every decision, and verification strict enough that you can parallelize with confidence. p3-stack keeps that system and rewires the mechanics to T3 Code's primitives:

- **Delegation.** `delegate_task` child agents replace Cursor's Task tool, with per-role providers and models resolved from `orchestrator_capabilities`. Cross-model panels are native.
- **Worktrees.** `delegate_task` with `isolation: "worktree"` gives each writer its own checkout. One writer per worktree, enforced by the app instead of by advice.
- **Watching.** `watch_pull_request` wakes the thread when checks finish, someone comments, or the branch conflicts. No polling loops.
- **Scheduling.** `schedule_task` runs audits and overnight cadences even when no turn is active. No `/loop`.
- **Memory.** `t3_thread_read` and `t3_thread_search` replace mining Cursor transcript files.
- **Proof.** `preview_*` browser tools and `device_*` simulators replace external control skills. Screenshots and recordings land in the thread.

## Install

Three steps on a new machine.

```bash
git clone https://github.com/maxzero66/p3-stack.git
cd p3-stack && ./install.sh
```

Then open a new thread and run `/setup-p3`, which maps each role to a model.

One command covers every harness already on the machine, at user level:

| Directory | Harness |
|---|---|
| `~/.agents/skills/` | codex, tcodex, T3 Codex (created when missing) |
| `<config home>/skills/` | claude, tclaude, T3 Claude, for each of `$CLAUDE_CONFIG_DIR`, `~/.tclaude`, `~/.claude` that exists |

A name that is already taken is skipped and reported, never deleted or replaced. A name counts as p3-stack's only when it is a symlink into this repo. Codex reads `~/.tcodex/skills/`, `~/.codex/skills/`, and `$CODEX_HOME/skills/` beside `~/.agents/skills/`, so a name taken in any of those is skipped too. `--replace <name>` takes one over and prints what it pointed at first. `--target <dir>` installs somewhere else, `--project /path/to/repo` installs into `<repo>/.agents/skills/` and `<repo>/.claude/skills/`, `--uninstall` removes only the links that point into this repo, and `--dry-run` prints the plan with no changes.

Skills are symlinked. Their `../<name>` and `../../agents/` references hold once the link is resolved to its real path, which `p3-mode` tells the agent to do, so they land in this repo's own `skills/` and `agents/` even when the install directory has a different skill under the same name; nothing else needs linking. Read literally from the install directory, they do not. Rerunning `./install.sh` after a pull or a move is safe: it repoints links from another p3-stack checkout that still exists and prunes links to skills that no longer exist. `install.sh` takes no GNU-only flags and runs on macOS as well as Linux. `p3-mode/scripts/check-plan.mjs` needs Node 20.11 or newer.

## Get started

1. Run `/setup-p3`. It reads `orchestrator_capabilities` and writes `p3-models.md`, mapping each role (code, judgment, the review panels) to a provider and model you actually have.
2. Use `/p3-mode` whenever you want rigorous work. It reads the request, picks a playbook, and runs the other skills as the steps need them.
3. Stuck or unsure which skill fits? Ask `/p3-help`.

## The mode

`p3-mode` routes every task. Its playbooks: investigation, bug fix, perf issue, hillclimb, runtime forensics, trace forensics, feature, refactoring, prototype, visual parity, authoring a skill, eval, babysit, shipping, autonomous run, orchestrate, autopilot-full, autopilot-stack, session pickup, pause safely, multi-phase plan, worktree cleanup, opening a PR.

## Skills

architect, arena, automate-me, benchmark-checklist, blast-radius, bro, correct, create-formal-verification-skill, create-verification-skill, figure-it-out, how, in-your-own-words, interrogate, ketchup, ketchup-video, maintain-formal-verification-skill, maintain-verification-skill, make-bot-ui, no-comments, p3-help, recall, reflect, setup-p3, sharpen, show-me-your-work, statechart, swarm, tdd, teach, technical-writing, typescript-best-practices, unslop, why.

## Principles

The twenty-four principle skills are indexed inside `p3-mode` and referenced by the other skills by name.

## Credit

p3-stack adapts [pstack](https://github.com/cursor/plugins/tree/main/pstack) by [poteto](https://x.com/poteto). The skills, principles, and language are hers; the T3 Code rewiring is this repo's. MIT, see [LICENSE](LICENSE).
