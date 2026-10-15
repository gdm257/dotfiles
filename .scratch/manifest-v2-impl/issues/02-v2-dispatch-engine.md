# 02: v2 引擎 manifest:dispatch 落地

**What to build:** 按 `.scratch/manifest-declarative/details/engine.md` 定稿契约，在现 `taskfile.d/manifest.yaml` 追加 `manifest:dispatch` task（与 v1 同文件并存，includes 不动）：required vars 恰为 `MANIFEST` + `CALL`；四步职责（解析 → 展开 → 过滤 → 透传），引擎零动词知识、零语义解释；item 唯一透传 var `ITEM_JSON`（toJson 进 / fromJson 出）；基础设施 var `FAIL_LOG`（开头 truncate、收尾非空则汇总 + exit 1）；结构错误 fail 且消息含 manifest 路径与展开序号 `#N`；空批静默 exit 0；严格串行；零依赖。

用落仓的契约 fixture manifests + 重放接收方 task（echo 形态）端到端验证，固定路径供后续手工回归重放（spec Testing Decisions 裁决）；透传机制实测注记见 engine.md Implementation Notes。

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] `task manifest:dispatch MANIFEST=<fixture> CALL=<临时接收方>` 按展开序逐 item 调用接收方，严格串行
- [ ] 接收方 `ref: 'fromJson .ITEM_JSON'` 还原后 bool / 嵌套 / list 类型保真；无任何便捷 var（KIND 等）
- [ ] 未知顶层键 / 未知或嵌套 group / item 缺 kind 或非标量 / items 元素非 map / platforms 值域外 → fail，消息含路径与 `#N`（v1 manifest 误入响亮报错）
- [ ] `enable: false` 静默跳过；引用条目 `enable` / `platforms` 不匹配整组跳过；引用条目 `continue_on_error` 向组内未声明 item 传播
- [ ] 接收方 cmd 失败不吞 → 迭代立即中止；`FAIL_LOG` 非空 → 末尾打印 failed items 汇总 + exit 1；全成功静默 exit 0
- [ ] `items` 空或全被过滤 → 不调 CALL，exit 0；`CALL` 为未知名 → 干净报错
- [ ] 不触碰 v1 `run` / `run:manifest`；行为契约全文对齐 `openspec/changes/manifest-v2/specs/manifest-v2-dispatch/spec.md`
