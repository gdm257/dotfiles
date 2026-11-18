# oobe-automation: OOBE 阶段自动化选型

Type: grilling
Status: resolved
Blocked by: 02

## Question

OOBE 阶段的自动化选型（unattend.xml 是唯一载体的既有决策内）：

- 用户管理：本地账号创建（unattend `LocalAccounts`）、是否 autologon、微软账号绕过策略。
- 首启触发器：`FirstLogonCommands` 跑什么（常更新应用的 manifest 安装？）、还是 per-user 计划任务，取决于 02 号票的事实。
- 用户设置落地：登录前模板（CopyProfile / Default hive / Active Setup）与登录后脚本的分工线，选型以 02 号票调研为准。
- OOBE 阶段跑的东西如何做到「单独运行或作用于已有 OS 也不破坏」。

## Answer

- 账号：unattend `LocalAccounts` 建单个无密码本地管理员；微软账号登录以后手动切换，不内置家庭版联网绕过 hack（目标为专业版工作机）。
- autologon：`AutoLogon` Count=1、空密码（账号本无密码，无明文密码问题），仅作首启 bootstrap 入口。
- 首启触发器：机器级「任意用户 logon 计划任务」为主通道（audit 阶段经 manifest 装好），`FirstLogonCommands` 仅跑同一个幂等薄入口脚本作首启加速/兜底；两者先到先做、后到检测已完成即退出。
- 计划任务上下文：任意用户触发、以该登录用户身份运行（需交互 token 操作用户 hive），`RunOnlyIfNetworkAvailable=false`；入口脚本自行幂等去重（无 new-user-only 触发器）。
- 并发收敛：入口脚本用全局 mutex（或锁文件 + 超时抢占）串行化，不建 per-user 状态机。
- 用户设置分工线：不用 CopyProfile、不用 Active Setup；「轻量 HKCU 默认值 / 文件布局」进 Default `ntuser.dat` 与 `C:\Users\Default` 预置（audit 阶段），「需应用在场或运行时上下文的设置 + 常更新应用安装」进 logon 任务的 per-user manifest（与活机维护同一 manifest 引擎）。
- 单独运行不破坏：per-user 逻辑按 manifest 幂等安装设计（重跑 = 补齐缺失）；退出码/preflight 详细契约归 07 号票统一。
