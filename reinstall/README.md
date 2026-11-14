# reinstall

Windows 重装的 PE 阶段驱动离线注入。装机流程：PE 内 WinNTSetup 施放镜像，deploy 在 PE 里把驱动离线注入目标系统 DriverStore，重启进 OOBE 前设备全部就位。驱动包来自驱动总裁的下载目录（`*.7z` 驱动包 + `.Scindex` 索引），build 负责预解压，deploy 负责注入。

契约见 openspec change `pe-driver-inject`；fixture 载荷源文件在仓库根 `fixtures/drvpath/`。

## 目录

| 路径 | 用途 |
|---|---|
| `build-drivers.cmd` | 载荷预解压：载荷目录全部 `*.7z` 解到 `drivers/<包名>/` |
| `pe-deploy.cmd` | 部署注入：目标盘定位、逐 INF DISM 注入、unattend 挂钩、日志 |
| `unattend.xml` | 空 unattend 骨架，部署时挂钩到目标系统 Panther 目录 |
| `self-check.cmd` | build + deploy 行为自检（fixture 端到端断言） |
| `bin/7zr.exe` | 自带解压工具，脚本永远用它，不赌宿主 PATH |

## Build

```
build-drivers.cmd [payload-dir]
```

- `payload-dir` 缺省 = 脚本所在目录（`%~dp0`）。把整个 `reinstall/` 拷到载荷目录旁传参运行，或把 `build-drivers.cmd` 与 `bin\` 拷进载荷目录直接运行。
- 载荷布局假定：`*.7z` 在载荷目录顶层；每个包按 7z 基名解到 `drivers/<包名>/`，包内目录结构原样保留；`.Scindex` 等其余文件一律忽略。
- 幂等：重跑覆盖解压，结果一致、退出码 0。
- 退出码 = 解压失败的包数；载荷无 `*.7z` 或解压工具缺失时报错并以 2 退出。
- 环境变量 `PIDRV_SEVENZIP` 覆盖解压工具路径（self-check 用的 seam，一般不用）。

输出全 ASCII 英文，任何 PE 代码页下不乱码。

## Deploy

```
pe-deploy.cmd [target-drive]
```

在 PE 里把 `drivers\` 下全部 INF 离线注入目标系统的 DriverStore，再把 `unattend.xml` 挂钩到目标 Panther 目录。

### 目标盘定位

- 显式传参：形如 `D:`（也接受 `D:\`）；`<target>\Windows` 不存在则拒绝注入，退出码 202。
- 无参：扫描 A–Z，凡根下有 `\Windows` 的卷都是候选。唯一命中自动选中；多候选列出候选并拒绝猜测（退出码 204，不写任何盘）；无候选报错退出码 203。
- 注意：PE 自己的启动卷恒有 `X:\Windows`，无参扫描通常至少命中 PE 卷 → PE 里实际上总是多候选，请显式传目标盘。

### 注入过程

- 注入前先做 dism 自检：`PIDRV_DISM` 指定的命令或 `PATH` 里的 `dism.exe` 不存在则退出码 201。PE 的 dism 版本 MUST 大于等于目标系统 build，否则注入结果不可预期；Win11 24H2+ 目标需要更新的 PE。
- 递归遍历 `drivers\`，每个 INF 单独一次 `dism /Image:<target> /Add-Driver /Driver:<inf>`，控制台与日志各打一行 `OK: <inf>` / `FAIL: <inf>`。不用 `/Recurse`、不用 `/ForceUnsigned`：单驱动失败可定位，失败不中断其余驱动。
- 注入完追加 `dism /Image:<target> /Get-Drivers` 清单到控制台与日志。
- 代价：每个 INF 一次 DISM 启动开销，INF 多时慢；换来逐驱动成败归因，接受。

### 退出码

| 退出码 | 含义 |
|---|---|
| 0 | 全部 INF 注入成功 |
| 1–99 | 注入失败的 INF 个数 |
| 201 | dism 不可用（缺失或不可解析） |
| 202 | 显式目标盘没有 `\Windows` |
| 203 | 扫描无候选系统盘 |
| 204 | 扫描多候选，拒绝猜测 |
| 205 | `drivers\` 下没有 INF，先跑 `build-drivers.cmd` |
| 206 | `unattend.xml` 拷入 Panther 失败，注入结果已成立 |

preflight 失败（201–205）不产生日志文件；206 属注入后的失败，日志已落盘。失败计数与 preflight 区间不相交，失败的 INF 不超过 100 个时退出码无歧义，更多失败以日志里的 `FAIL:` 行数为准（已知上限，接受）。

### 日志

- 位置：载荷目录下 `deploy-<timestamp>.log`，时间戳取 `%DATE%`/`%TIME%` 并把 `/ : .` 与空格换成 `-`（locale 星期字样会留在文件名里）。
- 内容：dism 每次调用的输出、逐 INF `OK:`/`FAIL:` 行、`/Get-Drivers` 清单、`done: N inf(s), M failed` 汇总。控制台每行同步写日志。

### unattend 挂钩

- 载荷根目录有 `unattend.xml` → 复制到 `<target>\Windows\Panther\unattend.xml`，日志记一行；Panther 不存在时先创建目录，新施放的镜像没有它。
- 没有 → 跳过，不算错误，不影响退出码。
- 拷贝失败 → 记 ERROR 并以 206 退出，注入结果不受影响。
- 自带的 `unattend.xml` 是空骨架：仅 XML 声明 + 空 `<unattend xmlns="urn:schemas-microsoft-com:unattend"/>`，需要时自行填充对应 pass。

### 环境变量 seam（均 self-check 专用，一般不用）

| 环境变量 | 覆盖点 | 说明 |
|---|---|---|
| `PIDRV_SEVENZIP` | build 的解压工具路径 | stub 解压器 |
| `PIDRV_DISM` | deploy 的 dism 命令 | stub dism |
| `PIDRV_SCAN_ROOTS` | deploy 扫描的盘根集合 | 用 fixture 目录树代替真实盘根，此时选中的目标是该根下子目录路径本身 |

### 端到端流程

1. 把 `reinstall/` 目录全部内容拷到驱动载荷根目录（U 盘侧）。
2. PE 里跑 `build-drivers.cmd`，预解压 `*.7z` 到 `drivers/`。
3. PE 里跑 `pe-deploy.cmd [目标盘]`，离线注入 + unattend 挂钩。

## Self-check

```
reinstall\self-check.cmd
```

在 `%TEMP%\pdi-selfcheck` 组装 fixture 载荷（拷入 `fixtures/drvpath` 两个包 + 假 `.Scindex` + 无关 `.txt`，用自带 7zr 打包），共 14 条断言：build 4 条（解压树完整、重跑幂等、空载荷非零退出、解压工具缺失非零退出），deploy 10 条（唯一命中自动选中并调 dism、多候选拒绝且不写盘、目标无效拒绝、坏 INF 计数失败不中断、全好退出 0、unattend 挂钩到位、新镜像自动建 Panther 并挂钩、unattend 缺省跳过、unattend 拷贝失败退出 206、dism 缺失退出 201 且不写日志）。deploy 断言用生成于临时目录的 stub dism（记录调用参数，见 `bad.inf` 退出 1）配合 `PIDRV_DISM`/`PIDRV_SCAN_ROOTS` seam，全程不碰真实盘。每条断言打印 PASS/FAIL，退出码 = 失败断言数，退出时清理临时目录。

## bin/7zr.exe

- 版本：26.04 (x86)（2026-10-05，随本仓库提交时的版本，以 `7zr.exe i` 输出为准）。
- 来源：<https://www.7-zip.org/a/7zr.exe>，Igor Pavlov 官方独立版控制台解压器，约 0.6 MB，支持 7z 全格式（含 BCJ2 过滤器）。Windows 自带 tar.exe 解不开驱动总裁产出的 7z（BCJ2 不支持），这是自带它的直接原因。
- 更新：重新下载同一 URL 覆盖 `reinstall/bin/7zr.exe`，跑一遍 self-check 即可。
