# Spec: PE 阶段驱动离线注入

## Problem Statement

每次给笔记本重装 Windows：PE 里 WinNTSetup 施放镜像、重启进 OOBE 后设备管理器一堆黄叹号，还得再跑驱动工具逐个装。驱动包其实早已用驱动总裁按硬件下载好，但没有任何可重复的机制让它们在装机时自动就位。

## Solution

仓库提供两个 cmd 脚本：build 脚本把驱动下载目录里的 7z 驱动包幂等预解压成散装 INF 目录树；deploy 脚本装机当天在 PE 里对离线目标盘逐 INF 注入全部驱动（DISM Add-Driver，逐驱动结果可问责），顺带把 unattend 骨架挂进目标系统供未来 OOBE 自动化使用。首启进 OOBE 前，所有设备驱动已在 DriverStore 就位。

## User Stories

1. As a 装机员, I want 一条命令把驱动下载目录解压成可注入的 INF 目录树, so that 不用手动解压每个 7z
2. As a 装机员, I want 装机当天在 PE 里跑一个脚本就完成驱动注入, so that 重启进 OOBE 时设备全部就位
3. As a 装机员, I want 脚本自动识别目标系统盘, so that 驱动不会注错盘
4. As a 装机员, I want 目标盘不明确时脚本停下并列出候选, so that 我显式选择而不是赌一个
5. As a 装机员, I want 单个驱动安装失败不中断整体流程, so that 装机不被个别坏包卡死
6. As a 装机员, I want 失败数体现在退出码里, so that 一眼知道有没有失败
7. As a 装机员, I want 日志写在载荷目录里, so that 装机后还能查每个驱动的结果
8. As a 装机员, I want 脚本自带解压工具, so that PE 里没有 7z 也能跑
9. As a 装机员, I want PE 里缺 dism 时得到明确报错, so that 我知道去换 PE 而不是瞎猜
10. As a 驱动维护者, I want 驱动总裁更新驱动包后重跑一次 build 即可, so that 载荷常新且不用记流程细节
11. As a 驱动维护者, I want build 幂等, so that 重复执行不出错不残留
12. As a 系统定制者, I want deploy 自动把 unattend 挂进目标系统, so that 未来 OOBE 自动化只改这一个文件
13. As a 系统定制者, I want unattend 是静态可独立验证的文件, so that 能单独调试它而不跑完整装机
14. As a 系统定制者, I want 没放 unattend 时 deploy 正常跳过, so that 只装驱动也行
15. As a 用户, I want 全部驱动包无差别注入, so that 换硬件或漏匹配也不用改脚本
16. As a 用户, I want 脚本输出纯 ASCII 英文, so that 任何 PE 代码页下都不乱码
17. As a 用户, I want README 记载从拷贝脚本到真机装机的完整流程, so that 半年后还能照着做

## Implementation Decisions

- 交付物为两个 cmd 批处理脚本 + 静态 unattend 骨架 + 自带 7zr.exe 二进制 + README，全部落在仓库 reinstall/ 目录；脚本以 %~dp0 相对定位载荷与依赖，禁止机器特定绝对路径。
- build：遍历载荷目录 *.7z，解压到 drivers/<包名>/（包名 = 7z 文件基名）；.Scindex 忽略；幂等（重跑覆盖解压）；解压统一走自带 7zr.exe。
- deploy：目标盘定位（无参扫描唯一命中 / 多命中列出退出 / 带参校验）→ DISM 对离线目标逐 INF 注入（遍历 INF 目录树） → if exist unattend 则拷入目标 Panther → 汇总退出。
- 不 ForceUnsigned：未签名驱动记为失败继续。
- 驱动全量注入，不做硬件过滤；不匹配的包驻留 DriverStore 无害。
- 不用 WinNTSetup 自带「添加驱动」；不用 unattend DriverPaths（其 pass 在 WinNTSetup 流程不可达）。
- unattend 骨架当前不含任何设置，仅保证结构合法、可被 Windows SIM 独立验证。

## Testing Decisions

- 只测外部行为（退出码、产物、日志），不测批处理内部实现。
- build 用 fixture 载荷目录（真实小 7z + .Scindex 干扰项）端到端自检：断言解压树、幂等重跑、无 7z 时非零退出。fixture 落仓库 fixtures/ 目录，跟随既有约定。
- deploy 的可自动化部分（目标盘探测、unattend 挂钩、日志、退出码）用 fixture 目标目录验证；DISM 注入本身需要离线 Windows 镜像，不进自动化测试，由真机演练 ticket 验收。
- 无既有批处理测试先例，本 change 建立最小 cmd 自检模式（跑 fixture + 断言退出码与产物存在性），不引入测试框架。

## Out of Scope

- OOBE 阶段的其他自动化（首启脚本、账号、region 跳过等）——unattend 只是挂钩，内容走后续 change。
- 驱动按硬件 ID 过滤、多机通用化。
- Win11 24H2+ 目标系统的兼容（需更新 PE，README 记载前提）。
- 驱动包的获取与更新本身（驱动总裁职责）。

## Further Notes

- 环境前提：PE 的 dism.exe 版本 ≥ 目标系统 build。
- 实测事实：Windows 自带 tar.exe 解不开载荷 7z（BCJ2 过滤器不支持），这是自带 7zr.exe 的直接原因。
- 驱动总裁重新扫描会增删载荷目录中的 7z，build 需重跑；.Scindex 对本方案无用。
