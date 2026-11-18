# Spec Delta

## MODIFIED Requirements

### Requirement: 环境自检与可移植性

deploy SHALL 在入口自检 dism 可用性，缺失时给指明原因的报错并以非零退出；dism 可用时 SHALL 进一步校验其文件版本不低于目标系统 build，低于时 MUST 拒绝注入、以专用退出码（207）退出、不执行任何写操作，报错 MUST 明确提示「PE 过旧，请升级 PE」；脚本输出 MUST 为纯 ASCII；脚本 MUST 以自身路径相对定位载荷与依赖，MUST NOT 含机器特定绝对路径。

#### Scenario: dism 缺失

- **WHEN** 运行环境 PATH 中无 dism
- **THEN** deploy 给出指明原因的报错并以非零退出，不执行任何写操作

#### Scenario: dism 版本低于目标 build

- **WHEN** dism 可用但其文件版本低于目标系统 build
- **THEN** deploy 以 207 退出，报错提示 PE 过旧需升级，不执行任何写操作

#### Scenario: dism 版本满足

- **WHEN** dism 可用且文件版本不低于目标系统 build
- **THEN** preflight 通过，注入照常进行

### Requirement: unattend 挂钩

deploy SHALL 把流水线根目录的跨阶段 unattend 骨架拷入目标系统 Panther 目录（必要时先创建该目录）；该骨架是全部 OOBE 自动化的唯一 unattend 载体；拷贝失败时 SHALL 记录错误并以非零退出。

#### Scenario: 挂钩存在

- **WHEN** 流水线根目录含 unattend 骨架
- **THEN** 该文件被拷入目标 \Windows\Panther\

#### Scenario: 挂钩拷贝失败

- **WHEN** unattend 文件存在但拷入 Panther 失败
- **THEN** 记录错误并以非零退出

#### Scenario: 挂钩缺失

- **WHEN** 流水线根目录不含 unattend 文件
- **THEN** deploy 正常完成，无报错
