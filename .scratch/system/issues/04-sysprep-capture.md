# sysprep-capture: 封装与镜像管理选型

Type: grilling
Status: resolved
Blocked by: 03

## Question

sysprep 封装与镜像管理机制：

- sysprep 参数与 unattend 搭配（/generalize /audit vs /oobe 的路线取舍）、重封装次数限制（SkipRearm/MG 现实约束）。
- capture 产物形态（wim 放哪：另一分区 / 移动盘；DISM /Capture-Image vs 第三方）与 PE 阶段施放方式（现流程用 WinNTSetup，是否沿用）。
- 镜像保鲜机制：多久重打、audit 脚本与保鲜重打是否同一流程；Win11 24H2+ 目标对新 PE 的要求并入考量。

来自 03 号票的既定约束：全局应用 manifest 约束 `--scope machine`；audit apply 末尾自检无新增未预配 per-user MSIX 包；generalize 前断网（防 Store/WU 再动 UWP 包）。本票封装流程 MUST 建立在这三层防护之上。

## Answer

（与用户两轮 grilling 定稿）

- sysprep 路线：audit 内容装完后跑 `sysprep /generalize /oobe /unattend:system\unattend.xml /shutdown`，镜像捕获后 PE 施放直接进 OOBE，不再回 audit。unattend generalize pass 写 `SkipRearm=true`（跳过 rearm 配额消耗，单机场景免掉 sysprep 报错来源）。
- capture 产物：DISM `/Capture-Image` 单镜像 `install.wim`（无第三方工具、与 pe-deploy 同工具链），文件名带日期与源 build 号。存放一份，落盘分区自动选择：排除 PE 启动卷、目标系统盘与网络分区后，选**剩余空间最大**的本地分区。
- PE 施放沿用现状：WinNTSetup 人工施放 + `pe-deploy.cmd` 自动注入，不做施放自动化。
- 镜像保鲜 = 完整重跑同一流程：进 audit → `system:audit:apply` 在线更新 → sysprep generalize → capture 新 wim。全量重打，不做增量；手动触发，维护循环最多放「镜像年龄」提醒，不自动重打（年龄阈值留给 06 号票）。
- PE 本体用第三方（主 FiePE、次 雷电PE），不出任何 PE 制作/维护脚本。dism ≥ 目标 build 的前提由 pe-deploy preflight 硬校验兜底：读 dism 文件版本 vs 目标系统 build，不足直接拒注入（新增退出码 207），报错信息明确提示「PE 过旧，请升级 PE」。每次重打镜像后人工确认所用 PE 的 dism ≥ 新镜像 build，确认不过就换/升 PE，属纯人工事项。
