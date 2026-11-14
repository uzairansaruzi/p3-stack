# p3-stack 跟上游 pstack 同步：实施 spec（c742dd6）

> **状态**：草案，待人批准后实施。本阶段只写 spec，没有改 `skills/`、`agents/`、`AGENTS.md`、`README.md`。
> **写于**：2026-11-14
> **上游**：https://github.com/cursor/plugins 的 `pstack/`，同步目标 `c742dd61706fbacc1b95f1a20b7b988cf096ce6c`（2026-10-27，pstack 0.15.36）。上游仓库 HEAD 已前进到 `3dbd22f`，但 `pstack/` 在 `c742dd6` 之后没有再改动，所以目标不变。
> **p3-stack 基线**：`09909eb`（2026-10-05，本地分支 `sync/upstream-c742dd6`）。
> **改造规则**：本仓库根目录 `AGENTS.md`，下文称「AGENTS 对照表」。

## 0. 结论摘要

- **base pin 唯一**：`4e5b1cf`（pstack 0.15.10，「add /poteto-help skill (#502)」）。依据见 §1。
- **同步量**：`4e5b1cf..c742dd6` 之间 74 个 commit 动过 `pstack/`，共 522 个文件：新增 418、修改 97、删除 7。418 个新增里 405 个是 `statechart/scripts/` 下的实现与测试夹具。
- **处理方案分布**（含 statechart 脚本按「直接搬」计）：

| 方案 | 新增 | 修改 | 删除 | 合计 |
|---|---|---|---|---|
| 直接搬 | 408 | 31 | 0 | 439 |
| 需适配 | 7 | 43 | 4 | 54 |
| 不处理 | 3 | 23 | 3 | 29 |
| 合计 | 418 | 97 | 7 | 522 |

- **7 个新技能**里，`in-your-own-words`、`sharpen`、`maintain-formal-verification-skill` 可直接搬；`ketchup`、`create-formal-verification-skill`、`statechart` 每一步都有 T3 对应，只需小适配；**`ketchup-video` 缺视频渲染机制，需要你选方案**（§3.4）。
- **最大的一处设计分歧**是 `orchestrate` playbook：上游已把「队列加 TSV 账本加脚本」整篇推翻，改成 25 行的「协调者用自己的工具」；p3 仍是旧结构。需要你选（D2）。
- **待人决策 8 项（D2 到 D9）**，另有 D1 供你确认 pin 的依据，见 §7。其中 D2、D3、D6 会改变工作量与交付内容。

## 1. base pin

### 1.1 结论

| 项 | 值 |
|---|---|
| pin commit | `4e5b1cf2ccb0ea3716f08c8ee0a5856b5ab93536` |
| 标题 | `feat(pstack): add /poteto-help skill (#502)` |
| 上游提交时间 | 2026-10-04 23:36 PDT（2026-10-05 06:36 UTC） |
| pstack 版本 | 0.15.10 |
| p3-stack 导入提交 | `09909eb`，2026-10-05 07:40 UTC |

### 1.2 判定方法（四步）

候选范围取上游 2026-09-22（`70b2dc8`，上一次大改）到 2026-10-05（`df58112`，Sol 下线）之间动过 `pstack/` 的 14 个 commit。比对前先把 p3 的改名（`poteto-mode→p3-mode`、`poteto-help→p3-help`、`setup-pstack→setup-p3`、`poteto-agent→p3-agent`）套到上游文本上，再逐行比较，忽略空白行。

**第一步：时间线排除后段。** p3 导入提交落在 2026-10-05 07:40 UTC。上游此后的 commit 最早是 `00b52d9`（2026-10-05 16:03 UTC），不可能被 p3 包含，所以候选只能是 `4e5b1cf` 及更早的 commit。

**第二步：用「没被 T3 改写过」的文件划出窗口。** 在 `4e5b1cf` 上，p3 有 43 个文件与上游逐行相同（套改名映射、忽略空白后；不含 `scripts/`）：`principle-*` 22 个、`why` 的 references 与 sources 9 个、`architect` 与 `interrogate` 的 references 各 2 个，以及 `bro`、`correct`、`tdd`、`technical-writing`、`typescript-best-practices`、`unslop`、`show-me-your-work`、`p3-mode` 各 1 个。这类文件 T3 没有改过，所以它们随上游 commit 的变化最能反映 p3 取自哪个版本。拿这 43 个文件去比每个候选：

| 候选 | 提交时间（UTC） | 43 个文件仍相同的数量 |
|---|---|---|
| `70b2dc8` | 2026-09-23 02:21 | 33 |
| `b0b9c7a` | 2026-09-23 17:37 | 38 |
| `23e4138` | 2026-10-03 04:37 | 41 |
| `9511e60` | 2026-10-03 20:28 | 42 |
| **`a586282` 到 `df58112` 的 8 个 commit** | 2026-10-03 23:19 至 2026-10-06 01:05 | **43** |
| `00b14f1`（下一个大改） | 2026-10-10 22:43 | 27 |

窗口内这 43 个文件没有任何改动，所以单靠逐行或 sha 精确匹配分不出窗口内的先后。窗口与第一步取交集，剩 `a586282`、`e43c7ee`、`4e5b1cf` 三个，需要第三步再分。

**第三步：用 `p3-help` 内容定位。** `poteto-help` 在 `4e5b1cf` 才首次出现。`a586282`、`e43c7ee` 的上游树里没有这个文件，而 p3 有 `p3-help`，所以 pin 不早于 `4e5b1cf`。窗口里晚于 `4e5b1cf` 的 commit 各自改了 `poteto-help`，p3-help 都不带这些改动：

| 上游 commit | 它对 `poteto-help` 做的改动 | p3-help 是否带有 |
|---|---|---|
| `00b52d9` | description 缩短并加 `disable-model-invocation: true` | 否，p3-help 仍是旧 description「Use for /p3-help, or when the user asks…」，无该字段 |
| `807c031` | 加 `references/prompting.md`、`references/recipes.md` | 否，p3 没有这两个文件 |
| `1e56b29` | 无模型规则时问一次是否现在跑 setup | 否，p3-help 没有这段 |
| `df58112` | 默认模型去掉 Sol | 不适用（p3 不写模型名） |

**第四步：数值复核。** p3-help 与各候选上游版本（套改名映射、忽略空白）的逐行差异数随 commit 单调上升：

| 候选 | `4e5b1cf` | `00b52d9` | `807c031` | `2cbf585` | `1e56b29` | `df58112` | `c742dd6` |
|---|---|---|---|---|---|---|---|
| p3-help 差异行 | **79** | 80 | 82 | 82 | 85 | 87 | 98 |

最小值在 `4e5b1cf`，与前三步一致。四步合起来只剩一个候选，所以不需要人决策。

### 1.3 复跑方式与注意事项

- 本次用的比对脚本是一次性的，没有入库。每一步的输入都是 `git ls-tree`、`git show <commit>:pstack/<路径>` 与 p3 工作区文件，附录给出取数命令，要复核可以照着重写。判定逻辑落成 `scripts/upstream-diff.sh` 后可复用（§5）。
- 全库「差异行总数」不适合作唯一依据。`e43c7ee` 的总差异（830）比 `4e5b1cf`（909）还小，原因是 `e43c7ee` 的上游树里没有 `poteto-help`，那 79 行差异没有被算进去。
- 背景里提到的「`why` 新增 `references/sources/<source>.md` 与 Preserve/Change/Avoid/Risk 收尾」「poteto-mode 编排表新增 unslop、deslop、control-cli/control-ui、benchmark-checklist、show-me-your-work」这两条漂移线索来自 hermes 端口（pin 在更早的 `c47b1284`）。**p3-stack 在 pin 上已经带有这些内容**：`why/references/sources/` 有 8 个文件，`why/SKILL.md` 第 144 行已有 Preserve / Change / Avoid / Risk，`p3-mode` 已引用 `unslop`、`benchmark-checklist`、`show-me-your-work`。它们不是 p3 的同步缺口。`control-cli/ui` 在 p3 里已被 `preview_*` 与 `device_*` 取代（AGENTS 对照表）。`deslop`（cursor-team-kit 的技能）p3 从未引用，`p3-mode` 的对应步骤是「提交前对 diff 跑 `unslop`」；上游本轮在 `autopilot-full` 又引用了一次 `deslop`，同步时按同一做法换成 `unslop`（§2.2 该行已注明）。

## 2. 同步清单

范围：`git diff --name-status --no-renames 4e5b1cf c742dd6 -- pstack/`，522 个文件。表里路径一律是上游路径（`pstack/` 下）。p3 对应路径按改名映射：`skills/poteto-mode→skills/p3-mode`、`skills/poteto-help→skills/p3-help`、`skills/setup-pstack→skills/setup-p3`、`agents/poteto-agent.md→agents/p3-agent.md`。

### 2.1 怎么读这张表

- **方案**
  - **直接搬**：纯原则文本，或上游改动与 p3 的 T3 改写不在同一处。套用上游改动（`git merge-file` 三方合并，base 取 pin，theirs 取目标，ours 取 p3，三者先套改名映射）即可，不需要新增 T3 机制。
  - **需适配**：上游改动涉及 Cursor 机制（`Task`、`subagent_type`、`/loop`、模型 slug、`AskQuestion` 等），或与 p3 已有的 T3 改写重叠。按 AGENTS 对照表重写，保留上游句子。
  - **不处理**：Cursor 或 Claude Code 专属，或 p3 已用 T3 工具取代。每条附理由。
- **冲突**列的判据是 `git merge-file` 的返回值：有冲突块写「冲突 N 处」，p3 有改写但无重叠写「可自动合并」，p3 与 pin 逐行相同写「无」。
- **批**对应 §6 的实施批次（B1 直接搬，B2 小适配，B3 大适配，B4 新技能，B5 收口，`—` 表示不处理）。
- 三种状态计数：修改 97、新增 418、删除 7。

### 2.2 逐文件表

#### 根与 agents（6 个文件）

| 上游路径（`pstack/` 下） | 状态 | 上游改了什么 | 方案 | 冲突 / 备注 | 批 |
|---|---|---|---|---|---|
| `.cursor-plugin/plugin.json` | 修改 | 版本号递增（0.15.x） | 不处理 | Cursor 清单，p3 靠 install.sh 软链 | — |
| `README.md` | 修改 | 新增 7 技能与 Claude Code 安装段、`poteto-help` 改手动触发、`interrogate` 改述；原则表摘要同步 | 需适配 | 冲突：p3 README 已重写（技能名只列清单），只摘技能表语义 | B5 |
| `agents/comment-sicko.md` | 修改 | frontmatter 的 agent id 改成 `comment-sicko`（让 Grok 能 spawn） | 不处理 | p3 的 agents/ 是提示词，无 harness id；Cursor 专属 | — |
| `agents/poteto-agent.md` | 修改 | 定位改成「`/poteto-mode` 运行中派出的 delegate」，不当 runner；运行 playbook、todo、spawn 的是接收 `/p3-mode` 的线程 | 需适配 | 冲突：p3-agent.md 已改写首段 | B3 |
| `plugin.json` | 新增 | 新增 Agent Plugins v1 根清单 | 不处理 | p3 无插件清单 | — |
| `docs/harness/claude-code.md` | 新增 | 新增 Claude Code 适配说明（逐项对照 Cursor 机制） | 不处理 | p3 目标是 T3 Code；该文件只为 Claude Code 安装写 | — |

#### p3-mode（上游 `poteto-mode`）SKILL 与 playbooks（19 个文件）

| 上游路径（`pstack/` 下） | 状态 | 上游改了什么 | 方案 | 冲突 / 备注 | 批 |
|---|---|---|---|---|---|
| `skills/poteto-mode/SKILL.md` | 修改 | ①首条消息复述用户目标，brief/PR `## Why`/最终报告开头都要复述 ②原则与 playbook 条目去掉括号内 skill 名/文件路径，改用命名规则 ③Subagents 增「Match the model to the job」、后台 steer/resume、slug 被拒时链式回退 ④poteto-agent 只作 delegate ⑤删 `mode:`/`reminder:` 等 Cursor 字段 | 需适配 | 冲突 7 处，最重的一份；p3 已把 Task 换成 delegate_task 并用角色名 | B3 |
| `skills/poteto-mode/playbooks/autonomous-run.md` | 修改 | 加推理档位句；「路上发现的问题」限定为「支持目标的」 | 需适配 | 冲突 1 处 | B3 |
| `skills/poteto-mode/playbooks/autopilot-full.md` | 修改 | 重写：owner 小时审计 `/loop 1h`、决策轨迹放根 agent 的 store 并每个单元 push、只对「运行能复现」的问题拦 PR、纯措辞改动不派 verifier、收尾用 ketchup | 需适配 | 冲突 1 处；`/loop 1h`→`schedule_task`，「VM 会死」→ worktree 可丢 | B3 |
| `skills/poteto-mode/playbooks/autopilot-stack.md` | 修改 | 缩成「跑 Autopilot-full 但不合并」，只列两处例外（停在 verified、仅在建立于另一 PR 时才叠栈） | 需适配 | 冲突 1 处 | B3 |
| `skills/poteto-mode/playbooks/babysit.md` | 修改 | Stack 拓扑那条改述；删「watcher re-arm 不授权合并」两行与 Reply 行 | 需适配 | 冲突 3 处：p3 用 watch_pull_request，该两行在 p3 已被改写 | B3 |
| `skills/poteto-mode/playbooks/bug-fix.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：仅因 p3 已改写同一邻行，一句话手工补 | B2 |
| `skills/poteto-mode/playbooks/eval.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：仅因 p3 已改写同一邻行，一句话手工补 | B2 |
| `skills/poteto-mode/playbooks/feature.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：仅因 p3 已改写同一邻行，一句话手工补 | B2 |
| `skills/poteto-mode/playbooks/hillclimb.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：仅因 p3 已改写同一邻行，一句话手工补 | B2 |
| `skills/poteto-mode/playbooks/multi-phase-plan.md` | 修改 | 检查与 check-plan 脚本的措辞更新（围栏代码块、行内代码） | 需适配 | 冲突 2 处；p3 用内联清单替代脚本 | B3 |
| `skills/poteto-mode/playbooks/opening-a-pr.md` | 修改 | PR 描述各节由说明段改成 `##` 标题清单并精简措辞；Stack 规则补「父 PR 合并后子 PR 改基到 trunk、补丁移到合并结果上、`--force-with-lease`」；子 agent 开 PR 前不再跑 interrogate | 需适配 | 冲突 3 处：Built-in PR tool、Origin CLI、deslop 在 p3 已删或改 | B3 |
| `skills/poteto-mode/playbooks/orchestrate.md` | 修改 | 整篇由「队列+TSV 账本+orch 脚本」改成「用协调者自己的工具」：Topology + Supervision 两节，112→25 行 | 需适配 | 冲突：设计方向被推翻，p3 仍是旧结构（Store layout/units.tsv/ledger）。见 §7 决策 D2 | B3 |
| `skills/poteto-mode/playbooks/perf-issue.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：仅因 p3 已改写同一邻行，一句话手工补 | B2 |
| `skills/poteto-mode/playbooks/refactoring.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：仅因 p3 已改写同一邻行，一句话手工补 | B2 |
| `skills/poteto-mode/playbooks/runtime-forensics.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：仅因 p3 已改写同一邻行，一句话手工补 | B2 |
| `skills/poteto-mode/playbooks/session-pickup.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：仅因 p3 已改写同一邻行，一句话手工补 | B2 |
| `skills/poteto-mode/playbooks/shipping.md` | 修改 | 九步压成六步，每条规则附理由；保留 patch-id 判定「结论是否跨 rebase 存活」；改基后 `--force-with-lease` | 需适配 | 冲突 1 处；`gh`/Origin 分支 p3 已改为只留 gh | B3 |
| `skills/poteto-mode/playbooks/trace-forensics.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0）；另有 3 处措辞精简 | 需适配 | 冲突：同上 | B2 |
| `skills/poteto-mode/playbooks/worktree-cleanup.md` | 修改 | 审计脚本改带 `-b <pr-base-ref>`，MERGED 对比默认分支而非 `origin/main`（cf9a111） | 需适配 | p3 用 t3_worktree_list/status，不用脚本；只把「按 PR 基线判 merged」补进分类步 | B2 |

#### p3-mode 的 scripts（13 个文件）

| 上游路径（`pstack/` 下） | 状态 | 上游改了什么 | 方案 | 冲突 / 备注 | 批 |
|---|---|---|---|---|---|
| `skills/poteto-mode/scripts/check-plan.mjs` | 修改 | 围栏代码块内不检查（87c8103）；行内代码分隔符匹配（86c2448） | 不处理 | p3 没有该脚本；§7 D4 问是否引入 | — |
| `skills/poteto-mode/scripts/check-plan.test.ts` | 新增 | 新增 check-plan 的测试 | 不处理 | 同上 | — |
| `skills/poteto-mode/scripts/orch/orch.test.ts` | 删除 | 上游删除（Orchestrate 不再调脚本） | 不处理 | p3 从未带 orch 脚本 | — |
| `skills/poteto-mode/scripts/orch/orch.ts` | 删除 | 上游删除（Orchestrate 不再调脚本） | 不处理 | p3 从未带 orch 脚本 | — |
| `skills/poteto-mode/scripts/orch/store.ts` | 删除 | 上游删除（Orchestrate 不再调脚本） | 不处理 | p3 从未带 orch 脚本 | — |
| `skills/poteto-mode/scripts/package.json` | 修改 | 测试入口改名（orch 去掉，check-plan 加入） | 不处理 | p3 无 scripts 目录 | — |
| `skills/poteto-mode/scripts/watch-pr/fakes.test-helper.ts` | 修改 | watch-pr 修复（评审线程分页、fork head 识别、轮询睡眠不越过截止时间、优先活跃 PR） | 不处理 | p3 用 `watch_pull_request`，无轮询脚本 | — |
| `skills/poteto-mode/scripts/watch-pr/github.test.ts` | 修改 | watch-pr 修复（评审线程分页、fork head 识别、轮询睡眠不越过截止时间、优先活跃 PR） | 不处理 | p3 用 `watch_pull_request`，无轮询脚本 | — |
| `skills/poteto-mode/scripts/watch-pr/github.ts` | 修改 | watch-pr 修复（评审线程分页、fork head 识别、轮询睡眠不越过截止时间、优先活跃 PR） | 不处理 | p3 用 `watch_pull_request`，无轮询脚本 | — |
| `skills/poteto-mode/scripts/watch-pr/policy.test.ts` | 修改 | watch-pr 修复（评审线程分页、fork head 识别、轮询睡眠不越过截止时间、优先活跃 PR） | 不处理 | p3 用 `watch_pull_request`，无轮询脚本 | — |
| `skills/poteto-mode/scripts/watch-pr/policy.ts` | 修改 | watch-pr 修复（评审线程分页、fork head 识别、轮询睡眠不越过截止时间、优先活跃 PR） | 不处理 | p3 用 `watch_pull_request`，无轮询脚本 | — |
| `skills/poteto-mode/scripts/watch-pr/types.ts` | 修改 | watch-pr 修复（评审线程分页、fork head 识别、轮询睡眠不越过截止时间、优先活跃 PR） | 不处理 | p3 用 `watch_pull_request`，无轮询脚本 | — |
| `skills/poteto-mode/scripts/worktree-audit.sh` | 修改 | MERGED 判定改对默认分支；GNU stat/date 读转录 mtime | 不处理 | p3 用 t3_worktree_* | — |

#### workflow 技能（how/why/arena/swarm/architect/interrogate/reflect/…）（41 个文件）

| 上游路径（`pstack/` 下） | 状态 | 上游改了什么 | 方案 | 冲突 / 备注 | 批 |
|---|---|---|---|---|---|
| `skills/architect/SKILL.md` | 修改 | 「grounding」改述；删部分重述；默认模型去掉 Sol（3→2 个 runner） | 需适配 | 冲突 1 处：runner 默认段 | B3 |
| `skills/architect/references/runner-prompt.md` | 修改 | 「several runners」改「the parallel runners」 | 直接搬 | 无 | B2 |
| `skills/arena/SKILL.md` | 修改 | 精简 Pick/Graft 文字；被拒的 runner 席位丢弃或替换；cross-judge 按模型家族轮选；评审永不取自父线程同家族 | 需适配 | 冲突 1 处（runner 选择段已改成 `arena runners`+`orchestrator_capabilities`） | B3 |
| `skills/automate-me/SKILL.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：同上 | B2 |
| `skills/benchmark-checklist/SKILL.md` | 修改 | 七问措辞精简，「怎么配合其他性能材料」改「其他性能材料」 | 直接搬 | 冲突 1 处：p3 有 2 行 T3 改写 | B2 |
| `skills/blast-radius/SKILL.md` | 修改 | 「several models」改「more than one model」，纯措辞 | 直接搬 | 冲突：p3 同行有 T3 改写，手工并入 | B2 |
| `skills/correct/SKILL.md` | 修改 | 第 3 步「测试行为」改成两个想象中的编辑（行为坏了测试要挂，只改内部不该挂） | 直接搬 | 无 | B1 |
| `skills/create-verification-skill/SKILL.md` | 修改 | Launch 就绪的定义改为「空数据目录也能走到可用状态（含迁移与种子）」；Features 小节措辞 | 需适配 | 冲突 1 处；p3 路径是 `.agents/skills/verify-<app>/`，别回退成 `.cursor/skills/` | B2 |
| `skills/figure-it-out/SKILL.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：同上 | B2 |
| `skills/how/SKILL.md` | 修改 | 步骤由 1/2a/2b/3/4 改成 1–4；简单题的 explainer 直接用 explainer-prompt；`readonly:true` 统一说明 | 需适配 | 冲突 3 处（spawn 配置） | B3 |
| `skills/how/references/explorer-prompt.md` | 修改 | 删「探索指令」17 行（agent 不看也会做） | 需适配 | 冲突 2 处：p3 在此文件多出 2 行 T3 工具说明 | B3 |
| `skills/interrogate/SKILL.md` | 修改 | 整篇重写：对手只留能被一次运行证实的发现；用 arena 的 Phase A3/A4/B/F，跳过 C/D/E；意图用 in-your-own-words 陈述；不再输出评分与 rubric | 需适配 | 冲突：p3 版本是旧结构整体改写，需按新结构重写；依赖 arena 与 in-your-own-words（见 §3） | B3 |
| `skills/interrogate/references/code-quality-review.md` | 删除 | 上游删除（新流程不再用 reviewer/rubric 引用） | 需适配 | p3 存在这 4 个文件，随 interrogate 重写一并删 | B3 |
| `skills/interrogate/references/lead-judgment.md` | 删除 | 上游删除（新流程不再用 reviewer/rubric 引用） | 需适配 | p3 存在这 4 个文件，随 interrogate 重写一并删 | B3 |
| `skills/interrogate/references/reviewer-prompt.md` | 删除 | 上游删除（新流程不再用 reviewer/rubric 引用） | 需适配 | p3 存在这 4 个文件，随 interrogate 重写一并删 | B3 |
| `skills/interrogate/references/rubric.md` | 删除 | 上游删除（新流程不再用 reviewer/rubric 引用） | 需适配 | p3 存在这 4 个文件，随 interrogate 重写一并删 | B3 |
| `skills/make-bot-ui/SKILL.md` | 修改 | frontmatter name 由 `Make Bot UI` 改 `make-bot-ui` | 不处理 | p3 的 name 已是 `make-bot-ui`，无差异可搬 | — |
| `skills/no-comments/SKILL.md` | 修改 | `subagent_type` 改 `comment-sicko`；加推理档位句 | 需适配 | 只取档位句；agent id 不处理 | B2 |
| `skills/poteto-help/SKILL.md` | 修改 | 改为仅手动触发（`disable-model-invocation`）；加 prompting/recipes 引用；无模型规则时问一次是否现在 setup；表里加 in-your-own-words/sharpen/ketchup/ketchup-video/formal/statechart；`autopilot, don't merge` | 需适配 | 冲突 6 处：p3-help 已整篇改写 | B3 |
| `skills/recall/SKILL.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：同上 | B2 |
| `skills/reflect/SKILL.md` | 修改 | 去掉「When to invoke」；各步标题由 ### 升为 ##；Locate 一节改述（仍禁止跨工作区 glob）；默认模型 Tooling 由 Sol 改 Grok、其余 max 改 xhigh | 需适配 | 冲突 4 处：p3 的转录读取已换成 t3_thread_read/search，别回退 | B3 |
| `skills/reflect/references/divergent-reviewer.md` | 修改 | 措辞精简；明确「不改文件，不 commit，由父线程应用」 | 需适配 | 冲突 1 处 | B3 |
| `skills/reflect/references/judgment-reviewer.md` | 修改 | 同上 | 需适配 | 冲突 1 处 | B3 |
| `skills/reflect/references/synthesizer.md` | 修改 | 2 行措辞 | 直接搬 | 可自动合并 | B2 |
| `skills/reflect/references/tooling-reviewer.md` | 修改 | 同上；技能「被用过」的判据改成读 SKILL.md/Task prompt/命令命中 | 需适配 | 冲突 1 处：p3 已把 Task prompt 换成 delegate_task brief | B3 |
| `skills/setup-pstack/SKILL.md` | 修改 | 预算档位更名（`unlimited — max reasoning`）；默认预算改 large(xhigh)；默认模型去掉 Sol，arena/architect/interrogate 列表 3→2 项；新增第 8 步：一次性提议生成形式化验证技能 | 需适配 | 冲突 4 处；p3 setup-p3 已有自己的 effort 梯度与 `<providerInstanceId>/<model>` 写法 | B3 |
| `skills/show-me-your-work/SKILL.md` | 修改 | 段内加一句「按任务难度选子 agent 的推理档位与快慢档，见 p3-mode 的 Subagents 一节」（ce649c0） | 需适配 | 冲突：同上 | B2 |
| `skills/swarm/SKILL.md` | 修改 | Phase A 重编号并修悬空引用；删冗余汇总说明 | 需适配 | 冲突 2 处：spawn 句已改成 delegate_task | B3 |
| `skills/technical-writing/SKILL.md` | 修改 | 四层规则的措辞精简，规则不变 | 直接搬 | 无 | B1 |
| `skills/typescript-best-practices/SKILL.md` | 修改 | Branded types 一行补「品牌必须来自校验型 type guard，不用 as」 | 需适配 | p3 该行有 1 处 T3 改写，可自动合并后复核 | B1 |
| `skills/typescript-best-practices/references/patterns.md` | 修改 | 示例改成 `isAgentId` type guard 后再返回，不再 `as` | 直接搬 | 无 | B1 |
| `skills/unslop/SKILL.md` | 修改 | description 去掉「Must always apply.」；删 Process 小节 | 直接搬 | 无 | B1 |
| `skills/why/SKILL.md` | 修改 | 步骤重排：种子上下文内联（不再附 git/gh 命令块）；调查员并成一次 spawn；`generalPurpose`+`readonly:false` 说明 | 需适配 | 冲突 7 处：p3 把 spawn 配置全改成 delegate_task + 角色名，须逐段重放 | B3 |
| `skills/why/references/epistemics.md` | 修改 | 删约 95 行，只留证据分级本体；改述为「一条主张一个层级，层级定章节与措辞」 | 直接搬 | 无 | B1 |
| `skills/why/references/investigator-prompt.md` | 修改 | 精简 42 行，调整投射给调查员的字段 | 需适配 | 冲突 2 处：p3 在此处有 T3 改写 | B3 |
| `skills/why/references/sources/code-archaeology.md` | 修改 | 删「这个来源有什么」；git 命令注释精简 | 直接搬 | 无 | B1 |
| `skills/why/references/sources/datadog.md` | 修改 | 精简 24 行 | 直接搬 | 无 | B1 |
| `skills/why/references/sources/incident-postmortem.md` | 修改 | 删 10 行 | 直接搬 | 无 | B1 |
| `skills/why/references/sources/sentry.md` | 修改 | 删「来源内容」清单 | 直接搬 | 无 | B1 |
| `skills/why/references/sources/slack.md` | 修改 | 删「来源内容」清单 | 直接搬 | 无 | B1 |
| `skills/why/references/synthesizer-prompt.md` | 修改 | 改述输出节标题，删冗余说明 | 需适配 | 冲突 1 处 | B3 |

#### principle-*（17 个文件）

| 上游路径（`pstack/` 下） | 状态 | 上游改了什么 | 方案 | 冲突 / 备注 | 批 |
|---|---|---|---|---|---|
| `skills/principle-attack-the-premise/SKILL.md` | 修改 | description 与正文由「普查哪些 actor 持有失衡」改为「写下前提并直接检验」 | 直接搬 | 无 | B1 |
| `skills/principle-build-the-lever/SKILL.md` | 修改 | Why/Pattern/Balance 三个粗体引导删掉，正文并成连续段落 | 直接搬 | 可自动合并：p3 有 1 行改写 | B1 |
| `skills/principle-encode-lessons-in-structure/SKILL.md` | 修改 | 删 Why 与 Pattern 小节，只留规则本体 | 直接搬 | 无 | B1 |
| `skills/principle-exhaust-the-design-space/SKILL.md` | 修改 | 删 13 行重述 | 直接搬 | 无 | B1 |
| `skills/principle-explain-the-number/SKILL.md` | 修改 | description 增「measure 之前就要用」；删 Why 段 | 直接搬 | 无 | B1 |
| `skills/principle-fix-root-causes/SKILL.md` | 修改 | 改述：症状是错误状态显形处，根因是系统第一次做错处；只有处理的状态合法时 guard 才算修复 | 直接搬 | 无 | B1 |
| `skills/principle-guard-the-context-window/SKILL.md` | 修改 | 删「隔离大载荷」「常用内容放行内」两条 | 直接搬 | 冲突：p3 此处有 4 行 T3 改写（subagent→delegate_task），上游是删除，按删除处理后复核 | B1 |
| `skills/principle-laziness-protocol/SKILL.md` | 修改 | 删 8 行重述 | 直接搬 | 无 | B1 |
| `skills/principle-make-operations-idempotent/SKILL.md` | 修改 | 去掉 PID 锁等具体机制，改述为「收敛到同一终态」的道理 | 直接搬 | 无 | B1 |
| `skills/principle-migrate-callers-then-delete-legacy-apis/SKILL.md` | 修改 | 删 8 行边角规则 | 直接搬 | 无 | B1 |
| `skills/principle-minimize-reader-load/SKILL.md` | 修改 | 两条轴并成一句；删 Why 与 The pattern 标题 | 直接搬 | 无 | B1 |
| `skills/principle-model-the-domain/SKILL.md` | 修改 | 精简 7 行，规则不变 | 直接搬 | 无 | B1 |
| `skills/principle-never-block-on-the-human/SKILL.md` | 修改 | 精简 12 行，规则不变 | 直接搬 | 无 | B1 |
| `skills/principle-redesign-from-first-principles/SKILL.md` | 修改 | description 缩成一句；正文措辞调整 | 直接搬 | 无 | B1 |
| `skills/principle-subtract-before-you-add/SKILL.md` | 修改 | 删 Why 与 Pattern 小节，加「默认做减法」 | 直接搬 | 无 | B1 |
| `skills/principle-test-behavior-not-implementation/SKILL.md` | 修改 | 去掉「所有函数返回 undefined 仍通过」之类具体断言写法，改述为可观察行为 | 直接搬 | 无 | B1 |
| `skills/principle-type-system-discipline/SKILL.md` | 修改 | 开头改写，删 23 行语法细节（指向 typescript-best-practices） | 直接搬 | 无 | B1 |

#### 新增技能与引用（10 个文件）

| 上游路径（`pstack/` 下） | 状态 | 上游改了什么 | 方案 | 冲突 / 备注 | 批 |
|---|---|---|---|---|---|
| `skills/create-formal-verification-skill/SKILL.md` | 新增 | 新增：生成项目内「形式化验证」技能（TLA+ 默认） | 需适配 | 见 §3；依赖 statechart | B4 |
| `skills/in-your-own-words/SKILL.md` | 新增 | 新增：复述用户目标与要解决的问题（7 行） | 直接搬 | 无机制依赖；见 §3 | B4 |
| `skills/ketchup-video/SKILL.md` | 新增 | 新增：同上，以带字幕的 slide 视频呈现 | 需适配 | 见 §3：无渲染工具，需人选 | B4 |
| `skills/ketchup/SKILL.md` | 新增 | 新增：catch-up 本线程自用户上条消息以来的变化与待决事项，带视觉 | 需适配 | 见 §3：媒体嵌入与待办来源 | B4 |
| `skills/maintain-formal-verification-skill/SKILL.md` | 新增 | 新增：代码变后让形式化验证与代码重新对齐 | 直接搬 | 见 §3；仅路径与技能名 | B4 |
| `skills/poteto-help/references/prompting.md` | 新增 | 新增：怎么把任务写成可验收的 prompt，一行纠偏用语 | 需适配 | 含 `/loop` 与 chat 措辞，换成 `schedule_task`/thread | B3 |
| `skills/poteto-help/references/recipes.md` | 新增 | 新增：可复制的 prompt 配方（过夜、卡住、catch-up 等） | 需适配 | 含 `/loop until done` 与 `/ketchup` 引用；依赖新技能 | B3 |
| `skills/sharpen/SKILL.md` | 新增 | 新增：把任务改深不改大，再重写 prompt（16 行） | 直接搬 | 见 §3 | B4 |
| `skills/statechart/SKILL.md` | 新增 | 新增：TLC 检查 TLA+ 模型并画 Mermaid 状态图 | 需适配 | 见 §3；依赖 mise/Java/网络 | B4 |
| `skills/statechart/references/render.md` | 新增 | 新增：用 npm `pele@1.9.0` 渲染 SVG 的说明与配色 | 需适配 | 见 §3 | B4 |


#### `skills/statechart/scripts/**`（405 个新增文件，整目录直接搬）

上游把 statechart 的实现与测试整目录放在 `skills/statechart/scripts/`，约 3.7 MB。逐文件列在下面，文件名无 Cursor 机制（唯一的 `cursor` 字样是 `package.json` 的包名 `@cursor-skill/statechart`，不影响运行）。方案取决于 D6（是否带测试夹具），默认按「整目录原样搬」。

| 上游路径（`pstack/skills/statechart/scripts/` 下） | 状态 | 文件数 | 方案 | 备注 |
|---|---|---|---|---|
| `statechart`、`statechart.ts`、`run.ts`、`worker.ts`、`pipeline.ts`、`ir.ts`、`package.json`、`tsconfig.json` | 新增 | 8 | 直接搬 | 入口与流水线。`statechart` 是 sh 包装，要求 node ≥ 22.18（22.x 线）或 ≥ 23.6，本机 22.23 满足；首次运行用 mise 装 TLC 与 Java，需联网 |
| `backends/{cfg,mermaid,plain-text,report}.ts` | 新增 | 4 | 直接搬 | 输出端 |
| `frontends/{config,dot,marks,messages,spec,trace,value,verdict,view}.ts` | 新增 | 9 | 直接搬 | 输入端 |
| `passes/{annotate,label,lift,loop-check,paths,reach,region-check,regions}.ts` | 新增 | 8 | 直接搬 | 分析 pass |
| `test/{chart,cli,config-fuzz,corpus,differential,messages,pipeline,plain-tlc,render,tlc-out}.test.ts`、`test/{java,labels,tlc}.ts`、`test/ConfigOracle.java` | 新增 | 14 | 直接搬 | 测试代码 |
| `test/charts/{Braces,Escapes,Phases}.mmd` | 新增 | 3 | 直接搬 | 渲染夹具 |
| `test/grid/{Grid.cfg,Grid.tla,sany.out}` | 新增 | 3 | 直接搬 | 解析夹具 |
| `test/corpus/*/*`（`.tla`、`.cfg`、`.out`、`.exit`、`.dot`、`.mmd`、`.md`、`.mjs`） | 新增 | 356 | 直接搬（D6 可裁） | 约 3.5 MB，全是回归夹具，运行时不读 |

#### docs/guide（11 个文件）

| 上游路径（`pstack/` 下） | 状态 | 上游改了什么 | 方案 | 冲突 / 备注 | 批 |
|---|---|---|---|---|---|
| `docs/guide/01-setup.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/02-poteto-mode.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/03-understand.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/04-design.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/05-build-and-clean.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/06-verify-and-ship.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/07-overnight.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/08-principles.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/09-make-it-yours.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/10-recipes-and-pitfalls.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
| `docs/guide/README.md` | 修改 | 指南同步 /correct、checklist、prompting 提示、新技能与 Claude Code 说明 | 不处理 | p3 从未带 docs/guide；§7 D5 问是否补 T3 版 | — |
#### 2.3 清单没有覆盖、但要知道的范围外文件

- 上游 `automations/benny/`（12 个文件，Slack 机器人自动化子包）、`assets/logo.png`、`LICENSE`：pin 之后没有改动，p3 当初也没搬，不属于本次同步。
- p3 独有的文件（上游没有）：目前在 pin 上为 0，`p3-mode/playbooks`、`references` 的文件名都能在上游找到对应。
- 上游删除 `interrogate/references/` 的 4 个文件后，p3 里这 4 个会变成「p3 多出、上游没有」，随 `interrogate` 重写一并删除（§2.2 已列）。

#### 2.4 覆盖验证

验收用命令（只读）：

```sh
git -C /tmp/cursor-plugins diff --name-status --no-renames 4e5b1cf c742dd6 -- pstack/ | wc -l   # 522
```

§2.2 表中的每个上游路径与 `statechart/scripts/**` 的 8 行目录组合起来，覆盖这 522 个路径，没有遗漏。本 spec 提交前已用脚本逐个核对：把表里的路径（含花括号展开，`test/corpus/*` 按 356 个文件计）与上面命令的输出做集合比较，缺失为 0。

## 3. 7 个新技能的可行性

读法：「T3 对应」一列写 AGENTS 对照表和本会话实际可见的 T3 工具里能承接这一步的机制；「没有对应」的步骤单独标出，列选项，不替你选。本会话的 `orchestrator_capabilities` 显示可用 provider 是 `codex` 与 `claudeAgent`，其余实例为 disabled。

### 3.1 `in-your-own-words`（上游 7 行，纯提示词）

| 步骤 | 依赖的机制 | T3 对应 |
|---|---|---|
| 用自己的话复述用户的目标和要解决的问题 | 无 | 无需机制 |

**结论：直接搬。** 保留 `disable-model-invocation: true`，正文原样。`interrogate` 的「陈述意图」一步依赖它，所以和 `interrogate` 同批（B3 内先落这个）。

### 3.2 `sharpen`（上游 16 行，纯提示词）

| 步骤 | 依赖的机制 | T3 对应 |
|---|---|---|
| 回答四个问题（顶级专家会做什么、最原始的材料、具体方法与工具、除了你我之外谁能证明结果对），再重写 prompt，把属于用户的选择留空 | 无 | 无需机制 |

**结论：直接搬。** 只返回重写后的 prompt，不做任务（上游 `88d4751` 恢复到这个行为）。

### 3.3 `ketchup`（上游 43 行）

| 步骤 | 依赖的 Cursor / 外部机制 | T3 对应 |
|---|---|---|
| 确定窗口：自用户在 `/ketchup` 之前写的最后一条消息起 | 对话上下文 | 本线程上下文；需要旁证时用 `t3_thread_read`（`view: "messages"`/`"activity"`，`afterPosition` 翻页） |
| 本轮只读：不改代码、不启动应用或任务、不发布 | 纯规则 | 无需机制 |
| 汇总自己的工作、子 agent 回报、他人消息 | 子 agent 结果 | `task_status` 取委托任务结果；`t3_thread_list` 看相关线程 |
| 查每个 PR、CI、agent 的当前状态 | `gh`、Task 结果 | `list_thread_pull_requests`（栈从底到顶）加 `gh pr view`；`watch_pull_request` 的唤醒记录 |
| 列出「只有用户能决定」的事项 | 对话判断 | `t3_pending_request`（`action: "list"`）只覆盖「待回答的提问」，审批项不在其中，其余仍靠判断；不是替代，是补充 |
| 语气借用 `/bro` | `bro` 技能 | p3 已有 `bro` |
| 嵌入截图与视频 | Cursor 的内联媒体 | T3 回复支持用 Markdown 图片语法嵌入绝对路径的图片、视频、音频。证据来源：`preview_snapshot`（`save=true` 返回 `screenshotPath`）、`preview_recording_stop`（返回本地路径，上限 50 MiB）、`device_screenshot` |
| Mermaid 图 | Cursor 聊天渲染 Mermaid | **需实测**：T3 聊天是否渲染 ```` ```mermaid ```` 代码块。不渲染时回退到 `html_preview` + `html_render` 出内联 SVG 或 HTML |
| `/visualize` 出图表 | Cursor 内置命令 | `html_preview`（先预览）+ `html_render`（出内联页面） |
| 「或生成的图片」 | 图像生成 | 没有对应工具。这句在 p3 版里删掉（上游本就要求「不画没捕获过的屏幕」，所以不损失约束） |

**结论：需适配（小）。** 每一步都落到 T3 机制，不需要你选。实施时有两件事要做：一是在一条真实线程里实测 Mermaid 是否渲染，二是把「`/visualize`」换成 `html_render`。

### 3.4 `ketchup-video`（上游 29 行）

| 步骤 | 依赖的 Cursor / 外部机制 | T3 对应 |
|---|---|---|
| 沿用 `/ketchup` 的窗口、只读规则与行动项 | 同 3.3 | 同 3.3 |
| 把工作产物画成 slide（至多 10 张，每张一个论点） | 画图能力 | 把每张 slide 写成 HTML，用 `preview_open` 打开，`preview_snapshot`（`save=true`）得到 PNG。可行 |
| 渲染一条静音横屏视频（mp4），slide 之间有动效，字幕烧进帧 | 视频编码器（上游没指定，实际要 ffmpeg 一类） | **没有对应工具。** T3 没有视频合成或编码工具。本机 `which ffmpeg ffprobe` 都没有 |
| 逐张核对：看每张 slide 的一帧、用文件的帧匹配量停留时长、按「每三词至少 1 秒」核对 | 解码与抽帧（ffprobe 或同类） | 同上：没有编码器就没有抽帧工具 |
| 内联嵌入视频 | 内联媒体 | 可行（见 3.3） |

**没有对应的一步是「合成视频并抽帧验证」。选项：**

- **A. 要求本机有 ffmpeg 与 ffprobe。** slide PNG 加 `xfade` 做转场，字幕用 `drawtext` 或 `subtitles` 滤镜烧入，验证用 ffprobe 与抽帧。最贴近上游，验证条款全部保留。代价：每台设备都要装 ffmpeg（本机现在没有），技能开头要先检查，缺则只给文字版 `/ketchup`。
- **B. 用 `preview_recording_start` / `preview_recording_stop` 录一页自动播放的 HTML slide 页。** 不需要 ffmpeg，产物直接是 T3 录屏。代价：上游明文要求「帧由 slide 生成，不要录屏」并按文件量停留时长；录屏的停留时长受页面时钟影响，且没有 ffprobe 就无法验证，这两条要放宽。
- **C. 不出视频，用 `html_render` 渲染一个内联、自动翻页的 slide 页。** 不产生文件，不依赖任何编码器，滑块、字幕、停留时长都在页面里可控。代价：产物是内联页面而不是视频，不能转发出线程，上游「检查渲染文件」一步没有对象。
- **D. 暂不移植，在 `UPSTREAM.md` 记为有意缺口。** 工作量为零；代价是 §4 的「每个上游技能都有 p3 对应」要为它开一条经你签字的例外。

### 3.5 `create-formal-verification-skill`（上游 43 行）

| 步骤 | 依赖的 Cursor / 外部机制 | T3 对应 |
|---|---|---|
| 从代码里选目标（一个承诺，破了伤害用户、测试够不到） | 读仓库 | 读文件、grep，无需机制 |
| 选工具：模型检查器、证明助手、SMT 验证器等，TLA+ 为默认 | 本机命令行工具 | shell。工具要用户能装，上游本就这样要求 |
| 生成一个项目内的验证技能 | 写文件到项目技能目录 | 写 `.agents/skills/<名字>/SKILL.md`，与 p3 的 `create-verification-skill` 用同一目录约定（它写 `.agents/skills/verify-<app>/`）。上游原文只说「项目内技能」，没写路径，p3 版要写明 |
| 在真实代码里造一个会破坏性质的临时改动，按生成的技能走一遍，再撤销 | shell 与 git | shell 与 git；可选用 `t3_thread_launch`（`workspaceStrategy: worktree`）把临时改动隔离在一次性 worktree 里 |
| TLA+ 的结果用 `/statechart` 读 | `statechart` 技能 | 取决于 `statechart` 是否搬入（3.7、D6）。不搬则这句改成「用大白话把反例讲成步骤」 |

**结论：需适配（小）。** 唯一的外部依赖是 `/statechart`，这是 §3.7 的问题，不是这个技能自己的缺口。

### 3.6 `maintain-formal-verification-skill`（上游 58 行）

| 步骤 | 依赖的 Cursor / 外部机制 | T3 对应 |
|---|---|---|
| 找到项目里的验证技能（靠它做什么来找，不靠名字） | 读项目技能目录 | 读 `.agents/skills/`（再加用户级 `~/.agents/skills/`） |
| 跑一遍、读覆盖代码的 commit、更新模型、重跑、判定是漂移还是 bug | shell 与 git | shell 与 git，无需机制 |
| 更新验证技能的同步 commit | 写文件 | 写文件 |
| 把验证的更新单独成一个变更 | git | git |

**结论：直接搬。** 只需要把「项目内技能目录」说成 `.agents/skills/`，其余原样。

### 3.7 `statechart`（上游 `SKILL.md` 83 行、`references/render.md` 94 行、`scripts/` 405 个文件）

| 步骤 | 依赖的 Cursor / 外部机制 | T3 对应 |
|---|---|---|
| 在仓库外的临时目录写 TLA+ spec 与 config | 文件系统 | 写文件，无需机制 |
| 运行 `<skill dir>/scripts/statechart SPEC.tla ...` | node（TypeScript 直跑）、mise、Java、TLC、联网 | shell 可跑。本机：node 22.23 满足，**java 与 mise 都没有**，首次运行由 mise 下载（需联网）。T3 的 shell 与 Cursor 的一样会受网络与权限限制 |
| 写 view 模块（`state()`、`step()`、`group()`） | TypeScript 运行时 | node 可运行 |
| 把 `chart.mmd` 作为 mermaid 代码块给用户 | 聊天渲染 Mermaid | **需实测**，同 3.3 |
| 用 Pele 渲染 SVG（npm `pele@1.9.0`），写在 `.mmd` 旁边 | npm 联网安装 | shell 加 npm 可行；SVG 再用 Markdown 图片语法嵌入，或经 `html_render` 内联 |
| 回放每条 bug 路径对真实代码，各一步一个动作 | 测试或在线复现 | shell 与测试；需要界面时用 `preview_*` 与 `device_*` |

**结论：需适配（小），但有两件事需要你定。**

- **运行环境**：Java 与 mise 在本机都没有。首次运行要联网下载，T3 里怎么处理由你定：直接让首次运行去装，还是 `setup-p3` 在选项里加一句「是否预装」。
- **仓库体积**：整目录 405 个文件、约 3.7 MB，其中 356 个是回归夹具。选项见 D6。

### 3.8 依赖关系与批次

```
in-your-own-words ──► interrogate（陈述意图）
statechart ──► create-formal-verification-skill ──► maintain-formal-verification-skill
create-formal-verification-skill ──► setup-p3 第 8 步（一次性提议）
ketchup ──► ketchup-video；ketchup ──► autopilot-full 的 Reply
以上 7 个 ──► p3-help 的技能表与 recipes.md
```

落地顺序：`in-your-own-words`、`sharpen`、`statechart` 最先（无前置），然后 `create-` 与 `maintain-formal-verification-skill`、`ketchup`，最后 `ketchup-video`，`p3-help` 与 `setup-p3` 在所有技能就位后再改。

## 4. 「同等表现」的可检验口径

### 4.1 判据

「同等」只取能用 grep 或脚本判定的部分，分三类：覆盖面（有没有）、机制（换没换）、卫生（残留与一致性）。每一条给命令，并给出**当前基线**，基线就是在 pin 上跑出来的结果，用来证明这条判据本身可用。

| # | 判据 | 检验方式 | 通过条件 | 基线（c742dd6 vs p3 现状） |
|---|---|---|---|---|
| P1 | 每个上游技能在 p3 都有对应技能（你的 (a)） | 用 `UPSTREAM.md` 的映射表，比对 `git ls-tree` 的上游 `skills/*` 与 p3 `skills/*` | 上游技能集经映射后 ⊆ p3 技能集；缺的必须登记在 `UPSTREAM.md` 的「有意缺口」并写明理由与决策日期 | 失败：上游 58 个、p3 51 个，缺 7 个。7 个都落地（或登记缺口）后通过 |
| P2 | 每个上游文件在 p3 都有对应文件，反向也成立 | 对 `skills/**` 与 `agents/**` 的非 `scripts/` 文件按路径映射比对 | 缺失与多出都为 0，例外写在 `UPSTREAM.md` 的白名单 | 失败：缺 10 个（6 个新技能的 `SKILL.md`、`statechart` 的 2 个文件、`p3-help` 的 2 个 references），多出 4 个（`interrogate/references/` 的 4 个）。在 pin 上为 0 与 0 |
| P3 | Cursor 残留词为 0（AGENTS 的 Definition of done 第 1 条） | 命令见 4.1 表后的 P3 命令，排除 `skills/statechart/scripts/` | 0 命中 | 通过：当前 0 命中。注意 `statechart/scripts/pipeline.ts` 会因 `./passes/loop-check.ts` 误中 `/loop`，所以该目录要排除 |
| P4 | 原来用到委托、并行、PR 监视、定时、录屏的步骤，都换成 T3 原生工具（你的 (b)） | 对每个上游文件与 p3 对应文件，按下表五类各查一次：上游命中左列，p3 必须命中右列任一 T3 词 | 全部通过或在白名单里 | 见 4.2：委托 16/16、PR 监视 4/4、读历史 6/6，定时 4/8、录屏 5/6，缺的都是「p3 已改成事件唤醒，不再需要定时」的合理情形，进白名单 |
| P5 | 保留上游句子：上游一行（≥30 字符）在 p3 对应文件里逐字保留的比例 | 脚本：改名映射、空白归一化后求比例 | 「直接搬」的文件 = 100%；「需适配」的文件 ≥ 40%，低于的列给人看 | 基线：107 个文件里 43 个 100%，9 个低于 50%（`p3-agent`、`setup-p3`、`worktree-cleanup`、`babysit`、`make-bot-ui`、`autopilot-full`、`p3-help`、`reflect`、`how`）。这 9 个就是 T3 改写最深的文件 |
| P6 | 引用可解析：相对链接指向存在的文件；`name:` 等于目录名；`disable-model-invocation` 与上游一致 | 脚本 | 全部一致，例外进白名单 | 基线：断链 1 个（`architect/references/runner-prompt.md` 指向 `references/rationale-template.md`，上游同样写法）；`name` 与目录名全部一致；`disable-model-invocation` 有 2 处与 c742dd6 不一致，正好是 `p3-help` 应加、`setup-p3` 是 T3 侧有意加的 |
| P7 | 角色名闭合：技能里提到的角色名都在 `setup-p3` 的角色表里，反之亦然；没有模型 slug | 以 AGENTS 的角色名清单为准的脚本；加 `grep -E 'claude-\|grok-\|gpt-'` | 双向无缺漏 | 基线通过（P3 已含 slug 检查）。同步后上游若新增角色名，会在这里暴露 |
| P8 | 长度不回退：p3 文件行数不超过上游（AGENTS 第 2 条） | 脚本 | 超出的文件数不增加，已超出的进白名单 | 基线：12 个文件已超出（如 `autopilot-full` 19 对 14、`orchestrate` 117 对 112），这 12 个记入白名单，不得新增 |

P3 命令（在 p3-stack 仓库根目录运行，没有输出即通过）：

```sh
grep -rEn 'Cursor|Task tool|subagent_type|cloud agent|\.cursor|agent-transcripts|AskQuestion|icon:|claude-|grok-|gpt-|/loop' skills agents \
  --exclude-dir=statechart
```

`--exclude-dir=statechart` 会同时排除 `skills/statechart/SKILL.md` 与 `references/`。这两个文件应单独跑一次同样的 grep，不排除目录。

### 4.2 P4 的五类对应

| 上游命中（正则） | p3 对应文件必须命中（任一） |
|---|---|
| `\bTask\b`、`subagent_type`、`run_in_background` | `delegate_task`、`t3_thread_launch` |
| `watch-pr`、`watcher` | `watch_pull_request` |
| `/loop`（独占一词）、`hourly audit`、`hourly tick` | `schedule_task` 或 `watch_pull_request` |
| `control-ui`、`control-cli` | `preview_`、`device_` |
| `agent-transcripts` | `t3_thread_read`、`t3_thread_search` |

基线在 pin（`4e5b1cf`）与目标（`c742dd6`）上分别跑了一遍：委托 16/16，PR 监视 5/5 与 4/4，读历史 7/7 与 6/6，录屏 5/6（缺的是 `p3-help`），定时 5/9 与 4/8（缺的是 `p3-help`、`babysit`、`shipping`、`visual-parity`，这几份 p3 已改成事件唤醒，不再用定时）。这些缺项要进 `UPSTREAM.md` 白名单并写理由，白名单之外的缺项才算失败。

### 4.3 不在口径里的东西

- **行为是否一致**不能靠 grep 判定。每个新技能在 T3 线程里跑一次冒烟（`ketchup` 看媒体是否内联，`statechart` 看能否出图）作为交付证据，但不算判据。
- P5 只衡量「保留了多少句子」，不衡量改写得对不对。改写的对错靠 review。

### 4.4 AGENTS.md 的 T3 工具表与本会话可见工具有出入（顺带发现）

AGENTS.md 的「T3 tool quick reference」列了一批工具名，本会话实际可见的 T3 工具里没有同名项：

| AGENTS.md 里的名字 | 本会话可见的对应 |
|---|---|
| `t3_thread_fork`、`t3_thread_merge_back` | `t3_thread_transfer`（`action: "fork"`/`"merge_back"`） |
| `update_scheduled_task` | `schedule_task`（带 `scheduledTaskId`） |
| `t3_queue_list`、`_read`、`_edit`、`_reorder`、`_cancel`、`_promote_to_steer` | `t3_queue`（`action` 区分） |
| `t3_pending_request_list`、`_read`、`_respond` | `t3_pending_request`（`action` 区分） |
| `preview_click`、`preview_type`、`preview_press`、`preview_scroll` | `preview_act`（`action` 区分） |
| `browser.preview` | 没有对应项 |
| `watch_pull_request`、`unwatch_pull_request` | 本会话的工具清单里没有，系统提示词里提到过，可能是延迟加载，**未核到** |

这可能只是 AGENTS.md 对应另一个 T3 版本，也可能已过时。本阶段不改 AGENTS.md。但如果以后加「工具名必须真实存在」的判据，需要先定权威来源。放进 §7 的 D9。

## 5. 持续跟进机制设计

本节只写设计，不实现。

### 5.1 `UPSTREAM.md`（放在 p3-stack 仓库根目录）

**用途**：记录 p3 当前对齐到上游哪个 commit，上游技能到 p3 技能的映射，以及哪些差异是有意保留的。`scripts/upstream-diff.sh` 只读这个文件。

**格式**：头部是 `key: value` 行，后面是三个固定标题的 Markdown 表。脚本只解析这三张表与头部，其余文字随便写。

```markdown
# Upstream tracking

upstream: https://github.com/cursor/plugins
subtree: pstack/
pin: c742dd61706fbacc1b95f1a20b7b988cf096ce6c
pin-date: 2026-10-27
pin-version: 0.15.36
synced-on: <同步完成当天>

pin 取「上游 main 上最后一个动过 subtree 的 commit」，不取仓库 HEAD。

## 映射

| 上游 | p3 | 对齐到 | 状态 | 备注 |
|---|---|---|---|---|
| skills/poteto-mode | skills/p3-mode | c742dd6 | ported | 改名 |
| skills/poteto-help | skills/p3-help | c742dd6 | ported | 改名 |
| skills/setup-pstack | skills/setup-p3 | c742dd6 | ported | 改名 |
| agents/poteto-agent.md | agents/p3-agent.md | c742dd6 | ported | 改名 |
| skills/ketchup-video | — | — | gap | D3 选 D：暂不移植 |
| skills/<其余同名> | skills/<同名> | c742dd6 | ported | |

## 有意缺口与忽略路径

| 上游路径（支持 glob） | 处理 | 理由 |
|---|---|---|
| docs/guide/** | ignore | p3 不带指南 |
| .cursor-plugin/**、plugin.json、docs/harness/** | ignore | Cursor 或 Claude Code 清单 |
| skills/poteto-mode/scripts/watch-pr/**、scripts/orch/**、scripts/worktree-audit.sh | ignore | 由 watch_pull_request 与 t3_worktree_* 取代 |
| automations/** | ignore | 作者个人自动化，p3 从未带 |

## 白名单（parity-check 的已知例外）

| 判据 | 路径 | 理由 |
|---|---|---|
| P4 schedule | skills/p3-mode/playbooks/babysit.md | p3 改成 watch_pull_request 事件唤醒 |
| P8 length | skills/p3-mode/playbooks/orchestrate.md | T3 重写需要更多行 |
```

**设计要点**

- **pin 的定义**：`git log -1 --format=%H <upstream main> -- pstack/`。因为本轮上游仓库 HEAD 是 `3dbd22f`，而 `pstack/` 停在 `c742dd6`，直接用仓库 HEAD 会把 pin 记错。
- **允许局部落后**：「对齐到」按技能记录。某个技能暂缓（比如 D2 选 B 时的 `orchestrate`）时，该技能保留旧 commit，其余技能前进。全局 `pin` 只在所有非 gap、非 ignore 的行都对齐到同一 commit 时才前进；否则 `pin` 取最小的那个。
- **映射表是改名的唯一来源**：`upstream-diff.sh` 和 `parity-check.sh` 都不再把改名写死在脚本里。

### 5.2 `scripts/upstream-diff.sh`

**一句话**：列出 pin 到上游最新之间，每个技能新增、修改、删除了什么，并和 `UPSTREAM.md` 对账。只读，不改任何文件，不 push。

**调用**

```sh
scripts/upstream-diff.sh [--to <rev>] [--upstream <path|url>] [--skill <name>] [--files] [--json]
```

| 参数 | 默认 | 作用 |
|---|---|---|
| `--to` | 上游 main 上最后一个动过 `pstack/` 的 commit | 比对终点 |
| `--upstream` | `${P3_UPSTREAM_CACHE:-~/.cache/p3-stack/cursor-plugins}`，缺失则 `git clone --filter=blob:none` | 上游本地副本，已存在则 `git fetch` |
| `--skill` | 全部 | 只看一个技能，同时打印该技能自 pin 以来的 commit 列表 |
| `--files` | 关 | 展开到文件级（`name-status` 加行数） |
| `--json` | 关 | 机器可读输出，给 `schedule_task` 或脚本消费 |

**行为**

1. 读 `UPSTREAM.md` 取 `pin`、映射表、忽略路径。
2. 执行 `git diff --name-status --no-renames <pin> <to> -- pstack/`，按 `skills/<名>`、`agents/`、`docs/`、其他分桶。命中「忽略路径」的文件折叠成一行「ignored (n files)」。
3. 每个技能输出一行：`NEW`（pin 上无此目录）、`DELETED`（目标上无）、`MOD`；附 `A/M/D` 文件数与 `+行/-行`，附 p3 对应路径与「对齐到」。
4. 对账，输出告警（每条告警一行，前缀 `WARN`）：
   - 上游出现映射表里没有的新技能。
   - 映射表登记为 `ported`，但 p3 目录不存在。
   - p3 有技能目录，映射表里没有对应行（p3 独有技能必须显式登记为 `p3-only`）。
   - 某技能「对齐到」早于 pin（局部落后）。
5. 末尾打印汇总：新增 N、修改 N、删除 N、被忽略 N。
6. **退出码**：`0` 无变化；`10` 有变化需要处理；`2` 出错（网络、UPSTREAM.md 解析失败）。这样 `schedule_task` 的周巡检只在退出码 `10` 时才唤醒人。

**不做的事**

- 不更新 `UPSTREAM.md`。移动 pin 是同步提交里人工做的事，脚本只打印建议的新 pin 行。
- 不自动三方合并，不改 p3 文件。合并方式写在同步 spec 里（本文 §2.1），由实施者执行。
- 不判定「该不该同步」。它只列事实。

**输出示例**

```
upstream pstack: c742dd6 -> 3b9e1a0  (12 commits, 9 files)
NEW      skills/foo            A=4            p3: (none)         WARN no mapping row
MOD      skills/p3-mode        M=3  +21 -17   p3: skills/p3-mode behind=c742dd6
DELETED  skills/bar            D=3            p3: skills/bar
ignored  docs/guide/** (2 files)
summary: new=1 mod=1 deleted=1 ignored=2        exit 10
```

### 5.3 伴生脚本 `scripts/parity-check.sh`

§4 的 P1 到 P8 要靠它跑，所以这里一并给出设计：

- 入口 `scripts/parity-check.sh [--to <rev>]`，只读，读 `UPSTREAM.md`。
- 每条判据输出 `PASS`/`FAIL`/`ALLOW`（命中白名单），最后一行是总计；有任一 `FAIL` 则退出码 1。
- 它是同步完成的验收门：新技能落地、pin 前进之前必须全绿。
- 约 150 行 bash 加少量 node；不引入新依赖（node 本就是 `install.sh` 之外 statechart 的要求，P5 才用到）。

### 5.4 跟进节奏

1. **巡检**：`schedule_task` 每周一次（`{"type":"fixed_time","timeOfDay":"09:07","weekdays":[1]}`），执行 `scripts/upstream-diff.sh`，退出码 `10` 才发消息，附 `--json` 摘要。（这是设计，实施阶段才创建。）
2. **判断**：有 `NEW` 技能时，对每个新技能写一节与本文 §3 同格式的「可行性」，再决定是否移植。没有 T3 对应的步骤，列选项给人选。
3. **同步**：按 §6 的批次顺序，每批一次 commit；`scripts/parity-check.sh` 全绿后，在同一个提交里更新 `UPSTREAM.md` 的 `pin`、`pin-date`、`pin-version`、`synced-on` 与映射表的「对齐到」。
4. **留痕**：每次同步在 `docs/` 下写一份 `sync-spec-<短 sha>.md`，命名遵循本文的格式。

## 6. 实施顺序与预计工作量

估算按「一个 worker 的有效工作时长」计，不含等待与 review。AGENTS.md 规定 delegated worker 一次只写一个文件，所以 B3 里每个文件是一个 worker 任务；B1、B2 是机械改动，建议由协调者用脚本三方合并完成，不派 worker。

| 批 | 内容 | 文件数 | 做法 | 预计 |
|---|---|---|---|---|
| B0 | `UPSTREAM.md`、`scripts/upstream-diff.sh`、`scripts/parity-check.sh`，并在现状上跑出 §4 的基线 | 3 | 协调者 | 2–3 h |
| B1 | 直接搬：`principle-*` 17 个、`why` 的 references 与 sources 6 个、`correct`、`technical-writing`、`unslop`、`typescript-best-practices`（2 个） | 28 | 协调者，`git merge-file` 脚本批量，跑完人读 diff | 1–1.5 h |
| B2 | 小适配：14 处「按任务难度选子 agent 档位」一句话（`bug-fix`、`eval`、`feature`、`hillclimb`、`perf-issue`、`refactoring`、`runtime-forensics`、`session-pickup`、`trace-forensics`、`recall`、`show-me-your-work`、`automate-me`、`figure-it-out`、`no-comments`），加 `create-verification-skill`、`worktree-cleanup`、`benchmark-checklist`、`blast-radius`、`architect/references/runner-prompt.md`、`reflect/references/synthesizer.md`；档位句在 T3 里落成 `delegate_task` 的 `target.options`（`effort` 或 `reasoningEffort`），见 D8 | 20 | 协调者 | 1.5–2 h |
| B3 | 大适配：`p3-mode` 的 SKILL（冲突 7 处）、`interrogate`（整篇重写加删 4 个 references）、`arena`、`architect`、`swarm`、`how`（2 个文件）、`why`（3 个文件）、`reflect`（4 个文件）、`setup-p3`（加第 8 步）、`p3-help`（加 2 个 references）、`p3-agent`、`autopilot-full`、`autopilot-stack`、`autonomous-run`、`babysit`、`shipping`、`opening-a-pr`、`multi-phase-plan`；`orchestrate` 取决于 D2 | 31 | 每个文件一个 worker；先 `p3-mode` 的 SKILL，后其余可并行（上限 4 个并行，跑前看 `free -h`） | 12–16 h（`orchestrate` 选 A 另加 3–4 h，选 B 加 0.5 h） |
| B4 | 新技能：`in-your-own-words`、`sharpen`（0.3 h）；`statechart`（整目录搬 1 h，环境冒烟 1–2 h）；`create-` 与 `maintain-formal-verification-skill`（1.5 h）；`ketchup`（1.5 h，含 Mermaid 实测）；`ketchup-video`（D3：A 约 4–6 h，B 与 C 约 3 h，D 为 0） | 8 加 405 | 每个技能一个 worker；`statechart` 目录用脚本复制 | 5.5–12 h |
| B5 | 收口：`README` 技能表、`parity-check.sh` 全绿、更新 `UPSTREAM.md` 的 pin、验收冒烟 | 1 | 协调者 | 1.5 h |
| 合计 | | | | **约 24–35 h**（含 D3 与 D2 的取值范围） |

**顺序理由**：B0 先行，是为了后面每批都能用 `parity-check.sh` 验。B1、B2 机械量大、风险低，先做可以把冲突面缩小到 B3。B3 内部先做 `p3-mode` 的 SKILL，因为多个 playbook 引用它的 Subagents 一节。B4 里 `in-your-own-words` 要先于 `interrogate`（B3）落地，所以这一个技能提前到 B3 的开头。

**回滚**：每批一个 commit，`git revert` 即可，不涉及外部系统；全程不 push。

## 7. 待人决策项

下面每一项我都没替你选。「默认」只出现在确实无关紧要的两项里，并写明。

**D1：base pin。** 已定，唯一结果 `4e5b1cf`，不需要你选。列在这里只是为了让你确认依据（§1）。

**D2：`orchestrate` playbook 怎么跟。** 上游把它从约 112 行的「队列加 `units.tsv` 与 `ledger.tsv` 加 orch 脚本」改成 25 行的「协调者用自己的工具」；p3 仍是旧结构（Store layout、The brief、Queue and drain、Stack safety、Liveness and failure、Escalation）。上游新版里的「Project tracker 与 Project store」是 Cursor 概念，T3 里没有。
- **A. 采纳上游薄版。** 用 `delegate_task`、`t3_thread_launch`、`watch_pull_request`、`schedule_task`、`t3_thread_transfer` 重写 Topology 与 Supervision 两节；p3 现有的约 90 行结构被丢弃。工作量 3–4 h。
- **B. 保留 p3 现版，只吸收上游新版里的规则**：先跑通一个单元再扇出、不用消息探活、停滞按原因重试、协调者深度至多三层、每 PR 的验证者与作者异家族。工作量 0.5 h。
- **C. 两版并存。** 薄版作 `orchestrate.md`，原版移到 `references/orchestrate-store.md` 并从薄版链接。工作量约 2 h。

**D3：`ketchup-video` 怎么出视频。** 选项 A 到 D 见 §3.4（ffmpeg / 录制 HTML 页 / 内联自动翻页页 / 暂不移植）。选 D 时 §4 的 P1 要登记一条经你签字的例外。

**D4：`check-plan.mjs` 要不要带。** 现状：p3 的 `multi-phase-plan` 把检查写成内联清单，没有脚本。上游本轮修了两处（围栏代码块内不检查、行内代码分隔符匹配）并补了测试。
- **A. 保持现状**，两处修复不处理。
- **B. 引入脚本与测试**到 `skills/p3-mode/scripts/`，playbook 第 6 步改回「运行脚本」。多一个 node 依赖，但符合 `encode-lessons-in-structure`。

**D5：`docs/guide/` 要不要补 T3 版。** 上游指南 11 篇 Markdown 加 6 张图（约 2.4 MB，多数是图），本轮改了 11 篇。p3 当初没带。
- **A. 继续不带。**
- **B. 另立一个项目补 T3 版**，本次同步不含。

**D6：`statechart/scripts/` 怎么进 p3。**
- **A. 整目录原样搬**：405 个文件、约 3.7 MB。可与上游逐字节对账，`UPSTREAM.md` 好管。
- **B. 只搬运行时**：约 29 个文件、约 200 KB，不带 `test/`。体积小，但以后上游改测试夹具要手工忽略，且 `package.json` 里的 `test` 脚本会指向不存在的目录。
- **C. 不搬，安装时按 pin 去上游拉取。** 仓库不变大，但 `install.sh` 要联网，且离线时 `statechart` 不可用。
- **D. 不移植 `statechart`。** 那么 `create-formal-verification-skill` 里「用 `/statechart` 读结果」一句改成「把反例讲成步骤」，P1 要登记例外。

**D7：delegated worker「一次只写一个文件」的约定。** B3 共 31 个文件，按现约定要 31 个 worker 任务。
- **A. 保持约定**，每个文件一个 worker，协调成本高。
- **B. 为本次同步放宽成「一个 worker 写一个技能目录」**，约 11 个 worker；需要在实施前改 `AGENTS.md` 的相应一行（本阶段没改）。

**D8：「按任务难度选推理档位与快慢档」在 T3 落成什么。** 上游 `ce649c0` 的新规则：每次 spawn 先取角色默认，难的升一档，常规的降一到两档，只有「CI 或 trunk 红了、有人此刻被阻塞」才用快速档。T3 的 `orchestrator_capabilities` 显示：Claude 模型有 `effort`，`claude-opus-5-5` 另有 `fastMode`；Codex 模型有 `reasoningEffort` 与 `serviceTier`（`priority`）。`setup-p3` 目前只记录 effort。
- **A. 只做档位**（`effort` / `reasoningEffort`），不做快慢档。与现有 `setup-p3` 一致，改动最小。
- **B. 档位加速度。** `setup-p3` 的角色行加 `speed` 记法，紧急时 `p3-mode` 取 `fastMode` 或 `serviceTier: "priority"`。不是每个模型都有这个选项，没有的要写明回退。

**D9：AGENTS.md 的 T3 工具表对不对得上。** §4.4 列出的差异（`t3_thread_fork`、`t3_queue_*`、`preview_click` 等）。
- **A. 实施前先对 AGENTS.md 的工具表做一轮校正**，再让 P7 之类的判据以它为准。
- **B. 先不管，实施按本会话可见的工具名写。** 技能里写的工具名会与 AGENTS.md 表对不上。
- 这一项也要定「权威来源」：以哪个 T3 版本的工具清单为准。

**另有两个无关紧要的默认项，我先按下面的默认写，你不反对就不用答：**

- 上游把 `arena`、`architect`、`interrogate` 的默认模型列表从 3 项减到 2 项（去掉 Sol）。默认跟上游，`setup-p3` 的角色模板改成 2 项。
- 上游 `README` 里的 Claude Code 安装段与 `docs/harness/claude-code.md` 不进 p3（p3 面向 T3 Code）。

## 附录：复现方法

```sh
# 上游副本（blobless）
git clone --filter=blob:none https://github.com/cursor/plugins.git /tmp/cursor-plugins
# pin 到目标的全部文件
git -C /tmp/cursor-plugins diff --name-status --no-renames 4e5b1cf c742dd6 -- pstack/
git -C /tmp/cursor-plugins diff --stat 4e5b1cf c742dd6 -- pstack/ | tail -1      # 522 files changed
git -C /tmp/cursor-plugins rev-list --count 4e5b1cf..c742dd6 -- pstack           # 74
# 三方合并预演（以某个文件为例）
git show 4e5b1cf:pstack/skills/why/SKILL.md > /tmp/base
git show c742dd6:pstack/skills/why/SKILL.md > /tmp/theirs
git merge-file -p skills/why/SKILL.md /tmp/base /tmp/theirs   # 先把三者套改名映射
```
