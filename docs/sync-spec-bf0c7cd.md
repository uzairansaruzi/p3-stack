# p3-stack 跟上游 pstack 同步：实施 spec（bf0c7cd）

- 上游：https://github.com/cursor/plugins
- 上一 pin：`c742dd6`（2026-10-27，0.15.36）
- 本轮目标：`bf0c7cd`（2026-11-15 11:36 UTC+8，0.15.42）
- 授权：max 于 2026-11-16 定「默认模型不抄，其他功能开始同步」

## 0. 结论摘要

上游本轮只有一个提交、六个子改动。五类功能改动已全部落地：`how`/`why` 各砍成单文件、两个 statechart 修复、sharpen 与 reflect 文案、配套引用改写。默认模型换代按 max 指示整块跳过，含它牵出的家族/厂商语义、四档预算按步移动、`# defaults: 2` 标记行。

`scripts/parity-check.sh` 全绿（PASS 8、ALLOW 5、FAIL 0、STALE 0）。`scripts/upstream-diff.sh` 报 0 个待处理单元。

## 1. 本轮上游范围

`git diff --name-status c742dd6 bf0c7cd -- pstack/` 共 59 个文件：修改 47、新增 1（`test/drawn.ts`）、删除 14（`how/references` 2 个、`why/references` 12 个）。其中 12 个落在 `UPSTREAM.md` 已登记的忽略路径（`automations/**`、`.cursor-plugin/**`、`docs/guide/**`、`docs/harness/**`、`plugin.json`），不进 p3。

上游提交正文把依据分六节写在 PR #1236 里，无评审、无评论。

## 2. 同步清单

### 2.1 已落地

| 上游路径 | p3 路径 | 上游改了什么 | 做法 |
|---|---|---|---|
| `skills/how/SKILL.md` | `skills/how/SKILL.md` | 砍成一个文件：一次只起一个只读子 agent，删复杂度门、explorers、输出小节、模型路由 | 需适配：`delegate_task` + `mode: "async"` + `task_status`，brief 写明只读。行数 21，与上游一致 |
| `skills/how/references/**` | 同名 2 个文件 | 删除 | 直接删 |
| `skills/why/SKILL.md` | `skills/why/SKILL.md` | 砍成 48 词单文件，不点名任何数据源与工具 | 直接搬，frontmatter 用上游新版 |
| `skills/why/references/**` | 同名 12 个文件 | 删除 | 直接删 |
| `skills/statechart/scripts/**` | 同路径 | SANY 失败报错段、父状态箭头走边界、新增 `test/drawn.ts` 与测试 | 整目录按 `bf0c7cd` 替换（D6=A 的既定做法） |
| `skills/sharpen/SKILL.md` | 同路径 | 改写 prompt 要求先原型再推荐，产品与偏好选择留给人 | 直接搬 |
| `skills/reflect/references/synthesizer.md` | 同路径 | 「会过时的细节」示例由模型重命名换成函数重命名 | 直接搬 |
| `skills/blast-radius/SKILL.md` | 同路径 | 不再引用 `why` 的步骤与规则 | 直接搬 |
| `skills/teach/SKILL.md` | 同路径 | 删 `why` 的收窄建议与角色名 | 需适配：删角色名，保留「并行跑 how/why」 |
| `skills/recall/SKILL.md` | 同路径 | 自己按来源起 investigator，不再借 `why` 的 playbook | 需适配：`delegate_task`，chat-history 工人走 `swarm workers` 角色 |
| `skills/no-comments/SKILL.md` | 同路径 | 先 trace 再跑 `/why` | 直接搬 |
| `agents/comment-sicko.md` | 同路径 | 同上 | 直接搬 |
| `skills/architect/SKILL.md` | 同路径 | 不再调 `how`，改为 trace 子系统 | 直接搬（`architect runners` 默认值跳过） |
| `skills/poteto-mode/SKILL.md` | `skills/p3-mode/SKILL.md` | 删 `how` 触发词、两处角色清单去掉 `how`/`why`、机械改读 `swarm workers` | 需适配：只取这几句，默认模型句跳过 |
| `skills/poteto-mode/playbooks/{investigation,bug-fix,feature,hillclimb,perf-issue,refactoring,multi-phase-plan}.md` | 同路径 | `how` 改 trace | 直接搬对应句 |
| `skills/setup-pstack/SKILL.md` | `skills/setup-p3/SKILL.md` | 删 `how explorer`、`how explainer`、`why investigators`、`why synthesizer` 四个角色 | 需适配：删角色模板行与两处描述；defaults 标记与预算按步移动跳过 |
| `AGENTS.md` | 同文件 | 角色名单 | 删四个退役角色 |
| `README.md` | `README.md` | 描述 | 只更新同步版本号，技能表语义未变 |

