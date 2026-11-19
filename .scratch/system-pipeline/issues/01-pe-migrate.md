# 01: reinstall/ 平移更名为 system/pe/

**What to build:** 现有 PE 阶段四件套（build-drivers / pe-deploy / unattend / bin）整体迁入 `system/pe/`，跨阶段 `unattend.xml` 移到 `system/` 根并由 pe-deploy 改为从该位置挂钩；README 与文档引用同步更新；行为不变，全部既有 self-check 断言照常通过。

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] `system/pe/` 下 build-drivers / pe-deploy / bin / self-check 就位，旧 `reinstall/` 路径清空
- [x] `system/unattend.xml` 为跨阶段唯一 unattend 载体，pe-deploy 挂钩路径正确
- [x] pe self-check 全部断言 PASS，退出码 0
- [x] README 与仓库内引用（含 fixtures 说明）不再出现 `reinstall/`
