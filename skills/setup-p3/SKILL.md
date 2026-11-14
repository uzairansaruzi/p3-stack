---
name: setup-p3
description: Configure which models p3-stack uses per role and at what reasoning budget. Detects your available models and writes p3-models.md, which overrides the skill defaults. Use for /setup-p3, "configure p3 models", "p3 budget", or changing p3-stack's model choices.
disable-model-invocation: true
---

# Setup p3

Write `p3-models.md`, a file that sets p3-stack's model per role. Default location is the current project root. Offer `~/.agents/p3-models.md` as the global option, and ask which one. A project file wins over the global one.

## Steps

### 1. Detect available models

Call `orchestrator_capabilities`. It lists the providers and models you can pass to `delegate_task` in this session, custom models included, with each one's provider instance ID, any reasoning options, and any speed option (`fastMode` or `serviceTier`). That is the only source. If it returns nothing, stop and tell the user. Never write a provider or model it did not return. `inherit-parent` is always valid even though it is not a detected model.

### 2. Load current state

The roles are the labels shown in step 5. If `p3-models.md` already exists at the chosen location, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from the defaults in step 3(b). A line whose role is not in step 5, such as `how critics`, is from a retired role. Drop it.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Ask plainly in the thread. Offer these four options with these exact labels, and name the current budget when the file records one. With no file, say that `large` is the default.

- `unlimited — max reasoning`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** Build the working table. On a fresh run, give code roles (`feature, refactoring`, `bug-fix`, `perf-issue`, `hillclimb`), the explorer, investigator, and swarm roles, and `reflect tooling` the fastest strong coding model detected. Give `judgment and prose`, `hardest tasks`, the explainer, and the synthesizers the most capable model detected. Fill each panel role with one entry per distinct provider detected, up to two. On a re-run, keep any role the user changed.

When the catalog exposes reasoning options for a model, set each real entry's effort option from the budget: `unlimited`, `large`, `medium`, and `small` take `max`, `xhigh`, `high`, or `medium`. The ladder is `max` > `xhigh` > `high` > `medium` > `low`. If the model does not expose the target, use the highest option at or below it, else mark the role as needing a choice. `inherit-parent` does not change. Under `unlimited`, a model whose top option is `xhigh` stays at `xhigh`. When the catalog exposes no reasoning options, map roles only and drop effort tokens; the budget label is still recorded. Speed does not follow the budget. For each real entry, read the model's speed option from the catalog: `fastMode` for Claude models, `serviceTier` for Codex models. Record that option's name as the entry's `speed`, or `n/a` when the model has none. The entry's default stays standard speed. The parent turns fast on at spawn time, only when someone is blocked right now, per the Subagents section of the **p3-mode** skill. With `n/a` the parent adjusts effort only.

**(c) Show the roles and confirm.** Show every role with its model, marking any entry not in the detected set as needing a choice. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models plus `inherit-parent` (the role runs on the parent thread's model, so omit the model in `delegate_task`) as the options. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one `delegate_task` runs per entry, `inherit-parent` entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena runs one judge. It tries only values from a provider other than the parent's, in list order, so order it by preference. An `inherit-parent` value never judges. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every real entry written must be in the `orchestrator_capabilities` result, under the provider instance it came from. `inherit-parent` always passes. If a chosen entry is not available, stop and ask again.

### 5. Write the file

Write `p3-models.md` with a `# budget` line with the chosen label and its target effort, and one line per role, using the same labels p3-mode uses. Write each `<entry>` as `<providerInstanceId>/<model>`, followed by its effort option and speed in parentheses (`<effort>, speed: <fastMode|serviceTier|n/a>`) when step 3(b) set them, or as the word `inherit-parent`. A model with no catalog reasoning options gets `(speed: ...)` alone. Separate the entries of a panel list with `; `, never a bare comma, so a role name or an entry can contain commas without ambiguity. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# p3 model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` as a value: the role runs on the parent thread's model (omit the delegate_task model). Entries in a panel list still count toward its fan-out.
# budget: large (xhigh)
feature, refactoring: <entry>
bug-fix: <entry>
perf-issue: <entry>
hillclimb: <entry>
judgment and prose: <entry>
hardest tasks: <entry>
how explorer: <entry>
how explainer: <entry>
why investigators: <entry>
why synthesizer: <entry>
reflect tooling: <entry>
reflect judgment, divergent, synthesizer: <entry>
arena runners: <entry>; <entry>
arena cross-judge pool: <entry>; <entry>
swarm workers: <entry>
architect runners: <entry>; <entry>
interrogate reviewers: <entry>; <entry>
```

### 6. Confirm

Tell the user the file was written, where, and that it applies to new sessions. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without pushing.

### 8. Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with /create-formal-verification-skill." On yes, invoke `/create-formal-verification-skill`. On no, move on without pushing.
