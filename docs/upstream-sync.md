# Upstream synchronization

p3-stack tracks [pstack](https://github.com/cursor/plugins/tree/main/pstack) (the `pstack/` directory of `cursor/plugins`). This system detects upstream improvements, adapts them for T3 Code with Claude, validates the result, and opens a reviewable pull request. Nothing ever merges, pushes to `main`, or advances the tracked baseline automatically.

## How it works

```
                  ┌──────────────────────────────────────────────────┐
                  │  .upstream-sync/state.json                       │
                  │  last_integrated_sha = last MERGED upstream tip  │
                  └───────────────┬──────────────────────────────────┘
                                  │
  daily cron / manual dispatch    ▼
┌─────────────┐   ┌──────────────────────┐   no changes ─► done
│ detect.mjs  │──►│ changes since SHA?   │── yes ─┐
└─────────────┘   └──────────────────────┘         │
   reads upstream via git diff only                ▼
                                  ┌─────────────────────────────┐
                                  │ Claude Code Action           │
                                  │ (file tools only, no shell)  │
                                  │ ports skills per AGENTS.md   │
                                  └──────────────┬──────────────┘
                                                 ▼
                                  ┌─────────────────────────────┐
                                  │ validate.mjs                │
                                  │ fail ─► discard, report-only│
                                  └──────────────┬──────────────┘
                                                 ▼
                                  ┌─────────────────────────────┐
                                  │ one PR: sync/upstream-<sha> │
                                  │ body = commits / ported /   │
                                  │ manual / excluded / checks  │
                                  └──────────────┬──────────────┘
                                                 ▼
                                  human review ─► merge advances
                                  .upstream-sync/state.json
```

Pieces:

| Path | Role |
|---|---|
| `.upstream-sync/state.json` | Tracked baseline. `last_integrated_sha` advances only when a sync PR merges. |
| `.upstream-sync/config.json` | Policy: path mapping (`poteto-mode` → `p3-mode`, …) and documented exclusions. |
| `.upstream-sync/reports/` | Run artifacts: detect report, Claude dispositions, validation result. Committed to the sync PR. |
| `scripts/upstream/detect.mjs` | Fetches upstream, diffs `pstack/` since the baseline, classifies every change (port / scripts / exclude / review). Reads text through git only; never checks out or runs upstream code. |
| `scripts/upstream/validate.mjs` | The gate: frontmatter, forbidden Cursor terms, T3 tool vocabulary (no invented APIs), reference resolution, naming, deletion and core-file guards, disposition completeness, state coherence. |
| `scripts/upstream/advance-state.mjs` | Advances the baseline SHA. Called only after validation passes, inside the PR branch. |
| `scripts/upstream/render-pr-body.mjs` | Builds the PR body from the report, dispositions, and validation result. |
| `.github/workflows/upstream-sync.yml` | Daily schedule (09:17 UTC) + manual dispatch. Orchestration, secrets, PR lifecycle. |

## Installation

The system is part of this repository. After merging the PR that adds it, it is live: the workflow file on `main` is what GitHub schedules. To verify, run **Actions → Upstream sync → Run workflow** once.

## Authentication and secrets

Adaptation uses the official [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action). Configure **one** of these repository secrets (Settings → Secrets and variables → Actions):

| Secret | What it is |
|---|---|
| `ANTHROPIC_API_KEY` | Anthropic API key. Preferred. |
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code OAuth token. Used only when no API key is set. |

No secret is required for detection or report-only PRs; the workflow degrades to a reviewable change report when credentials are absent (requirement: never block on missing credentials, never fake an adaptation). `GITHUB_TOKEN` is used for pushing the sync branch and managing PRs; it needs no configuration.

Security properties:

- Claude runs with a strict tool allowlist (Read/Write/Edit/Glob/Grep/WebFetch/WebSearch only). It has **no shell**, so it cannot run upstream scripts, `git`, `gh`, `npm`, or `node`.
- Upstream scripts detected by the sync are committed for human review and listed in the PR body; the workflow itself never executes anything from upstream.
- No model name or version is pinned anywhere; the action uses the account default.

## Configuration

All policy lives in `.upstream-sync/config.json`:

- `path_map` — upstream → p3-stack paths. Extend when upstream renames something or a new T3 adaptation renames a skill.
- `exclude` — paths never ported, each with a written reason shown in every PR. Cursor-only packaging (`plugin.json`, `.cursor-plugin/`, `assets/`), the Cursor-automation `scripts/` under `poteto-mode`, the Cursor guide, and the benny automations pack.
- `review` — changes reported for a manual decision instead of automated porting (docs, upstream README, license).

To change what gets ported, edit the config in a normal PR. The sync never edits it.

## Daily flow

1. At 09:17 UTC (or on manual dispatch) the workflow detects changes since `last_integrated_sha`.
2. If none, it exits green.
3. If an open PR already covers the same upstream head, it exits green (idempotent). Use `force` to redo.
4. Older open sync PRs are closed as superseded.
5. With credentials: Claude ports the changes per `AGENTS.md` and writes per-file dispositions. Without: skip to 7.
6. The validator gates the adaptation. Any failure discards Claude's work and falls back to step 7 with the failure attached.
7. One PR is created or updated: `sync/upstream-<short-sha>`, labeled `upstream-sync` (+ `report-only` when applicable).
8. **A human reviews and merges.** Merging is the only thing that advances `last_integrated_sha`.

The PR body always contains: upstream commits detected, changes incorporated, changes needing manual intervention, intentional exclusions with reasons, and validation results.

## Manual runs

- **Actions → Upstream sync → Run workflow** for an on-demand check.
- Inputs: `dry_run` (report only), `force` (redo despite an open PR), `max_turns` (Claude turn budget).

Local dry run (Node 24+, git):

```bash
node scripts/upstream/detect.mjs --write          # classify everything since the baseline
node scripts/upstream/validate.mjs --base origin/main --full   # check the repo as it stands
```

## Maintenance

- **After a human ports something manually** (no sync PR): run `node scripts/upstream/advance-state.mjs <new-upstream-sha>` in that PR so the baseline reflects reality. The check "the port's content actually matches that upstream state" stays human.
- **Upstream renames a skill**: add the mapping to `path_map` before the next run.
- **Upstream adds a new kind of asset** (not skills/agents/docs): it lands in the `review` list until you classify it.
- **Adaptation quality**: adjust the prompt in `.github/workflows/upstream-sync.yml` or the rules in `AGENTS.md` (the prompt defers to it).
- **Reports accumulate** in `.upstream-sync/reports/` on merged sync PRs; delete old ones occasionally if they grow large.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| PR labeled `report-only` though you wanted an adaptation | No `ANTHROPIC_API_KEY`/`CLAUDE_CODE_OAUTH_TOKEN` secret, the Claude step failed, or validation failed and discarded its work. The workflow log says which; the PR body carries validation output when it exists. Add secrets and re-run with `force`. |
| `upstream-history-rewritten` job failure | The baseline SHA is no longer an ancestor of upstream `main` (upstream force-pushed). Pick the new equivalent commit, verify your port against it, and update `last_integrated_sha` in a manual PR. |
| Validator fails on `dispositions: ... no disposition` | Claude stopped early (turn budget). Re-run with a higher `max_turns`, or port the listed files manually. |
| Validator fails on `t3-vocabulary` | An adaptation named a T3 tool that does not exist. Either fix the wording or, if upstream genuinely needs a new mechanism, add the real tool to `AGENTS.md`'s quick reference first — never the reverse. |
| Two sync PRs open | Should not happen (older ones are auto-closed as superseded). Close the stale one manually and note it in the fresh PR. |
| Claude step hangs or the job times out | Lower `max_turns`, or split the backlog: manually advance the baseline to an intermediate upstream SHA you ported by hand, then re-run. |
| Nothing happened today | Check the detect job summary: either up-to-date, a PR already covers the head, or the schedule was delayed (GitHub cron can lag; run manually). |

## Invariants (what the system will never do)

- Never merge a PR or push to `main`.
- Never execute code from upstream; scripts are data.
- Never modify `AGENTS.md`, `install.sh`, `.github/**`, or the sync tooling itself from inside an adaptation.
- Never mark changes as synchronized before their PR merges — the tracked SHA lives on `main` only.
- Never invent T3 tool APIs; the validator enforces the `AGENTS.md` vocabulary.
