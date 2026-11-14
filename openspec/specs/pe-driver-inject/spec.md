# pe-driver-inject Specification

## Purpose

重装 Windows 时让驱动在 PE 阶段离线就位：build 把驱动下载目录预解压为可注入的 INF 目录树，deploy 在 PE 内对离线目标全量注入并挂载 unattend 骨架，首启 OOBE 前设备驱动已在 DriverStore。

## Requirements

### Requirement: 载荷预解压

build 脚本 SHALL 将载荷目录中全部 7z 驱动包解压为 `drivers/<包名>/` 散装 INF 目录树（包名 = 7z 文件基名），MUST 幂等（重复执行结果一致），MUST 忽略 `.Scindex` 索引文件，且 SHALL 仅使用自带解压工具、不依赖宿主 PATH。

#### Scenario: 混合载荷目录

- **WHEN** 载荷目录同时含多个 7z 驱动包与 .Scindex 文件
- **THEN** 全部 7z 解压为对应 drivers/<包名>/ 目录，.Scindex 不产生任何动作

#### Scenario: 幂等重跑

- **WHEN** build 连续执行两次
- **THEN** 两次产物一致且退出码均为 0

#### Scenario: 空载荷

- **WHEN** 载荷目录不含任何 7z 包
- **THEN** 报错并以非零退出

#### Scenario: 解压依赖缺失

- **WHEN** 自带解压工具不在预期位置
- **THEN** 报错指明缺失依赖，而非静默失败

### Requirement: 目标系统盘定位

deploy 脚本无参运行时 SHALL 扫描各卷的 `\Windows` 目录，唯一命中时自动选中；多命中时 MUST 列出候选并以非零退出；显式传参时 MUST 校验目标存在 `\Windows` 后才执行任何写操作。

#### Scenario: 唯一命中自动选中

- **WHEN** 无参运行且恰有一个卷含 \Windows
- **THEN** 该卷被选为目标并继续执行

#### Scenario: 多候选拒绝执行

- **WHEN** 无参运行且多个卷含 \Windows
- **THEN** 列出全部候选并以非零退出，不执行任何写操作

#### Scenario: 指定盘校验失败

- **WHEN** 传入的目标盘符下不存在 \Windows
- **THEN** 拒绝执行并以非零退出

### Requirement: 驱动离线注入

deploy 脚本 SHALL 对目标离线镜像递归全量注入 INF 目录树中的驱动；单个驱动失败时 MUST 记录并继续；最终退出码 SHALL 等于失败驱动数；MUST NOT 强制接受未签名驱动。

#### Scenario: 全量注入成功

- **WHEN** 载荷含多个驱动包且全部有效签名
- **THEN** 全部注入成功，最终驱动计数反映新增，退出码为 0

#### Scenario: 个别驱动失败继续

- **WHEN** 载荷中存在无法安装的驱动（如未签名）
- **THEN** 其余驱动照常注入，失败者记入日志，退出码等于失败数

### Requirement: unattend 挂钩

载荷目录存在 unattend 文件时 deploy SHALL 将其拷入目标系统 Panther 目录（必要时先创建该目录）；不存在时 SHALL 跳过且不影响退出码；拷贝失败时 SHALL 记录错误并以非零退出。

#### Scenario: 挂钩存在

- **WHEN** 载荷目录含 unattend 文件
- **THEN** 该文件被拷入目标 \Windows\Panther\

#### Scenario: 挂钩拷贝失败

- **WHEN** unattend 文件存在但拷入 Panther 失败
- **THEN** 记录错误并以非零退出

#### Scenario: 挂钩缺失

- **WHEN** 载荷目录不含 unattend 文件
- **THEN** deploy 正常完成，无报错

### Requirement: 部署日志

deploy 脚本 SHALL 将逐驱动注入结果与最终驱动计数写入载荷目录的日志文件，供装机后核查。注入阶段开始后的运行 MUST 落日志；preflight 失败（未对目标执行任何写操作）的运行 MAY 不产生日志。

#### Scenario: 日志落盘

- **WHEN** 注入阶段开始后的 deploy 执行完成（无论成败）
- **THEN** 载荷目录存在本次运行的日志文件，含逐驱动结果与汇总计数

### Requirement: 环境自检与可移植性

deploy SHALL 在入口自检 dism 可用性，缺失时给指明原因的报错（含 PE 版本需不低于目标系统的提示）并以非零退出；脚本输出 MUST 为纯 ASCII；脚本 MUST 以自身路径相对定位载荷与依赖，MUST NOT 含机器特定绝对路径。

#### Scenario: dism 缺失

- **WHEN** 运行环境 PATH 中无 dism
- **THEN** deploy 给出指明原因的报错并以非零退出，不执行任何写操作
