# manifest-groups Specification

## Purpose

让 manifest 的 `run` 列表支持 `{ group: <name> }` 条目，执行时纯展开为 `groups.<name>` 下的 run item 列表，以收敛重复条目。

## Requirements

### Requirement: run item 支持 group 条目

`run` 列表中的条目若声明 `group: <name>`，执行时 SHALL 被展开为 `groups.<name>` 列表中的每一个 run item，各按原有 run item 解析规则（run item > preset > defaults）执行。group 条目本身 MUST NOT 支持覆盖任何字段（prefix/args 等），group 内条目 MUST NOT 允许嵌套 group。

#### Scenario: run 引用已定义的 group

- **WHEN** manifest 定义 `groups.foo` 含两个 run item，且 `run` 含 `{ group: foo }`
- **THEN** 两条命令按原有解析规则依次执行，顺序与 `groups.foo` 中一致

#### Scenario: group 条目不嵌套

- **WHEN** `groups.<name>` 内某条目声明了 `group` 字段
- **THEN** 执行报错，不静默跳过

### Requirement: 引用不存在的 group 报错

run 中的 group 条目引用未定义的 group 时，执行 SHALL 报错并指明 group 名与所在 manifest 路径，MUST NOT 静默跳过。

#### Scenario: 未知 group

- **WHEN** `run` 含 `{ group: bar }` 而 `groups.bar` 未定义
- **THEN** 执行失败，错误信息包含 `bar`

### Requirement: 向下兼容

不含 `group` 字段的 run item SHALL 保持既有解析与执行行为不变；manifest 不含 `groups` 时 SHALL 正常执行。

#### Scenario: 旧格式 manifest

- **WHEN** manifest 的 `run` 仅含直接条目且无顶层 `groups`
- **THEN** 行为与引入 group 支持之前完全一致
