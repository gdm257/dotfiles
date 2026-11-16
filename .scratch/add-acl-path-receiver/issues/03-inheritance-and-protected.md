# 03: inheritance reset 与 protected 后代跳过

**What to build:** item 声明 `inheritance: reset` 时，顶层路径 `icacls /reset` 后恢复继承再收敛；递归时 ACL protected（显式禁用继承）的后代目录完全跳过（不动 ACL、不 grant），顶层路径自身为 protected 且未声明 reset 时照常处理 owner/grants 但不动继承。未知 inheritance 值响亮失败。

**Blocked by:** 02

**Status:** done

## Comments

- Implemented and merged to add-acl-path-receiver (b8c233f); review fixes in 2363620.

- [ ] `inheritance: reset` 顶层 reset 生效；未声明时不动继承
- [ ] inheritance 未知值响亮失败
- [ ] 递归时 protected 后代完全跳过（icacls 无法过滤时用 powershell 枚举，符合 ADR-0001 例外）
- [ ] 顶层 protected 且未声明 reset：owner/grants 正常处理，继承不动，不跳过
- [ ] fixtures 补 inheritance 用例
