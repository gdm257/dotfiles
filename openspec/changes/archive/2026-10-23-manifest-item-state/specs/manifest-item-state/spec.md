# Spec Delta

## Purpose

定义 item 声明字段 `state` 的家族契约：表达资源期望方向（应在场 / 应不在场），值域由接收方按 kind 定义并拒绝未知值，收敛幂等（absent 未安装即成功），且仅作用于 manifest 声明的 item（declared-only）。

## ADDED Requirements

### Requirement: state 表达期望方向

item MAY 声明 `state` 表达资源期望方向：缺省与 `present` 为正向（应在场，安装收敛）；`absent` 为反向（应不在场，接收方执行卸载收敛）。`state` 为普通声明字段：引擎 MUST NOT 消费其值，absent 条目照常穿过过滤与透传到达接收方；`platforms` 过滤照常生效。

#### Scenario: 单条 absent 交给接收方卸载

- **WHEN** item 声明 `{ kind: winget-app, id: X, state: absent }`
- **THEN** 引擎照常透传该 item，接收方执行卸载收敛

#### Scenario: absent 与 platforms 正交

- **WHEN** item 声明 `state: absent` 且 `platforms: [linux]`，当前平台为 windows
- **THEN** 该 item 被 platforms 过滤，不调用接收方，卸载声明不在本机生效

### Requirement: 值域 per-kind 由接收方定义

`state` 值域 SHALL 由接收方按 kind 定义并响亮拒绝未知值。包类家族（`winget-app` / `scoop-app` / `choco-package`）值域恰为 `present` / `absent`；`windows-feature` 维持 `enabled` / `disabled`（dism 原生词汇），不迁移。

#### Scenario: 未知值响亮失败

- **WHEN** `winget-app` item 声明 `state: removed`
- **THEN** 接收方报错含该值与 kind，不静默跳过

#### Scenario: windows-feature 值域不变

- **WHEN** `windows-feature` item 声明 `state: enabled` 或 `state: disabled`
- **THEN** 行为与本 change 之前完全一致

### Requirement: 幂等达标判定

接收方对 state 的收敛 SHALL 幂等：`absent` 且资源未安装 SHALL 判成功（墓碑条目重跑无害）；`present` 且资源已安装 SHALL 判成功。安装与否的探测由接收方就地实现；`version` 仅参与安装命令拼装，MUST NOT 参与达标判定。

#### Scenario: absent 未安装即成功

- **WHEN** `state: absent` 的 app 未安装，接收方收敛
- **THEN** 判定成功，不报错，不执行卸载命令

#### Scenario: version 不参与 absent 判定

- **WHEN** `state: absent` 的 item 同时声明 `version`
- **THEN** 卸载分支无视 version，达标判定与版本无关

### Requirement: 包类接收方实现 absent 卸载

`winget-app` / `scoop-app` / `choco-package` 的接收方 SHALL 实现 absent 分支：卸载命令拼装、未安装即成功、复用 continue_on_error / FAIL_LOG 容错。无移除语义的 kind 遇 `absent` SHALL 响亮失败，MUST NOT 静默跳过。

#### Scenario: winget absent 卸载

- **WHEN** `winget-app` item 声明 `state: absent` 且该 app 已安装
- **THEN** 接收方执行卸载；失败按既有容错机制处理

#### Scenario: 无移除语义的 kind 报错

- **WHEN** `scoop-bucket` item 声明 `state: absent`
- **THEN** 接收方响亮报错，不静默跳过

### Requirement: 收敛边界 declared-only

收敛 SHALL 仅作用于 manifest 声明的 item；清单外已安装资源 MUST NOT 被自动卸载。全量清扫（清单外即删）MUST NOT 成为任何接收方或 wrapper 的默认行为。

#### Scenario: 清单外资源不被触碰

- **WHEN** 机器上装有 manifest 未声明的 app，任意 manifests wrapper 运行
- **THEN** 该 app 不被卸载、不被报告为 drift
