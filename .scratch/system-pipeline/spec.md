# system-pipeline: 重装开箱即用 + 日常维护流水线

Status: ready-for-agent

## Problem Statement

重装 Windows 后要把机器恢复到可用状态，需要大量手工操作：装全局应用、落系统设置、注入驱动、建账号、配用户设置；日常使用中配置被手动改掉后也没有一键拉回的手段。现有仓库只覆盖了 PE 阶段的驱动离线注入（`reinstall/`，临时名），其余阶段各自为零散手工动作，没有统一入口、没有幂等保证、没有自检。

## Solution

建立 `system/` 流水线，覆盖「重装后开箱即用」与「日常维护」两条路径，共用同一套 manifest 引擎与模块：

- **audit**：手动进 audit mode 后跑 task 命令，在线安装稳定基础件（winget 引导注册）+ 机器级设置（manifest 新 kind `registry:set`）+ Default profile 预置。
- **sysprep / capture**：`sysprep /generalize /oobe` 直进 OOBE，DISM capture 单 wim，自动选剩余空间最大的本地分区落盘。
- **PE**：沿用现有 build-drivers / pe-deploy 驱动注入与 unattend 挂钩，平移并入 `system/pe/`。
- **OOBE**：unattend 建单个无密码本地管理员 + 一次 AutoLogon；per-user 自动化主通道为机器级任意用户 logon 计划任务（audit 阶段经 manifest 装好），`FirstLogonCommands` 跑同一幂等薄入口兜底。
- **maintenance**：手动 task 命令重放全部 Windows `manifests:*:install` 任务，修复配置漂移。

