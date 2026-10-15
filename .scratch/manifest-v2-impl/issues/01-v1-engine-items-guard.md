# 01: v1 引擎防呆加固

**What to build:** 并存期第一笔：`run:manifest` 解析 manifest 后若顶层含 `items:` 即 fail（错误信息含 manifest 路径），使 v2 格式文件误入 v1 引擎时从「静默空跑 exit 0（假成功）」变为响亮报错。v1 的 task 名与既有语义一律不动，只加拒绝。

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] `run:manifest` 对顶层含 `items:` 的 manifest fail，错误信息含 manifest 路径
- [ ] 既有全部 v1 manifest（顶层 `run:` / `presets:` 形态）行为完全不变
- [ ] 实现零依赖（ADR-0001：bash builtins + Windows 自带命令 + Task 进程内模板）
- [ ] 上位契约：`.scratch/manifest-declarative/details/migration.md` Freeze 节
