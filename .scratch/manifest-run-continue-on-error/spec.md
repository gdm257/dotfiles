# manifest run continue on error

Status: ready-for-agent

## Problem Statement

manifest 体系执行一批 run item 时，Taskfile 默认行为是某个 run item 失败后立即中止，剩余 items 不再执行。但实际使用中有的 item 失败无关紧要（如清理脚本、可选的检查命令），用户希望失败后继续跑完剩余 items，同时不想丢失"有过失败"这一事实。

## Solution

`run:manifest` 支持"run item 失败后继续执行"的分层开关：

- 单个 run item 可声明固定字段 `continue_on_error: true`
- 调用 `run:manifest` 可传整批可选 var 控制所有 items
- run item 自身字段优先于整批 var（含反向覆盖：整批开启、单 item 关闭）
- 什么都不设置时保持现状——失败即停，完全向后兼容
- 继续模式下若有 item 失败，跑完后汇总失败并以非 0 退出码结束，不静默吞错

实现使用 bash 语法（`||` 收集失败 + 末尾统一退出），不使用 Taskfile 的 `ignore_error` 字段，因为该字段不支持插值。

## User Stories

1. As a dotfiles 使用者， I want 某 run item 声明 `continue_on_error: true` 后失败不中止整批, so that 无关紧要的 item 失败不会阻断重要 items 的执行
2. As a dotfiles 使用者， I want 调用 `run:manifest` 时传一个可选 var 让整批 items 失败后继续, so that 不修改 manifest 文件也能临时切换行为
3. As a dotfiles 使用者， I want run item 字段优先于整批 var, so that 整批继续运行时仍能把个别关键 item 标记为必须成功
4. As a dotfiles 使用者， I want 继续模式下最终退出码非 0 并汇总失败, so that 脚本化调用（CI、其他 task）能感知到有 item 失败
5. As a dotfiles 使用者， I want 不设置任何开关时行为与现在完全一致, so that 既有 manifest 与调用方式无需任何修改
6. As a dotfiles 使用者， I want group 条目与组内条目同样支持该字段, so that group 展开后的 items 与普通 run item 行为一致
7. As a dotfiles 使用者， I want 失败汇总信息可读（哪些 item 失败）, so that 排查时不需翻全量输出
8. As a dotfiles 使用者， I want 失败后继续运行的 item 依然按 manifest 顺序执行, so that 输出顺序可预测

## Implementation Decisions

- 修改 manifest 运行 task（`run` 与 `run:manifest`）的命令拼装与执行逻辑，全部在 Taskfile + bash 内实现，不引入外部脚本
- `continue_on_error` 仅作为 run item 自身字段，不参与 defaults 与 preset 回退解析（与 `enable` 字段的处理方式一致）
- run item 的命令在继续模式下通过 bash 语法（如 `||` 收集失败）实现容错，不使用 `ignore_error` 字段
- 继续模式下收集失败信息，整批跑完后输出汇总并以非 0 退出
- 整批开关通过调用 `run:manifest` 时传入的可选 var 实现，未传时视为不继续
- item 字段优先级高于整批 var

## Testing Decisions

- 只测外部行为：端到端调用 `run:manifest`，断言执行了哪些 items 与最终退出码，不测模板字符串的内部拼装
- 单一 seam：`task run:manifest MANIFEST=<fixture>`
- fixture manifest 使用必定失败的命令（如 `false`）构造失败场景
- Prior art: 仓库无测试框架，沿用 `manifests/` 下 fixture manifest 手工验证的惯例，验收以可重复执行的命令 + 预期输出为准

## Out of Scope

- 失败自动重试
- 并行执行 run items
- 修改 `enable`、group、preset 等既有字段语义
- 失败汇总的结构化输出格式（仅要求可读）

## Further Notes

- 分层粒度在访谈中确认：最细到单个 run item 固定字段，最粗到 `run:manifest` 整批
- 默认失败即停在访谈中明确确认，作为向后兼容的硬约束
