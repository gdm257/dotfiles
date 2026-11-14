# Memories

## Sources gathered

- `GLOSSARY.md` — read。词汇全部属于 Taskfile/manifest（活机配置）域：Manifest / Item / Kind / Group / Receiver。本 change 属离线装机域（PE 阶段摆载荷 + 离线注入），不触碰 manifest 体系，无术语冲突；装机域新词（载荷、预解压、注入）不入 GLOSSARY，由本 change 的 spec 承载。
- `docs/adr/` — read all 3（0001 manifest 引擎零依赖、0002 资源模型、0003 多 receiver 分发）。均为 manifest 域决策，与离线装机域无交集，无冲突需 surface。
- openspec specs — inventory via `openspec list --specs`（7 个）。逐个核对均为 manifest / schema 元规范，与驱动注入无关；本 change 引入全新 capability，无 MODIFIED / REMOVED。
- `.trellis/spec/` — absent, skipped.
- 设计定稿来源：本会话 grill-with-docs 三轮共识，定稿承载于本 change 的 `spec.md` 与 `.scratch/pe-driver-inject/spec.md`。

## Constraints carried forward

- 装机形态：PE + WinNTSetup 施放镜像、首启进 OOBE；不使用 WinNTSetup 自带「添加驱动」（社区口碑不稳、无日志、装机当天多一个要记住的 UI 步骤）。
- 驱动机制：deploy 脚本在 PE 内对离线目标执行 DISM `Add-Driver` 注入。rev：实现定稿从一次性 `/Recurse` 调用改为逐 INF 调用——包级粒度给不出逐驱动结果与「退出码 = 失败驱动数」契约，用速度换可问责。已否决的替代方案：unattend `DriverPaths`（官方文档限定 auditSystem / offlineServicing pass，WinNTSetup 施放的镜像首启走不到）；OOBE 阶段 pnputil 脚本（首启才装、需额外投放机制、还要善后临时目录）。
- 载荷形态：外部驱动下载目录（驱动总裁产物，7z 驱动包 + .Scindex 索引）→ build 脚本幂等预解压为散装 INF 目录树 `drivers/<包名>/`；`.Scindex` 忽略。实测依据：Windows 自带 tar.exe 解不开这些 7z（BCJ2 过滤器），故仓库自带 7zr.exe（7-Zip 官方独立版约 0.6 MB，7z 全格式），脚本永远用它，本机 / PE 通吃，不赌宿主 PATH。
- 目标盘定位：PE 的 C: 不一定是目标系统盘。无参时扫描各卷的 `\Windows`，唯一命中才自动使用；多命中列出候选并以非零退出；显式传参时校验该盘确有 `\Windows` 后才动手。
- unattend 挂钩：静态骨架文件（空设置、结构合法、可独立验证），deploy 以 `if exist` 方式拷入目标 `\Windows\Panther\`，不存在则跳过不报错。驱动不经 unattend；该文件是未来 OOBE 其他自动化的唯一载体。
- 容错与可观测：单个驱动失败（如未签名）记日志继续，不中断、不 ForceUnsigned；退出码 = 失败驱动数；日志（DISM 逐驱动输出 + `/Get-Drivers` 计数 + 汇总）落载荷目录（U 盘侧），事后可查。
- 实现约束：纯 cmd 批处理（PE 保证有 cmd.exe，不赌 PowerShell 在不在）；脚本输出全 ASCII（避 PE 代码页坑）；脚本以 `%~dp0` 相对定位载荷与依赖，禁止机器特定绝对路径。
- 范围边界：单机方案，驱动全量注入不做硬件过滤（PnP 自匹配，不匹配的驻留 DriverStore 无害）；OOBE 其他自动化（首启脚本、账号、region 等）out of scope，仅预留 unattend 挂钩。
- 环境前提：PE 的 dism.exe 版本 MUST ≥ 目标系统 build（Win10 基 PE 装 Win10 22H2 成立；将来装 Win11 24H2+ 需换新 PE）。deploy 入口 `where dism` 自检，缺失时给指明原因的报错。
- 仓库归属：交付物进本仓库 `reinstall/`（build 脚本、deploy 脚本、unattend 骨架、7zr.exe、README）；外部载荷目录不进 git，使用前人工拷贝脚本过去（README 记载流程）。命名定则：驱动注入发生在 PE 阶段，change / capability / 目录名不用 oobe；`reinstall/` 为阶段中性名，未来 OOBE 自动化（unattend 内容）同住此目录。
