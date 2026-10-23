# Memories

## Sources gathered

- `GLOSSARY.md` — read，且本 change 会话已更新：新增 State 词条（方向字段、per-kind 值域），Manifest 词条修正为「应存在与应不存在的资源」。rev1：State 词条中组级传播措辞待同步为通用下传表述（随实现 ticket 落地）。术语按其定义使用。
- `docs/adr/` — read both. ADR-0001（零依赖）继续全额适用：通用下传与 enable 死键拒绝均在 Task 进程内模板实现，不引入外部命令。ADR-0002（资源模型）分层不破：引擎零声明字段词汇、只做通用下传与透传，本 change 属自然延伸，无冲突需 surface。
- openspec specs — inventory via `openspec list --specs`（7 个）。read in full：`manifest-v2-schema`（保留键集合与传播规则，本 change 修订：传播类别枚举整体 REPLACED 为通用下传）、`manifest-v2-dispatch`（四步职责含 enable 过滤，本 change 修订）、`manifest-run-item-enable`（v1 引擎行为；v1 引擎已删除，本 change REMOVED 退役）；`manifest-groups` / `manifest-run-continue-on-error` 同为 v1 遗产但不在本 change 触碰范围；`spec-only-schema` / `trellis-schemas` 为元规范，无约束冲突。
- `.trellis/spec/` — absent, skipped.
- 设计定稿来源：`.scratch/manifest-item-state/spec.md`（grilling 共识定稿；rev1 修订：通用下传取代传播型枚举）。
- rev1 来源：实现落地后用户 review 两轮否决——先指出引擎模板点名 `state`（及既有 `continue_on_error` 特例）属 receiver 词汇泄漏进 manifest 引擎；进而定则「manifest 保持通用，manifest 层不得有任何 receiver 字段说明」（覆盖引擎文本、场景示例与报错指引）。

## Constraints carried forward

- `state` 并非新造词：schema spec「变体降为声明字段」的约定字段清单已含 `state`（期望态），windows-feature 接收方已是第一个消费者（`enabled` / `disabled`）。本 change 是把它升格为家族契约：字段名统一、值域 per-kind。字段语义与值域只活在 receiver 层 spec（`manifest-item-state` capability），manifest 层（schema / dispatch）零字段词汇。
- 通用下传（rev1 定则）：组引用条目即 defaults 块——除保留键 `group` / `platforms` / `kind` 外一切声明字段逐键下传给未声明成员，成员显式优先；下传非破坏性（不改组定义成员字典，重复引用互不污染）；引擎不持有、枚举或说明任何声明字段名，`state` 与 `continue_on_error` 的传播特例收编删除；模板实现沿 ADR-0001 零依赖。
- enable 废除是破坏性迁移：manifests 现存 8 处 `enable: false`（dsh 1、app-video 3、app-kernel 4）与引擎改动、fixtures 更新同批落地；引擎对残留 `enable` 响亮拒绝，指引文案为「注释掉该条目」——manifest 层报错不点名任何 receiver 字段（rev1 裁决：删除早期「或改用 state」字样，引擎已落地文案的同步入实现 ticket），对齐本仓 v1 键误入 fail 哲学。
- 无暂停语义：「不关心」= 注释，「不要」= `state: absent`；组级暂停 = 注释引用行，组定义原地保留。
- 幂等达标判定归接收方：absent + 未安装 = 成功（墓碑永久无害）；present + 已安装 = 成功；`version` 仅安装命令拼装。收敛边界 declared-only，清单外资源永不被动。
- v1 specs 退役只做 `manifest-run-item-enable`（与 enable 语义直接相关）；`manifest-groups` / `manifest-run-continue-on-error` 的退役另行处理，不搭车。
- 迁移与实现的执行排期不进本 change 的 specs delta，由 `.scratch/manifest-item-state/spec.md` 承载。
