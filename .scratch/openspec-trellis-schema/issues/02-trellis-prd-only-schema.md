# 02: trellis-prd-only schema

**What to build:** 轻量变体 `trellis-prd-only`：同样被 openspec CLI 识别，但规划 artifact 只有 prd（链：memories → prd → specs，apply requires specs）。memories/specs 文本与 01 完全一致（拷贝），apply instruction 与 01 逐字一致（"when present" 已覆盖无 design/implement 的情形）。与 01 共用的 instruction 文本不产生分叉。

**Blocked by:** 01: trellis schema（共用 instruction 文本以 01 为基准拷贝）

**Status:** ready-for-agent

- [x] `schema.yaml`（name: trellis-prd-only）+ `templates/` 在 pub-merge-recursive 对应路径创建
- [x] artifact 链：memories→prd→specs，apply requires specs
- [x] memories/specs/apply instruction 与 01 逐字一致（apply 无需变体兜底句）
- [x] `openspec schemas` 列出 trellis-prd-only；临时 change 渲染 instructions 无报错

## Comments
