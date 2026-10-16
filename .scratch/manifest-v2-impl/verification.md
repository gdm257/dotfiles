# Implementation Verification

## Scope

- 集成分支为 `manifest-v2-impl`；工单 01–11 的逐批验收记录保存在各自 issue，最后删除验收见 [11](issues/11-delete-v1-engine.md)。
- 70 个 manifest 原地迁移，70 个公开 wrapper 的名称与顺序保持；注释、禁用候选、资源身份、平台门控按迁移前内容保留。
- v1 删除独立提交 `81857dbe26317038037726fc0253533f49d006f8` 仅删两个旧 task，共 50 行；`fec539d` 单独清理失效重放说明。

## Review

- 固定基线 `42c87fba81ef7a1613eea1524d47d8a3dd50a910`，初次双轴审查目标 `19847bdd6d92cbed53fb9d25e6c6a769bf9e18ee`。
- Standards：0 个确认问题。OCR 可审 73/73，跳过 0；其余 31 个路径人工检查。大型迁移值并非全部逐字展开，不能据此保证实际平台执行效果。
- Spec：确认 group false 传播及复用污染、空 arch 静默过滤、部分结构错误缺少 `#N` 三项；均由 `24eb00df86fac02fa408a389864a9b6027a93451` 集中修复。Task 不支持 deepCopy，采用 fresh destination map 合并，重复引用不污染原始成员。
- 最终增量 `e4c2fb8...24eb00d` 两轴独立复审通过，残留发现 0。总计 9 个路径，OCR 可审 1/1，其余 8 个路径人工完整检查；两轴均覆盖 9/9，跳过 0。
- 追加审查 `19847bd...fec539d` 的两个删除相关文件，两轴均无新增问题。

## Validation

- Windows Git Bash 安全接收方检查九组通过，仅执行 echo / shell；安装接收方只做 dry-run。
- Python 标准库检查通过 14 接收方 × 6 场景、17 wrapper dry-run 与批内双清零。
- `task --list`、10 个代表性 wrapper dry-run、迁移后的顶层 `run:` / `presets:` 与执行性旧入口引用清零、diff whitespace 通过。
- 父代理独立对比基线与 `e4c2fb8` 的 70 个公开 wrapper 名称及顺序完全相同，并验证 `ea27795` 中 volta blob 与原始备份一致。
- 集中修复新增检查先红后绿，红阶段 19 个断言失败；绿阶段 24 个 dispatch CLI 场景通过，覆盖全部契约 fixture、group false / 成员优先 / 五次复用隔离、结构路径及序号、三层空 arch 拒绝。父代理独立重放同一检查再次通过。
- 修复后既有九组 receiver 检查、84 runtime 场景、17 wrapper dry-run、`task --list-all` 与基线至修复提交的 diff whitespace 均通过。只运行 echo / shell，未运行安装命令。

## Preservation

- 未执行 reset、强制删除、分支删除或 stash drop。
- wt01 / wt02 已在前序安全清理。wt03–wt10 均保留，因为 stash 后仍存在 tracked modifications，未满足 clean 条件。
- 每个保留 worktree 已分别命名备份 tracked/nonignored 修改和 ignored 虚拟环境；后者均验证 17 个文件、506,722 字节。虚拟环境内容目前在 stash 中，未留在原目录。
- 标签为 `inactive-worktree-preserve-wtNN-20261017` 与 `inactive-worktree-ignored-venv-wtNN-20261017`，NN 为 03–10。不要依赖易变的 stash 索引。

| Worktree | Tracked/nonignored SHA | Ignored environment SHA |
|---|---|---|
| wt03 | `608300d52c7270945121996bdabd42335db658c5` | `68720f05ce58de26a8eaf0e88bb77f0814053f36` |
| wt04 | `311070f52c3a66f163243c9c19093a9280b7a6c2` | `55240fd31a40f3bd8bc8765d4432e97e3bc5f25e` |
| wt05 | `42a6ee3208e5e4d060a6548dfe800a076f17b0fa` | `d9399afd608c81072283b140ea75297bbd7a3167` |
| wt06 | `e6954857adf303dd36f7e20a9de3f91303c08b21` | `1e2bbc2f4ee2db633921be9a1eced3714ad4f5ac` |
| wt07 | `b1f416d8bdcb8c9b747f0fb322de7ac475773041` | `a17fdb251887d21bf645f91262561105bbdd9ea0` |
| wt08 | `2de1dc580d3ef1a840abbccce460cb81a89f13f0` | `6ae392a0954fed1714d7495ccf8e39085aff5018` |
| wt09 | `4f1aa1b579869bc0b1769160f08a1308ac616c8e` | `b7431d1cfe8ff85e7dbe380c1d5242b8b31aabf4` |
| wt10 | `3a5ad694b3272148d01f401be4a174a21b24f4ca` | `62dbf014fdec1823a4116c28e4cc5c7468dfdc72` |

- 用户原有 volta 内容已在 `ea27795` 保留，blob 为 `97e66af63654e3e2c26dc3c9edd4a6249e0daab8`；原备份 `c85d4afd0f3e002d3678a81b71d8f28859a51033` 未修改。

## Limitations

- 未执行真实安装或原生 Linux / macOS 验证，未新增 CI 或测试框架，未 archive OpenSpec change。
- [app-shell manifest](../../manifests/app-shell.yaml) 既有缺失 group `scoop-install-sudo` 引用原样保留，仍会报错；没有擅自改为 `sudo`。
- [app-np manifest](../../manifests/app-np.yaml) 的 `path` group 原本未引用，继续保持非活动状态。
