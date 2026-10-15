# 03: 试点批 debug（kind: shell 接收方）

**What to build:** 第一个真实端到端切片：为 `kind: shell` 建接收方 task（执行 item 的 `cmd`，支持 `continue_on_error` 与 `FAIL_LOG` 容错模式），`manifests/debug.yaml` 原地重写为 v2（文件名路径不变），根 taskfile 的 `manifest:debug` wrapper 内部翻转为 `manifest:dispatch` + `MANIFEST` + `CALL`——三件套同一 commit 落地。交付后 `task manifest:debug` 用户面行为与迁移前一致，全程走 v2。

接收方 task 命名与落位实现期自定（既有 per-tool 任务改造属本批决策）。

**Blocked by:** 02: v2 引擎 manifest:dispatch 落地.

**Status:** ready-for-agent

- [ ] 接收方 task 就绪 + `manifests/debug.yaml` v2 重写 + wrapper 翻转，三件套同 commit
- [ ] `task manifest:debug` 经 dispatch 全程走通，行为与迁移前一致（wrapper 名不变）
- [ ] 批内 grep 双清零：该 manifest 顶层无 `run:` / `presets:`，全仓 `manifest:run:manifest` 无该批残留引用
- [ ] item 级 `continue_on_error` 与 `CONTINUE_ON_ERROR=true` 全局 var（接收方自取）行为不变
- [ ] 上位契约：`.scratch/manifest-declarative/details/schema.md` Escape Hatch 节、`details/migration.md` Coexistence / Batches 节
