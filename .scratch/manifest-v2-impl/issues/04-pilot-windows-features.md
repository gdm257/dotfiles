# 04: 试点批 windows-features（state 接收方）

**What to build:** 试点第二刀，验证非 install 形态与 `state` 字段：为 `windows-feature` 建接收方 task（dism enable/disable 按 item `state` 收敛，默认 `enabled`），`manifests/windows-features.yaml` 原地重写为 v2，`manifest:windows-features` wrapper 翻转为 dispatch——三件套同一 commit。交付后 `task manifest:windows-features` 用户面行为与迁移前一致。

接收方 task 命名与落位实现期自定。

**Blocked by:** 02: v2 引擎 manifest:dispatch 落地.

**Status:** ready-for-agent

- [ ] 接收方 task 就绪 + `manifests/windows-features.yaml` v2 重写（`feature` + `state` 声明字段）+ wrapper 翻转，三件套同 commit
- [ ] `task manifest:windows-features` 经 dispatch 全程走通，行为与迁移前一致
- [ ] 批内 grep 双清零：manifest 顶层无 `run:` / `presets:`，无 `manifest:run:manifest` 残留引用
- [ ] `state: disabled` 资源正确走 disable 分支（首次真实调用即结构自检，静态验收不实跑）
- [ ] 上位契约：`.scratch/manifest-declarative/details/schema.md` 约定声明字段节、kind registry 表
