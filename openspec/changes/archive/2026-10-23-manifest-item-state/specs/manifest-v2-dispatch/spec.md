# Spec Delta

## ADDED Requirements

### Requirement: 引擎职责四步与传播

引擎 SHALL 恰好执行解析（未知顶层键 fail）、展开（`items` 声明序、group 展开、引用条目非保留字段通用下传）、过滤（仅 `platforms`，三层一致）、透传（幸存 item 整 map 原样交 `CALL`）。引用条目 platforms 不匹配即整组跳过。引擎 MUST NOT 持有动词知识、解释字段语义或点名任何声明字段：kind 值域与字段语义一概不碰；残留 `enable` 键按结构错误 fail。

#### Scenario: 迭代严格串行按展开序

- **WHEN** 展开后幸存 items 为 [a, b, c]
- **THEN** 按此顺序逐个调用 `CALL`，无并发

#### Scenario: 下传字段照常透传

- **WHEN** 引用条目声明某非保留字段且组内成员未声明该字段
- **THEN** 成员透传时携带该字段值，接收方自行解释

#### Scenario: 残留 enable 响亮 fail

- **WHEN** 某 item 声明 `enable: false`
- **THEN** 引擎按结构错误 fail，错误信息含「注释掉该条目」指引，而非静默跳过

## MODIFIED Requirements

### Requirement: 结构错误消息含路径与序号

结构错误（未知顶层键、未知或嵌套 group、item 缺 kind 或非标量、items 元素非 map、platforms 值域外、已废除键 `enable`）SHALL fail，错误消息 MUST 含 manifest 路径与展开序号 `#N`（1-based，展开后序列中的位置）。

#### Scenario: items 元素非 map

- **WHEN** `items` 中某元素为纯字符串
- **THEN** fail 消息含 `item #<N> not a map` 与 manifest 路径

#### Scenario: 残留 enable 属结构错误

- **WHEN** 展开序中第 N 个 item 携带 `enable` 键
- **THEN** fail 消息含 `#N`、manifest 路径与「注释掉该条目」指引

### Requirement: 边界行为与零依赖

`items` 为空或全部被 platforms 过滤时 SHALL 静默 exit 0、不调用 `CALL`。实现 SHALL 零依赖（ADR-0001 全额适用：bash builtins + Windows 自带命令 + Task 进程内模板）。

#### Scenario: 空批静默通过

- **WHEN** manifest 的 `items` 为空，或所有 item 被 `platforms` 过滤
- **THEN** dispatch 不调用 `CALL`，exit 0

## REMOVED Requirements

### Requirement: 引擎职责恰好四步

**Reason**: 原 requirement 的过滤步含 `enable`、且带「enable false 静默跳过」scenario——enable 语义整体废除（残留键响亮拒绝，静默跳过不复存在），scenario 级无法表达行为反转，整块移除并以新块取代。
**Migration**: 新 requirement「引擎职责四步与传播」：过滤步仅剩 `platforms`，展开步含引用条目非保留字段通用下传；残留 `enable` 归入「结构错误消息含路径与序号」。
