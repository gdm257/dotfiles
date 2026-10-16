# Manifest v2 declares resources, not commands: execution semantics move to the receiving task

manifest 的声明单元从 v1 的命令碎片（`entrypoint` / `command` / `args` 与 `presets` / `defaults` 覆盖链）改为资源 item：恰一个 `kind` 加开放声明字段（`elevated` / `state` / `version` 等）。引擎退化为通用迭代分发器——展开 groups、按声明序迭代、过滤 `enable` / `platforms`、把整个 item 原样透传给调用方指定的 task，零动词知识、零语义解释；kind 如何变成命令、提权与失败如何处理，全部由接收方 task 就地决定。动机：v1 把命令拼装知识铺在 presets / defaults / entrypoint 三层覆盖链里，混合 kind（跨平台单 manifest）与变体（sudo / msstore / disable）只能靠形状爆炸表达；资源模型把「机器上有什么」与「怎么装」分开，新 manager 只需新增一个接收方 task，引擎不再变更。

## Considered Options

- manifest 即 taskfile（取消声明/执行二分）：被否决——丢失声明与执行的分离：manifest 是数据，可被任何消费者校验与盘点；做成 taskfile 后与 go-task 语义耦合，混合 kind 又要回到在声明文件里写命令。
- 命令瘦身版（保留 run item 字段形状、仅外移命令组装）：被否决——声明单元仍是命令而非资源，「机器上有什么」依旧不可表达，变体仍需形状爆炸，只是把爆炸点挪了个位置。

## Consequences

- ADR-0001（零依赖）全额适用于 v2 引擎：解析 / 展开 / 过滤 / 透传全部以 bash builtins 与 Windows 自带命令实现。
- 命令碎片键的废除成为免费防呆：v1 manifest 误入 v2 引擎会因未知顶层键响亮报错，并存迁移期不会静默空跑。
- 提权 / 容错降为同一套声明字段（`elevated` / `continue_on_error`），引擎零 preset 知识；是否消费由接收方决定。
- kind 无中心注册表：约定 `<manager>-<resource>` 小写 kebab-case，值域合法性由接收方判断。
