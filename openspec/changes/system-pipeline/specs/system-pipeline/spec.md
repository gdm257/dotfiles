# Spec Delta

## Purpose

定义「重装开箱即用 + 日常维护」流水线的阶段行为契约：audit / sysprep+capture / OOBE / maintenance 各阶段的可观察行为、统一幂等与退出码契约，PE 阶段契约由 pe-driver-inject 能力承载。

## ADDED Requirements

### Requirement: 阶段结构与命令命名

流水线 SHALL 以 `system/` 为顶层，按阶段分模块；taskfile 任务 SHALL 使用 `system:<stage>:<action>` 前缀；每阶段 SHALL 提供成对 check 命令（`system:<stage>:check`），check 只报告不施加变更，退出码 0=干净、10=有漂移、2xx=preflight 拒绝。

#### Scenario: check 只报告

- **WHEN** 配置存在漂移时运行 check 命令
- **THEN** 输出漂移报告，不施加任何变更，退出码为 10

#### Scenario: check 干净

- **WHEN** 状态与声明一致时运行 check 命令
- **THEN** 退出码为 0

### Requirement: audit 阶段镜像准备

audit apply SHALL 以 winget 注册引导为前置（App Installer 缺失时以 msixbundle 离线部署兜底），经 Manifest 引擎安装稳定基础件（每机器作用域）与 registry:set 系统设置，写入 Default profile 预置，并在末尾自检无未预配 per-user MSIX 包；apply MUST 可重入且重跑收敛。

#### Scenario: winget 未就绪引导

- **WHEN** 首次运行时 App Installer 未完成注册
- **THEN** 引导注册后安装继续，不因未就绪失败

#### Scenario: MSIX 自检拒绝

- **WHEN** 末尾自检发现未预配 per-user MSIX 包
- **THEN** 以 audit 退出码区间（211–219）内的非零码报错退出

#### Scenario: audit 重跑收敛

- **WHEN** audit apply 连续执行两次
- **THEN** 第二次不产生重复安装副作用，状态与声明一致

### Requirement: sysprep 封装与镜像捕获为拒绝级

封装命令 SHALL 先断网再执行 generalize 进 OOBE 的 sysprep（SkipRearm=true、指向跨阶段 unattend）；捕获 SHALL 产出带日期与源 build 号的单 wim，落盘分区自动选剩余空间最大的本地分区（排除启动卷、目标系统盘与网络分区）；sysprep 与捕获 MUST 为拒绝级：检测到已 generalize 或目标 wim 已存在时硬拒绝且无副作用。

#### Scenario: 拒绝级重跑

- **WHEN** 已捕获 wim 后再次运行捕获
- **THEN** 非零拒绝退出，既有 wim 不被改动

#### Scenario: 分区自动选择

- **WHEN** 未显式指定落盘分区且存在多个本地分区
- **THEN** 排除启动卷、目标盘与网络分区后选剩余空间最大者

### Requirement: OOBE 账号与 per-user 通道

unattend SHALL 建单个无密码本地管理员并做一次 AutoLogon；per-user 自动化 SHALL 以机器级任意用户 logon 计划任务为主通道（以登录用户身份运行），FirstLogonCommands 只跑同一幂等薄入口兜底；入口脚本 MUST 用全局 mutex 串行，后到者检测已完成即退出。

#### Scenario: 后建用户自动配置

- **WHEN** OOBE 完成后新建另一个用户并登录
- **THEN** logon 计划任务以该用户身份重放 per-user manifest，配置自动就位

#### Scenario: 双入口并发

- **WHEN** 首启时计划任务与 FirstLogonCommands 同时触发入口脚本
- **THEN** mutex 串行化执行，后到者检测已完成即退出，无并发冲突

### Requirement: maintenance 漂移修复

maintenance run SHALL 重放 Windows 上全部 `manifests:*:install` 任务，靠 Receiver 幂等把被改掉的机器级 item 恢复声明状态；MUST NOT 引入 update 语义、per-user 操作或 Windows Update/系统清理。

#### Scenario: 漂移拉回

- **WHEN** 某 manifest 声明的配置被手动改掉后运行 maintenance run
- **THEN** 该配置恢复声明值

### Requirement: 幂等两级与退出码区间

每个 action SHALL 声明收敛级（重跑拉回声明值：audit / OOBE per-user / maintenance / PE 注入）或拒绝级（先检测再硬拒绝：sysprep / capture）之一；preflight 拒绝退出码 SHALL 落在本阶段互不相交区间（PE 201–209、audit 211–219、OOBE 221–229、maintenance 231–239、根级 241–249）且无副作用；收敛级失败后直接重跑，拒绝级失败回阶段起点整体重跑。

#### Scenario: 收敛级失败重跑

- **WHEN** audit apply 中途失败后再次运行
- **THEN** 从头重跑收敛，无需清理中间状态

#### Scenario: 退出码区间

- **WHEN** 任一阶段 preflight 拒绝
- **THEN** 退出码落在本阶段区间且未产生任何副作用

### Requirement: 在线阶段日志

在线阶段（audit / sysprep / OOBE / maintenance）运行 SHALL 落日志到 `%TEMP%\system\<stage>-<timestamp>.log`，内容含 `FAIL:` / `ERROR:` 行前缀便于失败计数；PE 阶段维持既有日志约定。

#### Scenario: 日志落盘

- **WHEN** 任一在线阶段命令执行
- **THEN** 对应日志文件出现在 %TEMP%\system\，失败行带 FAIL:/ERROR: 前缀

### Requirement: 模块自检与根级薄入口

每模块 SHALL 自带 self-check（fixture 端到端断言，退出码 = 失败断言数），`system/` 根 SHALL 提供薄入口依次调用全部模块 self-check。

#### Scenario: 根级自检

- **WHEN** 运行根级 self-check 入口
- **THEN** 依次执行各模块断言，退出码等于全部失败断言数
