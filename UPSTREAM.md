# Upstream tracking

upstream: https://github.com/cursor/plugins
subtree: pstack/
pin: 4e5b1cf2ccb0ea3716f08c8ee0a5856b5ab93536
pin-date: 2026-10-05
pin-version: 0.15.10
synced-on: —
sync-target: c742dd61706fbacc1b95f1a20b7b988cf096ce6c
sync-spec: docs/sync-spec-c742dd6.md

`pin` 取「上游 main 上最后一个动过 subtree 的 commit」，不取仓库 HEAD。同步进行中 `pin` 取各行「对齐到」的最小值（此处仍是导入基线 4e5b1cf），全部对齐后才前进到 `sync-target`。
`scripts/upstream-diff.sh` 与 `scripts/parity-check.sh` 只读本文件：头部 `key: value` 加下面四张表（前三张是 spec §5.1 的固定表，第四张是 parity-check 的可选扩展）。状态取值：`ported`（已落地）、`pending`（已决定移植、未落地）、`gap`（有意缺口）、`p3-only`（p3 独有）。

## 映射

| 上游 | p3 | 对齐到 | 状态 | 备注 |
|---|---|---|---|---|
| skills/architect | skills/architect | 4e5b1cf | ported |  |
| skills/arena | skills/arena | 4e5b1cf | ported |  |
| skills/automate-me | skills/automate-me | 4e5b1cf | ported |  |
| skills/benchmark-checklist | skills/benchmark-checklist | 4e5b1cf | ported |  |
| skills/blast-radius | skills/blast-radius | 4e5b1cf | ported |  |
| skills/bro | skills/bro | c742dd6 | ported |  |
| skills/correct | skills/correct | c742dd6 | ported |  |
| skills/create-formal-verification-skill | skills/create-formal-verification-skill | — | pending | 新技能，批次 B4 |
| skills/create-verification-skill | skills/create-verification-skill | 4e5b1cf | ported |  |
| skills/figure-it-out | skills/figure-it-out | 4e5b1cf | ported |  |
| skills/how | skills/how | 4e5b1cf | ported |  |
| skills/in-your-own-words | skills/in-your-own-words | — | pending | 新技能，批次 B4 |
| skills/interrogate | skills/interrogate | 4e5b1cf | ported |  |
| skills/ketchup | skills/ketchup | — | pending | 新技能，批次 B4 |
| skills/ketchup-video | skills/ketchup-video | — | pending | 新技能，批次 B4 |
| skills/maintain-formal-verification-skill | skills/maintain-formal-verification-skill | — | pending | 新技能，批次 B4 |
| skills/maintain-verification-skill | skills/maintain-verification-skill | c742dd6 | ported |  |
| skills/make-bot-ui | skills/make-bot-ui | c742dd6 | ported |  |
| skills/no-comments | skills/no-comments | 4e5b1cf | ported |  |
| skills/poteto-help | skills/p3-help | 4e5b1cf | ported | 改名 |
| skills/poteto-mode | skills/p3-mode | 4e5b1cf | ported | 改名 |
| skills/principle-attack-the-premise | skills/principle-attack-the-premise | c742dd6 | ported |  |
| skills/principle-boundary-discipline | skills/principle-boundary-discipline | c742dd6 | ported |  |
| skills/principle-build-the-lever | skills/principle-build-the-lever | c742dd6 | ported |  |
| skills/principle-encode-lessons-in-structure | skills/principle-encode-lessons-in-structure | c742dd6 | ported |  |
| skills/principle-exhaust-the-design-space | skills/principle-exhaust-the-design-space | c742dd6 | ported |  |
| skills/principle-experience-first | skills/principle-experience-first | c742dd6 | ported |  |
| skills/principle-explain-the-number | skills/principle-explain-the-number | c742dd6 | ported |  |
| skills/principle-fix-root-causes | skills/principle-fix-root-causes | c742dd6 | ported |  |
| skills/principle-foundational-thinking | skills/principle-foundational-thinking | c742dd6 | ported |  |
| skills/principle-guard-the-context-window | skills/principle-guard-the-context-window | c742dd6 | ported | description 保留 delegated tasks 用词 |
| skills/principle-laziness-protocol | skills/principle-laziness-protocol | c742dd6 | ported |  |
| skills/principle-make-operations-idempotent | skills/principle-make-operations-idempotent | c742dd6 | ported |  |
| skills/principle-migrate-callers-then-delete-legacy-apis | skills/principle-migrate-callers-then-delete-legacy-apis | c742dd6 | ported |  |
| skills/principle-minimize-reader-load | skills/principle-minimize-reader-load | c742dd6 | ported |  |
| skills/principle-model-the-domain | skills/principle-model-the-domain | c742dd6 | ported |  |
| skills/principle-never-block-on-the-human | skills/principle-never-block-on-the-human | c742dd6 | ported |  |
| skills/principle-outcome-oriented-execution | skills/principle-outcome-oriented-execution | c742dd6 | ported |  |
| skills/principle-prove-it-works | skills/principle-prove-it-works | c742dd6 | ported |  |
| skills/principle-redesign-from-first-principles | skills/principle-redesign-from-first-principles | c742dd6 | ported |  |
| skills/principle-separate-before-serializing-shared-state | skills/principle-separate-before-serializing-shared-state | c742dd6 | ported |  |
| skills/principle-sequence-verifiable-units | skills/principle-sequence-verifiable-units | c742dd6 | ported |  |
| skills/principle-subtract-before-you-add | skills/principle-subtract-before-you-add | c742dd6 | ported |  |
| skills/principle-test-behavior-not-implementation | skills/principle-test-behavior-not-implementation | c742dd6 | ported |  |
| skills/principle-type-system-discipline | skills/principle-type-system-discipline | c742dd6 | ported |  |
| skills/recall | skills/recall | 4e5b1cf | ported |  |
| skills/reflect | skills/reflect | 4e5b1cf | ported |  |
| skills/setup-pstack | skills/setup-p3 | 4e5b1cf | ported | 改名 |
| skills/sharpen | skills/sharpen | — | pending | 新技能，批次 B4 |
| skills/show-me-your-work | skills/show-me-your-work | 4e5b1cf | ported |  |
| skills/statechart | skills/statechart | — | pending | 新技能，批次 B4 |
| skills/swarm | skills/swarm | 4e5b1cf | ported |  |
| skills/tdd | skills/tdd | c742dd6 | ported |  |
| skills/teach | skills/teach | c742dd6 | ported |  |
| skills/technical-writing | skills/technical-writing | c742dd6 | ported |  |
| skills/typescript-best-practices | skills/typescript-best-practices | c742dd6 | ported | 保留 p3 去掉的 paths: frontmatter 字段 |
| skills/unslop | skills/unslop | c742dd6 | ported |  |
| skills/why | skills/why | 4e5b1cf | ported |  |
| agents/poteto-agent.md | agents/p3-agent.md | 4e5b1cf | ported | 改名 |
| agents/comment-sicko.md | agents/comment-sicko.md | c742dd6 | ported | |
| README.md | README.md | 4e5b1cf | ported | p3 README 已重写，只摘技能表语义，批次 B5 |

