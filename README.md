# p3-stack

p3-stack is [pstack](https://github.com/cursor/plugins/tree/main/pstack) rebuilt for T3 Code. Same engineering discipline, native T3 orchestration.

pstack is poteto's answer to AI slop code. It turns an agent into an engineering team: one mode skill that routes to playbooks, principles that ground every decision, and verification strict enough that you can parallelize with confidence. p3-stack keeps that system and rewires the mechanics to T3 Code's primitives:

- **Delegation.** `delegate_task` child agents replace Cursor's Task tool, with per-role providers and models resolved from `orchestrator_capabilities`. Cross-model panels are native.
- **Worktrees.** `t3_thread_launch` binds a worker to its own worktree and branch. One writer per worktree, enforced by the app instead of by advice.
- **Watching.** `watch_pull_request` wakes the thread when checks finish, someone comments, or the branch conflicts. No polling loops.
- **Scheduling.** `schedule_task` runs audits and overnight cadences even when no turn is active. No `/loop`.
- **Memory.** `t3_thread_read` and `t3_thread_search` replace mining Cursor transcript files.
- **Proof.** `preview_*` browser tools and `device_*` simulators replace external control skills. Screenshots and recordings land in the thread.

## Install

```bash
git clone https://github.com/uzairansaruzi/p3-stack.git
cd p3-stack
./install.sh
```

`install.sh` links every `skills/*` directory into `~/.agents/skills/`, where T3 Code reads skills. Use `./install.sh --project /path/to/repo` to install into a project's `.agents/skills/` instead.

## Get started

1. Run `/setup-p3`. It reads `orchestrator_capabilities` and writes `p3-models.md`, mapping each role (code, judgment, the review panels) to a provider and model you actually have.
2. Use `/p3-mode` whenever you want rigorous work. It reads the request, picks a playbook, and runs the other skills as the steps need them.
3. Stuck or unsure which skill fits? Ask `/p3-help`.

## Model profiles

`/setup-p3` defaults to `~/.agents/p3-models.md`. Keep named profiles there and route repos by their Git origin:

```md
# p3 model configuration

## profile: personal
# budget: medium (high)
feature, refactoring: <personalProviderId>/<model> (high)

## profile: work
# budget: medium (high)
feature, refactoring: <workProviderId>/<model> (high)
arena runners: <workProviderId>/<model>, <anotherWorkProviderId>/<model>

## projects
default: personal
github.com/acme/*: work
```

Setup fills the full role table from the live catalog. Each entry names an account-specific provider instance and model directly; no separate provider list is needed. Missing profile roles require configuration, and retries stay on the configured provider instance. Parent aliases explicitly follow the current parent account. These are agent instructions, not a T3-enforced security boundary.

SSH and HTTPS origins normalize to `host/owner/repo`; worktrees share the same routing. Exact mappings beat wildcard mappings; otherwise the longest prefix wins. No match or no origin uses `default`; a present unsupported origin requires correction. Nondefault ports are retained, and wildcards match literal path prefixes. Invalid mappings stop delegation. See [model resolution](skills/setup-p3/model-resolution.md) for the rules.

A project-root `p3-models.md` still replaces the global file. Legacy flat files remain supported; setup previews their migration before writing. Re-running setup edits only the selected profile or mappings, preserving the rest.

## The mode

`p3-mode` routes every task. Its playbooks: investigation, bug fix, perf issue, hillclimb, runtime forensics, trace forensics, feature, refactoring, prototype, visual parity, authoring a skill, eval, babysit, shipping, autonomous run, orchestrate, autopilot-full, autopilot-stack, session pickup, pause safely, multi-phase plan, worktree cleanup, opening a PR.

## Skills

architect, arena, automate-me, benchmark-checklist, blast-radius, bro, correct, create-verification-skill, figure-it-out, how, interrogate, maintain-verification-skill, make-bot-ui, no-comments, p3-help, recall, reflect, setup-p3, show-me-your-work, swarm, tdd, teach, technical-writing, typescript-best-practices, unslop, why.

## Principles

The twenty-four principle skills are indexed inside `p3-mode` and referenced by the other skills by name.

## Credit

p3-stack adapts [pstack](https://github.com/cursor/plugins/tree/main/pstack) by [poteto](https://x.com/poteto). The skills, principles, and language are hers; the T3 Code rewiring is this repo's. MIT, see [LICENSE](LICENSE).
