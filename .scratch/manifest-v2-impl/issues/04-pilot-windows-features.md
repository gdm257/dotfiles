# 04: 试点批 windows-features（state 接收方）

**What to build:** 试点第二刀，验证非 install 形态与 `state` 字段：为 `windows-feature` 建接收方 task（dism enable/disable 按 item `state` 收敛，默认 `enabled`），`manifests/windows-features.yaml` 原地重写为 v2，`manifest:windows-features` wrapper 翻转为 dispatch——三件套同一 commit。交付后 `task manifest:windows-features` 用户面行为与迁移前一致。

接收方 task 命名与落位实现期自定。

**Blocked by:** 02: v2 引擎 manifest:dispatch 落地.

**Status:** resolved

- [x] 接收方 task 就绪 + `manifests/windows-features.yaml` v2 重写（`feature` + `state` 声明字段）+ wrapper 翻转，三件套同 commit
- [x] `task manifest:windows-features` 经 dispatch 全程走通，行为与迁移前一致
- [x] 批内 grep 双清零：manifest 顶层无 `run:` / `presets:`，无 `manifest:run:manifest` 残留引用
- [x] `state: disabled` 资源正确走 disable 分支（首次真实调用即结构自检，静态验收不实跑）
- [x] 上位契约：`.scratch/manifest-declarative/details/schema.md` 约定声明字段节、kind registry 表

## Comments

- commit `835b3a7`（分支 `manifest-v2-impl-04`；`git merge manifest-v2-impl` 结果 Already up to date）。
- 上游两处缺陷（已另行同步 parent，需在批外处理，影响 03/05-10）：02 引擎 key 原为 `manifest:dispatch`，公共名被 include namespace 前置为 `manifest:manifest:dispatch`，与契约名 `manifest:dispatch` 不符，已改为 `dispatch` 修复（1 行，含在本 commit）；go-task 的 `task:` 引用一律按调用方 namespace 前置解析、无回退无绝对语法，故 `CALL` 必须是 `manifest` namespace 相对名。parent 裁决（已实测复现）：全部接收方落 `taskfile.d/manifest.yaml`，key 与 CALL 统一 `<family>:apply` 形态（本批 `windows-feature:apply`）；engine.md 的 CALL 可含 namespace 与 Receiver Playbook 跨 taskfile 接收方形态不成立，仅落位偏离、命名与契约一致。
