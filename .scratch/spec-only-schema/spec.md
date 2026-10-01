# OpenSpec Spec-Only Schema

**Status:** ready-for-agent

## Problem Statement

既有 OpenSpec schemas 都绑定一套规划 artifacts（spec-driven 的 proposal/design/tasks、matt-pocock 的 spec/tickets、trellis 的 prd/design/implement）。但有两类场景只需要 delta specs 本身：一是 chat 里先说明 ideas、逐步推进、直接据此实现，规划文件纯属仪式；二是 backfill——从既有 codebase / commits / 其他框架的 artifacts 反向产出 specs，根本没有"规划"可言。这两类场景被现有 schemas 强迫产出无人阅读的中间文件。

## Solution

新增 `spec-only` schema：artifact 链仅 `memories → specs`，无 apply。memories 与 specs instruction 从既有 schemas 原样拷贝（specs 基于 matt-pocock 已前置 propose-capabilities 块的版本），新增一段来源指引区分 new work（chat 意图正向产出）与 backfill（从既有实现蒸馏），最小改写两处指向 proposal 的死引用，结尾加 `openspec validate` 完成判据。正向与 backfill 都走标准 change → validate → archive 生命周期。

## Language

**New work**:
spec-only 的正向用法——需求来自 chat 中尚未实现的 ideas，据此起草行为契约。
_Avoid_: forward, 逆向

**Backfill**:
spec-only 的反向用法——从既有 codebase / commits / 其他框架的 artifacts 蒸馏 observable behavior，反向产出 specs。
_Avoid_: 逆向用法, reverse

## User Stories

1. As a chat 驱动的开发者, I want 一个只产出 delta specs 的 schema, so that 说明 ideas 后不被强迫凑 proposal/design/tasks。
2. As a chat 驱动的开发者, I want specs instruction 告诉我从 chat 意图起草行为契约, so that 不存在的规划文件不被引用。
3. As a backfilling 开发者, I want 从既有 codebase / commits / 其他框架 artifacts 蒸馏 specs, so that 已有行为进入 `openspec/specs/` 主库而不经过规划仪式。
4. As a backfilling 开发者, I want backfill 走标准 change → validate → archive, so that 享受 archive 的合并逻辑而非手写主库。
5. As an agent, I want 来源段写明 "named in the chat", so that 我不猜需求来源。
6. As an agent, I want specs instruction 保留 skip_specs 出口, so that 零 delta change 有合法通道。
7. As an agent, I want 结尾的 validate 完成判据, so that 我知道何时停手。
8. As a 维护 schema 的开发者, I want memories / specs instruction 与 spec-driven / matt-pocock 原样拷贝、`propose-capabilities` 标记保留, so that 三处共享文本不分叉、可机械同步。
9. As a 维护 dotfiles 的开发者, I want schema 进 pub-merge-recursive 树, so that 随发布机制部署。

## Implementation Decisions

- schema 落盘 `pub-merge-recursive/AppData/Local/openspec/schemas/spec-only/`（`schema.yaml` + `templates/memories.md` + `templates/spec.md`），`version: 1`，不设为默认。
- artifact 链 `memories` → `specs`；无 apply 段——openspec 对无 apply 的 schema 优雅降级（"Proceed with implementation"），正向实现 chat 驱动，backfill 无实现一步直接 archive。
- memories instruction 与模板从 spec-driven 原样拷贝（`templates/memories.md` 与 matt-pocock 的字节一致）。
- specs instruction 基于 matt-pocock 版（其已前置 `<!-- propose-capabilities:start/end -->` 块），做三处改动：
  - 块前新增来源段：new work / backfill 各一条，backfill 定义为蒸馏 observable behavior、丢弃实现细节与源框架流程。
  - proposal 死引用全部改写为指向 identified above："per capability identified above"；path bullet 的 "from the proposal" / "in the proposal"；skip_specs 段末句改为 "If no capabilities were identified and `skip_specs` is not set, ask the user before writing anything"。skip_specs 段其余文本与 propose-capabilities 块内文本原样保留。
  - 结尾新增 `` Done when every capability above has a spec file and `openspec validate` passes. ``
- delta 语义无 backfill 特例：同一套 ADDED/MODIFIED/REMOVED/RENAMED（共识 Q4a）。
- instruction 全英文，风格对标 implement skill 的简明克制，符合 writing-for-agents（正向措辞、leading word、完成判据、无 no-op）。
- 不新增 README（与既有 schemas 一致）。

## Testing Decisions

- 唯一测试 seam 是 openspec CLI（与 trellis schemas 的决策一致），一次性 smoke，不落自动化测试。
- 已执行 smoke：`openspec schemas` 识别 spec-only（memories → specs）；临时仓库 `openspec new change --schema spec-only` 后渲染 memories 与 specs instructions（含来源段、identified above、完成判据）；手写 backfill 式 delta spec 后 `openspec validate <change> --strict` 通过；`openspec instructions apply` 在 artifacts 完成时正确降级为 "Proceed with implementation"。

## Out of Scope

- 不修改 spec-driven / matt-pocock / matt-pocock-wayfinder / trellis / trellis-prd-only 既有 schemas。
- 不为 backfill 提供批量/逐 commit 工具化（来源由 chat 指明，schema 保持静态 instruction）。
- 不将 spec-only 设为任何机器或项目的默认 schema。
- 不建自动化测试或 CI。

## Further Notes

- 决策脉络见本次 grilling 会话：两轮 Q&A 定稿 artifact 链、单 schema 双来源、无 apply、change 生命周期、skip_specs 保留、proposal 死引用最小改写。
- 部署副本（`AppData/Local/openspec` symlink 指向的 pub-merge-recursive 部署树）与仓库树分离；smoke 前已手动拷贝同步，后续依赖既有发布机制。
