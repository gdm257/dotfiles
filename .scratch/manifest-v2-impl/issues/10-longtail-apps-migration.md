# 10: 长尾批二：应用 / 系统 / 杂项族迁移

**What to build:** 长尾后半，18 个 manifest 逐族迁移：dotnet-source、dotnet-tool、k8s-helm-repo、k8s-krew、k8s-krew-unix、ansible-collection、ansible-role、bin、bin-linux、claude、codex、w2、wsl、omp、rclone、playnite、skills、dsh。每族一个接收方 task（kind 按 `<manager>-<resource>` 规则命名；registry 示范含 `dsh-plugin`、`openskills-skill`），manifest 原地重写、wrapper 翻转为 dispatch。批内三件套同一 commit。

接收方 task 命名与落位实现期自定。

**Blocked by:** 05: scoop 族迁移（大头批）.

**Status:** resolved

- [x] 各族接收方就绪（容错模式含）
- [x] 18 个 manifest 原地重写、wrapper 翻转，三件套同 commit
- [x] 全部 `task manifest:<name>` 用户面名字不变，经 dispatch 走通
- [x] 批内 grep 双清零
- [x] `CONTINUE_ON_ERROR` / item 级容错行为不变

## Answer

- 三件套实现 `1c5b7cb`，18 manifest + 16 接收方 + 18 wrapper，20 文件同 commit；批分支合并最新集成历史至 `c43b526`，merger fast-forward 合入集成分支。
- 实现者对比 v1 的 94 条有序命令参数序列一致，72 个容错渲染场景通过，包含显式 item false 覆盖全局 true、传入与 fallback `FAIL_LOG`、未知嵌套字段。
- merger 复核 20/20 文件，18 个 manifest 静态 grep 双清零，wrapper 名称及平台门控不变；18 个安全 dispatch dry-run 通过，Windows 渲染 85 条命令、9 个 Unix item 按平台过滤，`task --list` 与 diff whitespace 通过。
- 未安装资源，未在原生 Unix 平台执行；无关本地修改保持不动。
