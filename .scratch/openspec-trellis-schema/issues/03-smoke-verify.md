# 03: 端到端 smoke 验证

**What to build:** 两个 schema 作为整体走通 openspec CLI：分别以 `--schema trellis` 和 `--schema trellis-prd-only` 建临时 change，渲染全部 artifact instructions，写一个含 delta specs 的临时 change 跑 `openspec validate` 通过；确认 dotfiles 仓库内新增文件完整（无遗漏模板、无多余文件），临时产物清理干净。

**Blocked by:** 01: trellis schema, 02: trellis-prd-only schema

**Status:** ready-for-agent

- [x] 两个临时 change 的 instructions 渲染完整且 artifact 依赖链符合 spec
- [x] 含 delta specs 的临时 change `openspec validate` 通过
- [x] 临时 change / 临时目录清理，仓库只余两个 schema 目录的交付文件

## Comments
