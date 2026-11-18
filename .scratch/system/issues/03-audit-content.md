# audit-content: audit 阶段放什么、怎么放

Type: grilling
Status: resolved

## Question

audit mode 阶段的内容与机制选型：

- 全局应用装什么、来源用什么：复用既有 taskfile manifest 引擎（winget/choco）在线装，还是离线包批量安装（audit 阶段网络可用性、winget 在 audit/系统未激活下的限制需核实）；「经常更新的应用」明确划到 OOBE/维护阶段的判据。
- 系统设置怎么落：既有 `manifest:windows-features:set`（DISM）之外，registry/HKLM 类设置走什么载体；audit 里跑的与活机维护跑的是否同一套 manifest（幂等复用）。
- audit 阶段自动化的触发方式（手动进 audit 跑脚本？unattend auditSystem 挂钩？）与可重入性。

## Answer

（与用户两轮 grilling 定稿，全部取推荐项；事实部分由 research 子代理核实）

**事实基础**（官方文档核实，供后续票引用）：

- audit 模式官方支持联网（最大坑是镜像缺 NIC/WLAN 驱动，需先注入驱动包）；WiFi 配置在 sysprep 回 OOBE 后被清除（期望行为）。
- winget 在 audit 可用：首次登录（含内置 Administrator）触发 App Installer 异步注册，未完成时用 `Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe` 引导；App Installer 缺失时用 GitHub Releases 的 msixbundle（含 VCLibs 依赖）离线部署，或 `Repair-WinGetPackageManager`。不要求激活、不要求完成 OOBE；audit 交互会话不受 SYSTEM 上下文限制。
- 每机器作用域安装（EXE/MSI，`--scope machine`）能活过 sysprep /generalize；per-user MSIX 包会触发 `SYSPRP Package … was installed for a user, but not provisioned for all users` 中止（KB2769827），Store 自动更新内置应用是常见诱因。
- choco 在 audit 同样可用（内置 PowerShell/.NET 满足要求），且无 MSIX 坑。

**决策**：

1. **安装载体**：复用既有 taskfile manifest 引擎（`manifests:winget/choco:install`），不新造离线包机制。在线装为主，winget 注册引导作为 audit apply 的前置步骤，App Installer 缺失时 msixbundle 离线兜底；不维护本地安装器缓存目录。
2. **更新频率判据**：稳定基础件（运行库、字体、每机器工具、驱动辅助）进 audit 镜像；高频更新且用户数据耦合的应用（浏览器、IM、编辑器）划 OOBE/维护。镜像不因应用更新而变旧。
3. **系统设置载体**：registry/HKLM 类设置进 manifest 体系（新增 kind，如 `registry:set`），与 `windows-features:set` 同引擎；audit 与活机维护跑同一套 manifest，幂等复用、漂移修复免费获得。
4. **触发方式**：手动进 audit 后跑 task 命令（`system:audit:apply` 命名见 01 号票）；可重入、可分步调试，失败原地重跑，不依赖 unattend 状态机（auditSystem 挂钩方案否决）。
5. **sysprep 防坑**（约束同时写入 04 号封装票）：全局应用 manifest 约束 `--scope machine`；audit apply 末尾自检无新增未预配 per-user MSIX 包；generalize 前断网（防 Store/WU 再动 UWP 包）。不做「报错后人工清包」的事后路线。
