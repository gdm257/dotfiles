# 04: 引擎分发契约定稿

Type: grilling
Status: resolved
Blocked by: 02

## Question

通用迭代分发器的任务契约定稿（产出 detail file `details/engine.md`）：

- 入口 task 形态与命名（如 `manifest:run MANIFEST=<path> CALL=<task>`；CALL 的最终命名）。
- 引擎职责边界：展开 groups、按序迭代、过滤 enable/平台、整 item 原样透传——除此之外零语义（选择归引擎，语义归接收方 task）。
- item 透传的 var 形态：02 实测已定为 `toJson` + `ref: 'fromJson .ITEM_JSON'`（`ref: .ITEM` 整 map 在 for+task vars 中不可用，`map:` 形态叶子退化为 string）；本票确认接收方可依赖的稳定契约面（是否提供 KIND 等便捷变量（通用 ID 已在 03 否决）、缺失键语义、bool 只能经 JSON 通道保真）。
- 失败语义：容错字段如何到达接收方；引擎是否只提供基础设施（如失败日志路径 var）而由接收方 task 自行决定消费——与"引擎零语义解释"原则自洽。
- 结构错误报错面：未知 group、坏 kind 等沿用现有 `fail` 模式，错误信息含 manifest 路径。
- 混合 kind manifest 由接收方 task 自行按 `{{.ITEM.kind}}` 路由的示例写法（说明性示例，非规范）。
- 实现约束：ADR-0001 零依赖（bash builtins + Windows 自带命令 + Task 进程内模板）。

## Answer

一轮 grilling（7 问，均按推荐确认）定稿，全文见 [details/engine.md](../details/engine.md)：

1. **入口**：`manifest:dispatch`，required vars `MANIFEST` + `CALL`（排除 `TASK` 撞名；不与 v1 `manifest:run` / `run:manifest` 碰撞，v2 文件放置归 07）。
2. **职责边界**：解析 → 展开 groups（引用条目 `continue_on_error` 字段传播、未知/嵌套 group fail）→ 过滤 enable/platforms（三层一致）→ 整 item 透传；此外零语义。
3. **透传契约面**：唯一 item var `ITEM_JSON`（toJson 字符串），接收方 `ref: 'fromJson .ITEM_JSON'` 还原（约定名 `ITEM`）；无便捷 var（`KIND` / `MANIFEST` 均不做）；缺失键归接收方 `hasKey` / `default`；bool 保真仅此通道。
4. **失败语义**：引擎仅基础设施——传 `FAIL_LOG`（固定路径、开头 truncate、结尾非空汇总 + exit 1）；`continue_on_error` 与批量开关全部接收方消费；fail-fast 免费。
5. **结构错误**：v1 `fail` 模式 + manifest 路径 + 展开序号 `#N`；新增未知顶层键 / 缺 kind / 非 map / platforms 值域外模板；platforms 严格校验（typo 即 fail，与未知 group 同哲学）。
6. **边界行为**：空批或全过滤 = 静默 exit 0；严格串行；混合 kind 路由示例入 engine.md Receiver Playbook（非规范）。
7. **实现约束**：ADR-0001 全额适用；02 实测坑（`{{.V}}` 后接 `: ` 的 YAML 陷阱、`map:` bool 陷阱）入 engine.md Implementation Notes。
