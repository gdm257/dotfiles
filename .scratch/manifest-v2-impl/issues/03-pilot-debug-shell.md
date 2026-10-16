# 03: 试点批 debug（kind: shell 接收方）

**What to build:** 第一个真实端到端切片：为 `kind: shell` 建接收方 task（执行 item 的 `cmd`，支持 `continue_on_error` 与 `FAIL_LOG` 容错模式），`manifests/debug.yaml` 原地重写为 v2（文件名路径不变），根 taskfile 的 `manifest:debug` wrapper 内部翻转为 `manifest:dispatch` + `MANIFEST` + `CALL`——三件套同一 commit 落地。交付后 `task manifest:debug` 用户面行为与迁移前一致，全程走 v2。

接收方 task 命名与落位实现期自定（既有 per-tool 任务改造属本批决策）。

**Blocked by:** 02: v2 引擎 manifest:dispatch 落地.

**Status:** resolved

- [x] 接收方 task 就绪 + `manifests/debug.yaml` v2 重写 + wrapper 翻转，三件套同 commit
- [x] `task manifest:debug` 经 dispatch 全程走通，行为与迁移前一致（wrapper 名不变）
- [x] 批内 grep 双清零：该 manifest 顶层无 `run:` / `presets:`，全仓 `manifest:run:manifest` 无该批残留引用
- [x] item 级 `continue_on_error` 与 `CONTINUE_ON_ERROR=true` 全局 var（接收方自取）行为不变
- [x] 上位契约：`.scratch/manifest-declarative/details/schema.md` Escape Hatch 节、`details/migration.md` Coexistence / Batches 节

## Comments

- 实现 commit `42688df`（feat: pilot debug manifest with shell receiver）与 `6289826`（refactor: rename shell receiver to shell:apply），均落在分支 `manifest-v2-impl`；合并入集成分支的 merge commit 为 `46c2c0c`（2026-10-16）。
- 三件套：接收方 task `shell:apply`（`taskfile.d/manifest.yaml`，requires `ITEM_JSON` + `FAIL_LOG`，item 级 `continue_on_error` 与全局 `CONTINUE_ON_ERROR=true` 均收敛到 FAIL_LOG）、`manifests/debug.yaml` 原地 v2 重写（`items:` + `kind: shell` + `cmd`）、根 taskfile `manifest:debug` wrapper 翻转为 `task: manifest:dispatch` + `MANIFEST` + `CALL: "shell:apply"`（wrapper 名不变）。
- engine-key 修复：`manifest:dispatch:` → `dispatch:`（02 批缺陷，含在 `6289826`；04 批携带相同修复，merge 时该处自动合流、无冲突残留）。
- 命名裁决（parent，已实测复现）：接收方统一落 `taskfile.d/manifest.yaml`，key 与 `CALL` 采用 `<family>:apply` 形态（本批 `shell:apply`）；go-task `task:` 引用按调用方 namespace 前置解析、无回退，故 `CALL` 用 `manifest` namespace 相对名。详见 04 文件。
- 行为基线备注（`--dry` 实测）：v1 基线（`c0ade22:manifests/debug.yaml` 经 v1 引擎）打印 `g-entrypoint g-command g-args run-suffix`（顶层 `prefix` 丢失），v2 `task --dry manifest:debug` 打印 `echo 'from file'`（v2 item cmd）。v1 引擎 preset 解析路径丢失顶层 `entrypoint`/`prefix` 属既有行为（04 批 windows-features 基线同样丢失 `dism` 前缀，已用探针复现：preset 自带 `entrypoint` 时才输出）；`run:manifest:` 自 `c0ade22` 未改动，该差异与本次合并无关。
