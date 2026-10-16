# manifest-v2-dispatch Specification

## Purpose

定义 `manifest:dispatch` 引擎契约：required vars、解析 / 展开 / 过滤 / 透传四步职责、`ITEM_JSON` 唯一透传通道、`FAIL_LOG` 失败语义、结构错误消息规范与边界行为。引擎零动词知识、零语义解释。

## Requirements

### Requirement: 入口与 required vars

入口 task SHALL 为 `manifest:dispatch`，required vars 恰为 `MANIFEST`（manifest 文件路径）与 `CALL`（接收方 task 名，可含 namespace）。`CALL` SHALL 运行期经 `task: '{{.CALL}}'` 解析，指向不存在的 task 时干净报错。入口名 MUST NOT 与 v1 `manifest:run` / `manifest:run:manifest` 碰撞（并存期 v1 任务名不动）。

#### Scenario: 标准调用

- **WHEN** 执行 `task manifest:dispatch MANIFEST=app-np.yaml CALL=scoop:apply`
- **THEN** manifest 幸存 items 逐个调用 `scoop:apply`

#### Scenario: CALL 指向未知名

- **WHEN** `CALL` 为不存在的 task 名
- **THEN** 报错指明未知名，而非静默跳过

### Requirement: 引擎职责恰好四步

引擎 SHALL 恰好执行解析（未知顶层键 fail）、展开（`items` 声明序、group 展开、`continue_on_error` 传播）、过滤（`enable` / `platforms` 三层一致）、透传（幸存 item 整 map 原样交 `CALL`）。`enable: false` 静默跳过；引用条目不匹配即整组跳过。引擎 MUST NOT 持有动词知识或解释字段语义：kind 值域、字段含义、命令拼装一概不碰。

#### Scenario: 迭代严格串行按展开序

- **WHEN** 展开后幸存 items 为 [a, b, c]
- **THEN** 按此顺序逐个调用 `CALL`，无并发

#### Scenario: enable false 静默跳过

- **WHEN** 某 item 声明 `enable: false`
- **THEN** 该 item 不调用 `CALL`，也不报错

### Requirement: ITEM_JSON 唯一透传通道

引擎向 `CALL` 传 item 数据 SHALL 仅经 `ITEM_JSON`（string，`toJson` 产物）；接收方以 `ref: 'fromJson .ITEM_JSON'` 还原（约定绑定名 `ITEM`）后类型保真访问。引擎 MUST NOT 提供任何便捷 var（如 `KIND`）；缺失键由接收方以 `hasKey` / `default` 自理（fromJson 后未声明键得 `<no value>`，引擎不归一化、不补默认）。接收方 MUST NOT 以 `map:` / 字符串化形态判 bool。

#### Scenario: bool 类型保真

- **WHEN** item 声明 `elevated: true`，接收方 `fromJson` 还原后访问 `.ITEM.elevated`
- **THEN** 得到 bool true，可直接用于模板判断

#### Scenario: 未声明键由接收方自理

- **WHEN** item 未声明 `version`，接收方模板访问 `.ITEM.version`
- **THEN** 得 `<no value>`，接收方以 `default` / `hasKey` 兜底，引擎不介入

### Requirement: FAIL_LOG 失败语义

引擎 SHALL 向 `CALL` 传基础设施 var `FAIL_LOG`（固定路径复用文件，每次 dispatch 开头 truncate）。接收方 cmd 失败不吞时 `CALL` 失败、迭代立即中止（fail-fast）。引擎 MUST NOT 消费 `continue_on_error`：容忍失败与批量级开关归接收方自行包装（写 `FAIL_LOG` 并吞退出码）。dispatch 收尾 `FAIL_LOG` 非空 SHALL 打印 failed items 汇总并 exit 1。接收方不经 dispatch 独立调用时无 `FAIL_LOG`，MUST 自行降级。

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

`items` 为空或全部被过滤时 SHALL 静默 exit 0、不调用 `CALL`。实现 SHALL 零依赖（ADR-0001 全额适用：bash builtins + Windows 自带命令 + Task 进程内模板）。

#### Scenario: 空批静默通过

- **WHEN** manifest 的 `items` 为空，或所有 item 被 `enable` / `platforms` 过滤
- **THEN** dispatch 不调用 `CALL`，exit 0
