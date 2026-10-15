# 10: 长尾批二：应用 / 系统 / 杂项族迁移

**What to build:** 长尾后半，18 个 manifest 逐族迁移：dotnet-source、dotnet-tool、k8s-helm-repo、k8s-krew、k8s-krew-unix、ansible-collection、ansible-role、bin、bin-linux、claude、codex、w2、wsl、omp、rclone、playnite、skills、dsh。每族一个接收方 task（kind 按 `<manager>-<resource>` 规则命名；registry 示范含 `dsh-plugin`、`openskills-skill`），manifest 原地重写、wrapper 翻转为 dispatch。批内三件套同一 commit。

接收方 task 命名与落位实现期自定。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** ready-for-agent

- [ ] 各族接收方就绪（容错模式含）
- [ ] 18 个 manifest 原地重写、wrapper 翻转，三件套同 commit
- [ ] 全部 `task manifest:<name>` 用户面名字不变，经 dispatch 走通
- [ ] 批内 grep 双清零
- [ ] `CONTINUE_ON_ERROR` / item 级容错行为不变