统一契约：task 命令前缀 `system:<stage>:<action>`，成对 `system:<stage>:check`；幂等分收敛级/拒绝级；退出码按阶段划分 2xx 子区间；日志落 `%TEMP%\system\`；每模块自带 self-check。

## User Stories

1. As a 机器主人, I want 手动进 audit mode 后跑一条 `system:audit:apply` 命令就完成全局应用安装与系统设置, so that 封装前的准备工作不用逐项手工执行。
2. As a 机器主人, I want audit 阶段 winget 未完成注册时被自动引导注册, so that 在干净镜像上首次跑安装不因 App Installer 未就绪而失败。
3. As a 机器主人, I want App Installer 缺失时用离线 msixbundle 兜底部署, so that 镜像被精简过头也能恢复 winget 能力。
4. As a 机器主人, I want registry/HKLM 系统设置以 manifest item 声明（`registry:set` kind）, so that 机器级设置和应用安装走同一套声明式引擎、同样幂等。
5. As a 机器主人, I want audit 里只装更新频率低的稳定基础件, so that 镜像不会因为应用更新而迅速变旧。
6. As a 机器主人, I want 常更新的应用（浏览器、IM、编辑器）划到 OOBE 之后的 per-user 阶段, so that 每次开箱拿到的都是最新版。
7. As a 机器主人, I want audit 结束时自检镜像内没有新增的未预配 per-user MSIX 包, so that sysprep 不会因 KB2769827 的包问题中止。
8. As a 机器主人, I want 跑 sysprep 前的封装命令自动断网, so that Store / Windows Update 不会在 generalize 前再动 UWP 包。
9. As a 机器主人, I want 一条命令完成 `sysprep /generalize /oobe` 封装并关机, so that 封装参数不需要每次记忆与手打。
10. As a 机器主人, I want 镜像捕获用 DISM capture 成带日期与 build 号的单个 install.wim, so that 产物与 pe-deploy 同工具链、可追溯版本。
11. As a 机器主人, I want capture 自动选剩余空间最大的本地分区（排除启动卷/目标盘/网络分区）, so that 不需要每次手工指定存放位置。
12. As a 机器主人, I want 重复对已捕获状态跑 sysprep/capture 时被硬拒绝（非零退出并说明）, so that 不可重入的动作不会产生损坏状态。
13. As a 机器主人, I want PE 阶段照旧用 WinNTSetup 施放 + 驱动自动注入, so that 现有成熟流程不变。
14. As a 机器主人, I want PE 注入前硬校验 PE 的 dism 版本 ≥ 目标系统 build，不足直接拒绝（退出码 207）并提示升级 PE, so that Win11 24H2+ 新镜像不会被旧 PE 注入坏。
15. As a 机器主人, I want PE 驱动注入对已有系统照常进行, so that 不区分全新施放与存量系统、不增加出错面。
16. As a 新用户账号, I want OOBE 后首个登录自动完成一次, so that 无需手动登录就进入自动化引导。
17. As a 新用户账号, I want 任意用户登录时机器级 logon 计划任务以我的身份运行 per-user 安装与设置, so that 之后新建的每个用户都自动得到完整配置。
18. As a 新用户账号, I want 轻量 HKCU 默认值与文件布局来自 Default `ntuser.dat` / `C:\Users\Default` 预置, so that 不需要登录后脚本就能拿到基础用户环境。
19. As a 机器主人, I want per-user 入口脚本自行幂等去重并用全局 mutex 串行, so that 首启双触发（计划任务与 FirstLogonCommands）不会并发冲突。
20. As a 维护者, I want 跑一条 `system:maintenance:run` 重放全部 Windows `manifests:*:install` 任务, so that 被手动改掉的配置恢复声明状态。
21. As a 维护者, I want 每个阶段有成对的 `system:<stage>:check` 命令只报告不施加变更, so that 可以先看漂移再决定是否收敛。
22. As a 维护者, I want check 退出码区分「干净 / 有漂移 / preflight 拒绝」, so that 脚本与人工都能一眼判断状态。
23. As a 维护者, I want 收敛级阶段失败后直接重跑即可, so that 不需要理解断点续传。
24. As a 维护者, I want 在线阶段日志统一落 `%TEMP%\system\<stage>-<timestamp>.log`, so that 排障时知道去哪找日志。
25. As a 维护者, I want 每个模块自带 self-check（退出码 = 失败断言数）加根级薄入口, so that 改动后可以快速验证模块行为。
26. As a 机器主人, I want 镜像保鲜通过完整重跑 audit → sysprep → capture 流程实现, so that 保鲜与首次封装是同一套动作、无额外机制。

## Implementation Decisions

- 顶层目录定名 `system/`，按阶段分子目录 `pe/`、`audit/`、`oobe/`、`maintenance/`；跨阶段的 `unattend.xml` 放 `system/` 根；`reinstall/` 四件套（build-drivers / pe-deploy / unattend / bin）整体平移进 `system/pe/`，self-check 各模块自带 + 根级薄入口依次调用。
- taskfile 新任务前缀 `system:<stage>:<action>`（如 `system:audit:apply`、`system:maintenance:run`），与既有 `manifests:` 前缀并列；PE 阶段脚本在 PE 里裸跑，不建 taskfile 任务。
- audit 安装载体：复用既有 manifest 引擎（`manifests:winget/choco:install`），不新造离线包机制；winget 注册引导（`Add-AppxPackage -RegisterByFamilyName`）作为 audit apply 前置步骤，App Installer 缺失时 GitHub Releases msixbundle 离线兜底；不维护本地安装器缓存。
- 系统设置载体：manifest 体系新增 kind（如 `registry:set`）与对应 receiver，与 `windows-features:set` 同引擎；audit 与活机维护跑同一套 manifest。
- audit 触发：手动进 audit 后跑 task 命令；否决 unattend auditSystem 挂钩；可重入、失败原地重跑。
- 更新频率判据：稳定基础件（运行库、字体、每机器工具、驱动辅助）进 audit 镜像；高频更新且用户数据耦合的应用进 OOBE/维护。
- sysprep 防坑三层：全局应用 manifest 约束 `--scope machine`；audit apply 末尾自检无未预配 per-user MSIX；generalize 前断网。
- 封装：`sysprep /generalize /oobe /unattend:system\unattend.xml /shutdown`，generalize pass 写 `SkipRearm=true`；封装后不回 audit，直接 capture 进 OOBE。
- capture：DISM `/Capture-Image` 单 `install.wim`，文件名带日期与源 build 号；存放分区自动选择（排除 PE 启动卷、目标系统盘、网络分区，取剩余空间最大）；只存一份。
- PE 施放沿用 WinNTSetup 人工施放 + pe-deploy 自动注入；不做施放自动化；PE 本体用第三方（FiePE 为主），不做 PE 制作脚本。
- PE preflight 新增 dism-build 硬校验（退出码 207）。
- OOBE 账号：unattend `LocalAccounts` 建单个无密码本地管理员；`AutoLogon` Count=1 空密码仅作首启 bootstrap；微软账号后续手动切换，不内置家庭版绕过 hack。
- per-user 主通道：机器级任意用户 logon 计划任务（`LogonTrigger.UserId = NULL`，任意用户触发、以登录用户身份运行、`RunOnlyIfNetworkAvailable=false`），由 audit 阶段经 manifest 安装；`FirstLogonCommands` 跑同一幂等薄入口作首启加速/兜底；先到先做，后到检测已完成即退出；入口脚本全局 mutex（或锁文件 + 超时抢占）串行。
- 用户设置分工：否决 CopyProfile 与 Active Setup；轻量 HKCU 默认值 / 文件布局进 Default `ntuser.dat` 与 `C:\Users\Default` 预置（audit 阶段）；需运行时上下文的设置与常更新应用进 logon 任务的 per-user manifest（与活机维护同一引擎）。
- 维护：仅手动 task 命令 `system:maintenance:run`，无计划任务；覆盖 = 重放 Windows 全部 `manifests:*:install`（不加聚合选择机制）；不加 update kind；只管机器级，per-user 归 logon 任务；scoop update / Windows Update / 系统清理均不进。
- 幂等两级模型：收敛级（converge，重跑拉回声明值：audit / OOBE logon / maintenance / PE 注入）与拒绝级（refuse，先检测再硬拒绝：sysprep / capture）。
- 退出码区间：沿用「2xx = preflight 拒绝、无副作用」，按阶段分配：PE 201–209（现状不动，207 已占用）、audit 211–219、OOBE 221–229、maintenance 231–239、根级 241–249；新失败原因先用本阶段区间空位；self-check 退出码 = 失败断言数；check 退出码 0=干净、10=漂移、2xx=拒绝。
- 失败重入：收敛级直接重跑；拒绝级回阶段起点整体重跑，无断点续传；OOBE 双入口有 mutex 串行，失败下次登录自动重跑。
- 日志：在线阶段统一落 `%TEMP%\system\<stage>-<timestamp>.log`（PE 阶段维持现状），内容沿用 `FAIL:` / `ERROR:` 行前缀，不引入集中式日志或结构化格式。

## Testing Decisions

- 每模块一个 self-check（fixture 端到端断言，PASS/FAIL 逐条打印，退出码 = 失败断言数），`system/` 根再放薄入口依次调用——沿用 `reinstall/self-check.cmd` 的既有模式。
- 测试走外部行为（退出码、落盘文件、被调命令参数），不断言内部实现；优先沿用既有 env-var seam 模式（如 `PIDRV_DISM`、`PIDRV_SCAN_ROOTS` 的 stub 注入），新模块需要新 seam 时在模块 self-check 内闭合。
- PE 模块测试已有 14 条断言保持不动；audit / OOBE / maintenance 的 self-check 用 stub dism/registry/任务注册等 seam，全程不碰真实系统状态。

## Out of Scope

- dotfiles 自身（`D:/home` 布局）在新机器的落地：系统层就绪即达目的。
- flyoobe 集成：已查明与 PE/驱动阶段无交集，刚需未成立。
- 驱动更新（驱动总裁产物 → 存量系统 DriverStore 增量导入）：交给 Windows Update / 驱动总裁自身。
- 应用 update 语义（winget/scoop update kind）、scoop update、Windows Update、系统清理：交给各包管理器与系统自身机制。
- PE 制作/维护、施放自动化：PE 用第三方，施放保持 WinNTSetup 人工。
- 镜像年龄自动提醒/自动重打：保鲜为手动全量重跑，不加自动化。

## Further Notes

- 决策来源：wayfinder 地图 `.scratch/system/`（tickets 00–07，均经用户确认）；本 spec 为其汇总定稿。
- Win11 24H2+ 目标要求 PE 的 dism ≥ 目标 build，硬校验兜底之外，每次重打镜像后需人工确认 PE 版本。
- 用户级设置机制的调研依据（CopyProfile 副作用、Active Setup 支持状态、FirstLogonCommands 边界）见 `.scratch/system/research/02-user-settings-prelogin.md`。
