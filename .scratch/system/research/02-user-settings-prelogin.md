# 登录前用户级设置机制调研（Windows 10 / 11）

调研票：[02-user-settings-prelogin](../issues/02-user-settings-prelogin.md)。问题：Windows 在用户首次登录之前，完成「适用于所有（之后）新建用户」的用户级设置，有哪些机制。以 learn.microsoft.com 官方文档为准；个别机制官方文档已下线/仅存归档，会明确标注。

## 1. unattend `CopyProfile`（audit 模板用户 → Default Profile）

- 机制：specialize pass 的 [`Microsoft-Windows-Shell-Setup-CopyProfile`](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-copyprofile?view=windows-11)，把内置 Administrator（audit 模式下定制的模板用户）的 profile 覆盖到 default user profile；Windows 用 default profile 作为模板给每个新用户分配 profile。
- 作用范围：**所有之后新建的用户**（域加入后新建的域账号同样继承）。前提是走 sysprep `/generalize` + unattend 流程。
- 支持状态：Win10 / Win11 均受支持（unattend 设置至今有效，文档 Windows 11 版本仍在线）。
- dotfiles 适用面：HKCU 注册表默认值、用户文件/目录布局、多数应用首次运行前的偏好，都能进模板。已知坑（官方明确列出）：
  - 任务栏 pin、部分由 logon 过程重置的设置不会被复制；官方建议改用 Group Policy 或脚本。
  - Default Apps 等设置带 per-user hash 加密，复制过去会被判无效并在首次登录时重置；官方要求 CopyProfile 后手动 load hive 删除 `Shell\Associations\UrlAssociations`、`Explorer\FileExts` 等三个键。
  - [CopyProfile 官方 how-to](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/customize-the-default-user-profile-by-using-copyprofile?view=windows-11) 明确：**不支持用它定制 Start menu**（Win11 需用 Start layout JSON / layout modification 方案）。
  - 只能用内置 Administrator 做模板；多账号或域账号定制会丢。
  - 需要 generalized 镜像流程，对已装好、不想重装的系统不可用（重装级成本）。

## 2. 直接 reg load Default User 的 `ntuser.dat`

- 机制：`reg load HKU\TempDefault "C:\Users\Default\NTUSER.DAT"`，写入 HKCU 形态的默认值，再 `reg unload`。新用户首次登录时 hive 被复制为该用户的 `NTUSER.DAT`，预置键值随之生效。官方文档（CopyProfile 页的 Load Hive 步骤）承认该文件与操作方式，但**没有任何官方文档把「手工编辑 Default NTUSER.DAT」列为受支持场景**——属官方知悉、社区广泛使用、风险自担。
- 作用范围：**所有之后新建的用户**。
- 支持状态：机制上 Win10 / Win11 均有效；无承诺、无文档保证。
- dotfiles 适用面：只覆盖注册表（HKCU 默认值）；不能创建用户文件布局（profile 复制时会带上 `C:\Users\Default` 下的文件——注意：把文件放进 `C:\Users\Default` 目录本身是老牌手法，同样无官方支持承诺但普遍有效）。
- 已知坑：
  - 必须 `reg unload` 干净，否则 hive 被占用、写入丢失或损坏。
  - 写入的某些键会被首次登录流程重置（同 CopyProfile 的 hash/重置问题：FileExts、UrlAssociations、pin 等）。
  - 相对路径值（`%USERPROFILE%` 展开）要小心：hive 里存的是原始字符串，用户侧展开正确，但绝对路径 `C:\Users\Default\...` 会被原样带进新用户 profile——不要在模板 hive 里留下指向 Default 的绝对路径。

## 3. Active Setup（HKLM RunOnce 逐用户执行）

