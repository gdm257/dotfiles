# 01: trellis schema

**What to build:** 第一个可用的 `trellis` schema：openspec CLI 能识别它，`openspec new change --schema trellis` 建出的 change 按 memories → prd → design → implement → specs 链推进，规划 artifact 在 change 目录是指向 `.trellis/tasks/<task>/` 的指针 stub，memories/specs instruction 与 spec-driven 逐字一致，apply 内嵌 trellis-implement 约束与 before-dev 流程（不路由 skill）。文件落在 dotfiles 仓库 pub-merge-recursive 的 openspec schemas 目录。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] `schema.yaml`（name: trellis）+ `templates/`（memories/prd/design/implement/specs 指针 stub，样式仿 matt-pocock）在 pub-merge-recursive 对应路径创建
- [x] artifact 依赖链正确：memories→prd→design→implement / specs→prd，apply requires implement
- [x] memories 与 specs 的 instruction 与当前 spec-driven schema 逐字一致
- [x] prd/design/implement 为内嵌英文 instruction（prd 含 `.trellis/` 硬前置与 trellis-runtime 建任务目录；implement 含 `- [ ]` checkbox 格式契约）
- [x] apply instruction 内嵌：contextFiles → `.trellis/` 上下文加载（before-dev 流程，skill 仅可选捷径）→ change boundary → 逐任务实现勾选 → lint/typecheck 验证；禁 `git commit/push/merge`、禁派发 sub-agent（草案见 research/apply-instruction.md）
- [x] `openspec schemas` 列出 trellis；临时 change 渲染各 artifact instructions 无报错

## Comments
