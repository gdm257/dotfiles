# 03: Manifest v2 schema 定稿

Type: grilling
Status: resolved

## Question

纯资源声明的 manifest v2 数据模型定稿（产出 detail file `details/schema.md`）：

- item 结构：`kind`（唯一）+ 开放声明字段集（提权、容错、版本、bucket、平台…）的命名与语义。
- 选择类字段（引擎消费）：`enable`、平台字段的名称与匹配语义——对齐 go-task platforms 值域（linux/darwin/windows），是否支持负向匹配（如非 windows）。
- `groups` 在 v2 的语义（组织 / 批量选择 / 顺序）与 `run` 列表的存废：纯声明式下是否还需要"执行顺序列表"，还是 groups + item 声明顺序即全部（含依赖顺序问题：有些安装有先后依赖）。
- 现存 preset 家族 → kind 的映射指引：何种粒度算一个 kind（scoop-app？scoop-bucket？sudo 变体不算 kind 而算字段）。
- 字面命令 escape-hatch item（debug.yaml 类纯命令批）的形态。
- 命名以 GLOSSARY 术语为准（Kind / Item；05 同步词条）。

共识基线见 [map.md](../map.md) Notes；机制类事实引用 01。

## Answer

两轮 grilling 完成（11 问全部按推荐落定，用户逐轮确认）。定稿全文见 [details/schema.md](../details/schema.md)。要点：

- 顶层仅 `items` + `groups`：未知顶层键 `fail`（v1 manifest 误入 v2 引擎响亮报错，并存期防呆）；顺序唯一来源是 `items` 声明序（go template `range` map 按键排序的硬事实使 groups 不可作顺序来源）；无依赖图。
- item = `kind`（结构必填、值自由小写 kebab、引擎不校验值域）+ 开放声明字段；不设通用 id，身份由各 kind 自然字段承载。
- 保留键：`kind` / `enable` / `platforms`（对齐 go-task 值域、仅正向匹配、缺省全平台、内联 item / group 成员 / group 引用条目三层一致生效）/ `group`（引用形态）。
- 约定声明字段：`continue_on_error`（沿用名，引用条目向组内传播）、`version`（一律 string）、`elevated`（sudo 变体降字段）、`state`、`source`。
- kind 粒度规则 `<manager>-<resource>`，首批 registry 十二族；`scoop-app` 的 `bucket/app` 复合名不拆分。
- escape-hatch：`kind: shell` + 单字段 `cmd`，限调试类 manifest。

副产物：Destination 所列三份 detail files 中 `details/migration.md` 此前无属主票——补立 [07: 迁移策略 detail file 定稿](07-migration-strategy.md)（Blocked by: 04），06 的阻塞列表随之增加 07。
