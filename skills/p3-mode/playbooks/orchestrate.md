---
name: orchestrate
description: Run a multi-day, many-PR program as a standing coordinator that authors briefs, drains the queue, keeps the frontier green, and decides.
---

### Orchestrate

**You own the program, never the code. Author briefs, drain the queue, keep the frontier green, decide.** For a whole project handed to one standing coordinator thread: multi-day, many stacked PRs, dozens to hundreds of delegated workers, the human checking in twice a day instead of every five minutes. One task driven to a predicate is Autonomous run. One ambitious run needing a bespoke workflow is figure-it-out. Route here when the work outlives any single agent. Work one agent could finish inside the session's budget is not a program.

Ceremony must scale with the program. On cheap near-identical units, collapse it as each section directs.

Three rules carry the rest.

- Completions are queue events, not interrupts.
- Every brief states the standing orders that apply to its unit, explicitly. The register is the source, not the payload.
- The brief is the product. A vague brief fails quietly, because a worker cannot ask you a question.

#### Roles and placement

- **Coordinator (this thread).** Frames, authors briefs, drains the inbox, owns the human report, makes judgment calls. It never authors or edits code. Conflicted merges, restacks, and code changes are always tasks. Mechanically landing a verified unit (fast-forward or clean cherry-pick of a worker's commit, then push) is bookkeeping the coordinator may do itself on repos where local git is cheap. Queueing finished work behind an idle stacker is how a deadline harvests nothing. Workers and sub-coordinators are spawned with `delegate_task` (`mode: "async"`); their completion wakes the coordinator. A worker that needs its own worktree or branch still gets `delegate_task`: prepare the checkout first (an existing one from `t3_worktree_list`, or one the coordinator creates), and name its absolute path, branch, and base SHA in the brief. A top-level `t3_thread_launch` thread needs an explicit user request for separate threads. A worktree alone never justifies one. The coordinator reads and writes the store files at drain points. Nothing in the store spawns, waits, or wakes anything.
- **Sub-coordinator.** A `delegate_task` child, one per track, made durable by its handoff file in the store, not by a thread, and only when the program exceeds what one coordinator's drains can manage. A track the coordinator can drain itself needs no middle layer. Each nested layer re-pays a full orientation preamble, and a blocking sub-coordinator hides its children while the parent idles. Owns its track's units and boards, authors its workers' briefs, spawns its own workers and verifiers (nesting works to depth 3), and keeps `tracks/<track>/handoff.md` current. Rolls up aggregates at wave boundaries. Never forwards raw child reports. It writes them to the store and rolls up their paths. Cap in-flight children at what one drain can process, roughly ten, as a rolling window. Never as blocking batches, which cost the slowest child of every batch.
- **Worker / verifier.** A bounded `delegate_task` child. Child agents get only the brief, never the parent's context, so briefs state what they need or point at repo paths. A worker runs its unit, not this playbook: no store, no drains, no sub-workers unless its brief grants delegation. Runtime verification (`preview_*`, `device_*`, local app state) is still a delegated task in a prepared checkout. Escalate to the human only if it truly needs a top-level thread. Prefer fewer, broader workers. One writer per worktree or branch (principle-separate-before-serializing-shared-state). Resolve roles from `orchestrator_capabilities` via `p3-models.md`, and run a unit's verifier on a different model family from its worker.

Depth stays at coordinator, track, worker. Author the track decomposition per project (build, landing, and verification are common cuts, not a required shape). Hard-coded swarm trees were tried and parked as too rigid.

#### Store layout

Create `orchestrate/<project-slug>/` in the current project. Every file has exactly one writer. Owners publish facts, readers aggregate at read time. Bookkeeping is plain TSV, JSON, and markdown that the coordinator maintains by hand.

- `preferences.md` is the standing-orders register: numbered lines, one constraint each (model policy, authorizations such as commit, push, PR, merge, stack shape and count, verification bar, forbidden paths, escalation policy). Each brief restates the lines that apply to its unit, by number, in full. Hard constraints that apply (model policy, authorization gates, verification bar, forbidden paths) are never left implicit and never paraphrased away. Lines that cannot touch the unit stay out. Directives decay across resumes, and each dropped one costs a human turn. When you catch yourself restating an instruction, append the line before you act (principle-encode-lessons-in-structure).
- `overview.md` is the durable PR and issue DB. Append. Never rewrite wholesale per event.
- `units.tsv` has one row per unit: id, track, state, branch, PR, head SHA, brief path. Update rows in place.
- `frontier.json` is the computed merge frontier, per Stack safety.
- `ledger.tsv` is the verification ledger, per Verification.
- `handoff.md` is the durable current handoff: goal, current branches and SHAs, applicable constraints and authorizations, decisions, blockers, evidence paths, in-flight task ids and checkouts, next action and exact command to resume. Overwrite it at every drain. `tracks/<track>/handoff.md` is the same per sub-coordinator.
- `reports/` holds child reports and evidence, one file per report. Briefs and rollups cite these paths.
- `inbox/` holds completion pointers. `gates.md` parks human gates (question, options, default on no answer).
- `decisions.tsv` is the trail via the show-me-your-work skill.
- `status.md` is derived from `units.tsv` and `ledger.tsv` at each drain, never hand-maintained. Regenerate it from the tables instead of narrating events into it.

#### The brief

Your prompts to agents are your only product, and a sloppy brief compounds into slop across the whole tree. A field you cannot fill is a unit you have not scoped yet.

```
GOAL         one sentence, the outcome, executable by a stranger with no chat access
CHECKOUT     absolute path, branch, base SHA; prepared before spawn, exclusive to this unit
SCOPE        paths this unit may write; paths it may not
CONSTRAINTS  the applicable preferences.md lines in full, by number; what is authorized
             (commit, push, PR) and what is not
CONTEXT      current dependencies and evidence as file paths (reports/, repo files, PRs),
             each with a one-line conclusion; never raw upstream reports
ACCEPTANCE   checkable criteria, one per line
VERIFY       exact commands or the preview/device path, plus known gotchas
TIMEBOX      rough cap on runtime; on expiry, return partial findings and stop rather than run on
DELEGATION   none, or which roles it may spawn and how deep
FORBIDDEN    no rebase, no force-push, no fixes outside scope, plus unit-specific bans
REPORT       at most 300 words: status, branch, head SHA, PRs, verdict, what you actually ran,
             deviations, follow-ups, concise blockers and deciding evidence; exhaustive
             findings go to the designated report artifact
```

Size the brief to the unit. A one-command unit gets the template collapsed to a paragraph that still names goal, checkout, scope, the applicable constraints, the verify command, and the report shape. A 4KB scaffold around a two-line edit costs more to write and obey than the edit. Every brief stands alone: T3 child agents get only the brief, never the parent's context. Standing alone means the constraints that bind this unit are stated, not that the whole register is pasted.

A sub-coordinator brief adds its track boundary and unit list, its spawn budget, the drain protocol, and the rollup format (per child: name, status, PR, head SHA, verdict, one line, report path, plus track status and frontier delta). It does not carry this playbook. Its brief names the parts it runs.

A dependency is a context relay, not just ordering. Relay the upstream report's path and its one-line conclusion. The worker reads the file. Undeclared upstream context makes the worker guess. Missing fields are a refuse-to-spawn condition. Audit one sampled worker brief per sub-coordinator per wave, concurrently with the wave it samples, never as a gate in front of it. A failing brief stops that track and fixes the sub-coordinator's instructions, not just the worker, because brief quality decays late in a run. Never resume-chain a brief. Respawn fresh with consolidated scope.

#### Steps

1. **Frame.** State the done predicate as something countable ("all 126 units merged, each ledger-verified `unit-test-verified` or better"). Quantify scope: units, rough effort, expected stacks, and the wall-clock budget. If one agent could finish inside that budget, stop here and run Autonomous run instead. Collapsing must not depend on another document being present. It means none of the store, register, or pilot machinery below, verification inline, landing as you go. Collapsing does not mean reading everything yourself. Bulk reads and many-file edits still go to `delegate_task` workers first, and the session reads their conclusions. Schedule landing against the budget. By roughly 70% of it, stop spawning and land what is verified. Name the tracks per project. A contested decomposition or one-way door goes through the arena skill before the pilot. Present the framing once. Reversible prep proceeds without waiting.
2. **Set up the store.** Create the store files. Open the trail via the show-me-your-work skill, write the standing orders before any spawn, and seed `frontier.json` from existing PRs per Stack safety. Arm the hourly audit tick with `schedule_task` (`{"type":"interval","everyMs":3600000}`) so the program survives a quiet coordinator.
3. **Pilot.** Push one unit through the whole path: brief, worker, verification, stack entry, ledger row, merge. The pilot exists to falsify the brief template, the verify recipe, and the unit size while that costs one agent instead of fifty. Fix the contract from pilot evidence before any fan-out. Scale the pilot to the unit. On programs of near-identical cheap units, the first unit is the pilot, run as a normal unit with its verify command inline, and fan-out starts the moment it lands. The dedicated pilot pipeline (separate verifier agent, audit gate) is for expensive or novel unit shapes, not for clone-units where a serialized pilot has nothing to falsify.
4. **Scale.** Spawn a rolling window of workers up to the in-flight cap, refilling as children finish. Blocking batches pay the slowest child of every batch. Spawn track sub-coordinators only past the one-drain threshold in Roles. Recompute ready work after each drain. Relay upstream evidence paths into downstream briefs. Keep sibling communication upward only. The sampled brief audit runs alongside the wave it samples and stops the next refill on failure, not the current one.
5. **Drain.** Run the queue discipline below at every drain point.
6. **Land.** Landing is continuous, never a terminal phase. Integration starts with the first verified unit and runs alongside the remaining waves. On heavy repos the stacker is a standing role from wave one, integrating as units verify. On repos where local git is cheap, the coordinator lands verified units itself per Roles. Keep the frontier green before upper-stack work. Stack safety governs. Advance `frontier.json` only on merge or reported new head SHAs.
7. **Close.** Drain the final inbox, reconcile every spawned agent to a terminal row (done, abandoned, zombie-reconciled), confirm the predicate on the real artifact, confirm every landed PR has a verdict for its current head SHA, audit the trail per show-me-your-work including its cross-model review, encode recurring corrections into `preferences.md` or the brief template. Delete the audit tick with `delete_scheduled_task`. Leave the store intact. It is the postmortem.

#### Queue and drain

- On a completion wake, write the report to `reports/`, append a pointer to `inbox/` (agent, unit, status, report path) and return to what you were doing. Never deep-review inline. A completion that needs review becomes a verifier unit. Never review a diff inside a drain.
- Drain in batches at four points: the end of a critical section, a track rollup, a frontier watcher wake (arm `watch_pull_request`, end the turn, triage on wake, with the hourly `schedule_task` tick as the long heartbeat fallback), and before a human report. Begin each batch by listing `inbox/`. Arrivals during a drain wait for the next one. Completions arrive as wakes. Never loop on `task_status`. One read-only status pass per drain covers a wake that is overdue.
- Critical sections you finish first: authoring a brief, a stack operation, a conflict decision, writing a gate, updating ledger or frontier.
- Each drain classifies every pointer (landed, needs-verify, failed, zombie, noise), writes the resulting rows to `units.tsv` and `ledger.tsv`, regenerates `status.md`, overwrites `handoff.md`, then spawns the next wave in one message.
- Account for every spawned child at its track's rollup: arrived, respawned, or its scope explicitly absorbed. Silently redoing a missing child's work hides both the wasted spend and the coverage gap its result existed to close.
- A drain turn ends with three lines from `status.md`: counts against the states, what changed, gates open. Detail lives in `status.md`. The full reply contract applies at checkpoints and close.

#### Stack safety

- The frontier is a computed object, never narrative. Recompute `frontier.json` from `gh` and `list_thread_pull_requests` after every merge and stack mutation because GitHub base refs drift mid-restack: ordered PR list, branch names, head SHAs, a generation number, the lowest unmerged PR. Call `link_pull_request` for every layer the moment it exists. A PR missing from both sources is reported, never guessed.
- Exactly one stacker per stack may rebase or restack, serialized within its stack. Record the holder in the standing orders. Restacks run in the stacker's own prepared checkout, never in the coordinator's.
- Workers never rebase. Babysitters follow `playbooks/babysit.md`, one per stack, scoped to one immutable frontier generation. They report conflicts to the stacker rather than restacking.
- PR closes and retargets go through the stacker only. Closing a base PR orphans every chain above it. Merges and stack surgery are units with briefs like any other.
- One retro watcher follows merged PRs for reverts, post-merge CI breaks, and orphaned follow-ups.

#### Verification

Scale verification to the unit. When VERIFY is a single cheap command, the worker runs it and reports the output, and the coordinator spot-checks receipts. A dedicated verifier agent (on a different model family than the worker) is for units whose verification is expensive, judgment-laden, or high-blast-radius. A verifier agent whose entire product would be rerunning one command is ceremony, not verification.

Write one row per verdict to `ledger.tsv`, and check the current PR and head SHA before accepting a unit. `ledger.tsv`, one row per verdict, keyed by PR number plus head SHA: `live-ui-verified | unit-test-verified | type-check-only | verifier-blocked | verifier-failed`. CI green is an input to a verdict, not a verdict. Behavioral work needs better than `type-check-only`. `verifier-blocked` is not a pass. Respawn when the environment heals. `verifier-failed` gets a fix unit, not a re-verify. A worker may self-report. A verifier overrides it on the same key. A new head SHA voids the row, so re-verify after restack. The ledger answers "was this verified", not memory and not the transcript.

A unit is not done until its output is externalized the moment it lands, never batched to the end of the run. A worker pushes its branch when authorized. A verifier returns its verdict, exact PR and head SHA, and receipt paths. The coordinator alone records the verdict in `ledger.tsv` before accepting the unit, and receipts land in the store. Work that exists only in one worktree when that worktree dies was never done.

#### Liveness and failure

- Never resume an agent to check on it. A resume restarts an idle agent. Probe read-only, once per drain, never in a loop: the ledger, `units.tsv`, `gh`, pushed branches, `task_status`. Transcript mtime is not liveness.
- A silent death gets a synthetic postmortem row in the inbox (unit, failure mode, last evidence, options). Replan on evidence as it arrives. Never wait for full quiescence.
- Retry by mode: cap-hit or oom, respawn with smaller scope. Network-drop, retry as-is. Tool-error, retry on a different model. Unknown, retry once. Two retries, then abandon the unit and replan around it.
- A zombie that returns hours late reconciles against the current frontier and ledger before anything is accepted. Salvage unique findings through a fresh unit, never a blind merge.
- When continued spawning would produce garbage tree-wide (bad upstream output, broken acceptance, dead infra), write a stop line at the top of the standing orders, let in-flight work finish, fix the cause, clear it.
- Bound your own infra retries the same way you bound a child's. After a few consecutive tool aborts, stop retrying. Write the terminal state into `handoff.md` and end the run.
- After a restart, delegated tasks and local threads may be gone, pushed branches are not. Re-read `handoff.md`, the standing orders, and `units.tsv`, recompute the frontier, reattach work by PR and branch, respawn one sub-coordinator per track from its stored brief plus its track handoff, drain, resume.

#### Escalation

Reaches the human, batched into the status page rather than per item: irreversible actions (force-push to shared branches, deploys, deletions, closing someone else's PR), genuine product or preference calls no experiment settles, a standing order that contradicts observed reality, a program-level dead end that survived a replan. Park each as a `gates.md` entry before asking in the thread, and route work around it.

Never reaches the human: frontier nudges, restack mechanics, retries, CI flake triage, review-thread triage, format fixes, scope the brief already forbids (refuse and continue), and "should I keep going". When in doubt, act and log.

Mid-run discoveries fix only what blocks the frontier. Everything else parks in follow-ups. At this fan-out a small scope leak multiplies into PRs nobody asked for.

**Reply:** at checkpoints and close: the predicate and the count against it from `units.tsv` and `ledger.tsv`, tracks and what each landed, the frontier (PR list plus SHAs), verdicts summary, what was abandoned and why, gates awaiting the human (the only asks), the store path, and the trail path. Numbers from the tables, not narrative. Include PR links.
