# manifest-v2-dispatch Specification

## Purpose

定义 `manifest:dispatch` 引擎契约：required vars、解析 / 展开 / 过滤 / 透传四步职责、`ITEM_JSON` 唯一透传通道、`FAIL_LOG` 失败语义、结构错误消息规范与边界行为。引擎零动词知识、零语义解释。

## Requirements

### Requirement: 入口与 required vars

入口 task SHALL 为 `manifest:dispatch`，required vars 恰为 `MANIFEST`（manifest 文件路径）与 `CALLS`（kind→接收方 task 的路由映射，string，逗号分隔的 `<kind>=<task>` 条目；task 名可含 namespace）。`CALLS` 中各 task SHALL 运行期经 `task: '<task>'` 解析，指向不存在的 task 时干净报错。单 receiver 的旧 var `CALL` 废除（breaking change，调用方直接迁移）。

#### Scenario: 标准调用

- **WHEN** 执行 `task manifest:dispatch MANIFEST=<manifest> CALLS="<kind-a>=<task-a>, <kind-b>=<task-b>"`
- **THEN** manifest 中 kind 为 `<kind-a>` / `<kind-b>` 的幸存 items 分别逐个调用对应 task

#### Scenario: CALL 指向未知名

- **WHEN** `CALLS` 中某条目的 task 为不存在的 task 名
- **THEN** 报错指明未知名，而非静默跳过

### Requirement: ITEM_JSON 唯一透传通道

引擎向 `CALL` 传 item 数据 SHALL 仅经 `ITEM_JSON`（string，`toJson` 产物）；接收方以 `ref: 'fromJson .ITEM_JSON'` 还原（约定绑定名 `ITEM`）后类型保真访问。引擎 MUST NOT 提供任何便捷 var（如 `KIND`）；缺失键由接收方以 `hasKey` / `default` 自理（fromJson 后未声明键得 `<no value>`，引擎不归一化、不补默认）。接收方 MUST NOT 以 `map:` / 字符串化形态判 bool。

#### Scenario: bool 类型保真

- **WHEN** item 声明某声明字段 `k: true`，接收方 `fromJson` 还原后访问 `.ITEM.k`
- **THEN** 得到 bool true，可直接用于模板判断

#### Scenario: 未声明键由接收方自理

- **WHEN** item 未声明 `k`，接收方模板访问 `.ITEM.k`
- **THEN** 得 `<no value>`，接收方以 `default` / `hasKey` 兜底，引擎不介入

### Requirement: FAIL_LOG 失败语义

引擎 SHALL 向 `CALL` 传基础设施 var `FAIL_LOG`（固定路径复用文件，每次 dispatch 开头 truncate）。接收方 cmd 失败不吞时 `CALL` 失败、迭代立即中止（fail-fast）。引擎 MUST NOT 消费任何声明字段：容忍失败与批量级开关归接收方自行包装（写 `FAIL_LOG` 并吞退出码）。dispatch 收尾 `FAIL_LOG` 非空 SHALL 打印 failed items 汇总并 exit 1。接收方不经 dispatch 独立调用时无 `FAIL_LOG`，MUST 自行降级。

#### Scenario: 未容忍的失败立即中止

- **WHEN** 某 item 的 `CALL` 执行失败且接收方未吞错
- **THEN** 迭代立即中止，后续 items 不执行，退出码非 0

#### Scenario: 收尾汇总失败

- **WHEN** 接收方将失败 item 写入 `FAIL_LOG` 后整批跑完
- **THEN** dispatch 末尾打印 failed items 汇总并以 exit 1 结束

#### Scenario: 无失败正常退出

- **WHEN** 全部 items 成功，`FAIL_LOG` 为空
- **THEN** dispatch 静默 exit 0

### Requirement: 结构错误消息含路径与序号

结构错误（未知顶层键、未知或嵌套 group、item 缺 kind 或非标量、items 元素非 map、platforms 值域外）SHALL fail，错误消息 MUST 含 manifest 路径与展开序号 `#N`（1-based，展开后序列中的位置）。

#### Scenario: items 元素非 map

- **WHEN** `items` 中某元素为纯字符串
- **THEN** fail 消息含 `item #<N> not a map` 与 manifest 路径

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

### Requirement: 同一 kind 多接收方允许重复执行

同一 kind 在 `CALLS` 中出现多条映射条目时 SHALL 允许：匹配该 kind 的每个 item 按映射声明序逐个分发给每个声明的接收方，引擎 MUST NOT 去重或检测。接收方契约不变：所见 item 必为自己的 kind，否则 fail。

#### Scenario: 重复认领重复执行

- **WHEN** `CALLS` 中同一 kind 映射到两个 task 且有一个该 kind 的 item
- **THEN** 两个接收方各执行该 item 一次，共两次

#### Scenario: 接收方收到异 kind 仍 fail

- **WHEN** 因路由缺陷某接收方收到非自己 kind 的 item
- **THEN** 接收方按既有自验证语义 fail，引擎不兜底
