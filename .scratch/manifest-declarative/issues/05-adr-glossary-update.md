# 05: ADR-0002 与 GLOSSARY 更新

Type: task
Status: resolved
Blocked by: 03, 04

## Question

以 03/04 定稿为据，产出两份决策记录（措辞需用户过目）：

- `docs/adr/0002-manifest-resource-model.md`（编号与命名可调）：资源模型取代命令清单模型——manifest 只声明资源（kind + 字段），执行语义全部移居调用方 task。记录与 ADR-0001（零依赖）的承接关系。Considered Options 至少含：
  - verb 路由约定（`kind:verb` 分发与动词矩阵）——被否决：调用处 task 即动词，无需显式 verb 概念。
  - manifest 即 taskfile（取消声明/执行二分）——被否决：丢失声明与执行的分离。
  - 命令瘦身版（保留 run item 字段形状、仅外移命令组装）——被否决：声明单元仍是命令而非资源。
- GLOSSARY.md：重定义 Manifest；新增 Kind、Item 词条；移除 Run item / Preset / Defaults 词条；Group 词条按 03 定稿修订。格式遵循 domain-modeling skill 的 GLOSSARY-FORMAT / ADR-FORMAT。

## Answer

已完成，措辞经用户审定通过：

- 新增 [docs/adr/0002-manifest-resource-model.md](../../../docs/adr/0002-manifest-resource-model.md)：资源模型取代命令清单模型；Considered Options 含 verb 路由约定 / manifest 即 taskfile / 命令瘦身版三条否决记录；Consequences 首条记录 ADR-0001（零依赖）全额承接。
- 重写 [GLOSSARY.md](../../../GLOSSARY.md)：Manifest 重定义为纯资源声明；新增 Item、Kind 词条；移除 Run item / Preset / Defaults；Group 按 03 定稿修订（item 列表、无自身顺序语义、引用条目展开、禁嵌套）。
- 术语裁决注记：Item 的 _Avoid_ 含 `run item`（防 v1 术语回流），Kind 的 _Avoid_ 含 `preset`；ADR 不链接 `.scratch/` working-area 文件（与 ADR-0001 零链接先例一致）。

06（openspec change artifacts）与 07（迁移策略）可直接引用这两个文件。
