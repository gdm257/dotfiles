# manifest:dispatch 契约 fixture

票 02（v2 引擎 `manifest:dispatch`）的契约 fixture manifests，固定路径供手工回归重放（spec Testing Decisions 裁决）。
重放接收方为 `taskfile.d/receivers.yaml` 内的 `manifest:echo:replay`（internal: true，CLI 不入列、仅经 dispatch 调用；经 `taskfile.d/manifest.yaml` 的 flatten include 合入 `manifest` namespace）：

- 接收方以 `ref: 'fromJson .ITEM_JSON'` 还原 item 后 echo 一行证据：`item=<name> kind=<kind> flag=<bool> json=<item JSON>`
- item 带 `fail: true` 时接收方执行 `false`（普通失败原语，退出码 1，可被 `|| { ...; }` 容错包装捕获）
- 接收方按契约自行消费 `continue_on_error`（含组引用条目传播并入的值）与全局 `CONTINUE_ON_ERROR=true`，失败写 `FAIL_LOG` 并吞退出码；`FAIL_LOG` 非必需（default 兜底，不经 dispatch 独立调用不被绑死）

命令均在仓库根执行。退出码为 task 3.54.0 实测：结构/守卫错误（模板 `fail`）= 1；运行期 cmd 失败 = 201；task 不存在 = 200；internal task CLI 直呼 = 202。

## 场景重放命令

| 场景 | 命令 | 期望 |
|---|---|---|
| bool / 嵌套 / list 保真 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/bool-fidelity.yaml CALLS=echo=echo:replay` | 三行证据 `flag=true` / `flag=false` / 嵌套与 list JSON 完整；exit 0 |
| platforms 过滤 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/filtering.yaml CALLS=echo=echo:replay` | 仅 `always` 与当前 OS 命中的 `*-only`；组引用不匹配整组跳过（期望随 OS 变化）；exit 0 |
| fail-fast | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/fail-fast.yaml CALLS=echo=echo:replay` | `ok-1` 后 `boom` 失败立即中止，`never` 不被调用；exit 201 |
| 容错 + FAIL_LOG 汇总 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/fail-log-summary.yaml CALLS=echo=echo:replay` | `tolerated` 失败被记录、`ok-2` 继续；末尾打印 `manifest:dispatch: failed items:` + `  failed: tolerated`；exit 201 |
| continue_on_error 组传播 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-coe-propagation.yaml CALLS=echo=echo:replay` | `prop-1` 被容错（传播生效，echo JSON 可见 `continue_on_error`:true）、`prop-2` 继续；`explicit-off` 显式 false 不被覆盖、硬失败中止；`after-group` / `never-reached` 不被调用；exit 201 |
| 全局 true 下显式 false 优先 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-coe-propagation.yaml CALLS=echo=echo:replay CONTINUE_ON_ERROR=true` | `prop-2` 被调用；`explicit-off` 硬失败，`never-reached` / `after-group` 不被调用；exit 201，不能只断言退出码 |
| 全局 false 下显式 true 优先 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/fail-log-summary.yaml CALLS=echo=echo:replay CONTINUE_ON_ERROR=false` | `tolerated` 仍被容错，`ok-2` 继续，末尾有失败汇总；exit 201 |
| state 组传播 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-state-propagation.yaml CALLS=echo=echo:replay` | `prop-1` / `prop-2` 透传携带 `state: absent`、`after-group` 无 state；exit 0 |
| state 成员显式优先 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-state-member-override.yaml CALLS=echo=echo:replay` | `implicit` 携带传播的 `state: absent`、`explicit-present` 保留自身 `state: present`；exit 0 |
| 中性字段下传 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-field-propagation.yaml CALLS=echo=echo:replay` | `inherits` 透传携带引用条目声明的 `tier: gold`、`overrides` 保留自身 `tier: silver`、`after-group` 不带 tier；exit 0 |
| 重复引用不污染 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-field-repeated.yaml CALLS=echo=echo:replay` | 第一次引用带 `tier: gold` 下传、第二次不带：第二次展开的成员不带 tier；exit 0 |
| 独立 shell，无 FAIL_LOG | `task --taskfile fixtures/manifest-dispatch/receivers.taskfile.yaml shell ITEM_JSON='{"kind":"shell","cmd":"echo standalone-shell"}'` | 输出 `standalone-shell`；exit 0 |
| items 空 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/empty.yaml CALLS=echo=echo:replay` | 不调 CALL；exit 0 |
| 全部被过滤 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/all-filtered.yaml CALLS=echo=echo:replay` | 全部 item 被 platforms 过滤（arch 恒不匹配，含整组）；不调 CALL；exit 0 |
| 未知顶层键 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/unknown-top-key.yaml CALLS=echo=echo:replay` | fail：`item #1 unknown top-level key 'extra' in <path>`；exit 1 |
| 未知 group | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/unknown-group.yaml CALLS=echo=echo:replay` | fail：`item #1 unknown group 'nope' in <path>`；exit 1 |
| 嵌套 group | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/nested-group.yaml CALLS=echo=echo:replay` | fail：`item #2 nested group 'inner' in <path>`；exit 1 |
| item 缺 kind | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/missing-kind.yaml CALLS=echo=echo:replay` | fail：`item #2 missing or non-scalar kind in <path>`；exit 1 |
| kind 非标量 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/non-scalar-kind.yaml CALLS=echo=echo:replay` | fail：`item #2 missing or non-scalar kind in <path>`；exit 1 |
| items 元素非 map | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/non-map-item.yaml CALLS=echo=echo:replay` | fail：`item #2 not a map in <path>`；exit 1 |
| platforms 三段 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/invalid-platform-segments.yaml CALLS=echo=echo:replay` | fail：`item #2 invalid platform 'windows/amd64/extra' in <path>`；exit 1 |
| platforms 值域外 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/invalid-platform-os.yaml CALLS=echo=echo:replay` | fail：`item #2 invalid platform 'foo' in <path>`；exit 1 |
| v1 形打 v2 引擎 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/v1-form.yaml CALLS=echo=echo:replay` | fail：`item #1 unknown top-level key 'command' in <path>`（键序第一个未知键）；exit 1 |
| 混合 kind 路由 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/routing-mixed.yaml CALLS='alpha=echo:replay, beta=echo:replay'` | 按 CALLS 映射声明序分组（alpha 全部 items 后 beta），组内保持展开序；exit 0 |
| 无人认领 kind | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/routing-unclaimed.yaml CALLS=alpha=echo:replay` | `ok-1` 照常分发、`orphan` 不分发；失败汇总 `item #N unclaimed kind <kind> in <path>`；exit 201 |
| 重复认领 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/routing-duplicate.yaml CALLS='echo=echo:replay, echo=echo:replay'` | 每个 item 对每个认领 receiver 各执行一次（共 4 行）；exit 0 |
| CALL 未知名 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/bool-fidelity.yaml CALLS=echo=no-such-task` | 干净报错 `task: Task "manifest:no-such-task" does not exist`；运行期 for 调用失败 exit 200/201（task 版本敏感） |
| internal CLI 直呼 | `task manifest:echo:replay ITEM_JSON='{"kind":"echo","name":"x"}'` | 拒绝：`task: Task "manifest:echo:replay" is internal`；exit 202 |
| 接收方独立调用 | 任一非 dispatch task 以 `task:` 调 `manifest:echo:replay`，仅传 ITEM_JSON | 正常 echo、exit 0（FAIL_LOG 非必需，default 兜底） |

