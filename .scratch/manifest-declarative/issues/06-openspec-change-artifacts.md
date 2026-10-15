# 06: openspec change 全 artifacts 与 .scratch spec 总纲

Type: task
Status: resolved
Blocked by: 03, 04, 05, 07

## Question

汇总交付（设计锁定收图）：

- `.scratch/manifest-declarative/spec.md` 总纲：Problem Statement、Solution（共识模型六条）、迁移策略（并存 → 迁完 → 删除旧引擎，旧格式过渡期冻结、禁止新增）、Out of Scope。风格对齐既有 `.scratch/*/spec.md`。
- `openspec new change <name> --schema spec-only`：创建该 change 的全部 artifacts——memories 与 specs delta（由 `details/schema.md` 与 `details/engine.md` 提炼为行为契约 requirements / scenarios），`openspec validate` 通过。

## Answer

设计锁定收图交付完成：

- `.scratch/manifest-declarative/spec.md` 总纲落盘：Problem Statement / Solution（共识六条 + detail files 与 ADR/GLOSSARY/openspec change 指针）/ Migration Strategy（并存 → 冻结 → 迁完 → 删除）/ Out of Scope / Further Notes，风格对齐既有 `.scratch/*/spec.md`。
- openspec change `manifest-v2`（spec-only schema）创建，全部 artifacts 完成：
  - `memories.md`：Sources（GLOSSARY、ADR-0001/0002、三个 v1 specs 全读、`.trellis/spec/` 缺席跳过）+ 五条 Constraints carried forward（零依赖全额适用、toJson/fromJson 透传锁定、v1 引擎与 specs 并存期不动、v2 引用条目选择键与 v1 manifest-groups 非冲突、迁移策略不进 delta）。
  - specs delta 两个 capability，纯 ADDED：`manifest-v2-schema`（7 requirements：顶层结构 / item+kind / 声明序 / 保留键封闭集 / group 引用与传播 / kind shell escape hatch / 变体降字段）与 `manifest-v2-dispatch`（6 requirements：入口 vars / 四步职责 / ITEM_JSON 唯一通道 / FAIL_LOG 失败语义 / 结构错误消息 / 边界行为零依赖），均含 WHEN/THEN scenarios，措辞对齐既有 v1 specs（中文正文 + SHALL/MUST 关键词）。
  - `openspec validate manifest-v2 --strict` 通过；`openspec status` isComplete: true。
- 新增文件：`.scratch/manifest-declarative/spec.md`、`openspec/changes/manifest-v2/`（`.openspec.yaml` 由 CLI 生成；memories.md；specs/manifest-v2-schema/spec.md；specs/manifest-v2-dispatch/spec.md）。全部 LF。
- v1 specs（manifest-groups / manifest-run-item-enable / manifest-run-continue-on-error）未触碰：并存期 v1 引擎仍活，其退役随旧引擎删除归迁移 effort（delta 纯 ADDED 的依据，已记入 memories）。
- 后续实现 effort 依赖的事实：change 名 `manifest-v2`；capability 名 `manifest-v2-schema` / `manifest-v2-dispatch`；archive 后进入 `openspec/specs/` 主库。
