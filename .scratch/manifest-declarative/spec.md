# Manifest v2 declarative engine

Status: ready-for-agent

## Problem Statement

v1 manifest 把「机器上有什么」与「怎么装」揉在一份声明里：命令拼装知识铺在 presets / defaults / entrypoint 三层覆盖链，引擎持有全部动词知识。后果是混合 kind（跨平台单 manifest）与变体（sudo / msstore / disable）只能靠形状爆炸表达，每新增一个 manager 都要改引擎。本 effort 对 Manifest v2 做设计锁定：彻底声明式的资源模型 + 通用迭代分发引擎；实现与迁移另开 effort。

## Solution

共识模型六条（grilling 确认基线）：

1. Manifest v2 = 纯资源声明：item 恰有一个 `kind` + 开放声明字段（提权/容错/版本/平台…）；命令碎片字段（`presets` / `defaults` / `entrypoint` / `command` / `args` / `prefix` / `suffix`）全部废除。
2. 引擎 = 通用迭代分发器（ADR-0001 零依赖继续有效）：展开 groups → 按序迭代 → 过滤选择类字段（`enable` / `platforms`）→ 整 item 原样透传给调用方指定的任意 task。引擎零动词知识、零语义解释。
3. 调用处 task 即动词：提权 / 失败 / 收敛的处理全部在接收 task 就地实现；混合 kind 由接收方自行路由。
4. 提权 / 容错 = 同一种 item 声明机制，值不同；消费与否由调用方决定。
5. 交付物即设计锁定：本 spec 总纲 + detail files + ADR-0002 + GLOSSARY + openspec change（spec-only），实现不在内。
6. 范围外：引擎实现、manifests 迁移执行、wrapper 重写、旧引擎删除——本图 spec 只写并存 → 迁完 → 删除策略。

定稿细节（本总纲只述模型，规则全文以 detail files 为准）：

- 结构契约（顶层键、item、保留键、约定声明字段、kind registry、escape hatch）：[details/schema.md](details/schema.md)
- 引擎契约（入口、四步职责、`ITEM_JSON` 透传、失败语义、结构错误、边界行为）：[details/engine.md](details/engine.md)
- 决策记录：[ADR-0002](../../docs/adr/0002-manifest-resource-model.md)；术语以 [GLOSSARY.md](../../GLOSSARY.md) 为准
- 行为契约 specs：openspec change `manifest-v2`（`manifest-v2-schema` / `manifest-v2-dispatch` 两个 capability）

## Migration Strategy

并存 → 迁完 → 删除旧引擎，全文见 [details/migration.md](details/migration.md)：

- **并存**：`manifest:dispatch` 追加进现 `taskfile.d/manifest.yaml` 与 v1 同文件；manifest 原地重写同名文件；wrapper `manifest:<name>` 名字不变、内部翻转为 dispatch。「接收方 task 就绪 + manifest 重写 + wrapper 翻转」三件套同 commit，防 v1 引擎跑 v2 文件静默空跑。
- **冻结**：旧格式过渡期禁止新建 v1 manifest，新增资源 MUST 走 v2 表达；既有 v1 manifest 只许下机类编辑（删行/注释/`enable: false`）。双向机械防呆：v2 引擎未知顶层键 fail，v1 引擎顶层含 `items:` 即 fail。
- **迁完**：批 = 一个 manager 族 = 一个接收方 task 的覆盖面；试点 `debug` + `windows-features`，大头 scoop 族，其余按族推进；每批验收静态 grep 双清零，不实跑。
- **删除**：`manifests/` 顶层 `run:` / `presets:` 与全仓 `manifest:run` 双 grep 清零即删 v1 两个 task，无观察宽限期。

## Out of Scope

- 引擎实现与代码落地——设计锁定即收图，另开实现 effort。
- manifests 迁移执行、根 taskfile wrapper 重写、旧引擎删除——后续 effort 另开地图。
- verb 生态 / 动词矩阵 / 收敛式 status 实现规范——无 verb 概念，调用方自建。
- 既有 taskfile.d/*.yaml per-tool 任务的改造——接收透传 item 的新形态属实现/迁移期决策。

## Further Notes

- 决策脉络：wayfinder 地图 [map.md](map.md) 与七张决策票（issues/01–07）；go-task 机制事实见 issues/01 与 research/。
- 变体一律降为声明字段（如 sudo 变体 → `elevated: true`），kind 命名 `<manager>-<resource>`，不设 kind 变体。
