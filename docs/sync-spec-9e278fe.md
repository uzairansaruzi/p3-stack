# p3-stack 跟上游 pstack 同步：实施 spec（9e278fe）

- 上游：https://github.com/cursor/plugins
- 上一 pin：`bf0c7cd`（2026-11-15，0.15.42）
- 本轮目标：`9e278fe`（上游 2026-11-23 18:41 −0600，即 2026-11-24 08:41 UTC+8，0.15.48）
- 授权：max 2026-11-24 同意同步批 1 与批 2；批 3 待定

## 0. 结论摘要

上游本轮 6 个提交、79 个文件、+382/−1413，以瘦身为主。批 1（statechart 修复、`/reframe`）与批 2（14 条 principle、unslop、technical-writing 瘦身）已落地。批 3（reflect、多阶段计划、architect）会丢掉 p3 自有的编排与模板，暂不跟进，上游差异保留在这 5 个单元。

`scripts/parity-check.sh` 全绿（PASS 7、ALLOW 6、FAIL 0、STALE 0）。`scripts/upstream-diff.sh` 报 5 个待定单元：architect、p3-help、p3-mode、reflect、setup-p3。

## 1. 上游范围

| 提交 | 内容 | 处理 |
|---|---|---|
| `2f87c85` | 14 条 principle 与 unslop、technical-writing 瘦身；opening-a-pr、babysit、multi-phase-plan、architect 压缩；reflect 改单文件；删 check-plan.mjs 与 orchestrate.md；新增 worker.md；Opus 优先并封顶 xhigh | 文字瘦身跟进；结构性删改归批 3 |
| `e58dd04`、`dd24b67` | Gemini 面板座位改 Gemini 4 Neon，预算档位调整 | 跳过（默认模型策略） |
| `0b46ec3` | statechart 原生 Windows、TLC 的 `\r\n` 行尾、UTF-8 输出、janitor/kill 去 `/bin/sh` | 跟进 |
| `2dd5c0c`、`9e278fe` | 新增 `/reframe`，描述有歧义时先列候选问题 | 跟进 |

## 2. 与上游差异的成因

p3 与上游在 61 个映射单元里 30 个有差异、31 个逐字相同。差异按成因分四类，消解方式不同。

**运行时原语。** T3 的委派、唤醒、调度、记忆、界面验证、PR 登记与模型解析都和 Cursor 不同，这一类比的是机制，不是措辞。`delegate_task` 的子 agent 只拿 brief，所以每份 brief 必须自带目标与上下文；`watch_pull_request` 事件唤醒取代轮询与 `scripts/watch-pr`；`schedule_task` 取代 `/loop`；`t3_thread_read`/`t3_thread_search` 取代 `agent-transcripts`；`preview_*`/`device_*` 取代 `control-ui`/`control-cli`；`link_pull_request` 只登记不创建；角色模型按 `orchestrator_capabilities` 解析，不写死 slug。p3-mode、setup-p3、make-bot-ui、reflect、recall、automate-me、babysit、orchestrate 的主要差异都在这里。

**发行方式。** 上游靠 Cursor 插件清单和 `/add-plugin` 安装；p3 是多 harness 的用户级软链安装，所以有 `install.sh`、`install.targets`、路径自解析规则，以及上游没有的 `UPSTREAM.md` 与同步脚本。

**立场选择。** 与 T3 无关，是 p3 主动收窄：只保留 `gh`，删掉 Origin 与 Graphite 分支；不跟随上游默认模型换代；去掉 `fast or standard speed` 措辞；用本地 unslop 取代 `cursor-team-kit` 的 `/deslop`。这些需要在 UPSTREAM.md 里登记，不能当作同步遗漏。

**上游演进。** 本轮 6 个提交属于这一类，已按批 1+2 处理，批 3 暂缓。

## 3. 台账与心跳

两者都不是 p3 发明，各对应一个上游概念，只是换了 T3 机制。

