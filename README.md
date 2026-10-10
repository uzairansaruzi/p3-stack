# p3-stack

p3-stack is [pstack](https://github.com/cursor/plugins/tree/main/pstack) rebuilt for T3 Code. Same engineering discipline, native T3 orchestration.

pstack is poteto's answer to AI slop code. It turns an agent into an engineering team: one mode skill that routes to playbooks, principles that ground every decision, and verification strict enough that you can parallelize with confidence. p3-stack keeps that system and rewires the mechanics to T3 Code's primitives:

- **Delegation.** `delegate_task` child agents replace Cursor's Task tool, with per-role providers and models resolved from `orchestrator_capabilities`. Cross-model panels are native.
- **Worktrees.** Parents prepare isolated worktrees and name their absolute paths in child briefs. CLI cwd does not change the inherited T3 binding. Keep one writer per worktree.
- **Conversations.** `t3_thread_launch` creates a bound top-level conversation only when the user explicitly requests an independent one. A directory or branch alone does not authorize it.
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

## The mode

`p3-mode` routes every task. Its playbooks: investigation, bug fix, perf issue, hillclimb, runtime forensics, trace forensics, feature, refactoring, prototype, visual parity, authoring a skill, eval, babysit, shipping, autonomous run, orchestrate, autopilot-full, autopilot-stack, session pickup, pause safely, multi-phase plan, worktree cleanup, opening a PR.

## Skills

architect, arena, automate-me, benchmark-checklist, blast-radius, bro, correct, create-verification-skill, figure-it-out, how, interrogate, maintain-verification-skill, make-bot-ui, no-comments, p3-help, recall, reflect, setup-p3, show-me-your-work, swarm, tdd, teach, technical-writing, typescript-best-practices, unslop, why.

## Principles

The twenty-four principle skills are indexed inside `p3-mode` and referenced by the other skills by name.

## Validate the package

Run `node scripts/check-package.mjs` and `node --test scripts/check-package.test.mjs scripts/check-briefings.test.mjs scripts/briefing-recorder.test.mjs` from the repository root. The checker validates flat skill frontmatter and relative inline Markdown links outside code. Links from skills stay inside the installed skill directories. It checks target existence and skips heading fragments. Reference-style links and general YAML are outside its scope.

To check tool selection with actual model calls, run `node scripts/check-briefings.mjs <new-artifact-directory> <model> <effort>`. Choose the model and effort from a configured role and the live catalog. This requires an authenticated Codex CLI with the isolation flags shown in the script. Each of the three briefings has a 180-second deadline, and a 12-call recorder limit.

The local MCP recorder intercepts calls and returns fixture results. It cannot launch live conversations or delegated tasks. Receipts contain recorder tools, instruction and harness hashes, models and options from the run metadata, calls, and available usage. Each run is ephemeral. The recorder captures the actual model and effort from Codex MCP turn metadata, and saves the CLI invocation. Cost and active author time remain unknown. Missing calls, unexpected tools, timeouts, and authentication failures fail the run. These checks prove routing under the supplied instructions and tool descriptions, not live T3 workspace creation or the instructions' causal effect.

## Credit

p3-stack adapts [pstack](https://github.com/cursor/plugins/tree/main/pstack) by [poteto](https://x.com/poteto). The skills, principles, and language are hers; the T3 Code rewiring is this repo's. MIT, see [LICENSE](LICENSE).
