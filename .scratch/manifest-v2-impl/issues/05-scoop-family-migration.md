# 05: scoop 族迁移（大头批）

**What to build:** 大头批：为 scoop 族建接收方 task（一个接收方按 `kind` 路由三种 item：`scoop-app`（`name`，`bucket/app` 复合名原样保留；sudo 变体 → `elevated: true`）、`scoop-bucket`（`name` + `url`）、`scoop-config`（`key` / `value`）），16 个 manifest 原地重写为 v2——`app-*` × 14（np / kernel / layer / audio / video / devops / downloader / file / network / picture / process / shell / text / toolbox）+ `scoop-bucket` + `scoop-config`——对应 `manifest:app-*` 等 wrapper 全部翻转为 dispatch。批内三件套同一 commit 落地（接收方就绪即整批翻转）。

接收方 task 命名与落位实现期自定。

**Blocked by:** 03: 试点批 debug（kind: shell 接收方）; 04: 试点批 windows-features（state 接收方）.

**Status:** ready-for-agent

- [ ] scoop 接收方就绪（三 kind 路由 + `elevated` 提权消费 + `continue_on_error` / `FAIL_LOG` 容错模式）
- [ ] 16 个 manifest 原地重写为 v2，文件名路径不变；wrapper 全部翻转，三件套同 commit
- [ ] `task manifest:app-np` 等用户面名字不变，经 dispatch 走通
- [ ] 批内 grep 双清零：16 个 manifest 顶层无 `run:` / `presets:`，全仓 `manifest:run:manifest` 无该批残留引用
- [ ] `CONTINUE_ON_ERROR=true` 全局 var（接收方自取）与 item 级 `continue_on_error` 行为不变
- [ ] 上位契约：`.scratch/manifest-declarative/details/schema.md` Kind Registry 节、`details/migration.md` Batches 节
