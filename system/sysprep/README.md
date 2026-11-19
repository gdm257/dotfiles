# system/sysprep

audit 完成后的封装与镜像捕获阶段：seal 一条命令断网 + `sysprep /generalize /oobe` 封装关机，capture 在 PE 里对离线目标盘做 DISM capture 单 `install.wim`。契约见 openspec change `system-pipeline`。

## seal.cmd

在线（待封装系统内）运行，`task system:sysprep:seal` 等价：

1. 拒绝级 preflight：sealed marker（`%SystemRoot%\System32\Sysprep\sealed.marker`）已存在 → 241；`system\unattend.xml` 缺失 → 247。拒绝时不产生日志、不碰网络。
2. 断网：物理适配器 `Disable-NetAdapter`（PowerShell）。
3. `sysprep /generalize /oobe /unattend:<repo>\system\unattend.xml /shutdown`，unattend 的 generalize pass 已写 `SkipRearm=1`。
4. 写 sealed marker，机器随后关机。

已知时序：sysprep `/shutdown` 在进程返回后才触发关机，marker 紧随其后写入；极小概率来不及落盘。capture 只认 marker，若 PE 中确认 sysprep 已跑完而 marker 缺失，由人工判断补 marker 再 capture。

日志落 `%TEMP%\system\sysprep-<timestamp>.log`（preflight 拒绝不落日志）。

## capture.cmd

PE 中对离线目标盘运行：`capture.cmd <target-drive>`（形如 `D:`，同 pe-deploy 目标盘约定）。

- preflight：目标无 `\Windows` → 249；sealed marker 缺失（seal 未跑）→ 242；选中分区已有 `install-*.wim` → 243（只存一份，绝不覆盖）；无可选存放分区 → 244。拒绝时不调 dism。
- build 号：`reg load` 目标盘 `Windows\System32\config\SOFTWARE` 读 `CurrentBuild`（同 pe-deploy 做法），读不到 → 249。
- 分区选择：本地固定卷中剩余空间最大者，排除 PE 启动卷（`%SystemDrive%`）、目标系统卷、网络卷；真实路径用 powershell `Get-Volume` 过滤 `DriveType -eq 'Fixed'`。
- 捕获：`dism /Capture-Image /ImageFile:<分区>\install-<yyyymmdd>-<build>.wim /CaptureDir:<目标根> /Name:install-<yyyymmdd>-<build>`，文件名带日期与源 build 号。
- 日志落脚本目录 `capture-<timestamp>.log`，与 pe deploy 日志同侧（PE 阶段维持现状）。

## check.cmd

`task system:sysprep:check` 只报告不施加：0 = 未封装（可 seal）、10 = 已封装（待 capture）、247 = unattend 缺失或非良构。check 即拒绝级检测本身。

## 退出码

sysprep/capture 在 spec 的 2xx 分段里没有专用子区间，按 Implementation Decisions「根级 241–249」取值：

| 退出码 | 含义 |
|---|---|
| 241 | seal 拒绝：sealed marker 已存在 |
| 242 | capture 拒绝：目标盘无 sealed marker |
| 243 | capture 拒绝：选中分区已有 install wim |
| 244 | capture 拒绝：无可选存放分区 |
| 245 | sysprep 运行失败 |
| 246 | dism capture 失败 |
| 247 | `system\unattend.xml` 缺失或非良构 |
| 248 | 断网失败 |
| 249 | capture 参数无效或目标 build 读不到 |

check 退出码：0 干净、10 已封装、247 拒绝；self-check 退出码 = 失败断言数。

## 环境变量 seam（self-check 专用，一般不用）

| 环境变量 | 覆盖点 |
|---|---|
| `SYSP_SYSPREP` | seal 的 sysprep 命令 |
| `SYSP_NETOFF` | seal 的断网命令 |
| `SYSP_MARKER` | sealed marker 路径（seal/capture/check 共用） |
| `SYSP_DISM` | capture 的 dism 命令 |
| `SYSP_VOLUMES` | capture 的卷清单文件，行格式 `root free-mb type`（`fixed`/`boot`/`net`） |
| `SYSP_BOOT` | capture 排除的启动卷 |
| `SYSP_DATE` | capture 的 wim 日期段 |
| `SYSP_BUILD` | capture 的目标 build 号（跳过离线 hive 读取） |

## Self-check

```
system\sysprep\self-check.cmd
```

14 条断言：seal 5 条（已封装拒绝 241 且 stub 零调用、断网先于 sysprep、sysprep 精确参数、marker 写入、sysprep 失败 245 无 marker）、capture 6 条（未封装拒绝 242、wim 已存在拒绝 243、两种卷排序都选最大可用分区并排除 boot/net/target、wim 命名带日期与 build、无可选分区 244）、unattend 良构含 SkipRearm、check 0/10 两态。全程 stub seam，不碰真实系统状态。退出码 = 失败断言数，退出时清理临时目录。
