# 01: v1 引擎防呆加固

**What to build:** 并存期第一笔：`run:manifest` 解析 manifest 后若顶层含 `items:` 即 fail（错误信息含 manifest 路径），使 v2 格式文件误入 v1 引擎时从「静默空跑 exit 0（假成功）」变为响亮报错。v1 的 task 名与既有语义一律不动，只加拒绝。

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] `run:manifest` 对顶层含 `items:` 的 manifest fail，错误信息含 manifest 路径
- [x] 既有全部 v1 manifest（顶层 `run:` / `presets:` 形态）行为完全不变
- [x] 实现零依赖（ADR-0001：bash builtins + Windows 自带命令 + Task 进程内模板）
- [x] 上位契约：`.scratch/manifest-declarative/details/migration.md` Freeze 节

## Comments

- commit `0e534f5`（feat: v1 engine rejects v2 manifests with items key），已随集成分支 `manifest-v2-impl` 落地；守卫为 `run:manifest` 首条 cmd（Task 进程内模板 fail，零依赖）。
- 守卫实测（parent，2026-10-16）：`task manifest:run:manifest MANIFEST=manifests/debug.yaml` → exit 1，报错含路径：`v2 manifest (items:) not allowed in v1 engine: manifests/debug.yaml`。
- v1 面未动：`git diff 9f62b1e..manifest-v2-impl -- manifests/` 仅 `debug.yaml` / `windows-features.yaml`（03/04 批），其余 v1 manifest 零改动。