### 2.2 有意不同步

| 上游改动 | 处理 | 理由 |
|---|---|---|
| 默认模型换代（fable 5.2 / opus 5.5 / gemini 4 carbon） | 跳过 | max 2026-11-16 指示「默认模型不抄」。p3 的角色模型由 `setup-p3` 按 `orchestrator_capabilities` 生成 |
| `arena` 的家族最长前缀与 vendor 语义 | 跳过 | 与 fable 引入绑定；p3 的家族规则已按模型 id 定义，默认池里没有 fable 与 gemini 时无行为差异 |
| `setup-pstack` 的 `# defaults: 2` 标记与旧默认迁移 | 跳过 | p3 的 `p3-models.md` 每次按目录重写，没有上游那种「默认值落在用户文件里」的问题 |
| 四档预算改为按角色默认值步进 | 跳过 | 前提是默认值不再统一为 `xhigh`；p3 保留统一档位映射，行为不变 |
| `swarm`、`reflect` 表格里的默认 slug | 跳过 | 纯默认模型，同上 |
| `automations/**`、`.cursor-plugin/**`、`docs/guide/**`、`docs/harness/**`、`plugin.json` | 忽略 | 既有忽略表 |

## 3. 验收与证据

| 判据 | 命令 | 结果 |
|---|---|---|
| 上游文件覆盖与双向对应 | `scripts/parity-check.sh` | P1 58/58、P2 99/99 文件，全绿 |
| Cursor 残留词 | 同上 P3 | 0 命中 |
| 委托/监视/读历史换成 T3 工具 | 同上 P4 | delegate 15/15、watch 4/4、history 6/6 |
| 角色名闭合 | 同上 P7 | AGENTS.md 13 个角色，setup-p3 13 个，一致 |
| 长度不回退 | 同上 P8 | 8 个既有白名单，无新增 |
| 与上游无待办 | `scripts/upstream-diff.sh` | 0 提交、0 文件，exit 0 |
| statechart 父状态箭头与 SANY 报错 | `node --test skills/statechart/scripts/test/{chart,render}.test.ts` | 127 通过、0 失败，含「父状态唯一边界入口」与「Pele 1.9.0 不穿标题栏」两条新测试 |
| statechart 全量 | `node --test skills/statechart/scripts/test/*.test.ts` | 270 通过、62 跳过、1 失败；失败项是 `differential.test.ts` 缺开发依赖 `fast-check`，与本次改动无关（未安装 node_modules） |
| 安装脚本 | `bash scripts/install.test.sh` | 69 通过、0 失败 |

`corpus.test.ts` 的三条 SANY 报错测试需要 `TLA2TOOLS`，本机未设，按上游 CI 同样跳过。

## 4. 复跑方式

```sh
scripts/parity-check.sh                 # 需要 node 20.11+
scripts/upstream-diff.sh                # exit 0 表示无待办
node --test skills/statechart/scripts/test/*.test.ts
bash scripts/install.test.sh
```

要跑 SANY 报错测试，先下载 pin 住的 `tla2tools.jar`，再设 `TLA2TOOLS` 指向它。
