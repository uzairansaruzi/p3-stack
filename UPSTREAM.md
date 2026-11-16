# Upstream tracking

upstream: https://github.com/cursor/plugins
subtree: pstack/
pin: bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7
pin-date: 2026-11-15
pin-version: 0.15.42
synced-on: 2026-11-16
sync-target: bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7
sync-spec: docs/sync-spec-bf0c7cd.md

`pin` 取「上游 main 上最后一个动过 subtree 的 commit」，不取仓库 HEAD。同步进行中 `pin` 取各行「对齐到」的最小值，全部对齐后才前进到 `sync-target`（本轮已于 2026-11-16 前进到 bf0c7cd）。
`scripts/upstream-diff.sh` 与 `scripts/parity-check.sh` 只读本文件：头部 `key: value` 加下面四张表（前三张是 spec §5.1 的固定表，第四张是 parity-check 的可选扩展）。状态取值：`ported`（已落地）、`pending`（已决定移植、未落地）、`gap`（有意缺口）、`p3-only`（p3 独有）。

## 映射

| 上游 | p3 | 对齐到 | 状态 | 备注 |
|---|---|---|---|---|
| skills/architect | skills/architect | bf0c7cd | ported |  |
| skills/arena | skills/arena | bf0c7cd | ported |  |
| skills/automate-me | skills/automate-me | bf0c7cd | ported |  |
| skills/benchmark-checklist | skills/benchmark-checklist | bf0c7cd | ported |  |
| skills/blast-radius | skills/blast-radius | bf0c7cd | ported |  |
| skills/bro | skills/bro | bf0c7cd | ported |  |
| skills/correct | skills/correct | bf0c7cd | ported |  |
| skills/create-formal-verification-skill | skills/create-formal-verification-skill | bf0c7cd | ported | 新技能 |
| skills/create-verification-skill | skills/create-verification-skill | bf0c7cd | ported |  |
| skills/figure-it-out | skills/figure-it-out | bf0c7cd | ported |  |
| skills/how | skills/how | bf0c7cd | ported |  |
| skills/in-your-own-words | skills/in-your-own-words | bf0c7cd | ported | 新技能 |
| skills/interrogate | skills/interrogate | bf0c7cd | ported |  |
| skills/ketchup | skills/ketchup | bf0c7cd | ported | 新技能 |
| skills/ketchup-video | skills/ketchup-video | bf0c7cd | ported | 新技能 |
| skills/maintain-formal-verification-skill | skills/maintain-formal-verification-skill | bf0c7cd | ported | 新技能 |
| skills/maintain-verification-skill | skills/maintain-verification-skill | bf0c7cd | ported |  |
| skills/make-bot-ui | skills/make-bot-ui | bf0c7cd | ported |  |
| skills/no-comments | skills/no-comments | bf0c7cd | ported |  |
| skills/poteto-help | skills/p3-help | bf0c7cd | ported | 改名 |
| skills/poteto-mode | skills/p3-mode | bf0c7cd | ported | 改名 |
| skills/principle-attack-the-premise | skills/principle-attack-the-premise | bf0c7cd | ported |  |
| skills/principle-boundary-discipline | skills/principle-boundary-discipline | bf0c7cd | ported |  |
| skills/principle-build-the-lever | skills/principle-build-the-lever | bf0c7cd | ported |  |
| skills/principle-encode-lessons-in-structure | skills/principle-encode-lessons-in-structure | bf0c7cd | ported |  |
| skills/principle-exhaust-the-design-space | skills/principle-exhaust-the-design-space | bf0c7cd | ported |  |
| skills/principle-experience-first | skills/principle-experience-first | bf0c7cd | ported |  |
| skills/principle-explain-the-number | skills/principle-explain-the-number | bf0c7cd | ported |  |
| skills/principle-fix-root-causes | skills/principle-fix-root-causes | bf0c7cd | ported |  |
| skills/principle-foundational-thinking | skills/principle-foundational-thinking | bf0c7cd | ported |  |
| skills/principle-guard-the-context-window | skills/principle-guard-the-context-window | bf0c7cd | ported | description 保留 delegated tasks 用词 |
| skills/principle-laziness-protocol | skills/principle-laziness-protocol | bf0c7cd | ported |  |
| skills/principle-make-operations-idempotent | skills/principle-make-operations-idempotent | bf0c7cd | ported |  |
| skills/principle-migrate-callers-then-delete-legacy-apis | skills/principle-migrate-callers-then-delete-legacy-apis | bf0c7cd | ported |  |
| skills/principle-minimize-reader-load | skills/principle-minimize-reader-load | bf0c7cd | ported |  |
| skills/principle-model-the-domain | skills/principle-model-the-domain | bf0c7cd | ported |  |
| skills/principle-never-block-on-the-human | skills/principle-never-block-on-the-human | bf0c7cd | ported |  |
| skills/principle-outcome-oriented-execution | skills/principle-outcome-oriented-execution | bf0c7cd | ported |  |
| skills/principle-prove-it-works | skills/principle-prove-it-works | bf0c7cd | ported |  |
| skills/principle-redesign-from-first-principles | skills/principle-redesign-from-first-principles | bf0c7cd | ported |  |
| skills/principle-separate-before-serializing-shared-state | skills/principle-separate-before-serializing-shared-state | bf0c7cd | ported |  |
| skills/principle-sequence-verifiable-units | skills/principle-sequence-verifiable-units | bf0c7cd | ported |  |
| skills/principle-subtract-before-you-add | skills/principle-subtract-before-you-add | bf0c7cd | ported |  |
| skills/principle-test-behavior-not-implementation | skills/principle-test-behavior-not-implementation | bf0c7cd | ported |  |
| skills/principle-type-system-discipline | skills/principle-type-system-discipline | bf0c7cd | ported |  |
| skills/recall | skills/recall | bf0c7cd | ported |  |
| skills/reflect | skills/reflect | bf0c7cd | ported |  |
| skills/setup-pstack | skills/setup-p3 | bf0c7cd | ported | 改名 |
| skills/sharpen | skills/sharpen | bf0c7cd | ported | 新技能 |
| skills/show-me-your-work | skills/show-me-your-work | bf0c7cd | ported |  |
| skills/statechart | skills/statechart | bf0c7cd | ported | 新技能 |
| skills/swarm | skills/swarm | bf0c7cd | ported |  |
| skills/tdd | skills/tdd | bf0c7cd | ported |  |
| skills/teach | skills/teach | bf0c7cd | ported |  |
| skills/technical-writing | skills/technical-writing | bf0c7cd | ported |  |
| skills/typescript-best-practices | skills/typescript-best-practices | bf0c7cd | ported | 保留 p3 去掉的 paths: frontmatter 字段 |
| skills/unslop | skills/unslop | bf0c7cd | ported |  |
| skills/why | skills/why | bf0c7cd | ported |  |
| agents/poteto-agent.md | agents/p3-agent.md | bf0c7cd | ported | 改名 |
| agents/comment-sicko.md | agents/comment-sicko.md | bf0c7cd | ported | |
| README.md | README.md | bf0c7cd | ported | p3 README 已重写，只摘技能表语义 |

