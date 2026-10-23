# 03: 首批真实 absent 声明与收尾

**What to build:** 用户在真实 manifest（winget 为主）写入首批 `state: absent` 条目——本变更的原始需求：批量卸载已装不用的 winget app（清单由用户点名）。wrapper 全链路验证一次（dispatch → receiver，重放或实跑由用户定）；openspec change `manifest-item-state` validate 通过并 archive；.scratch 票据与 spec 状态收口。

**Blocked by:** 01, 02, 04（e2e 重放须跑在 rev1 通用下传引擎上，archive 前工件最终态含 rev1）

**Status:** resolved

- [x] 首批 absent 条目落真实 manifest（清单经用户确认）——**已取消**：用户 2026-10-23 撤回清单输入（「我没说要给」），真实 absent 条目由用户日后自行写入
- [x] 端到端验证一次（至少重放全链路）——以三套 fixture 全链路重放为准，tip `fa3ecff` 三套全绿
- [x] openspec validate manifest-item-state 通过并 archive——归档为 `2026-10-23-manifest-item-state`；v1 spec `manifest-run-item-enable` 随之退役
- [x] 四张票据 Status 收口、spec 状态更新

## Comments

- 2026-10-23：缩围收口。用户撤回 winget absent 清单输入并要求立即 squash 收尾；e2e 证据取三套 fixture 全链路重放（dispatch 31 场景 / receivers 9 PASS / runtimes PASS，集成分支 tip `fa3ecff`）。openspec change validate 通过并 archive 为 `2026-10-23-manifest-item-state`；v1 spec `manifest-run-item-enable` 退役（主 spec 与 change delta 一并移除，退休理由见 git 历史与 memories）。整条 feat/manifest-item-state 分支按用户指示 squash 为单提交。
