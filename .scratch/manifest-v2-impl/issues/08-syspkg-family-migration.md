# 08: apt / yum / choco 系统包族迁移

**What to build:** 三个单 manifest 小族合一批：为 `apt-package` / `yum-package` / `choco-package` 各建（或按 kind 路由共建）接收方 task（均消费 `name`），`manifests/apt.yaml`、`manifests/yum.yaml`、`manifests/choco.yaml` 原地重写为 v2，对应 wrapper 翻转为 dispatch。批内三件套同一 commit。windows（choco）与 unix（apt / yum）两侧各自走通。

接收方 task 命名与落位实现期自定。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** ready-for-agent

- [ ] 三接收方就绪（容错模式含）
- [ ] 三个 manifest 原地重写、wrapper 翻转，三件套同 commit
- [ ] `task manifest:apt` / `manifest:yum` / `manifest:choco` 用户面名字不变，经 dispatch 走通
- [ ] 批内 grep 双清零
- [ ] `CONTINUE_ON_ERROR` / item 级容错行为不变
