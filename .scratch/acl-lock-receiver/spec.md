Status: implemented

# acl-lock receiver：流氓软件目录锁定

## Problem Statement

流氓软件（如 AlibabaProtect）会在固定目录重新落盘。已实测可行的手工配方：禁继承并清空全部 ACE、只留 SYSTEM + Administrators ReadAndExecute、owner 改 SYSTEM。手工重复执行费时，且重装后需要一条命令重建防线。

## Solution

沿用 Manifest/Receiver 体系：新增 kind `acl-lock` 的 manifest items 只声明 `path`，receiver `acl:lock` 以固定配方幂等锁定该目录。管理员运行 `task manifests:lockdown:apply` 一次即完成全部清单内目录的锁定。

## User Stories

1. As a 重装系统的用户, I want 在 manifest 中声明要锁死的目录路径, so that 重装后一条命令重建防线。
2. As a 用户, I want 锁定配方固定不可配置（清空 ACE + SYSTEM/Admins 只读 + owner SYSTEM）, so that 行为可预测、fixture 可验证。
3. As a 用户, I want receiver 幂等（已锁定的目录重复运行静默跳过）, so that 我可以放心反复运行。
4. As a 用户, I want 非管理员或路径缺失（不存在或非目录）时响亮失败, so that 静默失效不被掩盖。

## Implementation Decisions

- kind 为 `acl-lock`；receiver 为 `acl:lock`（单向 apply，无反方向 receiver，沿 acl:apply 先例）。
- item schema：`path`（必填）与 `create`（可选，默认 false）；无 `state`、无 `grants`、无 `recursive`——单一隔离动词，权限内容不可配置。`create: true` 为声明式逐层创建：缺失目录先经 `[System.IO.Directory]::CreateDirectory` 建出再锁定（已存在时 no-op），且跳过路径守卫；缺省时路径缺失仍响亮失败。
- 固定配方（powershell，ADR-0001 允许的例外命令；principal 用 SID，规避本地化名称）：
  - `SetAccessRuleProtection($true, $false)` 断继承且不保留副本；
  - 移除全部现有 ACE；
  - 加 `S-1-5-18`（SYSTEM）与 `S-1-5-32-544`（Administrators）的 ReadAndExecute（ContainerInherit,ObjectInherit）；
  - owner 改 `S-1-5-18`。
- 幂等方式：读-比-跳过——目录已收敛（protected + owner SYSTEM + ACE 恰为 SYSTEM/Admins 两条 ReadAndExecute Allow）时静默跳过；否则应用配方。与 acl:apply 的无条件执行不同：锁定后无人有 WRITE_DAC，重复 Set-Acl 必失败，读-比-跳过是幂等的唯一可行路径。
- 仅顶层应用：子项靠 OI/CI 继承传播；已有 protected 的后代不受影响。
- 清单文件 `manifests/lockdown.yaml`；顶层 wrapper 任务 `manifests:lockdown:apply`，platforms 限 windows，CALLS 路由 `acl-lock=acl:lock`。
- receiver 对齐既有 receiver 模板：`ITEM_JSON` 单通道输入、kind 自验证、continue_on_error 包装。例外：FAIL_LOG 行记录 `failed: acl:lock <path>` 而非内嵌全量 cmd——cmd 内嵌进双引号 echo 后，嵌套引用与 `$( )` 引用错位使路径中的括号落入命令位，mvdan/sh 解析崩溃。
- 恢复（解锁）不进体系：管理员手工 takeown + icacls /reset，罕见且不可自动化审计。

## Testing Decisions

- 复用 `fixtures/manifest-dispatch/check-receivers.sh`：dry-run 断言命令拼装（配方各步骤、admin/路径守卫、converge 跳过分支）与 kind 自验证；实跑断言 continue_on_error 写 FAIL_LOG。
- ACL 真实生效验证（需要管理员 + 真实文件系统）不进 fixture，作为一次性手工验收步骤。

## Out of Scope

- 服务/计划任务清理（`sc delete`、`Disable-ScheduledTask` 等）——一次性手工操作，非幂等收敛。
- 解锁/反方向 receiver。
- 通用 ACL 配置能力（`acl:apply` 的领域）。
- 以 continue_on_error 容忍路径缺失——缺失即声明 `create: true` 建目录，失败不容忍。

## Further Notes

- 共识来自 interview-me 会话：单一隔离动词、ACL-only、单向、无初始填充逐轮确认。
