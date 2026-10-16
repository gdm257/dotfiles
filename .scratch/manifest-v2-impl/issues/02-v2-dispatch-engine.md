# 02: v2 引擎 manifest:dispatch 落地

**What to build:** 按 `.scratch/manifest-declarative/details/engine.md` 定稿契约，在现 `taskfile.d/manifest.yaml` 追加 `manifest:dispatch` task（与 v1 同文件并存，includes 不动）：required vars 恰为 `MANIFEST` + `CALL`；四步职责（解析 → 展开 → 过滤 → 透传），引擎零动词知识、零语义解释；item 唯一透传 var `ITEM_JSON`（toJson 进 / fromJson 出）；基础设施 var `FAIL_LOG`（开头 truncate、收尾非空则汇总 + exit 1）；结构错误 fail 且消息含 manifest 路径与展开序号 `#N`；空批静默 exit 0；严格串行；零依赖。

用落仓的契约 fixture manifests + 重放接收方 task（echo 形态）端到端验证，固定路径供后续手工回归重放（spec Testing Decisions 裁决）；透传机制实测注记见 engine.md Implementation Notes。

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] `task manifest:dispatch MANIFEST=<fixture> CALL=<临时接收方>` 按展开序逐 item 调用接收方，严格串行
- [x] 接收方 `ref: 'fromJson .ITEM_JSON'` 还原后 bool / 嵌套 / list 类型保真；无任何便捷 var（KIND 等）
- [x] 未知顶层键 / 未知或嵌套 group / item 缺 kind 或非标量 / items 元素非 map / platforms 值域外 → fail，消息含路径与 `#N`（v1 manifest 误入响亮报错）
- [x] `enable: false` 静默跳过；引用条目 `enable` / `platforms` 不匹配整组跳过；引用条目 `continue_on_error` 向组内未声明 item 传播
- [x] 接收方 cmd 失败不吞 → 迭代立即中止；`FAIL_LOG` 非空 → 末尾打印 failed items 汇总 + exit 1；全成功静默 exit 0
- [x] `items` 空或全被过滤 → 不调 CALL，exit 0；`CALL` 为未知名 → 干净报错
- [x] 不触碰 v1 `run` / `run:manifest`；行为契约全文对齐 `openspec/changes/manifest-v2/specs/manifest-v2-dispatch/spec.md`

## Comments

- 实现 commit `2a46d33`（feat: add v2 dispatch engine，初始批）；engine key 缺陷（`manifest:dispatch` → `dispatch`）由 03/04 批修复（`6289826` / `835b3a7`）。
- fixture 遗留切片 commit `4b88270`（test: add dispatch contract fixtures and replay receiver），fast-forward 并入集成分支（尖端 `3dd1ad1`）。交付：`fixtures/manifest-dispatch/`（README + 16 fixture，8 个结构错误型在 `structure/`；`v1-form.yaml` 刻意放 fixtures/ 避开票 11 对 `manifests/` 的 grep 判据）+ 重放接收方 `manifest:echo:apply`（`taskfile.d/manifest.yaml`，`internal: true` 仅经 dispatch 可达、CLI 不入列）。
- 逐场景实跑证据（Windows / task 3.54.0，重放命令见 fixture README）：bool / 嵌套 / list 保真（`flag=false` 不字符串化）；enable / platforms 过滤与整组跳过；fail-fast exit 201；容错 FAIL_LOG 汇总 + exit 1；`continue_on_error` 组传播且显式 false 不被覆盖；空批 / 全过滤静默 exit 0；8 型结构错误消息含路径。初始实现对未知顶层键及 group 错误未附 `#N`，最终 Spec review 确认为缺陷，以本票与 OpenSpec 的全型序号要求为准，不作契约豁免。双向防呆（v1 形 → v2 报未知顶层键；v2 形 → v1 触发 `0e534f5` 守卫，均 exit 1）；CALL 未知名 exit 200；接收方独立调用不被 FAIL_LOG 绑死（story 18 实证）。
- 接收方失败原语用 `false` 而非 `exit 1`（mvdan/sh 下 `exit` 会杀死解释器、绕过 `||` 容错包装）——接收方设计修正，非引擎缺陷。
- 环境观察（未动 v1）：TMPDIR 未设的 Windows shell 下 v1 引擎 `/tmp` faillog 路径被 mvdan/sh 解析到 cwd\tmp；v2 已有 TEMP 兜底不受影响。
