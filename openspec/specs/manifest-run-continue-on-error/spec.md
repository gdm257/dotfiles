# manifest run continue on error

run item 失败后可选择继续执行剩余 items：分层开关，item 字段优先于整批 var，继续模式下失败汇总并以非 0 退出。

## Purpose

控制 manifest 批量执行时 run item 失败后是否继续运行：分层开关，item 字段优先于整批 var，继续模式下失败汇总并以非 0 退出。

## Requirements

### Requirement: run item 支持 continue_on_error 字段
run item 声明 `continue_on_error: true` 时，该 item 命令失败后 SHALL 继续执行剩余 items；未声明或非 `true` 时 SHALL 保持失败即停。`continue_on_error` SHALL 仅作为 run item 自身字段（含 group 条目与组内条目），不参与 defaults 与 preset 回退解析。实现 SHALL 使用 bash 语法而非 Taskfile 的 `ignore_error` 字段。

#### Scenario: item 声明继续运行且失败
- **WHEN** 某声明 `continue_on_error: true` 的 run item 命令失败
- **THEN** 剩余 items 按原顺序继续执行

#### Scenario: 未声明时失败即停
- **WHEN** 未声明 `continue_on_error` 的 run item 命令失败
- **THEN** 立即中止，后续 items 不执行，退出码非 0

#### Scenario: 继续模式下的退出码
- **WHEN** 有声明继续运行的 item 失败且整批跑完
- **THEN** 输出失败汇总且退出码非 0；无失败时退出码为 0

### Requirement: 整批 var 开关与优先级
调用 `run:manifest` 传可选 var 为真时 SHALL 整批 items 失败后继续运行；run item 自身的 `continue_on_error` 字段 SHALL 优先于整批 var，未传 var 时 SHALL 视为不继续。

#### Scenario: 整批 var 开启
- **WHEN** 调用 `run:manifest` 传入整批继续 var
- **THEN** 所有 items 失败后继续运行，跑完后汇总失败并以非 0 退出

#### Scenario: item 字段反向覆盖整批 var
- **WHEN** 整批继续 var 已传，且某 item 声明 `continue_on_error: false`
- **THEN** 该 item 失败时立即中止，后续 items 不执行

#### Scenario: 未传整批 var 时 item 字段仍生效
- **WHEN** 未传整批 var，且某 item 声明 `continue_on_error: true`
- **THEN** 该 item 失败后继续执行剩余 items
