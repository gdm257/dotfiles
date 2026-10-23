# 04: 引擎通用下传与去词汇化

**What to build:** 组引用条目即 defaults 块——除保留键（`group` / `platforms` / `kind`）外，引用条目上任意声明字段逐键下传给组内未声明该键的成员，成员显式值优先；下传非破坏性，同组多次引用、各带不同下传字段时互不污染。引擎删除 `state` 与 `continue_on_error` 两个传播特判（由通用机制收编），模板不再点名任何声明字段名；enable 拒绝报错文案不含任何字段名，仍含 manifest 路径与展开序号。既有 coe / state 组级场景语义不变、照常绿，作为收编证据。

**Blocked by:** 无（01 / 02 已合并为其基线，可立即开工）。

**Status:** resolved

- [x] 引用条目任意非保留字段 `k: v` 下传到未声明 `k` 的成员；成员显式值优先
- [x] 同组两次引用、第一次带某下传字段、第二次不带 → 第二次展开的成员不带该字段（组定义未被第一次下传改写）
- [x] 引擎模板不再出现任何声明字段名（`state` / `continue_on_error` 点名特判全删）
- [x] enable 拒绝报错文案不含字段名，仍含 manifest 路径与 `#N`
- [x] 既有 group-coe-* / group-state-* 场景语义不变、照常绿
- [x] dispatch 检查脚本新增中性字段下传、重复引用不污染两个场景；旧报错文案断言若有 grep 字段名处随改
- [x] GLOSSARY State 词条的组级传播措辞同步为通用下传表述
- [x] 三套检查全绿（dispatch / receivers / runtimes），fixtures README 场景表格同步

## Design notes

- 依据：`.scratch/manifest-item-state/spec.md` Revision 1 与 openspec change `manifest-item-state` 的 `manifest-v2-schema` delta（「group 引用与通用下传」requirement）。
- 下传收集在组引用分支内完成，排除保留键后整体并入成员 map；合并必须构造新 map，禁止改写组定义内的成员字典（重复引用防污染）。
- 报错指引文案定为「注释掉该条目」语义，不点名任何字段；本票不改接收方任何行为。

## Comments

- 2026-10-23：implementer 于 worktree t04（分支 ticket/04-engine-generic-ref-propagation，TDD 红绿）完成；两提交 21a352c + cfea658 按用户指示 squash 为集成分支单提交 `7f9fe24` feat(manifest): propagate any reference entry fields to group members。引擎组引用分支以 $defaults 收集非保留键、逐键 fresh-dict merge 并入未声明成员；新 fixtures group-field-propagation / group-field-repeated；enable 文案三层去字段名。三套检查于 tip 复验全绿：dispatch 31 场景（29→31）、receivers 9 PASS、runtimes PASS。票据由协调者收口。
