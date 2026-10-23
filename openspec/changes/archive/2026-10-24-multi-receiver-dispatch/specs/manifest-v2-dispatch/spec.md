# Spec Delta

## MODIFIED Requirements

### Requirement: 入口与 required vars

入口 task SHALL 为 `manifest:dispatch`，required vars 恰为 `MANIFEST`（manifest 文件路径）与 `CALLS`（kind→接收方 task 的路由映射，string，逗号分隔的 `<kind>=<task>` 条目；task 名可含 namespace）。`CALLS` 中各 task SHALL 运行期经 `task: '<task>'` 解析，指向不存在的 task 时干净报错。单 receiver 的旧 var `CALL` 废除（breaking change，调用方直接迁移）。入口名 MUST NOT 与 v1 `manifest:run` / `manifest:run:manifest` 碰撞（并存期 v1 任务名不动）。

#### Scenario: 标准调用

- **WHEN** 执行 `task manifest:dispatch MANIFEST=app-np.yaml CALLS="scoop-app=scoop:install, choco-app=choco:install"`
- **THEN** manifest 中 kind 为 `scoop-app` / `choco-app` 的幸存 items 分别逐个调用对应 task

#### Scenario: CALL 指向未知名

- **WHEN** `CALLS` 中某条目的 task 为不存在的 task 名
- **THEN** 报错指明未知名，而非静默跳过

### Requirement: 边界行为与零依赖

`items` 为空或全部被 platforms 过滤时 SHALL 静默 exit 0、不调用任何接收方。展开后幸存 item 的 kind 不在 `CALLS` 映射中时 SHALL 视为路由错误：记录该 item（错误消息含 manifest 路径与展开序号 `#N`），不调用任何接收方处理它。实现 SHALL 零依赖（ADR-0001 全额适用：bash builtins + Windows 自带命令 + Task 进程内模板）。

#### Scenario: 空批静默通过

- **WHEN** manifest 的 `items` 为空，或所有 item 被 `platforms` 过滤
- **THEN** dispatch 不调用任何接收方，exit 0

#### Scenario: 无人认领的 kind 报错

- **WHEN** 某 item 的 kind 未出现在 `CALLS` 映射中
- **THEN** 该 item 计入失败汇总，dispatch 以非 0 退出，其余 items 照常分发

### Requirement: 引擎职责四步与传播

引擎 SHALL 恰好执行解析（未知顶层键 fail）、展开（`items` 声明序、group 展开、引用条目非保留字段通用下传）、过滤（`platforms`，三层一致；再按 `CALLS` 映射的 kind 路由分发）、透传（幸存 item 整 map 原样交接收方）。引用条目 platforms 不匹配即整组跳过。引擎 MUST NOT 持有动词知识、解释字段语义或点名任何声明字段：kind 仅作路由匹配的字符串，值域与字段语义一概不碰。

#### Scenario: 迭代严格串行按展开序

- **WHEN** `CALLS` 为 `[A, B]` 且展开后 A、B 各有幸存 items
- **THEN** 先按声明序跑完 A 的全部 items，再跑 B 的，无并发

#### Scenario: 下传字段照常透传

- **WHEN** 引用条目声明某非保留字段且组内成员未声明该字段
- **THEN** 成员透传时携带该字段值，接收方自行解释

## ADDED Requirements

### Requirement: 同一 kind 多接收方允许重复执行

同一 kind 在 `CALLS` 中出现多条映射条目时 SHALL 允许：匹配该 kind 的每个 item 按映射声明序逐个分发给每个声明的接收方，引擎 MUST NOT 去重或检测。接收方契约不变：所见 item 必为自己的 kind，否则 fail。

#### Scenario: 重复认领重复执行

- **WHEN** `CALLS="scoop-app=scoop:install, scoop-app=echo:replay"` 且有一个 `scoop-app` item
- **THEN** 两个接收方各执行该 item 一次，共两次

#### Scenario: 接收方收到异 kind 仍 fail

- **WHEN** 因路由缺陷某接收方收到非自己 kind 的 item
- **THEN** 接收方按既有自验证语义 fail，引擎不兜底