## 有意缺口与忽略路径

| 上游路径（支持 glob） | 处理 | 理由 |
|---|---|---|
| .cursor-plugin/** | ignore | Cursor 清单，p3 靠 install.sh 软链 |
| plugin.json | ignore | Agent Plugins 根清单，p3 无插件清单 |
| docs/harness/** | ignore | Claude Code 适配说明，p3 面向 T3 Code |
| docs/guide/** | ignore | D5=A：本轮不带指南 |
| automations/** | ignore | 作者个人自动化，p3 从未带 |
| skills/poteto-mode/scripts/watch-pr/** | ignore | 由 watch_pull_request 取代 |
| skills/poteto-mode/scripts/orch/** | ignore | 上游已删除，p3 从未带 |
| skills/poteto-mode/scripts/worktree-audit.sh | ignore | 由 git worktree list --porcelain 与 gh 取代 |
| skills/poteto-mode/playbooks/**（仅 Origin forge 分支） | note | 上游 playbook 里的 Origin forge 分支已删，p3 只保留 gh；这是正文缺口，不是文件缺口，不进忽略表 |
| pstack/**（默认模型内容） | note | 2026-11-16 max 定：不跟随上游默认模型换代（fable / opus / gemini），p3 角色模型由 setup-p3 按 orchestrator_capabilities 生成；其家族/vendor 语义、预算按步移动、defaults 标记一并跳过。见 docs/sync-spec-bf0c7cd.md §2.2 |

`install.sh` 是 p3 独有的安装方式：用户级多目标，把 `skills/*` 软链进 `~/.agents/skills` 与各 Claude 配置家目录的 `skills/`，同名外来条目跳过、不覆盖（`--replace <name>` 显式接管）。上游靠 `/add-plugin` 与 `.cursor-plugin/` 清单安装，没有对应脚本，所以不进映射表。

## 白名单

| 判据 | 路径 | 理由 |
|---|---|---|
| P4 schedule | skills/p3-mode/playbooks/visual-parity.md | p3 改成事件唤醒，不再用定时 |
| P4 preview | skills/p3-help/SKILL.md | p3-help 没有 control-ui/cli 对应句；B3 改写时复核 |
| P5 | agents/p3-agent.md | T3 改写最深，B3 重写首段 |
| P5 | skills/make-bot-ui/SKILL.md | T3 改写最深（preview_*/device_* 取代 control-ui） |
| P5 | skills/p3-mode/playbooks/babysit.md | T3 改写最深（watch_pull_request 事件唤醒） |
| P5 | skills/p3-mode/playbooks/worktree-cleanup.md | T3 改写最深（git worktree/gh/t3_thread_search 取代审计脚本） |
| P5 | skills/setup-p3/SKILL.md | T3 改写最深（角色表与 providerInstanceId 写法） |
| P6 | skills/setup-p3/SKILL.md | T3 侧有意加 disable-model-invocation |
| P8 | agents/p3-agent.md | 基线已超出 |
| P8 | skills/figure-it-out/SKILL.md | 基线已超出 |
| P8 | skills/p3-mode/playbooks/pause-safely.md | 基线已超出 |
| P8 | skills/show-me-your-work/SKILL.md | 基线已超出 |
| P8 | skills/ketchup-video/SKILL.md | D3=B：HTML 页 + preview_recording 录制步骤需写明 |
| P8 | skills/p3-mode/playbooks/worktree-cleanup.md | +2 行：git worktree/gh/t3_thread_search 取代审计脚本 |
| P8 | skills/statechart/SKILL.md | +1 行：离线时设 TLA2TOOLS/JAVA 的出路 |
| P8 | skills/statechart/references/render.md | +1 行：T3 下用图片语法或 html_render 展示 SVG |

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
| skills/correct/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/technical-writing/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/unslop/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/typescript-best-practices/references/patterns.md | B1 三方合并后与上游逐字相同 |
| skills/principle-build-the-lever/SKILL.md | B1 三方合并后与上游逐字相同 |
| skills/in-your-own-words/SKILL.md | 新技能，与上游逐字相同 |
| skills/sharpen/SKILL.md | 新技能，与上游逐字相同 |
| skills/statechart/scripts/** | D6=A：整目录原样搬 |