- 机制：登录时比对 `HKLM\Software\Microsoft\Active Setup\Installed Components\<GUID>` 与 HKCU 同路径；HKCU 无该键（或版本较旧）则执行其 `StubPath` 值，并把 HKLM 键复制到 HKCU。因此**每个用户只在首次登录时执行一次**，包括之后新建的所有用户。
- 作用范围：**所有用户的首次登录**（不止新用户；已存在但没跑过的老用户也会触发）。
- 支持状态：**当前官方文档已不覆盖**——仅存 [archive blog（2011）](https://learn.microsoft.com/en-us/archive/blogs/aruns_blog/active-setup-registry-key-what-it-is-and-how-to-create-in-the-package-using-admin-studio-install-shield)与旧版 IE 部署文档；Win10/11 上机制仍在工作（系统自身组件仍在用），但属「无文档、无支持承诺」的遗留机制。
- dotfiles 适用面：非常适合「机器级装好 dotfiles 脚本，逐用户首次登录时以该用户身份执行」的引导钩子。
- 已知坑：
  - StubPath 以**管理员提升的 SYSTEM→用户上下文**执行的经典 UAC 问题：归档评论区指出 UAC 开启时对 installer 场景可能失效（对普通脚本无碍）；实际以用户身份运行，标准用户下写 HKLM 会失败——所以 StubPath 应只做 per-user 工作。
  - 执行在桌面出现前、同步进行，StubPath 慢会拖慢首次登录。
  - 无官方支持承诺，理论上可在未来版本失效。

## 4. unattend OOBE `FirstLogonCommands` / `LogonCommands`

- 机制：oobeSystem pass 的 [FirstLogonCommands](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogonCommands?view=windows-11) / [LogonCommands](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-logoncommands?view=windows-11)，在「用户首次登录时」、桌面显示前运行命令（两者现已同为并发异步执行）。
- 作用范围：文档措辞是 "the first time a user logs on to the computer"。实践中普遍观察是 **OOBE 后第一个完成登录的用户触发一次**，之后新建的用户不会再触发——即**不满足「所有之后新建用户」**这一票的硬需求。
- 支持状态：Win10 / Win11 均受支持（S mode 除外）。
- dotfiles 适用面：适合做「首用户一次性 bootstrap」（例如调用部署脚本、建立计划任务/Active Setup 来覆盖后续用户），不适合直接作为逐用户机制。
- 已知坑：
  - 非管理员首登 + UAC 开启时弹确认框，取消即不运行；UAC 关闭时标准用户直接不运行。
  - 与 audit 模式交互：boot 进 audit 也会排队该命令（官方给出 Reseal Mode = Audit 的规避办法）。
  - LogonCommands 明确不能启动需要管理员权限的应用。

## 5. per-user 触发的计划任务（logon trigger）

- 机制：Task Scheduler [LogonTrigger](https://learn.microsoft.com/en-us/windows/win32/taskschd/logontrigger-userid)：`UserId` 为 NULL 时**任意用户登录都触发**，可用 `Principal.GroupId` 限定组。机器级（HKLM/SYSTEMTasks）注册一次，每个用户（含之后新建用户）登录时以其身份运行。
- 作用范围：**所有用户的每次登录**（无 "new user only" 触发器；用「上次结果/标记文件」自行幂等去重）。
- 支持状态：Win10 / Win11 完全受支持，有完整官方文档与 PowerShell（`Register-ScheduledTask`）支持。
- dotfiles 适用面：最正统的「机器级注册、用户上下文执行」钩子；dotfiles 引导脚本可用它实现幂等的 per-user setup。
- 已知坑：
  - 无「仅新用户」触发器，需脚本自行判断（如检测标记文件）。
  - 每次登录都会跑，注意幂等与静默；默认在登录时可能可见控制台窗口（用 `-WindowStyle Hidden` / wscript 包装）。
  - RDP 等会话类型的行为有已知怪例（[Q&A 案例](https://learn.microsoft.com/en-us/answers/questions/60416/task-scheduler-trigger-on-remote-connection-to-not)），物理/常规登录无碍。

## 6. 其他官方认可的 per-user / 预置机制

- **Provisioning packages**（[官方文档](https://learn.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-packages)）：机器级应用 PPKG，多在首次登录/OOBE 时落到用户上下文；官方支持，适合企业批量，但对个人 dotfiles 偏重、且 unattend/PPMK 工具链成本高。
- **Group Policy / GPP（域环境）**：官方推荐的 per-user 设置下发方式；非域个人机不适用（本地 GPO 的 per-user 能力弱）。
- **Start layout / layoutmodification.xml**：官方指定的 Start/任务栏定制通道，弥补 CopyProfile 的盲区。
- **`C:\Users\Default` 下放文件**：新建用户 profile 会复制 Default 目录内容；无专门文档页但与 Default profile 机制同源，普遍有效、同样无承诺。

## 对比事实表

| 机制 | 作用范围（之后新建用户？） | Win10/11 支持状态 | 主要坑 |
| --- | --- | --- | --- |
| CopyProfile | ✅ 所有新建用户 | 官方支持 | 需 sysprep 重装级流程；Default Apps/pin/Start 不被复制或被重置；需善后删注册表键；仅限内置 Administrator 模板 |
| reg load Default `ntuser.dat` | ✅ 所有新建用户 | 机制有效，但无官方支持承诺 | 只覆盖注册表；unload 不净会损坏 hive；绝对路径泄漏；部分键首登被重置 |
| Active Setup | ✅ 每个用户首次登录（含老用户） | 仍工作，但官方文档已下线（仅 archive） | 无支持承诺；StubPath 需 per-user 幂等；拖慢首登；UAC 场景有历史问题 |
| FirstLogonCommands / LogonCommands | ❌ 仅 OOBE 后首个登录用户一次 | 官方支持（S mode 除外） | 标准用户 + UAC 可能不运行；仅当 bootstrap 入口用 |
| 计划任务 logon trigger（UserId NULL） | ✅ 任意用户每次登录（无 new-user-only） | 官方支持，文档完整 | 需脚本自行幂等去重；每次登录执行；窗口可见性 |
| Provisioning packages / GPP | ✅（PPKG 机器级 + 首登落地；GPP 需域） | 官方支持 | 工具链/域成本高，个人 dotfiles 场景偏重 |

## 结论（面向 dotfiles 选型）

对「不影响重装、作用于之后所有新建用户」的 dotfiles 引导，最稳组合是：**机器级注册 logon-trigger 计划任务（任意用户）+ 脚本内幂等去重**，或 **Active Setup StubPath**（机制仍活但无支持承诺，作次选）。`Default NTUSER.DAT` / `C:\Users\Default` 预置适合做轻量 HKCU 默认值与文件骨架。CopyProfile 仅在本来就重装/做镜像时顺带使用；FirstLogonCommands 只当首个用户的一次性 bootstrap 入口。

## Sources

- [CopyProfile (unattend)](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-copyprofile?view=windows-11)
- [Customize the default user profile by using CopyProfile](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/customize-the-default-user-profile-by-using-copyprofile?view=windows-11)
- [FirstLogonCommands (unattend)](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands?view=windows-11)
- [LogonCommands (unattend)](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-logoncommands?view=windows-11)
- [LogonTrigger.UserId (Task Scheduler)](https://learn.microsoft.com/en-us/windows/win32/taskschd/logontrigger-userid)
- [Active Setup Registry Key（archive blog, 2011）](https://learn.microsoft.com/en-us/archive/blogs/aruns_blog/active-setup-registry-key-what-it-is-and-how-to-create-in-the-package-using-admin-studio-install-shield)
- [Provisioning packages](https://learn.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-packages)