## 有意缺口与忽略路径

| 上游路径（支持 glob） | 处理 | 理由 |
|---|---|---|
| .cursor-plugin/** | ignore | Cursor 清单，p3 靠 install.sh 软链 |
| plugin.json | ignore | Agent Plugins 根清单，p3 无插件清单 |
| docs/harness/** | ignore | Claude Code 适配说明，p3 面向 T3 Code |
| docs/guide/** | ignore | D5=A：本轮不带指南 |
| automations/** | ignore | 作者个人自动化，p3 从未带 |
| agents/comment-sicko.md | ignore | 上游改的是 Cursor agent id，p3 的 agents/ 是提示词 |
| skills/make-bot-ui/SKILL.md | ignore | 上游改的 name 字段，p3 已一致 |
| skills/poteto-mode/scripts/watch-pr/** | ignore | 由 watch_pull_request 取代 |
| skills/poteto-mode/scripts/orch/** | ignore | 上游已删除，p3 从未带 |
| skills/poteto-mode/scripts/worktree-audit.sh | ignore | 由 t3_worktree_* 取代 |

## 白名单

| 判据 | 路径 | 理由 |
|---|---|---|
| P4 schedule | skills/p3-help/SKILL.md | p3 改成事件唤醒与 schedule_task 按需提及，未逐句保留 /loop；B3 改写 p3-help 时复核 |
| P4 schedule | skills/p3-mode/playbooks/visual-parity.md | p3 改成事件唤醒，不再用定时 |
| P4 preview | skills/p3-help/SKILL.md | p3-help 没有 control-ui/cli 对应句；B3 改写时复核 |
| P5 | agents/p3-agent.md | T3 改写最深，B3 重写首段 |
| P5 | skills/make-bot-ui/SKILL.md | T3 改写最深（preview_*/device_* 取代 control-ui） |
| P5 | skills/p3-mode/playbooks/babysit.md | T3 改写最深（watch_pull_request 事件唤醒） |
| P5 | skills/p3-mode/playbooks/worktree-cleanup.md | T3 改写最深（t3_worktree_* 取代审计脚本） |
| P5 | skills/setup-p3/SKILL.md | T3 改写最深（角色表与 providerInstanceId 写法） |
| P6 | skills/architect/references/runner-prompt.md | 上游同样指向不存在的 references/rationale-template.md |
| P6 | skills/setup-p3/SKILL.md | T3 侧有意加 disable-model-invocation |
| P8 | agents/p3-agent.md | 基线已超出 |
| P8 | skills/figure-it-out/SKILL.md | 基线已超出 |
| P8 | skills/how/references/explorer-prompt.md | 基线已超出：多出 T3 工具说明 |
| P8 | skills/p3-mode/playbooks/autopilot-full.md | 基线已超出，B3 重写 |
| P8 | skills/p3-mode/playbooks/autopilot-stack.md | 基线已超出，B3 重写 |
| P8 | skills/p3-mode/playbooks/babysit.md | 基线已超出：watch_pull_request 说明 |
| P8 | skills/p3-mode/playbooks/orchestrate.md | 基线已超出；D2=A 重写后应能去掉本行 |
| P8 | skills/p3-mode/playbooks/pause-safely.md | 基线已超出 |
| P8 
| P8 | skills/show-me-your-work/SKILL.md | 基线已超出 |
| P8 | skills/why/references/investigator-prompt.md | 基线已超出：T3 改写 |
| P8 | skills/why/references/synthesizer-prompt.md | 基线已超出：T3 改写 |

