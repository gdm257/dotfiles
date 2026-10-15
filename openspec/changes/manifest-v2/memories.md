# Memories

## Sources gathered

- `GLOSSARY.md` — read. v2 术语已定稿（ticket 05）：Manifest / Item / Kind / Group 按其定义使用；run item / Preset / Defaults 已废除，不再出现。
- `docs/adr/` — read both. ADR-0001（引擎零依赖）全额适用于 v2；ADR-0002（资源模型取代命令清单）即本 change 的决策记录，三条否决选项在档。
- openspec specs — inventory via `openspec list --specs`：manifest-groups / manifest-run-item-enable / manifest-run-continue-on-error / spec-only-schema / trellis-schemas。前三个 read in full：均描述 v1 `run` item 行为（v1 引擎），本 change 纯新增 v2 契约，不触碰；无 spec 覆盖 v2 schema / dispatch，无近重复。
- `.trellis/spec/` — absent, skipped.
- 设计定稿来源：`.scratch/manifest-declarative/`（map.md、details/schema.md、details/engine.md、details/migration.md、issues/01–07、research/ 两份实测）。

## Constraints carried forward

- ADR-0001 零依赖：解析 / 展开 / 过滤 / 透传全部以 bash builtins + Windows 自带命令 + Task 进程内模板实现，不引入外部脚本。
- 透传形态锁定 toJson/fromJson（issues/02 实测）：`ref: .ITEM` 整 map 透传在 for+task vars 中不可用（nil pointer）。
- 并存期约束：v1 引擎与 v1 specs（manifest-groups 等）在迁移完成前均不动，本 change 纯 ADDED；v1 specs 退役随旧引擎删除归迁移 effort。
- v2 的 group 引用条目可声明选择类保留键（`enable` / `platforms`）与 `continue_on_error` 传播，与 v1 manifest-groups 的「group 条目不覆盖任何字段」分属两代引擎，各自成立，非冲突。
- 迁移策略不进本 change 的 specs delta，由 `.scratch/manifest-declarative/spec.md` 总纲与 details/migration.md 承载。
