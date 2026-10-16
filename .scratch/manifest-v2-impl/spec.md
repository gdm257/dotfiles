# Manifest v2 implementation and migration

Status: resolved

实施与验收结果见 [Implementation Verification](verification.md)。工单 01–11 已完成；旧 worktree 的安全保留原因与备份 SHA 记录在该文件中。

## Problem Statement

Manifest v2 设计已锁定（模型、schema、引擎契约、迁移策略、ADR-0002、GLOSSARY、openspec change `manifest-v2` 均就绪），但仓库里跑的仍是 v1：命令碎片铺在 presets / defaults / entrypoint 三层覆盖链，引擎持有全部动词知识，混合 kind 与变体靠形状爆炸表达。需要把 v2 落地——引擎、逐族接收方、70 个 manifest 换代、wrapper 翻转、v1 防呆与最终删除——且迁移全程用户面零感知、不出现「v1 引擎跑 v2 文件静默空跑」的假成功。

## Solution

并存 → 迁完 → 删除三段式落地：`manifest:dispatch` 引擎与 v1 同文件并存并即刻加固 v1 防呆（双向误入均响亮报错）；试点批（debug + windows-features）验证接收方模式后，按 manager 族逐批迁移（接收方就绪 + manifest 原地重写 + wrapper 内部翻转，三件套同 commit），scoop 大头批之后各族并行；双 grep 清零后单独 commit 删除 v1 引擎，无宽限期。用户面不变量全程保持：`task manifest:<name>` 名字与行为不变、`CONTINUE_ON_ERROR=true` 可用、失败汇总 UX 不变。旧格式并存期冻结：禁止新建 v1 manifest，新增资源一律 v2 表达。

## User Stories

1. As a dotfiles 使用者, I want `task manifest:<name>` 名字迁移前后全程不变, so that 肌肉记忆、脚本与文档零改动。
2. As a dotfiles 使用者, I want 换代后同一命令装出同样的东西, so that 迁移无感知。
3. As a dotfiles 使用者, I want `CONTINUE_ON_ERROR=true` 全局 var 迁移前后同样可用, so that 临时容错习惯不变。
4. As a dotfiles 使用者, I want 失败汇总 UX 不变（failed items 列表 + 非 0 退出码）, so that 脚本化调用仍能感知有 item 失败。
5. As a dotfiles 使用者, I want v2 manifest 误入 v1 引擎立即响亮报错, so that 不会假成功、悄悄什么都没装。
6. As a dotfiles 使用者, I want v1 manifest 误入 v2 引擎立即响亮报错, so that 不会静默空跑。
7. As a dotfiles 使用者, I want 提权安装（sudo 类）照常工作, so that 需要管理员权限的资源不被迁移破坏。
8. As a manifest 作者, I want manifest 只声明「有什么资源」（kind + 开放声明字段）, so that 不再维护 preset / defaults / entrypoint 覆盖链。
9. As a manifest 作者, I want 变体用声明字段表达（sudo → `elevated`、msstore → `source`、disable → `state`）, so that 不再靠形状爆炸。
10. As a manifest 作者, I want 冻结期新增资源一律写 v2 表达, so that 规则简单明确且倒逼迁移推进。
11. As a manifest 作者, I want 跨平台差异用 `platforms` 显式声明、单 manifest 可混合 kind, so that 平台差异声明在一处。
12. As a manifest 作者, I want 未知声明字段被接收方静默容忍, so that 字段扩展不破坏既有接收方。
13. As a manifest 作者, I want `platforms` typo 被引擎拒绝, so that 不会静默丢 item。
14. As a manifest 作者, I want group 引用条目支持整组开关与 `continue_on_error` 向组内传播, so that 组织复用不重复。
15. As a manifest 作者, I want 调试命令批用 `kind: shell` 表达, so that 调试清单也是纯声明。
16. As a 接收方 task 作者, I want 新 manager 只需新增一个接收方 task, so that 引擎零改动。
17. As a 接收方 task 作者, I want item 经 `ITEM_JSON` 类型保真到达（bool / 嵌套 / list）, so that 模板判断不踩字符串化的坑。
18. As a 接收方 task 作者, I want 接收方不经 dispatch 独立调用时不被 `FAIL_LOG` 绑死, so that task 可复用。
19. As a 接收方 task 作者, I want 提权与容错消费与否由接收方决定, so that 接收方保持薄而专。
20. As an AFK agent（迁移执行者）, I want 结构错误带 manifest 路径与 `#N` 展开序号, so that 一次定位修一处。
21. As an AFK agent, I want 每批验收静态 grep 即可, so that 不需要在已装机器上实跑。
22. As an AFK agent, I want 三件套同 commit 的原子性要求明确, so that 任何中间 checkout 都是自洽状态。
23. As an AFK agent, I want 双 grep 清零即删旧引擎, so that 终态无死代码滞留。

## Implementation Decisions

