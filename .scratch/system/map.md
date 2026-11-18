# Wayfinder Map: system（重装开箱即用 + 日常维护）

## Destination

一份 openspec change（matt-pocock schema）定稿整条「重装系统后开箱即用 + 日常维护」流水线的架构决策：阶段分工（audit / sysprep / PE / OOBE / 维护）、各阶段机制选型、模块可单独运行与幂等契约。图只做决策，实现由后续 apply 会话执行。

## Notes

- 单机方案；目标系统 Win10 + Win11 双版本（注意：现 reinstall/ 的 PE 前提是 dism ≥ 目标 build，Win11 24H2+ 需新 PE，决策时必须纳入）。
- 「开箱即用」到系统层就绪为止：dotfiles 自身（D:/home 布局）的落地不进图。
- 现有素材（决策必须建立在其上，不重造）：
  - `reinstall/`：PE 阶段驱动离线注入，契约见已归档 openspec change `2026-11-14-pe-driver-inject`（已否决 unattend DriverPaths 与 OOBE pnputil 方案）。将并入新命名（暂定 `system/`）。
  - taskfile manifest 引擎：`manifests:winget/scoop/choco:install`、`manifests:windows-features:set` 等任务已存在；GLOSSARY 的 Manifest/Item/Kind/Group/Receiver 词汇属活机配置域。
  - `reinstall/unattend.xml`：空骨架，是未来 OOBE 其他自动化的唯一载体（既有决策）。
- Skills：grilling、domain-modeling（grilling 票必用）。
- 用户原始思路（供参照，不是结论）：已有镜像 → audit 装全局应用+系统设置 → sysprep 封装 → PE 装机+驱动 → OOBE 装常更新应用+用户管理+用户设置。核心未知：登录前能否完成用户设置 / 是否有适用于所有新建用户的模板配置。

## Decisions so far

<!-- 建图会话（charting）钉住的目的地与边界 -->

- [00 charter: 目的地与边界](issues/00-charter.md): 交付物为 openspec change（matt-pocock）；维护与开箱即用共用同一体系；`reinstall/` 更名并入（暂定 `system/`）；单机；Win10+Win11；home 布局落地与 flyoobe 集成 out of scope；镜像保鲜记入 fog。
- [02 user-settings-prelogin: 登录前用户设置机制](issues/02-user-settings-prelogin.md): 作用于所有新建用户的机制是 CopyProfile、Default `ntuser.dat`/`C:\Users\Default` 预置、Active Setup（无支持承诺）、任意用户 logon-trigger 计划任务；FirstLogonCommands 只覆盖 OOBE 后首个登录用户，只能当 bootstrap 入口。
- [01 naming-structure: 目录命名与阶段结构定稿](issues/01-naming-structure.md): 顶层定名 `system/`，按阶段分子目录（pe/audit/oobe/maintenance），跨阶段 unattend.xml 放根，self-check 各模块自带 + 根级薄入口；taskfile 新前缀 `system:<stage>:<action>`，PE 阶段不进 taskfile（勘误：现有前缀实为 `manifests:`）。
- [03 audit-content: audit 阶段放什么、怎么放](issues/03-audit-content.md): 复用 manifest 引擎在线装（winget 注册引导前置 + msixbundle 离线兜底）；registry/HKLM 设置进 manifest 新 kind（如 `registry:set`），audit 与活机维护同一套 manifest；触发为手动 task 命令（否决 auditSystem 挂钩）；按更新频率划 audit/OOBE 边界；sysprep 防坑 = `--scope machine` 约束 + per-user MSIX 自检 + generalize 前断网（约束联动 04 号票）。
- [05 oobe-automation: OOBE 阶段自动化选型](issues/05-oobe-automation.md): `LocalAccounts` 建单个无密码本地管理员 + 空密码 AutoLogon（Count=1）；per-user 主通道 = 机器级任意用户 logon 计划任务（audit 经 manifest 装），`FirstLogonCommands` 跑同一幂等薄入口作兜底，全局 mutex 串行；设置分工 = 轻量 HKCU 默认值进 Default hive 预置（audit），需运行时上下文的设置与常更新应用进 logon 任务的 per-user manifest；否决 CopyProfile / Active Setup / 家庭版绕过 hack。
- [04 sysprep-capture: 封装与镜像管理选型](issues/04-sysprep-capture.md): `sysprep /generalize /oobe` 直进 OOBE（SkipRearm=true）；DISM capture 单 wim 存一份，自动选剩余空间最大的本地分区（排除启动卷/目标盘/网络分区）；施放沿用 WinNTSetup + pe-deploy；保鲜 = 手动完整重跑 audit→sysprep→capture，全量不增量；PE 用第三方（FiePE/雷电PE），dism ≥ 目标 build 由 pe-deploy preflight 硬校验兜底（新退出码 207）。
- [06 maintenance-loop: 日常维护循环骨架](issues/06-maintenance-loop.md): 仅手动 task 命令（`system:maintenance:run`）；维护 = 重放 Windows 全部 `manifests:*:install` 修配置漂移（与 audit 同一 manifest 引擎，无选择机制）；不加 update kind、不做驱动导入、不含 Windows Update/系统清理；维护只管机器级，per-user 归 05 的 logon 任务。
- [07 idempotent-contract: 单独运行与幂等契约](issues/07-idempotent-contract.md): 幂等分收敛级（audit/OOBE/maintenance/PE 注入，重跑拉回声明值）与拒绝级（sysprep/capture，检测后硬拒绝）；退出码按阶段划 2xx 子区间（PE 201–209、audit 211–219、OOBE 221–229、maintenance 231–239、根级 241–249），self-check 退出码=失败断言数；成对 `system:<stage>:check` 命令（0=干净、10=漂移、2xx=拒绝）；PE 对存量系统照常注入；收敛级失败直接重跑、拒绝级回阶段起点整体重跑、无续传；在线阶段日志落 `%TEMP%\system\<stage>-<timestamp>.log`。

- [08 openspec-draft: 汇总起草 openspec change](issues/08-openspec-draft.md): change `system-pipeline` 定稿（4/4 artifacts、validate 通过）：spec 26 条 stories + 8 张实现票（`.scratch/system-pipeline/issues/`）+ 3 个 delta specs（system-pipeline / registry-set 新能力、pe-driver-inject 增 207 校验）；map 完成，实现交后续 apply 会话。

## Not yet specified

（无：本图已走完，全部决策已固化为 openspec change `system-pipeline`。）

## Out of scope

- 驱动更新（驱动总裁产物 → DriverStore 增量导入）：[06 maintenance-loop](issues/06-maintenance-loop.md) 裁定不做，交给 Windows Update / 驱动总裁自身。
- dotfiles 自身（D:/home junction/state 布局）在新机器的落地：用户裁定不进图，系统层就绪即达。
- flyoobe 集成：前一会话已查明与 PE/驱动阶段无交集、刚需未成立，裁定不进图。
