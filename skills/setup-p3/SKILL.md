---
name: setup-p3
description: Configure model profiles, Git remote routing, and reasoning budgets in p3-models.md. Use for /setup-p3, "configure p3 models", "p3 budget", or changing p3-stack's model choices.
disable-model-invocation: true
---

# Setup p3

Write `p3-models.md`, a file that sets p3-stack's model per role. Read [model resolution](model-resolution.md) before loading or choosing models. Default to `~/.agents/p3-models.md` for shared profiles and Git remote routing; offer a project-root file as an explicit override. If a project file already exists, show that it takes precedence and ask which file to edit. Editing the global file does not bypass a project override.

## Steps

### 1. Detect available models

Call `orchestrator_capabilities`. It lists the providers and models you can pass to `delegate_task` in this session, custom models included, with each one's provider instance ID and any reasoning options. That is the only source. If it returns nothing, stop and tell the user. For the edited profile, use only runnable provider instances and models it returned. Parent aliases explicitly use the current parent account, as described in model resolution.

### 2. Load current state

Show the detected project identity, matching mapping, and active profile using model resolution. If resolution fails, show the error and repair it through setup before delegation.

Offer the existing profiles, `new profile`, and `project mappings`. Default to the active profile when one resolves. For a new file, offer `personal` as the first profile and default mapping. Show provider display labels alongside instance IDs when choosing role targets. Each role records its provider directly; no separate provider list is written.

For profile edits, load that profile's budget and role values; keep other profiles and mappings intact. The roles are the labels in step 5. Drop retired role lines only in the edited profile and list them in the preview. For mapping edits, show exact identities and `host/path/*` patterns with their destination profiles, validate them using model resolution, and change only `## projects`.

Offer to edit an existing flat file in its original format or migrate it to profiles. A flat-format edit updates the budget and roles using the original setup workflow and writes no profile or mapping sections.

Read legacy flat files unchanged until the user accepts migration: wrap the existing budget and roles in a named profile and add `default: <name>`. Confirm the preview before writing. Preserve role choices and effort values during migration.

### 3. Budget, map, and confirm

For mapping-only edits or migration without model changes, preview the proposed section and confirm it, then go to step 4. Keep existing budgets and efforts.

**(a) Ask for a budget.** Ask plainly in the thread. Offer these four options with these exact labels, and name the current budget when the file records one.

- `unlimited — keep max`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** Build the working table. Choose runnable targets from the live catalog; preserve existing role targets unless the user changes them. For new roles in an existing profile, ask for a target instead of silently choosing another account. On a fresh profile, give code roles (`feature, refactoring`, `bug-fix`, `perf-issue`, `hillclimb`) and the explorer, investigator, and swarm roles the fastest strong coding model detected. Give `judgment and prose`, `hardest tasks`, the explainer, the synthesizers, and `reflect tooling` the most capable model detected. Fill each panel role with one entry per distinct detected provider instance, up to three. On a re-run, keep any role the user changed.

When the catalog exposes reasoning options for a model, set each real entry's effort option from the budget: `unlimited` takes the highest option, and `large`, `medium`, and `small` take `xhigh`, `high`, or `medium`. The ladder is `max` > `xhigh` > `high` > `medium` > `low`. If the model does not expose the target, use the highest option at or below it, else mark the role as needing a choice. `inherit-parent` does not change. When the catalog exposes no reasoning options, map roles only and drop effort tokens; the budget label is still recorded.

**(c) Show the roles and confirm.** Show every role with its model, marking any entry not in the detected set as needing a choice. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering detected models plus `inherit-parent`, explicitly identifying the parent account (omit the target for validated parent inheritance) as the options. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one `delegate_task` runs per entry, `inherit-parent` entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena selects one value from it whose provider differs from the parent's when possible. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

For a profile edit, validate its role entries, parent aliases, and efforts against `orchestrator_capabilities` and model resolution. Mapping-only edits leave model entries untouched. Validate all profile names and mappings before writing. An unavailable choice needs correction. Preserve unedited profiles even when their providers are unavailable in this session.

### 5. Write the file

Write `p3-models.md` with a `# budget` line with the chosen label and its target effort, and one line per role, using the same labels p3-mode uses. Write each entry as `<providerInstanceId>/<model>`, followed by its effort option in parentheses when step 3(b) set one. Replace only the edited section, preserving every other profile, mapping, and comment. Re-runs stay idempotent. For an accepted legacy migration, replace the flat layout with the previewed profile layout. Shape:

```
# p3 model configuration

## profile: personal
# budget: unlimited (max)
feature, refactoring: <providerInstanceId>/<model> (<effort>)
bug-fix: <providerInstanceId>/<model> (<effort>)
perf-issue: <providerInstanceId>/<model> (<effort>)
hillclimb: <providerInstanceId>/<model> (<effort>)
judgment and prose: <providerInstanceId>/<model> (<effort>)
hardest tasks: <providerInstanceId>/<model> (<effort>)
how explorer: <providerInstanceId>/<model> (<effort>)
how explainer: <providerInstanceId>/<model> (<effort>)
why investigators: <providerInstanceId>/<model> (<effort>)
why synthesizer: <providerInstanceId>/<model> (<effort>)
reflect tooling: <providerInstanceId>/<model> (<effort>)
reflect judgment, divergent, synthesizer: <providerInstanceId>/<model> (<effort>)
arena runners: <entry>, <entry>, <entry>
arena cross-judge pool: <entry>, <entry>, <entry>
swarm workers: <providerInstanceId>/<model> (<effort>)
architect runners: <entry>, <entry>, <entry>
interrogate reviewers: <entry>, <entry>, <entry>

## projects
default: personal
github.com/<organization>/*: personal
```

### 6. Confirm

Tell the user the path, edited profile or mappings and resolved profile for the current repo. It applies to new sessions. Re-running this skill updates only the chosen section.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without pushing.
