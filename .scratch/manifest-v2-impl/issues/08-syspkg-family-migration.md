# 08: apt / yum / choco 系统包族迁移

**What to build:** 三个单 manifest 小族合一批：为 `apt-package` / `yum-package` / `choco-package` 各建（或按 kind 路由共建）接收方 task（均消费 `name`），`manifests/apt.yaml`、`manifests/yum.yaml`、`manifests/choco.yaml` 原地重写为 v2，对应 wrapper 翻转为 dispatch。批内三件套同一 commit。windows（choco）与 unix（apt / yum）两侧各自走通。

接收方 task 命名与落位实现期自定。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** resolved

- [x] 三接收方就绪（容错模式含）
- [x] 三个 manifest 原地重写、wrapper 翻转，三件套同 commit
- [x] `task manifest:apt` / `manifest:yum` / `manifest:choco` 用户面名字不变，经 dispatch 走通
- [x] 批内 grep 双清零
- [x] `CONTINUE_ON_ERROR` / item 级容错行为不变

## Comments

- 实现 `e70f86b`，merge commit `1228047` 合入集成分支；与 winget 的 EOF 追加冲突仅保留两侧完整接收方，无语义改写。
- 三件套同 commit，active item 身份与顺序保留，apt 2 / yum 1 / choco 6；批内 grep 双清零，`task --list` 与安全 wrapper dry-run 通过。Windows 上 yum wrapper 平台跳过，独立 receiver dry-run 验证 `yum groupinstall Development Tools`，保留旧命令行为。未执行真实安装或原生 Unix 验证。

## Answer

- 原子实现 `e70f86b` 经 `1228047` 合入，apt 2 / yum 1 / choco 6 个 active item 身份、顺序及公开 wrapper 保留。
- 容错修复 `c72e2eb` 经 `5d24208` 合入，显式 item false 覆盖全局 true，传入 `FAIL_LOG` 优先、缺失时 fallback。
- merger 九组 CLI 检查全部通过，其中安装接收方只做 dry-run；`task --list` 与 diff whitespace 通过。Windows 平台跳过及独立 receiver 渲染结果见前述记录，未执行安装或原生 Unix 验证。