## 逐字搬运

| 路径（p3 侧，支持 glob） | 理由 |
|---|---|
| skills/principle-attack-the-premise/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-encode-lessons-in-structure/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-exhaust-the-design-space/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-explain-the-number/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-fix-root-causes/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-laziness-protocol/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-make-operations-idempotent/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-migrate-callers-then-delete-legacy-apis/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-minimize-reader-load/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-model-the-domain/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-never-block-on-the-human/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-redesign-from-first-principles/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-subtract-before-you-add/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-test-behavior-not-implementation/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/principle-type-system-discipline/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/why/references/epistemics.md | B1 三方合并后与上游逐字相同 |
| skills/why/references/sources/code-archaeology.md | B1 三方合并后与上游逐字相同 |
| skills/why/references/sources/datadog.md | B1 三方合并后与上游逐字相同 |
| skills/why/references/sources/incident-postmortem.md | B1 三方合并后与上游逐字相同 |
| skills/why/references/sources/sentry.md | B1 三方合并后与上游逐字相同 |
| skills/why/references/sources/slack.md | B1 三方合并后与上游逐字相同 |
| skills/correct/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/technical-writing/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/unslop/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/typescript-best-practices/references/patterns.md | B1 三方合并后与上游逐字相同 |
| skills/principle-build-the-lever/SKILL.md | B1 三方合并后与上游逐字相同 |
