# Spec Delta

## Purpose

通过 sym-link kind 的 manifest items 声明 home 布局 symlink，`link:apply` receiver 幂等收敛，重装系统后一条命令重建 home 链接布局，取代 dotbot link 指令。

## ADDED Requirements

### Requirement: sym-link 路由与 receiver 契约

kind 为 `sym-link` 的 item SHALL 经 manifest dispatch 路由到 `link:apply` receiver；receiver SHALL 遵守既有 receiver 契约（ITEM_JSON 单通道输入、kind 自验证 fail、FAIL_LOG 与 continue_on_error 包装）。`state` 无 absent 语义：声明 `absent` SHALL 响亮失败。

#### Scenario: dispatch 路由 sym-link

- **WHEN** manifest 含 `{kind: sym-link, src: S, dst: D}` 且顶层任务声明 CALLS `sym-link=link:apply`
- **THEN** 该 item 被路由到 link:apply，其余 kind 不受影响

#### Scenario: kind 不匹配响亮失败

- **WHEN** link:apply 收到 kind 非 sym-link 的 item
- **THEN** receiver 响亮失败，不执行任何命令

#### Scenario: absent 响亮失败

- **WHEN** sym-link item 声明 `state: absent`
- **THEN** receiver 响亮失败，不静默跳过

### Requirement: src/dst 声明语义

`src` SHALL 为仓库根相对路径：glob（恰一层、含隐藏条目，语义对齐 dotbot `*`+`.*` 成对规则）或不含通配符的精确路径。`dst` SHALL 为 `~/` 锚定的家目录路径，缺省 `~/`；以 `/` 结尾 SHALL 为目录语义（链接落在 dst 下，链接名为 src 条目的 basename），否则 SHALL 为精确链接路径。

#### Scenario: 目录语义以 basename 落位

- **WHEN** item 声明 `src: apps/*, dst: ~/`
- **THEN** `apps/` 下每个条目（含隐藏条目）在 `~/` 下以同名链接落位，不递归

#### Scenario: 精确路径语义

- **WHEN** item 声明 `src: libraries/Documents/PowerShell/ConsoleHost_history.txt` 且 dst 为不含尾部 `/` 的完整文件路径
- **THEN** 链接创建于该精确路径，不追加 basename

#### Scenario: dst 缺省为家目录

- **WHEN** item 未声明 dst
- **THEN** 按 `~/` 目录语义处理

### Requirement: 幂等收敛

对每个展开条目：链接目标不存在 SHALL 创建 SymbolicLink 且父目录缺失先创建；已是指向同一来源的 SymbolicLink SHALL 跳过；SymbolicLink 指向他处 SHALL 删除重建；目标存在但非 SymbolicLink SHALL 响亮失败。重复执行 SHALL 结果一致，无累积副作用。

#### Scenario: 缺失创建并补父目录

- **WHEN** 目标路径及其父目录均不存在
- **THEN** 先创建父目录再创建 SymbolicLink

#### Scenario: 同指跳过

- **WHEN** 目标已是指向该来源的 SymbolicLink
- **THEN** 不做任何改动，判成功

#### Scenario: 异指 relink

- **WHEN** 目标为 SymbolicLink 但指向其他来源
- **THEN** 删除后重建为指向声明来源

#### Scenario: 非 SymbolicLink 响亮失败

- **WHEN** 目标路径存在且不是 SymbolicLink（真实文件或目录）
- **THEN** receiver 响亮失败并指出该路径，不覆盖

#### Scenario: 重复执行幂等

- **WHEN** 对同一 item 连续执行两次 apply
- **THEN** 链接集与指向完全一致，无重复副作用

### Requirement: 匹配边界

含通配符的 `src` 零匹配 SHALL 静默成功（bootstrap 时 gitignored 目录缺席不阻塞批处理）；不含通配符的 `src` 缺失 SHALL 响亮失败。

#### Scenario: glob 零匹配静默

- **WHEN** `src: state/*` 而 `state/` 目录为空或不存在
- **THEN** 该 item 判成功，不报错

#### Scenario: 精确路径缺失响亮失败

- **WHEN** `src` 不含通配符且路径不存在
- **THEN** receiver 响亮失败并指出该路径

### Requirement: Windows SymbolicLink 机制

receiver SHALL 以 SymbolicLink 创建全部链接（文件与目录一致），MUST NOT 使用 junction；创建失败（如未开启开发者模式）SHALL 响亮失败并透出 PowerShell 原生错误。

#### Scenario: 文件与目录同为 SymbolicLink

- **WHEN** apply 处理文件条目与目录条目
- **THEN** 两者均以 SymbolicLink 创建，无 junction

#### Scenario: 无特权响亮失败

- **WHEN** 会话无 symlink 创建特权，New-Item 失败
- **THEN** receiver 以非 0 退出并透出错误输出
