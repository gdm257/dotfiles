# 02: run:manifest 整批 var 开关

**What to build:** 调用 `run:manifest` 传可选 var（如 `CONTINUE_ON_ERROR=true`）时整批 items 失败后继续运行；run item 自身的 `continue_on_error` 字段优先于整批 var，含反向覆盖（整批继续、单 item 关闭后失败即中止）。未传 var 时行为与 ticket 01 完成后一致。

**Blocked by:** 01 (run item 级 continue_on_error 字段)

**Status:** ready-for-agent

- [ ] 传整批 var 时所有 items 失败后继续，最终汇总失败并以非 0 退出
- [ ] 未传 var 时行为与既有（默认失败即停 / item 字段控制）一致
- [ ] item 声明 `continue_on_error: false` 可在整批继续模式下对该 item 恢复失败即停
- [ ] item 声明 `continue_on_error: true` 在未传整批 var 时仍继续（ticket 01 行为不受影响）
- [ ] 端到端验证两种优先级方向
