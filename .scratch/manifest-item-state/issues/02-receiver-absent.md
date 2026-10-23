# 02: 包类接收方 absent 收敛与非适用 kind 拒绝

**What to build:** winget-app / scoop-app / choco-package 三个接收方支持 `state: absent`：探测未安装即判成功（幂等墓碑），已安装则拼装卸载命令（winget / scoop / choco 各自的 uninstall，参数拼装对齐各自安装命令的习惯）；`version` 在 absent 分支不参与命令与达标判定。state 值域 per-kind 校验：包类恰为 `present` / `absent`，未知值响亮失败（对齐 windows-feature 既有 unknown-state 分支）。scoop-bucket / scoop-config 声明任何 state 值即响亮失败（无移除语义，不静默跳过）。容错复用既有 continue_on_error / FAIL_LOG 机制。契约见 openspec change `manifest-item-state` 的 manifest-item-state delta。

**Blocked by:** None（与 01 并行：接收方消费 ITEM 字段，不依赖引擎改动）

**Status:** resolved

- [x] 三 kind absent + 已装：stub 断言卸载命令形态（id/name 参数对齐安装习惯，且无版本参数）
- [x] absent + 未装：成功且不执行卸载命令
- [x] 缺省 / present：既有安装行为回归不变
- [x] 未知 state 值：响亮失败，错误含值与 kind
- [x] scoop-bucket / scoop-config 声明 state 即失败
- [x] manifest-runtimes/check.py 全绿（PATH stub，不实跑包管理器）

## Comments

- 实施备注（3b477da + merge aff5f12，merger 全绿验证）：探测用 `winget list --source <src> --id <id>` / `scoop list <name>` / `choco list --exact <name>`；scoop 卸载保留 elevated 的 sudo 前缀；stub 体系扩 `3 package receivers x 6 state cases + 2 no-removal kinds`。
