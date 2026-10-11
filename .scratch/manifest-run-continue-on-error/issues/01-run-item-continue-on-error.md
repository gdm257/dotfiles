# 01: run item 级 continue_on_error 字段

**What to build:** run item 声明 `continue_on_error: true` 时，该 item 命令失败后继续执行剩余 items；整批跑完后汇总失败并以非 0 退出码结束。用 bash 语法（`||` 收集失败 + 末尾统一退出）实现，不使用 `ignore_error`。字段仅作 run item 自身字段，不参与 defaults 与 preset 回退解析。group 条目与组内条目同样支持。

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] run item 声明 `continue_on_error: true` 且失败时，后续 items 仍按顺序执行
- [ ] 未声明该字段的 item 失败时行为不变：立即中止，退出非 0
- [ ] 继续模式下若有失败，最终输出失败汇总且退出码非 0
- [ ] 继续模式下无失败时退出码为 0
- [ ] group 条目与组内条目声明的字段同样生效
- [ ] 端到端验证：`task run:manifest MANIFEST=<fixture>`，fixture 含必定失败的命令
