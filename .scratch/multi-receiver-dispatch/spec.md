# Spec: multi-receiver dispatch

Status: ready-for-agent

## Problem Statement

当前 dispatch 1 个 manifest 时只能指定一个 receiver，manifest 文件被迫按 receiver/kind 一切一份（~65 个文件），无法按应用域组织。

## Solution

`manifest:dispatch` 接受 `CALLS`（`<kind>=<task>` 逗号分隔路由映射），在展平阶段按 kind 过滤路由：一个 manifest 可混合任意 kind，每类 item 分发给对应 receiver。receiver 契约不变（所见必为自己 kind，否则 fail）。

## User Stories

1. As a dotfiles 维护者, I want 一个 manifest 文件混合多种 kind, so that 按应用域而非包管理器组织清单
2. As a dotfiles 维护者, I want 一次 dispatch 把不同 kind 的 item 路由到各自 receiver, so that 不必为每种 kind 写一条 dispatch 条目
3. As a dotfiles 维护者, I want 无人认领的 kind 计入失败汇总并 exit 1, so that 路由写错时响亮报错而非静默漏装
4. As a dotfiles 维护者, I want 同一 kind 被多个 receiver 认领时重复执行, so that 可以对同一批 item 做多种处理（如 install + replay 验证）
5. As a dotfiles 维护者, I want 失败语义复用现有 FAIL_LOG 机制, so that 多 receiver 批量失败时依旧得到末尾汇总
6. As a dotfiles 维护者, I want uninstall 侧同样以独立 CALLS 声明, so that 无隐式 install↔uninstall 派生魔法

## Implementation Decisions

- 路由模型：dispatch 阶段按 kind 过滤（receiver 只见自己的 item），非 receiver 自跳过——保留“异 kind 即 fail”的 receiver 自验证契约，路由错误在引擎侧暴露
- `CALL` 单任务 var 废除，改 `CALLS` 映射；无兼容层
- 迭代序：CALLS 映射声明序 × items 展开序，严格串行
- 失败复用 FAIL_LOG + continue_on_error + 末尾汇总 exit 1
- 同 kind 多认领允许重复执行，不检测
- 零依赖（ADR-0001）全额适用：bash builtins + Windows 自带命令 + Task 进程内模板
- taskfile.yaml 既有调用条目一次性迁移到 CALLS（breaking change 落地，无兼容层）
- 现有 ~65 个 manifest 文件不重组

## Testing Decisions

- 只测外部行为：以 fixture manifest 跑真实 `manifest:dispatch`，用现有 `echo:replay` 接收方回放 item，断言分发集合、顺序、失败汇总与退出码
- seam：现有最高 seam（引擎入口），不新增 seam
- 先例：仓库既有 manifest 引擎测试方式（echo:replay）

## Out of Scope

- ~65 个 manifest 文件的重组（机制交付即可，以后按需合并）
- 示范性混合 kind manifest（迁移后现有条目即验证）
- fallback 语义、并发、kind 中心注册表

## Further Notes

- OpenSpec delta：`openspec/changes/multi-receiver-dispatch/`（validate 已通过）
- kind 从“引擎仅校验存在”升级为“路由匹配字符串”，属对 ADR-0002 引擎零语义解释的延伸，由 ADR-0003 记录
