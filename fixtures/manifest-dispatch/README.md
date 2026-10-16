# manifest:dispatch 契约 fixture

票 02（v2 引擎 `manifest:dispatch`）的契约 fixture manifests，固定路径供手工回归重放（spec Testing Decisions 裁决）。
重放接收方为 `taskfile.d/manifest.yaml` 内的 `manifest:echo:apply`（internal: true，CLI 不入列、仅经 dispatch 调用）：

- 接收方以 `ref: 'fromJson .ITEM_JSON'` 还原 item 后 echo 一行证据：`item=<name> kind=<kind> flag=<bool> json=<item JSON>`
- item 带 `fail: true` 时接收方执行 `false`（普通失败原语，退出码 1，可被 `|| { ...; }` 容错包装捕获）
- 接收方按契约自行消费 `continue_on_error`（含组引用条目传播并入的值）与全局 `CONTINUE_ON_ERROR=true`，失败写 `FAIL_LOG` 并吞退出码；`FAIL_LOG` 非必需（default 兜底，不经 dispatch 独立调用不被绑死）

命令均在仓库根执行。退出码为 task 3.54.0 实测：结构/守卫错误（模板 `fail`）= 1；运行期 cmd 失败 = 201；task 不存在 = 200；internal task CLI 直呼 = 202。

## 场景重放命令

| 场景 | 命令 | 期望 |
|---|---|---|
| bool / 嵌套 / list 保真 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/bool-fidelity.yaml CALL=echo:apply` | 三行证据 `flag=true` / `flag=false` / 嵌套与 list JSON 完整；exit 0 |
| enable / platforms 过滤 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/filtering.yaml CALL=echo:apply` | 仅 `always` 与当前 OS 命中的 `*-only`；`disabled` 跳过、组引用不匹配整组跳过（期望随 OS 变化）；exit 0 |
| fail-fast | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/fail-fast.yaml CALL=echo:apply` | `ok-1` 后 `boom` 失败立即中止，`never` 不被调用；exit 201 |
| 容错 + FAIL_LOG 汇总 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/fail-log-summary.yaml CALL=echo:apply` | `tolerated` 失败被记录、`ok-2` 继续；末尾打印 `manifest:dispatch: failed items:` + `  failed: tolerated`；exit 201 |
| continue_on_error 组传播 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-coe-propagation.yaml CALL=echo:apply` | `prop-1` 被容错（传播生效，echo JSON 可见 `continue_on_error`:true）、`prop-2` 继续；`explicit-off` 显式 false 不被覆盖、硬失败中止；`after-group` / `never-reached` 不被调用；exit 201 |
| 全局 true 下显式 false 优先 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/group-coe-propagation.yaml CALL=echo:apply CONTINUE_ON_ERROR=true` | `prop-2` 被调用；`explicit-off` 硬失败，`never-reached` / `after-group` 不被调用；exit 201，不能只断言退出码 |
| 全局 false 下显式 true 优先 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/fail-log-summary.yaml CALL=echo:apply CONTINUE_ON_ERROR=false` | `tolerated` 仍被容错，`ok-2` 继续，末尾有失败汇总；exit 201 |
| 独立 shell，无 FAIL_LOG | `task --taskfile fixtures/manifest-dispatch/receivers.taskfile.yaml shell ITEM_JSON='{"kind":"shell","cmd":"echo standalone-shell"}'` | 输出 `standalone-shell`；exit 0 |
| items 空 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/empty.yaml CALL=echo:apply` | 不调 CALL；exit 0 |
| 全部被过滤 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/all-filtered.yaml CALL=echo:apply` | 不调 CALL；exit 0 |
| 未知顶层键 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/unknown-top-key.yaml CALL=echo:apply` | fail：`item #1 unknown top-level key 'extra' in <path>`；exit 1 |
| 未知 group | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/unknown-group.yaml CALL=echo:apply` | fail：`item #1 unknown group 'nope' in <path>`；exit 1 |
| 嵌套 group | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/nested-group.yaml CALL=echo:apply` | fail：`item #2 nested group 'inner' in <path>`；exit 1 |
| item 缺 kind | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/missing-kind.yaml CALL=echo:apply` | fail：`item #2 missing or non-scalar kind in <path>`；exit 1 |
| kind 非标量 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/non-scalar-kind.yaml CALL=echo:apply` | fail：`item #2 missing or non-scalar kind in <path>`；exit 1 |
| items 元素非 map | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/non-map-item.yaml CALL=echo:apply` | fail：`item #2 not a map in <path>`；exit 1 |
| platforms 三段 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/invalid-platform-segments.yaml CALL=echo:apply` | fail：`item #2 invalid platform 'windows/amd64/extra' in <path>`；exit 1 |
| platforms 值域外 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/structure/invalid-platform-os.yaml CALL=echo:apply` | fail：`item #2 invalid platform 'foo' in <path>`；exit 1 |
| v1 形打 v2 引擎 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/v1-form.yaml CALL=echo:apply` | fail：`item #1 unknown top-level key 'command' in <path>`（键序第一个未知键）；exit 1 |
| CALL 未知名 | `task manifest:dispatch MANIFEST=fixtures/manifest-dispatch/bool-fidelity.yaml CALL=no-such-task` | 干净报错 `task: Task "manifest:no-such-task" does not exist`；exit 200 |
| internal CLI 直呼 | `task manifest:echo:apply ITEM_JSON='{"kind":"echo","name":"x"}'` | 拒绝：`task: Task "manifest:echo:apply" is internal`；exit 202 |
| 接收方独立调用 | 任一非 dispatch task 以 `task:` 调 `manifest:echo:apply`，仅传 ITEM_JSON | 正常 echo、exit 0（FAIL_LOG 非必需，default 兜底） |

## 最小接收方检查

先运行 `bash fixtures/manifest-dispatch/check-dispatch.sh` 重放全部引擎 fixture，断言输出、退出码与结构错误路径和 `#N`。新增 `group-coe-false.yaml` 验证 group false 覆盖 global true 并硬停；`group-coe-member-override.yaml` 验证成员显式 true 优先；`group-coe-repeated.yaml` 验证重复引用 true / false / 未声明互不污染。三份 `structure/empty-platform-arch-*.yaml` 分别覆盖内联、成员和引用的空 arch，均期望 `item #2 invalid platform 'windows/'` 与 fixture 路径、exit 1。未知顶层键定位固定为 `#1`，未知 group 定位到下一展开位置，嵌套 group 定位到该成员位置。非空 arch 仍仅按当前 ARCH 匹配，不新增枚举。

在仓库根运行 `bash fixtures/manifest-dispatch/check-receivers.sh`，Windows 使用 Git Bash，不使用 WSL 的 bash。检查只依赖 task CLI 与 bash builtins，不新增测试框架。

`receivers.taskfile.yaml` 仅提供非 dispatch 调用 seam；检查断言实际输出与退出码，覆盖全局 true 的显式 false 反向覆盖、未声明字段继承全局、独立 shell 的成功与容错，以及带空格的传入 FAIL_LOG。只实跑 shell / echo；安装接收方仅用 `task --dry` 渲染，禁止执行安装。

## 书写规范

照 `.scratch/manifest-declarative/research/dispatch-fixture-findings.md`：含 `key: value` 展开的 shell 命令整体加引号、echo JSON 用单引号、LF + UTF-8、零依赖（bash builtins + task 进程内模板）。

## 注意

- 本目录 fixture 仅供引擎回归，禁止放入 `manifests/`（票 11 删除判据对 `manifests/` 全目录 grep 顶层 `run:` / `presets:`，v1 形 fixture 会污染判据）。
