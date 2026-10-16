# 07: brew 族迁移

**What to build:** 为 brew 族建接收方 task（`brew-app`（`name`，cask 与否等留给接收方判断）+ `brew-tap`（`name`）按 kind 路由），13 个 manifest 原地重写为 v2——`brew-app-*` × 12（devops / downloader / file / kernel / layer / network / process / shell / text / toolbox / video / vps）+ `brew-tap`——对应 wrapper 翻转为 dispatch。批内三件套同一 commit。

接收方 task 命名与落位实现期自定。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** resolved

- [x] brew 接收方就绪（app + tap 路由 + 容错模式）
- [x] 13 个 manifest 原地重写、wrapper 翻转，三件套同 commit
- [x] `task manifest:brew-app-shell` 等用户面名字不变，经 dispatch 走通
- [x] 批内 grep 双清零
- [x] `CONTINUE_ON_ERROR` / item 级容错行为不变

## Answer

- 三件套实现 `a3d2b00`，批分支合并集成历史 `f783c25`，merger 以 `7ebc5eb` 合入集成分支。13 manifest、接收方与 13 wrapper 同一 implementation commit，名称及平台门控保留。
- 13 个 manifest 共 174 条命令参数与顺序对比 v1 一致；merger 独立复验身份及顺序、13 个 dispatch dry-run、grep 双清零、`task --list` 和 diff whitespace 均通过。
- `brew:apply` 按 kind 路由 app / tap，未知字段容忍；item 显式 false 覆盖全局 true，传入 `FAIL_LOG` 优先、独立调用有 fallback，均经安全 dry-run 验证。
- 未安装资源，未在原生 Linux / macOS 执行；Windows 上直接 dispatch dry-run 绕过 Unix wrapper 平台门控，仅验证渲染。
