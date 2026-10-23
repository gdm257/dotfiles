# Manifest item state semantics

Status: resolved（openspec change 已归档为 2026-10-23-manifest-item-state）

## Problem Statement

manifest 只能表达「装」：receiver 全部只有 install 一个方向，「不想要」只能注释掉条目。注释机器读不到——已装的 app 注释掉之后永远没人管卸载。winget/scoop/choco 已装 app 想批量卸载，数量很多，手工不可行；且长远方向是让 manifest 逐渐向 nix/k8s 式幂等状态机演进：声明期望状态，重跑收敛，未达标即行动。

## Solution

Item 用声明字段 `state` 表达方向：缺省正向（应在场，安装），`absent` 反向（应不在场，卸载）。`enable` 字段废除，暂停语义不存在：「不关心」= 注释，「不要」= `state: absent`。幂等达标：absent + 未安装 = 成功（墓碑条目永久无害）；present + 已安装 = 成功。收敛是 declared-only：清单外的资源永不被动。

批量语义由**通用下传**承载：组引用条目即 defaults 块——除保留键（`group` / `platforms` / `kind`）外，组引用上声明的一切字段整体下传给未声明该键的成员，成员显式值逐键优先。引擎不认识任何声明字段名（`state` 与 `continue_on_error` 的传播特例均被通用机制收编删除），manifest 层与 receiver 词汇彻底解耦。

## User Stories

1. As a manifest 作者, I want 给单个 item 声明 `state: absent` 让 receiver 自动卸载, so that 几十个已装 app 不用手工逐个卸。
2. As a manifest 作者, I want 在组引用条目上声明 `state: absent` 批量卸载整组, so that 批量操作一处声明完成。
3. As a manifest 作者, I want 组内成员用显式 state 压过引用条目下传值（整组 absent 但保留 B）, so that 例外不用拆组。
4. As a manifest 作者, I want 组正常引用（安装）时组内个别成员单独 `state: absent`, so that 渐进迁移想卸谁标谁。
5. As a manifest 作者, I want 已卸载的 absent 条目重跑直接成功（幂等墓碑）, so that 条目留作记录而不毒害后续 run。
6. As a manifest 作者, I want absent 分支无视 `version`, so that 版本声明不干扰卸载语义。
7. As a manifest 作者, I want present 条目已安装即达标, so that 日常 run 是幂等收敛而非反复动作。
8. As a manifest 作者, I want 写错 state 值时 receiver 响亮失败, so that 拼写错误立刻暴露而非静默跳过。
9. As a manifest 作者, I want 「不关心」用注释表达且这是唯一写法, so that 装 / 不装不删 / 卸三种意图各有唯一明确栖息地。
10. As a manifest 作者, I want 残留 `enable` 被引擎响亮拒绝并指引注释掉该条目, so that 旧肌肉记忆不会静默装上我以为暂停的东西。
11. As a manifest 作者, I want absent 条目同样过 platforms 过滤, so that 平台选择与方向语义正交、其他平台的卸载声明不在本机生效。
12. As a manifest 作者, I want 同组多次引用（一次 present 一次 absent）按声明序确定性生效, so that 病态写法也可预测。
13. As a manifest 作者, I want 组引用上声明 `version` / `elevated` / `source` 等任意声明字段同样整组下传, so that 组即 defaults 块、一族公共参数一处写完。
14. As a manifest 作者, I want 同组被多次引用且各带不同下传字段时互不污染, so that 重复引用语义稳定可预测。
15. As a receiver 维护者, I want state 值域按 kind 定义（包类 `present|absent`，windows-feature 维持 `enabled|disabled`）, so that 各 manager 用自己的原生词汇。
16. As a receiver 维护者, I want 无移除语义的 kind（如 scoop-bucket / scoop-config）遇 absent 响亮失败, so that 语义边界清楚、不静默空跑。
17. As a receiver 维护者, I want absent 分支照家族约定实现即可、引擎零字段知识, so that 新 manager 或新声明字段加入时引擎永不改。
18. As a 引擎维护者, I want 引擎不认识任何声明字段名（含 `state` 与 `continue_on_error`），只做通用下传与透传, so that manifest 层与 receiver 词汇解耦、ADR-0002 分层不破。
19. As a 引擎维护者, I want 下传逐键成员显式优先, so that 组默认与成员例外在同一组里共存。
20. As a 引擎维护者, I want 保留键（`group` / `platforms` / `kind`）不参与下传, so that 引擎自留地的语义不被 defaults 机制模糊。
21. As a 引擎维护者, I want enable 保留键删除后选择类字段只剩 platforms, so that 过滤步变简单、spec 是减法。
22. As a 手装软件的用户, I want 清单外的已装资源永不被 manifest 体系自动卸载, so that 手动安装的工具绝对安全。

## Implementation Decisions

