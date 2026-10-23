# manifest-v2-schema Specification

## Purpose

定义 Manifest v2 的结构契约：manifest 是纯资源声明（`items` + `groups`），item 必含恰一个 `kind`，其余字段开放；引擎可消费的保留键为封闭集合，命令碎片字段全部废除。

## Requirements

### Requirement: 顶层结构仅 items 与 groups

manifest 顶层 SHALL 仅含 `items`（有序列表）与 `groups`（`<name>` → item 列表的 map，仅作组织与复用）。未知顶层键 SHALL 使引擎 fail，错误信息 MUST 含 manifest 路径，不静默空跑。

#### Scenario: 未知顶层键报错

- **WHEN** manifest 顶层声明了 `items` / `groups` 之外的键
- **THEN** 引擎 fail，错误信息含该键名与 manifest 路径，而非静默空跑 exit 0

### Requirement: item 必含恰一个 kind

item SHALL 为 map 且必含 `kind`（标量字符串）；缺失或非标量 SHALL fail，错误信息含展开序号。kind 值为自由字符串（约定小写 kebab-case），引擎 MUST NOT 校验值域，是否合法由接收方 task 判断。保留键之外的字段全部开放，由接收方按 kind 解释；接收方 MUST 静默容忍未知字段。item 不设通用 `id`，身份由各 kind 的自然字段承载。

#### Scenario: item 缺 kind

- **WHEN** 展开序中第 N 个 item 缺 `kind` 或 `kind` 非标量
- **THEN** 引擎 fail，错误信息含 `#N` 与 manifest 路径

#### Scenario: 任意 kind 值照常透传

- **WHEN** item 声明接收方不认识的 `kind: some-unknown-kind`
- **THEN** 引擎不做值域校验，照常透传，由接收方 task 决定接受或报错

### Requirement: 顺序唯一来源是 items 声明序

迭代顺序 SHALL 唯一来自 `items` 声明序；`{group: <name>}` 引用条目展开为 `groups.<name>` 列表的元素顺序。`groups` map 自身 MUST NOT 作顺序来源（map 遍历按键排序，声明序不可依赖）。不设依赖图，安装先后靠排列 `items` 顺序达成。

#### Scenario: group 展开保持列表序

- **WHEN** `items` 含 `{group: g}`，`groups.g` 列表为 [b, a, c]
- **THEN** 迭代顺序为 b、a、c，与 `groups.g` 列表序一致

### Requirement: 保留键封闭集合

引擎消费的保留键 SHALL 恰为 `kind` / `platforms` / `group`；未来新增消费字段 MUST 扩展此集合，MUST NOT 复用声明字段名。`platforms` 为 string 或 string 列表，值域对齐 go-task（`windows` / `linux` / `darwin`，MAY 带 `/arch`），仅正向匹配、缺省全平台、不支持负向匹配；值域外 SHALL fail。选择类字段三层一致：内联 item、group 成员、group 引用条目均可声明。

#### Scenario: 引用条目不匹配整组跳过

- **WHEN** `{group: g, platforms: linux}` 在 windows 平台求值
- **THEN** 整组跳过，组内 item 不迭代

#### Scenario: platforms 值域外报错

- **WHEN** item 声明 `platforms: win`（typo）
- **THEN** 引擎 fail，错误信息含该值、`#N` 与 manifest 路径

### Requirement: kind shell escape hatch

`kind: shell` SHALL 为唯一内建特例 kind：单声明字段 `cmd`（string），可携带选择类保留键；定位调试类 manifest 专用，不承载正式安装逻辑。

#### Scenario: shell item 透传

- **WHEN** item 为 `{ kind: shell, cmd: echo 'from file' }`
- **THEN** 引擎按普通 item 透传，接收方执行 `cmd`

### Requirement: 变体降为声明字段

kind 命名 SHALL 遵循 `<manager>-<resource>` 小写 kebab-case 约定；变体一律降为声明字段，MUST NOT 设 kind 变体。声明字段为开放集、多词 snake_case，名称与语义由接收方按 kind 定义（见 manifest-item-state），本 spec 不持有、枚举或说明任何声明字段名。

#### Scenario: 变体以声明字段差异表达

- **WHEN** 同一 kind 的资源需要区分变体
- **THEN** 以 item 上声明字段的取值差异表达，不新增 kind 变体

### Requirement: group 引用与通用下传

`{group: <name>}` 引用条目展开为 `groups.<name>` 的成员；未知 group、嵌套 group（成员再含 `group` 键）SHALL fail。引用条目即 defaults 块：除保留键（`group` / `platforms` / `kind`）外，其上声明的一切字段 SHALL 逐键下传给组内未声明该键的 item（字段并入 item map，引擎不消费值）；item 显式声明的值 SHALL 优先。manifest 层 MUST NOT 持有、枚举或说明任何声明字段名。下传 MUST 非破坏性：SHALL NOT 改动组定义内的成员字典；同组多次引用、各带不同下传字段时互不污染。

#### Scenario: 未知 group 报错

- **WHEN** `items` 含 `{group: bar}` 而 `groups.bar` 未定义
- **THEN** 引擎 fail，错误信息含 group 名与 manifest 路径

#### Scenario: 任意非保留字段向组内下传

- **WHEN** 引用条目声明某非保留字段 `k: v`，组内 item A 未声明 `k`、item B 显式声明 `k: w`
- **THEN** A 透传时携带 `k: v`，B 保持 `k: w`

#### Scenario: 重复引用不污染

- **WHEN** 同组被两次引用，第一次携带某下传字段、第二次未携带
- **THEN** 第二次展开的成员不带该字段，组定义未被第一次下传改写
