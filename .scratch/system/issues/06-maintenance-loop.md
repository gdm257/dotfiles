# maintenance-loop: 日常维护循环骨架

Type: grilling
Status: resolved
Blocked by: 03

## Question

维护阶段的骨架：触发方式（计划任务 / 手动 task 命令 / 二者并存）、覆盖内容（应用更新、驱动更新、配置漂移修复）、与开箱即用各阶段共用哪些模块。驱动更新机制（驱动总裁产物 → 已有系统 DriverStore 增量更新）在此定稿后从 fog 毕业。

## Answer

- 触发：仅手动 task 命令（`system:maintenance:run`），无计划任务；将来要自动化时再加一条 schtask 包装同一入口。
- 覆盖 = 配置漂移修复：维护命令重放 Windows 上全部 `manifests:*:install` 任务（不新增聚合选择机制、不用 Group 挑选），靠 Receiver 幂等收敛，被手动改掉的 item 恢复声明状态。维护与 audit 在机器级配置上是同一个动作（同一套 manifest 引擎）。
- 应用更新（winget/scoop update kind）本轮不做：更新交给各包管理器自身机制，体系不加 update 语义。
- 驱动更新不进体系：驱动总裁产物 → DriverStore 的增量导入不做，交给 Windows Update / 驱动总裁自身（Out of scope）。
- 边界确认：维护循环只管机器级；per-user 刷新只在 05 号票定的 logon 计划任务里发生。
- scoop update / Windows Update / 系统清理均不进维护循环。

## Answer

- 触发：仅手动 task 命令（`system:maintenance:run`），无计划任务；将来要自动化时再加一条 schtask 包装同一入口。
- 覆盖 = 配置漂移修复：维护命令重放 Windows 上全部 `manifests:*:install` 任务（不新增聚合选择机制、不用 Group 挑选），靠 Receiver 幂等收敛，被手动改掉的 item 恢复声明状态。维护与 audit 在机器级配置上是同一个动作（同一套 manifest 引擎）。
- 应用更新（winget/scoop update kind）本轮不做：更新交给各包管理器自身机制，体系不加 update 语义。
- 驱动更新不进体系：驱动总裁产物 → DriverStore 的增量导入不做，交给 Windows Update / 驱动总裁自身（Out of scope）。
- 边界确认：维护循环只管机器级；per-user 刷新只在 05 号票定的 logon 计划任务里发生。
- scoop update / Windows Update / 系统清理均不进维护循环。
