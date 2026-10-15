# 11: 删除 v1 引擎

**What to build:** 收口票：全部迁移批完成后，满足删除判据即删 v1 引擎——`manifests/` 全目录顶层 `run:` / `presets:` grep 零命中（零 v1 格式内容）且全仓 `manifest:run` grep 零命中（v1 入口引用清零，实证唯一调用方为根 taskfile wrapper）。删除动作 = 单独一个 commit 删 `run` + `run:manifest` 两个 task；`taskfile.d/manifest.yaml` 随即只含 `dispatch`，文件名不改，成为纯 v2 引擎。无观察宽限期。

**Blocked by:** 03: 试点批 debug; 04: 试点批 windows-features; 05: scoop 族迁移; 06: winget 族迁移; 07: brew 族迁移; 08: apt / yum / choco 系统包族; 09: 长尾批一; 10: 长尾批二.

**Status:** ready-for-agent

- [ ] 删除前判据复核：`manifests/` 顶层 `run:` / `presets:` grep 零命中；全仓 `manifest:run` grep 零命中
- [ ] 单独 commit 删除 `run` 与 `run:manifest` 两 task，其余不动
- [ ] 删除后 `taskfile.d/manifest.yaml` 只含 `manifest:dispatch`
- [ ] 抽查若干 `task manifest:<name>` wrapper 仍正常（走 dispatch）
- [ ] 上位契约：`.scratch/manifest-declarative/details/migration.md` Deletion 节
