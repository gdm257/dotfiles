# 06: winget 族迁移

**What to build:** 为 `winget-app` 建接收方 task（消费 `id`、`source`（`winget` / `msstore`，默认 `winget`）、`version`（string）；msstore 变体 → `source: msstore`），`manifests/winget.yaml` 原地重写为 v2，`manifest:winget` wrapper 翻转为 dispatch——三件套同一 commit。交付后 `task manifest:winget` 行为与迁移前一致。

接收方 task 命名与落位实现期自定。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** ready-for-agent

- [ ] 接收方 task 就绪 + `manifests/winget.yaml` v2 重写 + wrapper 翻转，三件套同 commit
- [ ] `source` / `version` 声明字段按接收方契约消费；msstore 资源走 msstore 分支
- [ ] 批内 grep 双清零：manifest 顶层无 `run:` / `presets:`，无 `manifest:run:manifest` 残留引用
- [ ] `CONTINUE_ON_ERROR` / item 级容错行为不变
- [ ] 上位契约：`.scratch/manifest-declarative/details/schema.md` Kind Registry 节
