# Prompts worth copying

Swap in the real paths, skills, and done checks. Informal wording works.

## Understand

- `/p3-mode read thread <id>. restate the underlying issue in your own words, in plain english.`
- `/in-your-own-words <long or messy ask>`
- `/sharpen <the prompt you're about to send>`
- `/p3-mode investigate why <symptom>. give me what we know, what data you used, and your best hypotheses. don't change any code yet.`
- `use /how to understand <subsystem>. then use /why to find out why it broke recently.`
- `/recall my work on <topic> from last week, then read <issue>.`
- `/teach me why you implemented it this way and not <other way>. what did you trade off?`
- `/p3-mode take over this branch. read the decision log, find what's done, and continue. don't redo finished work.`

## Build

- Bug: `/p3-mode <symptom>. repro first, then fix and verify.`
- Bug in an app: `/p3-mode repro this with /verify-<app>. if it repros on main, fix it and show me a video as proof.`
- Bug with a cheap test: `/p3-mode repro <bug> first. if there's a cheap test path, /tdd it. then fix and rerun.`
- Feature: `/p3-mode add <behavior>. <current output> stays byte-identical. verify both.`
- Refactor: `/p3-mode move <code> into one module, zero behavior change. record the current output first and prove it's unchanged after.`
- Perf: `/p3-mode <operation> takes <time> on <fixture>. trace it, fix the measured cause, show me before and after.`

## Design and plan

- `/p3-mode prototype a few options for <feature>. take screenshots or videos for me to compare.`
- `/p3-mode we need <feature>. /architect it first, and answer open questions with prototypes. let me review before proceeding.`
- `/p3-mode write a tutorial for how i would use <new package> first. then /teach me why it beats the current one.`
- `ask /arena for a second opinion on this thread and our approach.`
- `/p3-mode turn this design into a plan. small verifiable PRs, each with its own verification steps.`
- `/p3-mode plan the migration of <library> to <target>. small verifiable PRs. the result must match the original exactly, bugs included.`

## Review and ship

- `/interrogate the whole branch, but skeptically. don't change anything yet. no nitpicks unless it's a real bug or regression.` Read the Dropped list too.
- `/create-formal-verification-skill prove <property> holds in <module>, even when <steps> interleave or retry.` After merges or refactors in that code: `/maintain-formal-verification-skill`.
- `/swarm check every package under <dir> against its check script. one worker per package. one report.`
- `/p3-mode open the pr. small ordered commits, evidence in the description.`
- `/p3-mode babysit this pr. get it green.` For status only: `/p3-mode check on pr <number>. anything outstanding?`
- `/p3-mode land the stack.`

## Away and back

- `/p3-mode im going to bed. <goal> in a fresh worktree off <base>. done means <checks>. keep a decision log. don't ask me before committing. keep going until the checks pass, using `schedule_task` to wake yourself if you stall. if you're truly stuck after a few hours, stop and write up why.`
- `/show-me-your-work catch me up on what you did last night.` Read its Attention section first.
- `/ketchup` catches you up on this thread since your last message and lists every call that waits on you.
- `/p3-mode full autopilot on this queue. each item is independent.`
- `/p3-mode autopilot these changes, but don't merge. i'll land them.`
- `/reflect capture what we learned so the next run doesn't repeat it.` Approve only edits that change a future decision.
- `/bro` restates the last reply in plain words.
