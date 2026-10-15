# 01: go-task v3.54.0 动态分发能力事实核查

Type: research
Status: resolved

## Question

新引擎按调用方指定的 task 对每个 item 分发（`task:` 字段运行期模板化）、整 map 透传（`for` + `ref:`）、以及 wildcard 任务名替换手写 wrapper 的可行性，需要以官方文档/源码级事实确认，作为引擎契约设计的前提。

## Answer

绘图阶段 grilling 中由 research subagent 完成（锚定版本 v3.54.0，2026-10-01 发布），完整事实清单见 [research/gotask-v3.54-facts.md](../research/gotask-v3.54-facts.md)。要点：

- `cmds` 内 `task:` 字段是运行期模板，官方文档明文支持（loops 篇 "template the task name itself"）；`task: "{{.ITEM.kind}}:{{...}}"` 类按 item 路由机制成立。
- `for: {var, as}` + `task` + `vars` 是文档化一等公民；map 逐键取值有官方背书，整 map 传递用 `ref:`（个别组合未逐字背书，转 02 本地实测）。
- `includes` 不支持 glob（#1678 仍 open）；wildcard 任务名（v3.35.0+，`.MATCH` 捕获）与 wildcard include key 是动态入口的替代路径。
- status / sources / preconditions、退出码表、slim-sprig 函数清单齐备；收敛式实现可纯用原生机制。
- `ref` 是 vars YAML 级关键字而非模板函数；模板引擎为 Task 维护的 slim-sprig fork，非完整 sprig。
