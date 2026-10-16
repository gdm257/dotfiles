# 07: brew 族迁移

**What to build:** 为 brew 族建接收方 task（`brew-app`（`name`，cask 与否等留给接收方判断）+ `brew-tap`（`name`）按 kind 路由），13 个 manifest 原地重写为 v2——`brew-app-*` × 12（devops / downloader / file / kernel / layer / network / process / shell / text / toolbox / video / vps）+ `brew-tap`——对应 wrapper 翻转为 dispatch。批内三件套同一 commit。

接收方 task 命名与落位实现期自定。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** claimed

- [ ] brew 接收方就绪（app + tap 路由 + 容错模式）
- [ ] 13 个 manifest 原地重写、wrapper 翻转，三件套同 commit
- [ ] `task manifest:brew-app-shell` 等用户面名字不变，经 dispatch 走通
- [ ] 批内 grep 双清零
- [ ] `CONTINUE_ON_ERROR` / item 级容错行为不变
