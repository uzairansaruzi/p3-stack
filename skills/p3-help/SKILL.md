---
name: p3-help
description: Guides users through p3-stack setup, /p3-mode, and picking the skill, playbook, or principle for a task. Use for /p3-help, or when the user asks how to install, set up, or use p3-stack, or which p3-stack skill fits. Not for requests to do work, even ones that name p3-stack.
---

# P3 help

Answer the user's question about p3-stack, hand them a prompt they can send, and link the file the answer came from. For a help question, don't start the work. The user asked how, and a p3-stack run spends real tokens, so let them send the prompt.

A message that asks for work, such as "use p3-stack to fix this bug", is not a help question. Read [`p3-mode`](../p3-mode/SKILL.md), do the work under it, and mention once that invoking `/p3-mode` keeps the work in this style.

This file maps questions to the skills and playbooks that hold the answers. Those files own the details. Read the file you route to before you quote it, and trust it when it disagrees with this map. The links here are repo-relative, so give the user the file's public copy: `https://github.com/uzairansaruzi/p3-stack/blob/main/` followed by its path.

## Find out what they need

Infer the need from the message and the conversation. A named situation, such as "which skill reviews a PR?", goes straight to its section. If the need is still unclear, ask one multiple-choice question with these options, then answer only the section they pick: get set up, start a task with `/p3-mode`, pick a skill for a situation, fix a run that went wrong, or make p3-stack my own.

Check the state that changes the answer, and mention it only when it does. Read [model resolution](../setup-p3/model-resolution.md) to check project and global configuration, the Git mapping, active profile, and role targets. With neither file, roles use skill defaults. No `verify-*` skill or other app harness in the project means agents have no scripted way to drive the app; mention `/create-verification-skill` when the question is about proving a change works.

## Get set up

1. Install by cloning the repo and running `./install.sh`. It links every skill into `~/.agents/skills/`, where T3 Code reads skills; `./install.sh --project /path/to/repo` targets a project's `.agents/skills/` instead.
2. Run [`/setup-p3`](../setup-p3/SKILL.md). It edits a model profile or Git remote mappings in `p3-models.md`, with explicit provider/model targets per role and a reasoning budget. The file applies to new sessions.
3. Start a real task with `/p3-mode`, a goal, and a check that can pass or fail.

Installing changes nothing until the user invokes a skill. Only `/p3-help` loads from the user's words. The [README](../../README.md) has the details. Offer to word their first prompt with them.

If cost is the worry, say where the tokens go and how to spend fewer. p3-stack spends extra tokens on subagents and review panels. Rerun `/setup-p3` and pick a smaller budget or cheaper models. A parent alias explicitly uses the current parent account and model; use a provider/model target to pin an account. It saves tokens when the parent model is cheaper. A shorter panel list runs fewer subagents, one for each entry. Save `/p3-mode` for work that needs rigor.

## Start a task with `/p3-mode`

`/p3-mode` matches the task to a playbook, copies the playbook's steps into the todo list, and runs the other skills as the steps need them. A step it skips stays in the list as `skip: <reason>`. A good prompt states the goal and how to tell it's done. It doesn't list skills, because a hand-written sequence tends to drop or reorder steps the playbook would keep.

Skills are invoked by name (`/p3-mode`). There are no mode toggles, so start each new task with `/p3-mode`. Mid-chat, "new task" makes the mode match a fresh playbook. `/p3-mode` already uses `agents/p3-agent.md` for the delegates its playbook steps spawn. To get the same style from a delegate of your own, open its brief with `agents/p3-agent.md`.

## Pick a skill

The default answer is `/p3-mode`, which runs most of the others when its steps need them. Name a skill directly when the user wants more or less of something than the playbook gives. Read the skill before you recommend it, and give one example prompt.

