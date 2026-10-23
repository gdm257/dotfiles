# 02: 迁移 taskfile 调用条目到 CALLS

**What to build:** 仓库内所有现有 `manifest:dispatch` 调用条目从 `CALL` 迁到 `CALLS`（各条目的 kind=task 映射由其 manifest 实际 kind 决定），breaking change 落地，无兼容层。迁移后全部既有任务可跑、分发行为不变。

**Blocked by:** 01（CALLS 引擎可用）

**Status:** done

- [x] 仓库内不再有 `CALL:` 单任务形式的 dispatch 条目
- [x] 每条迁移条目的 CALLS 覆盖其 manifest 中的全部 kind，无遗漏
- [x] 抽查若干既有任务实际跑通，分发的 item 集合与迁移前等价
- [x] uninstall 侧条目同样迁移（独立 CALLS，不做 install↔uninstall 派生）——N/A：taskfile.yaml 中本无 uninstall dispatch 条目，uninstall receivers 未被任何 dispatch 引用

## Comments

- 迁移与 01 同一提交完成（impl-01 子代理一并迁移全部 70 处调用点）；主会话独立复核：`grep CALL:` 无残留，dry-run `manifests:app:np:install` 渲染正确。
