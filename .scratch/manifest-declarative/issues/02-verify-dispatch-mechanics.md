# 02: 本地验证 item 透传的未背书组合

Type: research
Status: resolved

## Question

go-task v3.54.0 文档未逐字背书、但新引擎透传契约依赖的三个组合，用最小 fixture taskfile 本地实测（在 ADR-0001 零依赖约束内，仅 task + bash）：

1. `for: {var: ITEMS, as: ITEM}` 循环内 `task:` 调用的 `vars` 中 `ref: .ITEM` 整 map 透传（不被字符串化）。
2. 备选形态：item 以 `toJson` 字符串传递、接收方 `ref: 'fromJson .ITEM_JSON'` 还原。
3. 裸（非 for）`task: '{{.CALL}}'` 动态任务名解析。

实测结论写入本票 Answer（含 fixture 位置与 `task --version` 输出），供 04 引擎契约直接引用；组合不可行时给出最小可行替代并记录。

## Answer

research subagent 实测完成（task v3.54.0，Windows + git-bash）。fixture 见 [research/dispatch-fixture/](../research/dispatch-fixture/)，完整结论与 gotchas 见 [research/dispatch-fixture-findings.md](../research/dispatch-fixture-findings.md)。判定：

1. **Combo A（`for` + `task` vars 里 `ref: .ITEM` 整 map 透传）不可用**：ref 求值上下文不含循环变量，receiver 报 `nil pointer evaluating interface {}.name`；字符串形态 `"{{.ITEM}}"` 被字符串化；不传 vars 时循环变量也不自动透传。现行引擎的 `map:` 形态可用但叶子全部退化为 string（`sudo: false` 裸 `if` 判真的实测陷阱）。
2. **Combo B（`toJson` 字符串 + receiver `ref: 'fromJson .ITEM_JSON'`）可用**：map 保真，嵌套键访问、true/false/missing 布尔判断、`toJson` round-trip 全部正确。
3. **Combo C（裸 `task: '{{.CALL}}'` 动态任务名）可用**：运行期从 var 解析，含 namespaced 目标（`ns:hello`）；未知名干净报错（exit 200）。

结论：新引擎透传契约采用 Combo B 形态（唯一类型保真的整 map 透传）；动态派发名可直接用 manifest/调用方 var 决定目标 task；`map:` 仅限纯 string 字段且 bool 必须以字符串比较。实现级最大坑：cmds 里 `{{.V}}` 后跟 `: ` 会让整个 taskfile YAML 解析失败，此类命令必须整体引号包裹。
