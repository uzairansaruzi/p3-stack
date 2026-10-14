# Agent usage policy

Applies to every p3 coordinator and worker, including reviewers with their own role instructions. Preserve the user's requested work and verification gates.

## Before a phase

State the result to produce, relevant files, verification gate, and stop condition. Record the allowed worker starts, experiment attempts, and review rounds in the phase plan. Include descendants in those counts. Reuse the existing plan or decision log instead of creating a second ledger.

Choose allowances from the work. A configured panel needs its configured seats. A user-requested experiment floor needs at least that many attempts. For work without a specified shape, start with one implementation worker and one independent reviewer. Add another worker only for a named independent question or a different model's judgment.

A phase allowance is a checkpoint, not permission to abandon the task. At its limit, report the verified result and unresolved question. Continue with a new bounded phase when new evidence justifies it. Do not silently repeat the same phase or relax the user's goal. Ask only for decisions or authorization the user must supply.

## Delegation

Use `delegate_task` for every child. Resolve the provider, model, and effort from the named role and `orchestrator_capabilities`. Omit the model for `inherit-parent`, but keep the same delegation tool. A missing tool is a capability problem, not permission to create an ordinary top-level conversation instead.

Every brief includes this policy's resolved path, its own role, exact scope, artifact paths, verification gate, allocated limits, and whether it may create children. Routed reviewer roles keep their domain instructions and receive this policy too. No child inherits the parent's conversation. Reading a workflow for context does not authorize a leaf worker to run its fan-out steps.

Children are leaf workers unless the parent allocates named child work. Nested work consumes the root phase's remaining allowance. Reserve it in the parent plan before spawning. Record each returned task ID once. Use a distinct client request ID per task or review round, stable across retries of that request. A retry with the same accepted task ID is not another worker. Never duplicate a live task because a result or acknowledgment was delayed. A confirmed failed task's replacement uses a new request ID and consumes another start. Do not repeat quota failures against unchanged capacity. Continue independent work or use an authorized viable fallback.

Keep full logs and large data in files. Return findings, necessary measurements, failures, unresolved questions, and artifact paths. Read already loaded material again only when it changed or a specific uncertainty requires it.

## Model and effort

Use `routine workers` for bounded facts, extraction, and summaries. Use `mechanical edits` for simple edits whose target and transformation are specified. Complexity takes precedence over specification precision. Cross-cutting design, concurrency, and subtle algorithms use `hardest tasks` even when the steps are specified. Use the task's existing code or judgment role when the answer needs design, debugging, or synthesis. Missing tier lines use the existing corresponding role; name that fallback. Do not inherit an expensive coordinator model merely because the work is small.

Use the configured effort. Increase it only for a concrete unresolved reasoning problem after checking missing facts and the test or measurement path. Escalation changes one task, not the global table or every worker. Record the reason and return to the configured effort for later tasks. Do not change effort or thinking settings repeatedly within a conversation whose cache you want to reuse.

## Experiments and reviews

Before an experiment, name its hypothesis, distinguishing outcome, baseline, and gate. Record attempts and results. Do not rerun an unchanged experiment unless a failed run or measured noise calls for it. Batch independent cases in a script that emits a compact result file.

Before another review round, name the changed behavior or unresolved finding it must examine. Carry forward confirmed findings and responses. Re-review that scope. Broaden only when the change alters an assumption outside it. A repeated objection needs new evidence, a fix, or a recorded dismissal, not another identical panel.

Two failed attempts with the same premise trigger [Attack the Premise](../../principle-attack-the-premise/SKILL.md). Exhausted attempts trigger the phase checkpoint. Explicit user targets, attempt floors, and required reviews still govern.

## Long-running tools

Launch one durable script for a long run or experiment matrix. Give it a stable output path, terminal status, and compact result summary. Preserve its process or run ID so a restart can inspect it rather than launch it again.

Use the tool's completion delivery or a T3 task result to resume. Async delegated tasks notify their parent when complete. Read `task_status` when the result is needed during other work. Otherwise end the turn and let completion wake it. For persistent recurring or webhook work use `schedule_task` only when that ongoing work is requested. For PR monitoring use `watch_pull_request`. Without completion delivery, choose a bounded status-check cadence based on the next meaningful event. Repeated tails of an unchanged log are not progress.

Cache lifetime is a provider property. Do not assume T3 ownership or the parent model settings give a worker a particular lifetime. Verify recorded cache-write TTL when the runtime exposes it. Keep tool definitions, reusable instructions, and effort stable. Compaction or changed prefixes can still require new writes. Newly appended messages and results must be processed once. Ordinary growth is not evidence of invalidation.

A long cache TTL may suit workers that repeatedly wait longer than a short TTL. Compare write cost and expected reuse before selecting it. Five-minute and one-hour writes can have different prices. A multi-hour tool can outlast either lifetime. Never invent an unsupported cache option in `delegate_task` or silently change host configuration.

Warming is an optional provider integration, not an agent status loop. It must renew the same cached prefix before expiry, preserve model and thinking settings, and avoid generating output where supported. Check provider restrictions. Zero-output warming can be incompatible with enabled thinking or streaming. Warming only a generic system prompt does not preserve conversation history. Warming after expiry still pays for a write. Include warming requests and cache reads in the estimate. Stop warming when active work ends. Do not keep paused tasks warm indefinitely or claim API-equivalent savings reproduce subscription usage.

## Usage and outcomes

Pair each phase's verified outcome with its worker starts, experiment attempts, and review rounds. Examples include a reproduced defect and passing fix, a measured hypothesis kept or rejected, or an investigation whose open question is resolved. A review with no findings can still complete its assigned gate.

When the runtime supplies usage, record model, effort, uncached input, cache reads, cache writes by TTL, and output for the parent and descendants. Thinking is already included in output. Keep recorded usage separate from inferred expiry and billing weights. Mark unavailable fields as unavailable. Do not add agent turns or mine every transcript solely to manufacture usage statistics.

These instructions define the workflow checks. Hard token or concurrency limits require enforcement by the runtime. Do not claim a Markdown budget is a runtime cap.
