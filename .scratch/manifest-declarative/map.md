# Map: manifest 引擎彻底声明式（设计锁定）

wayfinder:map

## Destination

manifest 引擎重构为彻底声明式的**设计锁定**：`.scratch/manifest-declarative/spec.md` 总纲 + detail files（schema / 引擎契约 / 迁移策略）+ ADR-0002 + GLOSSARY 更新 + spec-only openspec change 的全部 artifacts（memories → specs）创建完成并通过 validate。实现与迁移不在本图。

## Notes

- 书写遵循 ~/.dsh/AGENTS.md artifacts 规则：LF、UTF-8、中文为主、英文标题与术语保持英文。
- 共识基线（grilling 已确认，六条）：
  1. Manifest v2 = 纯资源声明：item 恰有一个 kind + 开放声明字段（提权/容错/版本/平台…）；命令碎片字段（presets/defaults/entrypoint/command/args/prefix/suffix）全部废除。
  2. 引擎 = 通用迭代分发器（ADR-0001 零依赖继续有效）：展开 groups → 按序迭代 → 过滤选择类字段（enable/平台）→ 整 item 原样透传给调用方指定的任意 task。引擎零动词知识、零语义解释。
  3. 调用处 task 即动词：提权/失败/收敛的处理全部在接收 task 就地实现；混合 kind 由接收方自行路由。
  4. 提权/容错 = 同一种 item 声明机制，值不同；消费与否由调用方决定。
  5. 交付物即 Destination 所列；设计锁定即收图。
  6. 范围外：引擎实现、manifests 迁移执行、wrapper 重写、旧引擎删除（spec 只写并存→迁完→删除策略）。
- go-task 机制事实：见 [01: go-task v3.54.0 动态分发能力事实核查](issues/01-gotask-capability-facts.md)。
- 术语：GLOSSARY 将重定义 Manifest、新增 Kind / Item、废除 Run item / Preset / Defaults（05 执行）。
- skills：03、04、07 讨论时调用 grilling 与 domain-modeling；ADR/GLOSSARY 格式见 domain-modeling skill 的 ADR-FORMAT / GLOSSARY-FORMAT。

## Decisions so far

- [01: go-task v3.54.0 动态分发能力事实核查](issues/01-gotask-capability-facts.md): 动态 task 名运行期模板化官方支持；for+task+vars 一等公民；includes 无 glob；wildcard 任务名 v3.35.0+ 可用——引擎契约机制前提成立。
- [02: 本地验证 item 透传的未背书组合](issues/02-verify-dispatch-mechanics.md): `ref: .ITEM` 整 map 透传在 for+task vars 中不可用（nil pointer）；`toJson` + `ref: 'fromJson ...'` 类型保真可行；裸动态 `task: '{{.CALL}}'` 运行期解析可行——透传契约采用 toJson/fromJson 形态。
- [03: Manifest v2 schema 定稿](issues/03-manifest-v2-schema.md): 顶层仅 items+groups（未知顶层键 fail，v1 误入响亮报错）；item = kind+开放字段，保留键 enable/platforms/group；变体降字段（elevated/state/source/version:string/continue_on_error）；kind = `<manager>-<resource>`；escape-hatch kind: shell——定稿见 details/schema.md。
- [04: 引擎分发契约定稿](issues/04-engine-dispatch-contract.md): 入口 `manifest:dispatch`（`MANIFEST`+`CALL`）；唯一透传 var `ITEM_JSON`（fromJson 还原，零便捷 var）；引擎仅基础设施（`FAIL_LOG` truncate/汇总/exit 1），`continue_on_error` 归接收方；结构错误含路径与展开序号、platforms 严格校验；空批静默 exit 0、严格串行——定稿见 details/engine.md。
- [05: ADR-0002 与 GLOSSARY 更新](issues/05-adr-glossary-update.md): `docs/adr/0002-manifest-resource-model.md` 落盘（资源模型取代命令清单，三条否决选项入档，承接 ADR-0001 零依赖）；GLOSSARY 重定义 Manifest、新增 Item / Kind、废除 Run item / Preset / Defaults、修订 Group——措辞经用户审定。
- [07: 迁移策略 detail file 定稿](issues/07-migration-strategy.md): 并存 = dispatch 同文件追加 + manifest 原地重写 + wrapper 名不变同批翻转（三件套同 commit，防 v1 引擎跑 v2 文件静默空跑）；v1 冻结禁新增只许下机编辑 + v1 引擎加 `items:` 防呆；批 = manager 族（试点 debug+windows-features、大头 scoop），验收静态 grep 不实跑；双 grep 清零即删旧引擎、无宽限——定稿见 details/migration.md。
- [06: openspec change 全 artifacts 与 .scratch spec 总纲](issues/06-openspec-change-artifacts.md): spec.md 总纲落盘（共识六条 + 迁移策略四段）；openspec change `manifest-v2`（spec-only）全 artifacts 完成——memories + 纯 ADDED 两 capability（manifest-v2-schema 7 reqs / manifest-v2-dispatch 6 reqs，v1 specs 不动），`validate --strict` 通过——Destination 达成。

## Not yet specified

（无——七票全收、无新增 fog；Destination 已达成，地图完成。实现与迁移另开 effort。）

## Out of scope

- 引擎实现与代码落地——设计锁定即收图，另开实现 effort。
- manifests 迁移执行、根 taskfile 60 个 wrapper 重写、旧引擎删除——后续 effort 另开地图；本图 spec 仅写迁移策略。
- verb 生态 / 动词矩阵 / 收敛式 status 实现规范——无 verb 概念，调用方自建；spec 至多 MAY 级提及。
- 既有 taskfile.d/*.yaml per-tool 任务（scoop:install 等）的改造——接收透传 item 的新形态属实现/迁移期决策。
