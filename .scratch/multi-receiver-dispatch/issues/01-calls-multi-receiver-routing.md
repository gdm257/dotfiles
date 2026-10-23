# 01: dispatch 引擎支持 CALLS 多接收方路由

**What to build:** `manifest:dispatch` 接受 `CALLS`（`kind=task` 逗号映射），按 kind 路由分发：混合 kind 的 manifest 一次 dispatch 到多个 receiver；无人认领 kind 计入 `FAIL_LOG` 汇总并 exit 1；同 kind 重复认领重复执行；`CALL` var 移除。用 fixture manifest + `echo:replay` 验证路由、顺序、失败语义。

**Blocked by:** None (can start immediately)

**Status**: done

- [x] `CALLS="kind-a=task-a, kind-b=task-b"` 时各 kind 的幸存 item 只分发给对应 receiver
- [x] manifest 中出现映射表外的 kind → 计入失败汇总、exit 1、其余 item 照常分发
- [x] 同一 kind 多条映射 → item 对每个认领 receiver 各执行一次
- [x] 迭代严格串行：映射声明序 × items 展开序
- [x] `CALLS` 含不存在的 task 名 → 干净报错指明未知名
- [x] 空批/全被 platforms 过滤 → 静默 exit 0
- [x] `CALL` var 不再存在
- [x] 失败语义复用 FAIL_LOG（truncate 开头、末尾汇总、exit 1）
- [x] 零依赖：bash builtins + Windows 自带命令 + Task 模板，无 coreutils
