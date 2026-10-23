# Dispatch routes items to receivers by kind at the engine, receivers never self-skip

`manifest:dispatch` 接受 `CALLS`（`<kind>=<task>` 逗号分隔映射），在展平阶段按 kind 过滤路由：混合 kind 的 manifest 一次 dispatch 到多个 receiver。kind 不匹配的处理选择 dispatch 阶段过滤，而非把全部 item 透传、receiver 自行跳过——receiver 契约（所见必为自己 kind，否则 fail）保持不变，路由写错（manifest 中出现无人认领的 kind）在引擎侧计入失败汇总并 exit 1，而非静默漏装或改写 ~35 个 receiver 模板。同一 kind 被多个 receiver 认领时允许重复执行，不做去重检测。

## Considered Options

- receiver 自跳过（dispatch 透传全部 item，receiver 对异 kind 静默跳过）：被否决——需改写全部 receiver 模板，且"异 kind 即 fail"的自验证降级后，路由错误从响亮失败变为静默漏装。
- fallback 语义（按序尝试、首个成功生效）：被否决——与 kind 自认领模型冲突，dotfiles 场景无此需求。

## Consequences

- kind 从「引擎仅校验存在性」升级为「路由匹配字符串」：这是对 ADR-0002「引擎不点名声明字段」的延伸，kind 属于引擎可消费的保留键封闭集合（`kind` / `platforms` / `group`），引擎仍不校验值域、不解释字段语义。
- `CALL` 单任务 var 废除（breaking change），uninstall 侧以独立 `CALLS` 声明，无 install↔uninstall 自动派生。
- manifest 文件不再被迫按 receiver 一切一份，可按应用域混合组织；现有文件的重组按需渐进进行。
