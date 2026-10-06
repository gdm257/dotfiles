# manifest run item enable

让 manifest 的 run item（含 group 条目与组内条目）支持 `enable: false` 跳过，便于临时禁用个别条目而不删除。

## Purpose

控制 manifest 中单个 run item 及 group 条目的执行开关：声明 `enable: false` 时静默跳过，默认执行。

## Requirements

### Requirement: run item 支持 enable 字段
run item 声明 `enable: false` 时 SHALL 被跳过不执行；未声明或为 `true` 时 SHALL 正常执行。`enable` SHALL 仅作为 run item 自身字段，不参与 defaults 与 preset 回退解析。值不做类型校验，未声明或非 `false` 时视为启用。

#### Scenario: 单个 run item 被禁用
- **WHEN** manifest 的 `run` 列表中某条目声明 `enable: false`
- **THEN** 该条目被静默跳过，其余条目正常执行

#### Scenario: 未声明 enable
- **WHEN** run item 未声明 `enable`
- **THEN** 条目按既有解析与执行行为运行

### Requirement: group 条目与组内条目支持 enable
`run` 列表中的 group 条目（`{ group: <name> }`）声明 `enable: false` 时 SHALL 跳过整组；`groups.<name>` 内的单个条目声明 `enable: false` 时仅跳过该条目，组内其余条目正常执行。两者独立生效，无继承。

#### Scenario: group 条目整体禁用
- **WHEN** `run` 中的 group 条目声明 `enable: false`
- **THEN** 该组所有条目均不执行，且不触发未知 group 校验以外的报错

#### Scenario: 组内单条禁用
- **WHEN** `groups.<name>` 内某条目声明 `enable: false`
- **THEN** 仅该条目被跳过，组内其余条目正常执行
