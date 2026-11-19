# 05: sysprep 封装与镜像捕获

**What to build:** audit 完成后一条命令完成封装与捕获：断网 → `sysprep /generalize /oobe`（SkipRearm=true、指向 `system/unattend.xml`、/shutdown）→ DISM capture 单 `install.wim`（文件名带日期与源 build 号，自动选剩余空间最大的本地分区，排除启动卷/目标盘/网络分区）；sysprep 与 capture 为拒绝级，检测到已 generalize / 已有 wim 时硬拒绝；配套 `system:sysprep:check` 与 self-check（stub seam 验证拒绝级检测与分区选择）。

**Blocked by:** 04

**Status:** resolved

- [x] 封装命令先断网再 generalize，参数与 unattend 挂钩正确
- [x] capture 产物命名带日期与 build 号，分区选择排除规则正确（stub 盘集合验证）
- [x] 拒绝级：已 generalize / 目标 wim 已存在时非零拒绝且无副作用
- [x] check 即拒绝级检测；self-check 断言全 PASS
