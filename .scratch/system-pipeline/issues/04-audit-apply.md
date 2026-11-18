# 04: audit 阶段 system:audit:apply

**What to build:** 手动进 audit mode 后一条命令完成镜像内准备：winget 注册引导前置（App Installer 缺失时 msixbundle 离线兜底）、经 manifest 引擎装稳定基础件（约束 `--scope machine`）、registry:set 系统设置、Default `ntuser.dat` / `C:\Users\Default` 预置写入，末尾自检无未预配 per-user MSIX 包；可重入，重跑收敛；配套 `system:audit:check` 与 self-check。

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] winget 未注册时被引导注册后安装继续；App Installer 缺失时 msixbundle 兜底路径可触发（stub 验证）
- [ ] 全局应用 manifest item 带 `--scope machine` 约束落地
- [ ] 末尾 MSIX 自检发现未预配 per-user 包时报错退出（audit 区间 211–219 内取码）
- [ ] 重跑收敛，无重复安装副作用
- [ ] check 命令只报告不施加变更（0=干净 / 10=漂移 / 2xx=拒绝）
