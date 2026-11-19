# audit

手动进 audit mode 后跑 `task system:audit:apply`，一条命令完成镜像内准备；`task system:audit:check` 只报告不施加变更（0 干净 / 10 漂移 / 2xx 拒绝）。

## 流程

1. winget 引导：winget 不可用时 `Add-AppxPackage -RegisterByFamilyName` 注册 App Installer；包本身缺失时 GitHub Releases msixbundle 离线兜底（下载 → 安装 → 注册）
2. `manifests/system-audit.yaml` 机器级基础件（item 带 `scope: machine`）
3. `manifests/registry.yaml` 机器级 HKLM 设置（registry:set）
4. Default profile 预置：`reg load C:\Users\Default\NTUSER.DAT` 到 `HKLM\TMP_SYSAD_DP`，应用 `manifests/system-default-profile.yaml` 后卸载；`default-profile/` 目录存在时种子文件到 `C:\Users\Default`
5. MSIX 自检：`Get-AppxPackage -AllUsers` 与 `Get-AppxProvisionedPackage` 比对，存在未预配 per-user 包即失败（KB2769827），两种模式都实跑

幂等为收敛级：失败原地重跑。日志落 `%TEMP%\system\audit-<timestamp>.log`。

## Exit codes（audit 区间 211–219）

| code | 含义 |
| ---- | ---- |
| 211 | 存在未预配 per-user MSIX 包 |
| 212 | winget 引导失败 |
| 213 | manifest 步骤失败 |
| 214 | Default profile 步骤失败 |
| 10 | check 模式发现漂移（check 专用，非 2xx） |

check 模式：registry 值经 `reg query` 实机比对（REG_SZ/REG_DWORD）；install 类不实机比对（receiver 无 check seam），manifest 非空或引导/种子待做即保守报 10。

## Seams（self-check 用，均可用环境变量覆盖）

`SYSAD_WINGET` winget 命令（定义且文件存在视为可用，否则走引导路径）、`SYSAD_POWERSHELL`（默认 powershell，承载 appx/msix-check 脚本调用）、`SYSAD_CURL`、`SYSAD_MSIXURL`、`SYSAD_TASK`（整体替换 manifest dispatch 调用）、`SYSAD_REG`、`SYSAD_NTUSER`、`SYSAD_DPDIR`、`SYSAD_DPDEST`。

## Self-check

`system/audit/self-check.cmd`，退出码 = 失败断言数；stub 在 `system/audit/fixtures/`（ps/task/reg/curl/winget），经 SC_* 日志与开关环境变量驱动，不碰真实系统状态。
