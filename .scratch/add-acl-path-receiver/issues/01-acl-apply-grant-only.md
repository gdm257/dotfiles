# 01: acl:apply receiver 骨架与 grant-only item 端到端

**What to build:** 一个只含 `path` + `grants` 的 acl-path item，经 `task manifests:permissions:apply` 端到端跑通：dispatch 按 kind 路由到新 receiver `acl:apply`，receiver 完成 kind 自验证、非管理员检测、路径存在检测、grants 冒号格式校验，最终用一条 icacls 命令批量 grant，失败走 FAIL_LOG / continue_on_error 包装。

**Blocked by:** None (can start immediately)

**Status:** done

## Comments

- Implemented and merged to add-acl-path-receiver (bee0d28); review fixes in 2363620.

- [ ] receiver 对齐既有模板：`ITEM_JSON` 输入、kind 非 acl-path 响亮失败、FAIL_LOG 包装
- [ ] 非 admin 运行响亮失败并提示用管理员重跑
- [ ] path 不存在响亮失败（item 级 `continue_on_error: true` 可容忍）
- [ ] grants 每项缺 `:` 响亮失败；合法项拼成单条 icacls grant 命令执行
- [ ] grants 缺省时不执行任何 grant
- [ ] `manifests/permissions.yaml`、顶层 wrapper 任务（platforms 限 windows）就位
- [ ] fixtures 新增 acl-path grant-only 用例并纳入自验脚本