- **心跳**：上游 `autonomous-run.md` 的 time-based heartbeat 和 `multi-phase-plan.md` 的 `/loop 1h` 审计节拍。T3 没有 `/loop`，等价物是 `schedule_task` 的 interval tick。p3 在 2026-10 初版移植（`09909eb`）引入，`2a2c7b5` 补上关闭动作，`ba2d2df` 写明 tick prompt 要带 playbook 与台账路径。
- **台账**：上游 orchestrate 的 Project tracker `notes.md`、autopilot-full 的 decision trail，以及 multi-phase-plan 的「每次 tick 记一行」在 T3 的落点。T3 线程的 todolist 不跨轮次持久，PR 列表只有 PR 与 head，没有 owner 与 verdict，所以 p3 用一行一个单元的文件台账。`ba2d2df` 引入。

解决的问题只有一个：跨天程序在轮次结束、上下文压缩、线程重启之后，coordinator 仍要能拿到每个单元的状态，并在没有事件时被唤醒。

按奥卡姆剃刀，两者都保留：台账的五个字段（owner、PR、head、verdict、state）每个都承担下一步动作，删任一个都要回读 PR 或线程；心跳是 T3 唯一的定时唤醒机制。可删的是重复解释，`orchestrate.md` 里「todolist 只是本轮视图」一句已删。上游本轮删掉 orchestrate.md，p3 保留为 p3 专属，因为这段话把 delegate、watch、schedule 组合成一个跨天程序的用法，figure-it-out 每次重推的成本更高。

## 4. 本轮落地

| 上游路径 | p3 路径 | 做法 |
|---|---|---|
| `skills/statechart/scripts/**` | 同路径 | 整目录按 `9e278fe` 替换，新增 `janitor.ts`、`kill.ts`；`SKILL.md` 补原生 Windows 运行方式，保留 p3 的 `<skill dir>` 自解析与离线出路 |
| `skills/reframe/SKILL.md` | 同路径 | 新技能，逐字搬；p3-help 与 README 技能表各加一行 |
| 14 条 `principle-*` | 同路径 | 逐字搬 `9e278fe`，其中 5 条补进「逐字搬运」表 |
| `skills/unslop/SKILL.md` | 同路径 | 逐字搬 |
| `skills/technical-writing/SKILL.md` | 同路径 | 逐字搬 |
| `skills/poteto-mode/playbooks/{feature,refactoring}.md` | 同路径 | architect 一句改「for the shape」 |
| `skills/poteto-mode/worker.md` | `agents/p3-agent.md` | 不新建文件，把 brief 即整条标准、不问人、只在真阻塞停三条并进 delegate brief |

## 5. 有意不同步

| 上游改动 | 处理 | 理由 |
|---|---|---|
| 默认模型与角色表：Opus 优先封顶 xhigh、Gemini 4 Neon、退役 `hardest tasks`/`architect runners`/`reflect *`、预算 4→3 档 | 跳过 | 2026-11-16 既定策略；p3 角色由 setup-p3 按 `orchestrator_capabilities` 生成 |
| reflect 改单文件、删 4 个 reviewer 模板 | 批 3 待定 | p3 的三路 reviewer 是 T3 上的重写，需单独评估 |
| multi-phase-plan 砍成 5 步、删 check-plan.mjs | 批 3 待定 | 计划校验脚本是 p3 的结构化约束，删它要另作决定 |
| architect 砍成两段、删 3 个 references | 批 3 待定 | p3 的 Phase B 走 arena 与 runner-prompt，删 references 要先改写法 |
| 删 orchestrate.md | p3 保留 | 见 §3；P2 白名单登记 |
| opening-a-pr 压到 3 段、babysit 压到 6 条 | 批 3 待定 | p3 版本已绑定 `watch_pull_request` 与 `link_pull_request` |

## 6. 验收

| 判据 | 命令 | 结果 |
|---|---|---|
| 上游覆盖与双向对应 | `scripts/parity-check.sh` | PASS 7、ALLOW 6、FAIL 0、STALE 0 |
| 未同步单元清单 | `scripts/upstream-diff.sh` | 5 个待定单元，warnings 0 |
| statechart 脚本 | `npm test`（`skills/statechart/scripts`） | 374 tests：304 pass、0 fail、70 skipped（未设 `TLA2TOOLS`） |
| 逐字一致性 | parity-check P9 | 436 个文件与 `9e278fe` 逐字相同 |
