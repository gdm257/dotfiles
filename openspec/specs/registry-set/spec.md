# registry-set Specification

## Purpose

让 registry/HKLM 类机器设置以 Manifest item 声明（kind `registry:set`），经既有 dispatch → Receiver 路由收敛到声明值，与活机维护共用同一套幂等语义。

## Requirements

### Requirement: registry item 收敛写入

Receiver SHALL 将 `registry:set` item 声明的注册表值写入生效；重跑 MUST 幂等（结果一致）；item 声明值与实际值不一致时重跑 MUST 拉回声明值。

#### Scenario: 首次写入

- **WHEN** 目标注册表值不存在或与声明不一致
- **THEN** Receiver 将其写为声明值

#### Scenario: 幂等重跑

- **WHEN** 值已是声明值时重跑
- **THEN** 无变更发生，结果与上次一致

#### Scenario: 漂移修复

- **WHEN** 值被手动改掉后重跑
- **THEN** 值恢复为 manifest 声明值

### Requirement: 引擎路由不变

`registry:set` SHALL 走既有 Manifest 引擎路由：item 缺 kind、kind 未知等校验与 unclaimed 报错行为与其他 kind 完全一致；引擎与 dispatch 不因本 kind 改变。

#### Scenario: 未知 kind 仍报 unclaimed

- **WHEN** manifest 中出现 dispatch 未声明接收的 kind
- **THEN** 引擎按既有行为报 unclaimed 并失败退出
