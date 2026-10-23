# Spec Delta

## ADDED Requirements

### Requirement: group 引用与通用下传

`{group: <name>}` 引用条目展开为 `groups.<name>` 的成员；未知 group、嵌套 group（成员再含 `group` 键）SHALL fail。引用条目即 defaults 块：除保留键（`group` / `platforms` / `kind`）外，其上声明的一切字段 SHALL 逐键下传给组内未声明该键的 item（字段并入 item map，引擎不消费值）；item 显式声明的值 SHALL 优先。manifest 层 MUST NOT 持有、枚举或说明任何声明字段名。下传 MUST 非破坏性：SHALL NOT 改动组定义内的成员字典；同组多次引用、各带不同下传字段时互不污染。

#### Scenario: 未知 group 报错

- **WHEN** `items` 含 `{group: bar}` 而 `groups.bar` 未定义
- **THEN** 引擎 fail，错误信息含 group 名与 manifest 路径

#### Scenario: 任意非保留字段向组内下传

- **WHEN** 引用条目声明某非保留字段 `k: v`，组内 item A 未声明 `k`、item B 显式声明 `k: w`
- **THEN** A 透传时携带 `k: v`，B 保持 `k: w`

#### Scenario: 重复引用不污染

- **WHEN** 同组被两次引用，第一次携带某下传字段、第二次未携带
- **THEN** 第二次展开的成员不带该字段，组定义未被第一次下传改写

## MODIFIED Requirements

### Requirement: 保留键封闭集合

引擎消费的保留键 SHALL 恰为 `kind` / `platforms` / `group`；未来新增消费字段 MUST 扩展此集合，MUST NOT 复用声明字段名。`platforms` 为 string 或 string 列表，值域对齐 go-task（`windows` / `linux` / `darwin`，MAY 带 `/arch`），仅正向匹配、缺省全平台、不支持负向匹配；值域外 SHALL fail。选择类字段三层一致：内联 item、group 成员、group 引用条目均可声明。已废除键 `enable` 出现于任意层 SHALL fail，错误信息 MUST 含 manifest 路径与展开序号，并指引「注释掉该条目」——旧肌肉记忆 MUST NOT 静默装上以为暂停的资源。

#### Scenario: 引用条目不匹配整组跳过

- **WHEN** `{group: g, platforms: linux}` 在 windows 平台求值
- **THEN** 整组跳过，组内 item 不迭代

#### Scenario: platforms 值域外报错

- **WHEN** item 声明 `platforms: win`（typo）
- **THEN** 引擎 fail，错误信息含该值、`#N` 与 manifest 路径

#### Scenario: 残留 enable 响亮报错

- **WHEN** 内联 item、group 成员或 group 引用条目声明 `enable` 键
- **THEN** 引擎 fail，错误信息含 manifest 路径、`#N` 与「注释掉该条目」指引

## REMOVED Requirements

### Requirement: group 引用与传播规则

**Reason**: 「传播型声明字段」类别枚举（`continue_on_error` / `state`）把 receiver 侧字段名写进了 manifest 层 spec，违反 manifest 通用原则——manifest 层不得持有、枚举或说明任何 receiver 字段；且传播类别每扩一个字段就要改一次 manifest 层，方向错误。
**Migration**: 新 requirement「group 引用与通用下传」：除保留键外一切声明字段通用下传、成员显式优先、非破坏性；`未知 group 报错` 场景随迁保留；具体字段的语义与值域由 receiver 层 spec（`manifest-item-state` capability）定义，场景示例改用中性占位字段。