- 引擎放置：`manifest:dispatch` 追加进 v1 引擎所在 taskfile 同文件并存；includes 与 v1 任务名全程不动（另立文件即被迫改入口名，已否决）。
- 入口契约：required vars 恰为 `MANIFEST` + `CALL`；`CALL` 运行期解析、可含 namespace，未知名干净报错。
- 四步职责：解析（未知顶层键 fail）→ 展开（`items` 声明序、group 展开、`continue_on_error` 传播）→ 过滤（`enable` / `platforms` 三层一致）→ 透传（幸存 item 整 map 原样交 `CALL`，严格串行）。引擎零动词知识、零语义解释。
- 透传唯一通道 `ITEM_JSON`（toJson 进、fromJson 出，约定绑定名 `ITEM`）；零便捷 var；bool 保真仅此一条通道。
- 失败语义：引擎仅基础设施——`FAIL_LOG` 每次开头 truncate、收尾非空则打印汇总 + exit 1；fail-fast 免费；`continue_on_error` 与批量级开关归接收方自包装。
- 结构错误一律 fail 且消息含 manifest 路径与展开序号 `#N`；`platforms` 严格值域校验。
- 零依赖：ADR-0001 全额适用（bash builtins + Windows 自带命令 + Task 进程内模板）。
- v1 加固（并存期第一笔）：`run:manifest` 解析后顶层含 `items:` 即 fail，只加拒绝、不动 v1 语义。
- 迁移形态：manifest 原地重写同名文件（路径稳定、git diff 即迁移记录）；wrapper 用户面名不变、内部翻转为 dispatch + `CALL`；三件套（接收方就绪 + 重写 + 翻转）同批同一 commit。
- 批次：批 = manager 族 = 一个接收方覆盖面；试点 debug（`kind: shell`）+ windows-features（`state`）→ scoop 族 16 个 → winget / brew / 系统包 / 长尾两批并行；windows 与 unix 互不阻塞。
- 接收方：命名与落位实现期自定；混合 kind 按 `kind` 路由；kind 命名 `<manager>-<resource>` 小写 kebab，变体一律降为声明字段。
- 冻结执行面 = 约定 + 双向机械防呆，不建 CI lint（单人仓库）。
- 删除判据：`manifests/` 顶层 `run:` / `presets:` 与全仓 `manifest:run` 双 grep 清零即删 v1 两 task，单独 commit，无观察宽限期。
- UX 不变量：CLI 全局 var（如 `CONTINUE_ON_ERROR`）由接收方自取，迁移前后行为面不变。

## Testing Decisions

- 只测外部行为：执行了哪些 items、最终退出码、错误消息；不测模板字符串内部拼装。
- 唯一 seam = task CLI 边界（与用户确认）：`task manifest:dispatch MANIFEST=<fixture> CALL=<重放接收方>` 打引擎；同形态打 v1（v2 形 fixture 断言响亮报错）验防呆。不新增更低层 seam。
- 契约 fixture 落仓固定路径供手工回归重放（用户裁决，偏离用完即弃惯例）：覆盖结构错误各型、`enable` / `platforms` 过滤（含整组跳过）、bool 保真透传、fail-fast 与 `FAIL_LOG` 汇总、空批 exit 0；重放接收方（echo 形态）随 fixture 一并落仓。
- 迁移批零实跑：验收静态 grep 双清零（`manifest:run:manifest` 引用、manifest 顶层 `run:` / `presets:`），首次真实调用即结构自检（已装多为 no-op，实跑无验收价值）。
- Prior art：manifest-run-continue-on-error 的 fixture manifest 手工验证惯例（端到端断言 items 与退出码，仓库无测试框架）。

## Out of Scope

- 重开设计锁定决策：模型六条、通用 `id`、便捷 var、并发迭代、负向 `platforms`、依赖图 `requires:`。
- verb 生态 / 动词矩阵 / 收敛式 status 实现规范——无 verb 概念，调用方自建。
- CI lint 与自动化测试框架。
- 非 manifest 体系的既有 taskfile.d 任务改造（接收透传所需除外）。
- openspec change `manifest-v2` 的 archive 时机——另行处理。
- 新 manager / 新 kind 生态扩展——迁移完成后的增量工作。

## Further Notes

- 设计出处：`.scratch/manifest-declarative/`（map + details/schema.md + details/engine.md + details/migration.md）、ADR-0001 / ADR-0002、GLOSSARY、openspec change `manifest-v2`（`manifest-v2-schema` / `manifest-v2-dispatch` 行为契约）。
- 执行切片：本目录 issues/01–11，frontier = 01（v1 防呆）与 02（引擎落地），可并行。
- 冻结本身是推进迁移的 forcing function：所在族未迁则先迁该族。
- fixture 落仓裁决已同步至 02 票；本 spec 与 tickets 验收措辞如有出入，以 spec 为准并回改票。
