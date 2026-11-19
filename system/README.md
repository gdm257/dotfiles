# system

重装开箱即用 + 日常维护流水线：audit 准备镜像 → sysprep 封装捕获 → PE 施放与驱动注入 → OOBE 首启 → per-user 登录任务 → 日常维护，共用同一套 manifest 引擎。契约见 openspec change `system-pipeline`。

## Stage structure

| 目录 | 阶段 | README |
|---|---|---|
| `system/pe/` | PE 驱动构建与离线注入（build-drivers / pe-deploy），PE 里裸跑、无 task 任务 | [system/pe/README.md](pe/README.md) |
| `system/audit/` | audit mode 在线准备（winget 引导、机器级基础件、HKLM 设置、Default profile、MSIX 自检） | [system/audit/README.md](audit/README.md) |
| `system/oobe/` | OOBE 首启：unattend 建号 + AutoLogon、per-user 薄入口（check.cmd / per-user.cmd） | 本页 OOBE 一节 |
| `system/sysprep/` | 封装（seal）与镜像捕获（capture），拒绝级动作 | [system/sysprep/README.md](sysprep/README.md) |
| `system/maintenance/` | 活机维护：重放全部 Windows 机器级 manifest 任务（run.cmd / check.cmd） | 本页 Maintenance 一节 |
| `system/unattend.xml` | 跨阶段共享 unattend：LocalAccounts 单管理员、AutoLogon Count=1、FirstLogonCommands、generalize `SkipRearm=1` | — |

## Commands

| 任务 | 动作 | 退出码语义 |
|---|---|---|
| `task system:audit:apply` | audit mode 在线准备镜像（收敛级，失败原地重跑） | 0 成功；211–214 见退出码表 |
| `task system:audit:check` | 只报告不施加 | 0 干净 / 10 漂移 / 2xx 拒绝 |
| `task system:sysprep:seal` | 断网 + `sysprep /generalize /oobe` 封装关机（拒绝级） | 0 成功；241/245/247/248 见表 |
| `task system:sysprep:check` | 只报告封装状态 | 0 未封装 / 10 已封装待 capture / 247 unattend 问题 |
| `task system:oobe:check` | 只报告 OOBE 漂移（unattend 段、logon 任务项、per-user 入口） | 0 干净 / 10 漂移 / 221 拒绝 |
| `task system:maintenance:run` | 重放全部 Windows 机器级 `manifests:*:install/apply/set`（收敛级） | 0 收敛 / 231 重放失败 |
| `task system:maintenance:check` | 只报告机器级漂移 | 0 干净 / 10 漂移 / 232 工具缺失 |
| `task manifests:system-peruser:install` | per-user 清单重放（logon 任务与 FirstLogonCommands 调 `system/oobe/per-user.cmd`，后者默认跑本任务） | 0 成功 / 引擎退出码 |

PE 阶段脚本在 PE 里裸跑（`system/pe/build-drivers.cmd`、`system/pe/pe-deploy.cmd`），不建 taskfile 任务。

## Exit codes

按阶段划分 2xx 子区间（2xx 一律 preflight 拒绝、无副作用），区间互不相交；check 专用 0/10 除外。`system/self-check.cmd` 逐阶段断言所有 `exit /b 2xx` 落在各自区间。

| 区间 | 阶段 | 已用码 |
|---|---|---|
| 201–209 | PE | 201 dism 缺失、202 目标盘无效、203/204/205 驱动包问题、206 unattend 拷贝失败、207 PE dism 版本低于目标 build |
| 211–219 | audit | 211 未预配 per-user MSIX、212 winget 引导失败、213 manifest 步骤失败、214 Default profile 步骤失败 |
| 221–229 | OOBE | 221 state 根/unattend 不可用、222 锁抢占失败、223 重放失败、224 done-marker 写失败 |
| 231–239 | maintenance | 231 重放失败、232 工具缺失 |
| 241–249 | 根级 / sysprep（共用同一区间是刻意的文档化选择，sysprep 拒绝级与根级动作同属封装捕获链路） | 241 已封装、242 无 sealed marker、243 wim 已存在、244 无存放分区、245 sysprep 失败、246 capture 失败、247 unattend 缺失/非良构、248 断网失败、249 参数无效/build 读不到 |

self-check（根级与各模块）退出码 = 失败断言数。

## End-to-end flow

1. 手动进 audit mode，跑 `task system:audit:apply`：winget 引导 + 机器级基础件 + HKLM 设置 + Default profile 预置 + MSIX 自检；audit 清单同时装好任意用户 logon 计划任务（`manifests/system-oobe.yaml`）。
2. 跑 `task system:sysprep:seal`：断网、`sysprep /generalize /oobe` 封装并关机（写 sealed marker）。
3. PE 里 WinNTSetup 人工施放，`pe-deploy.cmd` 自动注入驱动并把 `system/unattend.xml` 挂进目标 Panther；再对离线盘跑 `sysprep/capture.cmd` 捕获单 `install-<日期>-<build>.wim`（仅重打镜像时）。
4. OOBE：unattend 建单个无密码本地管理员并 AutoLogon 一次；`FirstLogonCommands` 跑 `system/oobe/per-user.cmd` 兜底，任意用户登录计划任务为 per-user 主通道，二者全局锁串行、done-marker 幂等。
5. 日常维护跑 `task system:maintenance:run` 重放机器级 manifest，修复漂移；`system:<stage>:check` 先看漂移再决定收敛。

镜像保鲜：全量重跑 audit → seal → capture，与首次封装同一套动作，无额外机制。

## OOBE

`system/oobe/check.cmd` 报告漂移；`system/oobe/per-user.cmd` 是 per-user 薄入口（锁串行 + done-marker 幂等，默认重放 `task manifests:system-peruser:install`）。per-user 清单（`manifests/system-peruser.yaml`）起步为空，只声明 `winget-app` 与 `sym-link` 两种 kind：registry receiver 仅支持 HKLM，HKCU 运行时设置待支持 HKCU 的 receiver 加入后再进清单。

## Maintenance

`system/maintenance/run.cmd` 按 taskfile 声明顺序重放全部 Windows 机器级 manifest 任务；per-user 清单（`manifests:system-peruser:install`）、uninstall、update 均不收录，per-user 归 OOBE 登录任务。`system/maintenance/check.py` 报告漂移不施加。

## Logs

在线阶段日志统一落 `%TEMP%\system\<stage>-<timestamp>.log`（audit / oobe / maintenance / sysprep，拒绝级 preflight 不落日志）；PE 阶段维持现状，日志在脚本 / payload 目录（`deploy-*.log`、`capture-*.log`）。内容沿用 `FAIL:` / `ERROR:` 行前缀。

## Self-check

各模块自带 self-check（退出码 = 失败断言数）；根级薄入口 `system/self-check.cmd` 依次跑 pe → audit → oobe → sysprep → maintenance 五个套件，并断言各阶段 2xx 退出码不越出自己的区间，退出码 = 全部失败断言之和。