- 通用下传规则：引擎展开组引用时，收集引用条目上除保留键 `group` / `platforms` / `kind` 外的全部键为 defaults 集，逐键搬运给未声明该键的成员，成员显式值优先；引擎不解释、不过滤、不校验任何声明字段值。`continue_on_error` 与 `state` 的引擎传播特例双双删除，由本机制收编（既有语义不变）。
- defaults 集的合并必须非破坏性：不得改动组定义内的成员字典，重复引用同一组、各带不同 defaults 时不得相互污染。
- schema spec 的引擎消费保留键缩为 `kind` / `platforms` / `group`；「传播型声明字段」枚举类别作废，改为通用下传规则（任何声明字段均可组级声明并下传）。dispatch 的过滤步删除 enable，只剩 platforms。
- 残留 `enable` 键引擎响亮拒绝，错误信息指引「注释掉该条目」（对齐本仓「响亮报错」哲学与 v1 键防呆先例；manifest 层零 receiver 字段词汇，报错文本不点名任何声明字段）。
- state 值域 per-kind 由 receiver 定义并响亮拒绝未知值（先例：windows-feature 的 unknown state 分支）。包类家族：`present`（缺省）/ `absent`。
- 幂等达标判定归 receiver：absent + 未安装 = 成功；present + 已安装 = 成功；`version` 仅参与安装命令拼装，不参与达标判定。
- winget / scoop / choco 三个 receiver 增加 absent 分支：卸载命令拼装 + 安装探测（未装即成功）+ 复用既有 continue_on_error / FAIL_LOG 容错机制。
- drift 边界 declared-only：全量清扫（清单外即删）永不为默认行为；如未来需要，另立显式 wrapper，本 change 不建。
- 既有 `enable: false` 全部迁移为注释（dsh 1 处、app-video 3 处、app-kernel 4 处）；v1 时代 spec `manifest-run-item-enable` 标记过时。
- 不引入暂停语义的任何替代形态；组级暂停 = 注释引用行，组定义原地保留。

## Testing Decisions

- 只测外部行为（task CLI 边界的输出与退出码），不测模板内部结构。
- 引擎行为沿 manifest-v2 唯一 seam 先例：`task manifest:dispatch MANIFEST=<fixture> CALL=<重放接收方>`，断言 enable 拒绝报错、下传结果（ITEM_JSON 内字段可见）、platforms 与 state 正交、组引用展开序。
- 通用下传的回归证明：既有 group-coe-* 与 group-state-* fixtures 语义不变、必须照常绿（两特例被收编的证据）；新增第三方字段下传 fixture（组级 `version`）与重复组引用不污染 fixture。
- receiver 行为沿 manifest-runtimes 的 stub 先例：PATH 上放 stub 探测/卸载命令，断言命令拼装形态与「未安装即成功」的幂等路径；不实跑真实包管理器。
- prior art：manifest-dispatch fixture 清单表格 + check 脚本、manifest-runtimes 的 receivers x cases 检查。

## Out of Scope

- 组级 `kind` 声明与下传（组成员各自声明 kind 的现状保持——通用机制本可支持，无需求不启用）。
- 声明字段的引擎级 / schema 级值校验（值域校验是 receiver 职责，引擎保持零词汇）。
- 全量 drift 清扫 wrapper（declared-only 是定案，sweep 未来另议）。
- 升级 / 版本收敛语义（`state: latest` 或 present 的版本对齐）——present 仅「已装即达标」。
- 暂停语义的任何回归形态（enable / paused / 其他）。
- apt / brew / yum / wsl / x-cmd 等其余 receiver 族的 absent 实现（约定已覆盖，实现按需另开）。
- 实现与迁移的执行排期——本 spec 即实现蓝图，落地由后续 tickets 承载。

## Further Notes

- 决策脉络：初版为 grill-with-docs 会话共识（enable 废除、两值 state、成员显式优先、declared-only 收敛、per-kind 值域、残留 enable 响亮拒绝）。
- **Revision 1**：通用下传取代「传播型声明字段」枚举。动因：实现落地后 review 指出引擎模板点名 `state`（及既有 `continue_on_error` 特例）是 receiver 词汇泄漏进 manifest 引擎，违反零知识迭代器原则（manifest 必须 receiver / item 无关）；改为组引用即 defaults 块、引擎不认识任何声明字段名。进而定则 manifest 层零 receiver 字段词汇——schema / dispatch 层场景示例改用中性占位字段，enable 拒绝指引删去「或改用 state」字样（引擎已落地文案同步入实现 ticket）。
- **Revision 2**（归档后用户裁决）：absent 收敛移入方向专用卸载接收方 `winget:uninstall` / `scoop:uninstall` / `choco:uninstall`，install 接收方不再内嵌卸载分支，方向不匹配（install 遇 absent、卸载遇 present 含缺省）响亮失败；windows-feature:set 维持 dism enable/disable 单接收方不动。enable 死键拒绝机制整体删除——引擎零 enable 知识，`enable` 归位普通声明字段静默透传（容忍未知字段契约），removed-enable fixtures 与 schema / dispatch 全部 enable 条款随之移除；manifests 内注释行中的 enable 字面量一并删净。
- 术语以 GLOSSARY 为准：State 词条、Manifest 词条（「应存在与应不存在」）。State 词条中「组引用条目的 state 传播」措辞待随本次修订同步为通用下传表述。
- 行为契约落 openspec change `manifest-item-state`（spec-only 工作流，未 archive）：`manifest-v2-schema` 的传播 requirement 与 `manifest-v2-dispatch` 的「引擎职责四步与传播」requirement 需随 rev1 同步修订。
- windows-feature 的 `state: enabled/disabled` 是本家族约定的第一个实例，值域保持不动。