## 最小接收方检查

先运行 `bash fixtures/manifest-dispatch/check-dispatch.sh` 重放全部引擎 fixture，断言输出、退出码与结构错误路径和 `#N`。新增 `group-coe-false.yaml` 验证 group false 覆盖 global true 并硬停；`group-coe-member-override.yaml` 验证成员显式 true 优先；`group-coe-repeated.yaml` 验证重复引用 true / false / 未声明互不污染。三份 `structure/empty-platform-arch-*.yaml` 分别覆盖内联、成员和引用的空 arch，均期望 `item #2 invalid platform 'windows/'` 与 fixture 路径、exit 1。未知顶层键定位固定为 `#1`，未知 group 定位到下一展开位置，嵌套 group 定位到该成员位置。非空 arch 仍仅按当前 ARCH 匹配，不新增枚举。新增 `group-state-propagation.yaml` / `group-state-member-override.yaml` 验证组引用 `state: absent` 传播与成员显式优先（断言整段输出相等）；新增 `group-field-propagation.yaml` / `group-field-repeated.yaml` 验证中性字段（`tier`）逐键下传与重复引用互不污染（引擎模板不点名任何声明字段，断言整段输出相等）；`filtering.yaml` / `all-filtered.yaml` 收敛为纯 platforms 用例（全部过滤以恒不匹配的 arch 表达）。

在仓库根运行 `bash fixtures/manifest-dispatch/check-receivers.sh`，Windows 使用 Git Bash，不使用 WSL 的 bash。检查只依赖 task CLI 与 bash builtins，不新增测试框架。

`receivers.taskfile.yaml` 仅提供非 dispatch 调用 seam；检查断言实际输出与退出码，覆盖全局 true 的显式 false 反向覆盖、未声明字段继承全局、独立 shell 的成功与容错，以及带空格的传入 FAIL_LOG。只实跑 shell / echo；安装接收方仅用 `task --dry` 渲染，禁止执行安装。

## 书写规范

照 `.scratch/manifest-declarative/research/dispatch-fixture-findings.md`：含 `key: value` 展开的 shell 命令整体加引号、echo JSON 用单引号、LF + UTF-8、零依赖（bash builtins + task 进程内模板）。

## 注意

- 本目录 fixture 仅供引擎回归，禁止放入 `manifests/`（票 11 删除判据对 `manifests/` 全目录 grep 顶层 `run:` / `presets:`，v1 形 fixture 会污染判据）。
