Status: ready-for-agent

# acl-path receiver：基于 manifest items 的 Windows 权限修复

## Problem Statement

我经常重装 Windows 系统。D 盘让我可以跨系统复用数据，但每次重装后用户 SID 变化，D 盘上旧账户的 ACE 变成孤立 SID，新用户对部分目录无权访问。目前只能手工 takeown/icacls 逐个修复，费时且容易遗漏。

## Solution

沿用现有 Manifest/Receiver 体系：新增 kind `acl-path` 的 manifest items 声明各路径的期望 owner 与授权，新增 receiver `acl:apply` 幂等地收敛这些路径的 ACL。重装系统后以管理员身份运行一次 `task manifests:permissions:apply` 即完成全部受管路径的权限修复。

## User Stories

1. As a 重装系统的用户, I want 在 manifest 中声明任意路径的期望 owner, so that 重装后一条命令把所有受管路径的 owner 收敛到新用户。
2. As a 重装系统的用户, I want 在 manifest 中按 principal 分别声明授权（含 SID）, so that 重装后按清单恢复各路径的访问权限。
3. As a 重装系统的用户, I want 对指定路径可选地重置 ACL 继承, so that 清除旧 SID 残留的脏 ACL 并恢复从父目录继承。
4. As a 重装系统的用户, I want 递归修复整棵子树且完全跳过显式禁用继承的后代目录, so that 既修干净正常路径又不破坏有意保护的特殊目录。
5. As a 用户, I want receiver 不做任何隐式授权，一切以 item 显式声明为准, so that 权限的 source of truth 唯一且可审计。
6. As a 用户, I want 非管理员运行时得到清晰的失败提示, so that 我知道需要用管理员终端重跑。
7. As a 用户, I want 路径不存在时响亮失败, so that manifest 写错或目录缺失不被静默掩盖。
8. As a 用户, I want 单个 item 失败可通过 continue_on_error 容忍, so that 批量修复不被个别路径卡死。
9. As a 用户, I want receiver 幂等（重复执行无副作用）, so that 我可以放心反复运行。

## Implementation Decisions

- kind 为 `acl-path`；receiver 为 `acl:apply`（单向 apply，无反方向 receiver）。
- item schema（开放字段由 receiver 解释，遵守 manifest-v2-schema）：
  - `path`（必填）：目标路径；
  - `recursive`（可选，默认 false）：递归整棵子树；
  - `owner`（可选）：user/group 名或 SID，原样传给 takeown；递归时含子树；
  - `inheritance`（可选，默认 no-op）：声明 `reset` 时重置为从父目录继承；未知值响亮失败；
  - `grants`（可选）：每项为 `principal:perms` 的 icacls 原生语法字符串，一条 icacls 命令批量 grant；每项必须含 `:` 否则响亮失败。
- 不引入 `state` 字段：acl-path 只有单一收敛方向，无反方向语义。
- 无隐式授权：`grants` 缺省时不执行任何 grant；纯 `owner` item 合法。
- 执行顺序：前置校验（管理员、路径存在、字段校验）→ takeown → inheritance reset（仅顶层路径）→ icacls grant（recursive 时 `/t /c`）。
- protected（显式禁用继承）后代目录在递归时完全跳过（ACL 不动、不 grant）；顶层路径自身为 protected 且未声明 `inheritance: reset` 时，正常处理 owner/grants 但不动继承、不跳过。
- 幂等方式：无条件执行（icacls/takeown 重复执行无累积副作用），不读-比-写。
- 工具链遵守 ADR-0001 零依赖：takeown/icacls 为 Windows 自带；检测 protected 目录需要枚举 ACL，若 icacls 无法满足则用 powershell（ADR 允许的例外命令）。
- 清单文件 `manifests/permissions.yaml`；顶层 wrapper 任务 `manifests:permissions:apply`，platforms 限 windows，CALLS 路由 `acl-path=acl:apply`。
- receiver 完全对齐既有 receiver 模板：`ITEM_JSON` 单通道输入、kind 自验证、FAIL_LOG 与 continue_on_error 包装。

## Testing Decisions

- 测试缝复用 `fixtures/manifest-dispatch/` 现有体系：新增 acl-path 的 fixture 与断言，沿用 check-dispatch.sh / check-receivers.sh 的自验脚本模式（shell 断言，不引新依赖）。
- 只测外部行为：item 经 dispatch 路由到 acl:apply 后产生的命令拼装与失败分支（非 admin、路径缺失、非法字段值），不测模板内部实现。
- ACL 真实生效验证（需要管理员 + 真实文件系统）不进 fixture，作为实现 ticket 中的一次性手工验收步骤。

## Out of Scope

- dry-run 机制（现有体系无先例，本次不新增）。
- 权限位 DSL / SDDL 精确声明（grants 直接用 icacls 原生语法）。
- deny 清单外路径的收敛（declared-only，清单外资源不触碰）。
- 自动提权（gsudo / -Verb RunAs）。
- 清单内容的初始数据填充（哪些路径进 permissions.yaml 由用户后续维护）。

## Further Notes

- 共识来自 grill-with-docs 会话：Q1–Q14 逐轮确认，关键裁决为无 state、无隐式授权、owner/grants 皆显式、protected 后代全跳过、非 admin 响亮失败。
