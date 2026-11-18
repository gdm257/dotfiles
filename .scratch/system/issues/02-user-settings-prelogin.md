# user-settings-prelogin: 登录前用户设置机制调研

Type: research
Status: resolved

## Question

Windows 在用户首次登录之前，完成「适用于所有新建用户」的用户级设置，有哪些机制？逐个调研其能力、边界与坑（以官方文档为准，覆盖 Win10 与 Win11）：

- unattend `CopyProfile`（audit 阶段模板用户 → Default Profile）
- 直接挂载/修改 Default User 的 `ntuser.dat`（HKU 写入）
- Active Setup（HKLM RunOnce 机制，逐用户执行）
- unattend OOBE `FirstLogonCommands` / `LogonCommands`（只对首个登录用户）
- per-user 触发的计划任务（logon trigger, any user）
- 其他官方认可的 per-user provisioning 机制

每项回答：能否作用于「之后新建的所有用户」？在 Win10/Win11 是否仍受支持？对 dotfiles 场景（用户级 app 设置、注册表、文件布局）的适用面与已知坑（如 CopyProfile 的副作用清单）。产出对比事实表，供 OOBE 票选型。

## Answer

结论要点（详见[调研报告](../research/02-user-settings-prelogin.md)，含对比事实表与来源）：

- **能作用于之后所有新建用户**的机制：unattend `CopyProfile`（官方支持，但需 sysprep 重装级流程，Default Apps / pin / Start 不被复制或被重置）、直接 reg load Default User `ntuser.dat` + `C:\Users\Default` 放文件（有效但无官方支持承诺）、Active Setup StubPath（每个用户首登各执行一次，官方文档已下线仅存 archive，无支持承诺）、任意用户 logon-trigger 计划任务（`LogonTrigger.UserId = NULL`，官方支持，无 new-user-only 触发器需脚本幂等去重）。
- **不能**覆盖后续新建用户：`FirstLogonCommands` / `LogonCommands` 只在 OOBE 后首个用户登录时运行一次（且标准用户 + UAC 下可能不运行），只能当 bootstrap 入口。
- 对 dotfiles 选型：最稳是「机器级注册任意用户 logon 计划任务 + 脚本幂等」；Active Setup 次选；Default `ntuser.dat` 预置适合轻量 HKCU 默认值；CopyProfile 仅在本来就重装/做镜像时顺带用。Win10 / Win11 上这些机制均仍工作（S mode 除外）。
