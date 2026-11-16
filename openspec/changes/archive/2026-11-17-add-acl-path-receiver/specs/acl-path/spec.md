# Spec Delta

## Purpose

通过 acl-path kind 的 manifest items 声明式收敛 Windows 路径的 owner 与 ACL，重装系统后一条命令完成受管路径的权限修复。

## ADDED Requirements

### Requirement: acl-path 路由与 receiver 契约

kind 为 `acl-path` 的 item SHALL 经 manifest dispatch 路由到 `acl:apply` receiver；receiver SHALL 遵守既有 receiver 契约（ITEM_JSON 单通道输入、kind 自验证、FAIL_LOG 与 continue_on_error 包装）。

#### Scenario: dispatch 路由 acl-path

- **WHEN** manifest 含 `{kind: acl-path, path: P, grants: [...]}` 且顶层任务声明 CALLS `acl-path=acl:apply`
- **THEN** 该 item 被路由到 acl:apply，其余 kind 不受影响

#### Scenario: kind 不匹配响亮失败

- **WHEN** acl:apply 收到 kind 非 acl-path 的 item
- **THEN** receiver 响亮失败，不执行任何命令

### Requirement: 显式授权

receiver SHALL 仅按 item 的 `grants` 声明授权：每项为 `principal:perms` 的 icacls 原生语法，批量拼成单条 grant 命令；`grants` 缺省时不执行任何授权。

#### Scenario: 批量授权

- **WHEN** item 声明 grants 为 `["user1:(OI)(CI)F", "S-1-5-32-545:(OI)(CI)RX"]`
- **THEN** 一条 icacls 命令同时授予两个 principal，principal 支持用户名、组名、裸 SID

#### Scenario: grants 缺省不授权

- **WHEN** item 无 grants 字段
- **THEN** 不执行任何 icacls grant

#### Scenario: 格式非法响亮失败

- **WHEN** grants 某项不含 `:`
- **THEN** receiver 响亮失败并指出该项

### Requirement: owner 收敛

item 声明 `owner` 时 receiver SHALL 将指定路径 owner 收敛到该 principal（任意 user/group 名或 SID，原样传 takeown）；未声明时不动 owner。

#### Scenario: 声明 owner

- **WHEN** item 声明 `owner: some-user`
- **THEN** takeown 将顶层路径 owner 置为 some-user

### Requirement: 递归与 protected 后代跳过

item 声明 `recursive: true` 时操作 SHALL 覆盖整棵子树，且子树中 ACL protected（显式禁用继承）的后代目录 SHALL 完全跳过；默认 false 只作用于顶层路径。

#### Scenario: 递归收敛跳过 protected 后代

- **WHEN** recursive: true 且子树中某后代目录禁用了继承
- **THEN** 该后代目录的 ACL 与 owner 均不被触碰，其余路径正常收敛

### Requirement: 继承控制

item 的 `inheritance` 字段 SHALL 支持 `reset`（顶层路径重置为从父目录继承）与缺省 no-op；其他值 MUST 响亮失败。顶层路径自身为 protected 且未声明 reset 时，SHALL 正常处理 owner/grants 但不动继承。

#### Scenario: 声明 reset

- **WHEN** item 声明 `inheritance: reset`
- **THEN** 顶层路径 ACL 重置为从父目录继承后按 grants/owner 收敛

#### Scenario: 未知值响亮失败

- **WHEN** item 声明 `inheritance: enforce`
- **THEN** receiver 响亮失败

#### Scenario: 顶层 protected 不跳过

- **WHEN** 顶层路径禁用了继承且未声明 inheritance
- **THEN** owner/grants 照常处理，继承保持不动

### Requirement: 前置校验与失败语义

receiver SHALL 在执行前检测管理员权限与路径存在性：非管理员或路径缺失时响亮失败；item 级 `continue_on_error: true` SHALL 可覆盖路径缺失类失败继续批处理。

#### Scenario: 非管理员响亮失败

- **WHEN** 在非管理员会话运行 acl:apply
- **THEN** 响亮失败并提示以管理员身份重跑

#### Scenario: 路径缺失响亮失败

- **WHEN** item 的 path 不存在
- **THEN** 响亮失败；该 item 声明 continue_on_error 时失败记入 FAIL_LOG 且批处理继续

### Requirement: 幂等收敛

apply SHALL 无条件执行收敛命令且重复执行结果一致（icacls/takeown 对已达标路径无累积副作用），不做读-比-写。

#### Scenario: 重复执行幂等

- **WHEN** 对同一 item 连续执行两次 apply
- **THEN** 两次结束后 ACL 状态一致，无重复 ACE 累积