| The user wants to | Skill |
|---|---|
| Do any non-trivial task with rigor | [`/p3-mode`](../p3-mode/SKILL.md) |
| Know how code works now, or where new code should live | [`/how`](../how/SKILL.md) |
| Know why code is shaped this way, or where a number came from | [`/why`](../why/SKILL.md) |
| Understand a change or subsystem, explained plainly | [`/teach`](../teach/SKILL.md) |
| Catch up on their own recent work on a topic | [`/recall`](../recall/SKILL.md) |
| Know what a small diff could break outside itself | [`/blast-radius`](../blast-radius/SKILL.md) |
| Settle types and module shape before code that crosses a function boundary | [`/architect`](../architect/SKILL.md) |
| Get several attempts at one brief, merged into the best one | [`/arena`](../arena/SKILL.md) |
| Run parallel checks over slices, or race workers, as delegated child tasks | [`/swarm`](../swarm/SKILL.md) |
| Have several models review a diff and try to break it | [`/interrogate`](../interrogate/SKILL.md) |
| Fix a bug test-first when a cheap local test exists | [`/tdd`](../tdd/SKILL.md) |
| Apply TypeScript rules to `.ts` or `.tsx` work | [`/typescript-best-practices`](../typescript-best-practices/SKILL.md) |
| Strip comments before review, using a reviewer that didn't write them | [`/no-comments`](../no-comments/SKILL.md) |
| Clean AI tells out of prose | [`/unslop`](../unslop/SKILL.md) |
| Write docs, an RFC, a README, a PR description, or a commit message to a standard | [`/technical-writing`](../technical-writing/SKILL.md) |
| Hear the last reply again in plain words | [`/bro`](../bro/SKILL.md) |
| Give agents a scripted way to drive the app and prove behavior | [`/create-verification-skill`](../create-verification-skill/SKILL.md) |
| Bring a verification skill and its feature map back in line with the app | [`/maintain-verification-skill`](../maintain-verification-skill/SKILL.md) |
| Vet a performance number before reporting or acting on it | [`/benchmark-checklist`](../benchmark-checklist/SKILL.md) |
| Run a large or cross-cutting change, or one to review after stepping away | [`/figure-it-out`](../figure-it-out/SKILL.md) |
| Keep a decision log during a run, and review it afterward | [`/show-me-your-work`](../show-me-your-work/SKILL.md) |
| Pick a model for each role and a reasoning budget | [`/setup-p3`](../setup-p3/SKILL.md) |
| Turn their own working habits into a personal mode skill | [`/automate-me`](../automate-me/SKILL.md) |
| Turn what a finished task taught into skill edits | [`/reflect`](../reflect/SKILL.md) |
| Stop agents from repeating the same mistakes in this repo | [`/correct`](../correct/SKILL.md) |
| Build a page whose buttons wake a bot over a webhook | [`/make-bot-ui`](../make-bot-ui/SKILL.md) |
| Find their way around p3-stack | `/p3-help` |

If a skill directory next to this one is missing from the table, read its frontmatter and route by its description. The `principle-*` directories are covered under principles below.

Close calls:

- `/how` explains what the code does. `/why` explains the reasons. `/teach` runs one or both and explains the result plainly.
- `/arena` gives every worker the same brief and merges the best parts. `/swarm` splits work into slices or a race and returns one report.
- `/architect` implements right after it settles the design. Add "with checkpoint" to review the design before it writes code.
- `/interrogate` reviews the diff. `/blast-radius` looks for breakage outside the diff and proves the one fact that makes the change safe.
- `/recall` rebuilds context across recent threads. Resuming one specific thread, delegated task, or branch is the Session pickup playbook.
- `/figure-it-out` designs one rigorous run. The Orchestrate playbook runs a program that spans days and many PRs. The Autonomous run playbook drives one task to a finish condition.

**Not in p3-stack:** p3-stack has no `/orchestrate` skill. Orchestrate is a `/p3-mode` playbook.

## Playbooks and principles

Playbooks are step lists inside `/p3-mode`, not skills, so they aren't invoked by name. Inside `/p3-mode`, describing the task picks one, and these phrases name one directly; the Playbooks section of [`p3-mode`](../p3-mode/SKILL.md) lists every playbook and when it applies:

- "babysit this pr" or "check on pr 123" runs Babysit. It drives the PR to merge-ready and stops there. It doesn't merge unless the user asks to merge, land, or ship.
- "land the stack" runs Shipping. "take over this branch" runs Session pickup. "pause safely" runs Pause safely. "run the eval playbook" runs Eval.
- "full autopilot on this queue" runs Autopilot-full. "stack them, don't ship" runs Autopilot-stack.

p3-stack has no planning skill. For work that spans phases or stacked PRs, asking `/p3-mode` for a plan runs the [Multi-phase plan playbook](../p3-mode/playbooks/multi-phase-plan.md), which writes the plan and doesn't implement it. For a design question, the Prototype playbook or `/architect` settles it in code first.

Principles are one-rule skills that `/p3-mode` reads and cites in its replies. The user rarely invokes one. They steer with the names instead, as in "apply prove it works. show me the real output." Typing `/principle-<name>` still loads one on demand.

## Fix a run that went wrong

| Symptom | Fix |
|---|---|
| The mode stopped applying after a few turns | Start each new task with `/p3-mode`; there's no mode to toggle on. |
| A question got treated as the next step of the last task | Say "new task", or say the turn doesn't need the mode. |
| A new model choice had no effect | The file from `/setup-p3` applies to new sessions. Start one. |
| Runs cost more than expected | See the cost paragraph under Get set up. |
| A skill didn't load on its own | Only `/p3-help` loads from the user's words. The others load when the user invokes them by name or when `/p3-mode` runs them, and it doesn't run every skill. |
| Parallel agents overwrote each other | Give each worker its own worktree through `t3_thread_launch`, and keep one writer per worktree. |
| An overnight run moved but finished nothing | It needs a check that can pass or fail, not a duration. |
| The reply claims success from a green build | Ask for the real command, flow, stored value, or profile. That's the prove-it-works principle. |

## Make p3-stack my own

- [`/automate-me`](../automate-me/SKILL.md) drafts a personal mode skill from the user's own history, to use alongside `/p3-mode`. [`/reflect`](../reflect/SKILL.md) after a session turns its lessons into skill edits the user approves. `/p3-mode write a skill for <workflow>` runs the authoring playbook, and the eval playbook tests a skill change blind.
- Fix a misbehaving skill in its own PR, not inside the feature work where it went wrong.

## Reply

Lead with the answer. Give at most one example prompt in a code block, then the link to that file. Keep it short unless the user asked for the whole map.
