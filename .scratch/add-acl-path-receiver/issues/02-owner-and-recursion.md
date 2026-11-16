# 02: owner 收敛与递归子树

**What to build:** item 声明 `owner`（任意 user/group 名或 SID，原样传 takeown）与 `recursive: true` 时，receiver 先 takeown（递归 `/r`）再 icacls grant（`/t /c`），整棵子树收敛；非递归 item 只作用于顶层路径。

**Blocked by:** 01

**Status:** done

## Comments

- Implemented and merged to add-acl-path-receiver (971d446); review fixes in 2363620.

- [ ] owner 声明时 takeown 执行，principal 支持用户名、组名、裸 SID
- [ ] recursive: true 时 takeown `/r`、icacls `/t /c`；默认 false 只处理顶层
- [ ] owner 与 grants 组合、owner 单独存在均合法
- [ ] fixtures 补 owner / recursive 用例
