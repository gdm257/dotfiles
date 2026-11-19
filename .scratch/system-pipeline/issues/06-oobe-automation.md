# 06: OOBE 自动化：账号、首启入口与 per-user 通道

**What to build:** 填充 `system/unattend.xml` OOBE pass：LocalAccounts 建单个无密码本地管理员、AutoLogon Count=1、FirstLogonCommands 跑幂等薄入口；机器级任意用户 logon 计划任务经 manifest（audit 阶段装）作为 per-user 主通道，以登录用户身份重放 per-user manifest（常更新应用 + 需运行时上下文的设置）；入口脚本全局 mutex 串行、检测已完成即退出；配套 `system:oobe:check` 与 self-check。

**Blocked by:** 02

**Status:** resolved

- [x] unattend OOBE pass 含 LocalAccounts / AutoLogon / FirstLogonCommands，与 05 的封装命令联用无冲突
- [x] logon 计划任务以 manifest item 装入，任意用户触发、以登录用户身份运行
- [x] 双入口并发时 mutex 串行，后到者检测已完成即退出
- [x] per-user manifest 重放幂等（重跑=补齐缺失）
- [x] check 只报告；self-check 断言全 PASS（stub 任务注册/用户 hive seam）
