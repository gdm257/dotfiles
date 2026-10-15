# Manifest v2 Schema（定稿）

Status: 定稿。[03: Manifest v2 schema 定稿](../issues/03-manifest-v2-schema.md) 两轮 grilling 落定（11 问，均按推荐确认）。
上位：[map.md](../map.md)；引擎消费契约（透传 var 形态、失败语义等）由 [04: 引擎分发契约定稿](../issues/04-engine-dispatch-contract.md) 定稿于 `details/engine.md`。

## Goals

Manifest v2 是纯资源声明：只声明「机器上有什么资源」，不声明命令如何拼装。命令碎片字段（`presets` / `defaults` / `entrypoint` / `command` / `args` / `prefix` / `suffix`）全部废除；执行语义全部移居调用方 task（共识基线见 map Notes）。

## Top-level Structure

- 仅两个顶层键：
  - `items`：有序列表，元素为 item map 或 group 引用条目 `{group: <name>}`。
  - `groups`：`<name> → item 列表` 的 map，仅作组织与复用，无自身顺序语义。
- 未知顶层键 → 引擎 `fail`（错误信息含 manifest 路径）。v1 manifest（`run:` / `presets:` 等）误入 v2 引擎会响亮报错而非静默空跑——迁移并存期的免费防呆。
- 顺序唯一来源：`items` 声明序。group 引用条目展开为 `groups.<name>` 列表的元素顺序（列表有序）。`groups` 自身不可作顺序来源：go template `range` 遍历 map 按键排序，声明序不可依赖。
- 无依赖图 / `requires:`：安装先后依赖靠排列 `items` 顺序达成，超出部分归接收方。

## Item

- item = map，必含恰好一个 `kind`（字符串）；缺失或非标量 → 引擎 `fail`。
- kind 值为自由字符串（约定小写 kebab-case），引擎不校验值域——零语义原则；某 kind 是否合法由接收方 task 判断。
- 不设通用 `id`：item 身份由各 kind 的自然字段承载（`scoop-app` 用 `name`、`winget-app` 用 `id`、`windows-feature` 用 `feature`）。
- 保留键之外的字段全部开放，由接收方按 kind 解释；接收方 MUST 静默容忍未知字段。

## Reserved Keys（引擎消费）

| 键 | 类型 | 语义 |
|---|---|---|
| `kind` | string | item 类型标识，结构必填 |
| `enable` | bool | 默认 true；false = 静默跳过 |
| `platforms` | string 或 string 列表 | 值域对齐 go-task platforms（`windows` / `linux` / `darwin`，MAY 含 arch 如 `windows/amd64`）；仅正向匹配；缺省 = 全平台；不支持负向匹配，表达「非 windows」需显式列出其余 OS |
| `group` | string | 仅 `items` 引用条目上：`{group: <name>}`，展开引用 `groups.<name>` |

- 作用层级三层一致：内联 item、group 成员、group 引用条目均可声明 `enable` / `platforms`；引用条目上不匹配 = 整组跳过。
- 未知 group、嵌套 group（group 成员再含 `group` 键）→ `fail`，沿用现引擎语义。
- 引擎未来新增消费字段 MUST 扩展本保留键集合，不得复用声明字段名。

## 约定声明字段（接收方消费）

开放集；多词字段用 snake_case。已知约定字段：

| 字段 | 类型 | 语义 |
|---|---|---|
| `version` | string | 资源版本；一律字符串（书写防 YAML float 陷阱，如 `3.13`） |
| `elevated` | bool | 提权声明（sudo / gsudo 通吃）；消费与否由调用方决定 |
| `state` | string | 资源期望态，如 `windows-feature` 的 `enabled` / `disabled`（默认 `enabled`） |
| `source` | string | 安装源变体，如 `winget-app` 的 `winget` / `msstore`（默认 `winget`） |
| `continue_on_error` | bool | 容错声明：item MAY 失败；引擎/接收方如何消费由 04 定稿 |

- `continue_on_error` 在 group 引用条目上的值向组内未声明该字段的 item 传播（现状语义不变）。

## Escape Hatch

`kind: shell`：单声明字段 `cmd`（string），可携带选择类保留键。定位：调试类 manifest（`debug.yaml` 类纯命令批）专用，不承载正式安装逻辑。

```yaml
items:
  - kind: shell
    cmd: echo 'from file'
```

## Kind Registry（非规范首批）

规则：kind = `<manager>-<resource>`，小写 kebab；变体一律降为声明字段，不设 kind 变体。

| 现存 preset 家族 | v2 kind | 身份/变体字段 |
|---|---|---|
| `scoop-install` / `scoop-install-sudo` | `scoop-app` | `name`（`bucket/app` 复合名原样保留，不拆分）；sudo 变体 → `elevated: true` |
| `scoop-bucket-add` | `scoop-bucket` | `name` + `url` |
| `scoop-config` | `scoop-config` | `key` / `value` |
| `winget-install` / `msstore-install` | `winget-app` | `id`；`source`；`version` |
| `brew install` | `brew-app` | `name`（cask 与否等留给接收方） |
| `brew tap` | `brew-tap` | `name` |
| `apt` / `yum` / `choco` install | `apt-package` / `yum-package` / `choco-package` | `name` |
| `dism /online /enable-feature`、`/disable-feature` | `windows-feature` | `feature`；`state` |
| `dsh plugin add` | `dsh-plugin` | `name`；`profile` |
| `openskills install` | `openskills-skill` | `repo` |

全部 60+ manifests 的逐一映射属迁移期工作（map Out of scope），本表仅是规则示范与首批枚举。

## 样例

安装批（`app-np.yaml` 类）的 v2 长相（节选）：

```yaml
groups:
  fonts:
    - { kind: scoop-app, name: LXGWWenKai }
    - { kind: scoop-app, name: SarasaGothic-ttc }
  path:
    - { kind: scoop-app, name: gdm257/path-user-local }
    - { kind: scoop-app, name: gdm257/path-globolize-user-scoop, elevated: true }

items:
  - { group: fonts }
  - { group: path }
```

跨平台单 manifest（混合 kind 由接收方 task 按 `kind` 路由，共识基线第 3 条）：

```yaml
items:
  - { kind: apt-package, name: build-essential, platforms: linux }
  - { kind: choco-package, name: git, platforms: windows }
```
