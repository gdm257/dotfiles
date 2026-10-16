# 11: 删除 v1 引擎

**What to build:** 收口票：全部迁移批完成后，满足删除判据即删 v1 引擎——`manifests/` 全目录顶层 `run:` / `presets:` grep 零命中（零 v1 格式内容）且全仓 `manifest:run` grep 零命中（v1 入口引用清零，实证唯一调用方为根 taskfile wrapper）。删除动作 = 单独一个 commit 删 `run` + `run:manifest` 两个 task；`taskfile.d/manifest.yaml` 随即只含 `dispatch`，文件名不改，成为纯 v2 引擎。无观察宽限期。

**Blocked by:** 03: 试点批 debug; 04: 试点批 windows-features; 05: scoop 族迁移; 06: winget 族迁移; 07: brew 族迁移; 08: apt / yum / choco 系统包族; 09: 长尾批一; 10: 长尾批二.

**Status:** resolved

- [x] 删除前判据复核：`manifests/` 顶层 `run:` / `presets:` grep 零命中；全仓 `manifest:run` grep 零命中
- [x] 单独 commit 删除 `run` 与 `run:manifest` 两 task，其余不动
- [x] 删除后 `taskfile.d/manifest.yaml` 只含 `manifest:dispatch`
- [x] 抽查若干 `task manifest:<name>` wrapper 仍正常（走 dispatch）
- [x] 上位契约：`.scratch/manifest-declarative/details/migration.md` Deletion 节

## Comments

- （票 02 批注，2026-10-16）删除判据 grep 范围修正：全仓 `manifest:run` 零命中需排除 `fixtures/`（`fixtures/manifest-dispatch/README.md` 的防呆重放命令必然含该字样，属文档性命中而非 v1 入口引用）；`manifests/` 顶层 `run:` / `presets:` 判据不受影响（v1-form fixture 刻意落在 fixtures/ 下）。

## Answer

- 删除提交 `81857dbe26317038037726fc0253533f49d006f8` 仅修改 `taskfile.d/manifest.yaml`，删除 v1 `run` / `run:manifest` 共 50 行。dispatch、includes、echo 与全部 v2 接收方逐字保留；“只含 dispatch”指纯 v2 引擎，不删除接收方。
- 单独文档提交 `fec539d` 删除过时的 v2 → v1 防呆重放行及排除说明。
- 删除前后 `manifests/` 顶层 `run:` / `presets:` 零命中，执行性 v1 引用零命中；历史规范文本、runtime namespace 子串及 checker 的负向断言不属于 v1 调用。
- receiver 九组检查、runtime 14 × 6 场景与 17 wrapper dry-run、`task --list`、10 个代表性 wrapper dry-run、diff whitespace 均通过；没有执行安装。OCR 可审 1/1，排除 README 人工检查完成。
