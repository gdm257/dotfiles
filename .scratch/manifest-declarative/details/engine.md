# Manifest v2 Engine Contract（定稿）

Status: 定稿。[04: 引擎分发契约定稿](../issues/04-engine-dispatch-contract.md) 一轮 grilling 落定（7 问，均按推荐确认）。
上位：[map.md](../map.md)；item 结构与保留键见 [details/schema.md](schema.md)；透传机制实测依据见 [02: 本地验证 item 透传的未背书组合](../issues/02-verify-dispatch-mechanics.md)。

## Entry

- 入口 task：`manifest:dispatch`，required vars 恰好两个：
  - `MANIFEST`：manifest 文件路径。
  - `CALL`：接收方 task 名，可含 namespace（如 `scoop:apply`），运行期经 `task: '{{.CALL}}'` 解析（02 Combo C 实测可用；未知名干净报错）。
- 调用形态：`task manifest:dispatch MANIFEST=<path> CALL=<task>`。
- 命名裁决：排除 `TASK`（go-task 保留 var 撞名风险）；不与 v1 `manifest:run` / `manifest:run:manifest` 碰撞——并存期 v1 任务名不动，v2 引擎的文件放置归 [07: 迁移策略 detail file 定稿](../issues/07-migration-strategy.md)。

## Engine Responsibilities

引擎 = 通用迭代分发器，恰好四步，此外零动词知识、零语义解释：

1. **解析**：读 `MANIFEST`（`fromYaml`）；未知顶层键 `fail`（schema 防呆：v1 manifest 误入响亮报错）。
2. **展开**：按 `items` 声明序；`{group: <name>}` 引用条目展开为 `groups.<name>` 列表元素（列表有序）；引用条目的 `continue_on_error` 向组内未声明该字段的 item 传播（字段并入 item map，非消费；现状语义不变）；未知 group、嵌套 group `fail`。
3. **过滤**：`enable` / `platforms` 三层一致（内联 item、group 成员、group 引用条目）；`enable` 缺省 true，false = 静默跳过；引用条目不匹配 = 整组跳过。`platforms` 仅正向匹配、缺省 = 全平台；匹配当前 `OS` / `ARCH`，值带 arch 时双段相等；值域严格校验（见 Structural Errors）。
4. **透传**：幸存 item 整 map 原样交 CALL（见 Item Passthrough），严格串行、按展开序。

选择归引擎（enable / platforms / 结构合法性），语义归接收方 task（kind 值域、字段含义、命令拼装一概不碰）。

## Item Passthrough

- 唯一 item 数据 var：`ITEM_JSON`（string，`toJson` 产物）。接收方以 `ref: 'fromJson .ITEM_JSON'` 还原（约定绑定名 `ITEM`），此后 `{{ .ITEM.name }}` 等访问类型保真（bool / 嵌套 / list，02 Combo B 实测全对）。
- 不提供任何便捷 var：`KIND`、`MANIFEST` 等一律不做（通用 `id` 已在 03 否决，同一逻辑——`fromJson` 后 `.ITEM.kind` 一步可达，便捷 var 只添永久契约维护面）。
- 缺失键：fromJson 后访问未声明键得 `<no value>`；接收方 MUST 以 `hasKey` / `default` 自理，引擎不归一化、不补默认。
- bool 保真仅此一条通道：接收方 MUST NOT 以 `map:` / 字符串化形态判 bool（02 实测 `sudo: false` 裸 if 判真陷阱）。

## Failure Semantics

引擎仅基础设施，不消费 `continue_on_error`（基线 3/4）：

- 引擎向 CALL 传基础设施 var `FAIL_LOG`（固定路径复用文件，每次 dispatch 开头 truncate——ADR-0001 既有裁决）。
- fail-fast 免费：接收方 cmd 失败不吞 → CALL 失败 → 迭代中止。
- 容忍失败归接收方：按 item 的 `continue_on_error` 自行包装（如 `... || { echo "failed: <标识>" >> {{ .FAIL_LOG }}; }` 并吞退出码）。
- 批量级开关（整批继续之类）同样归接收方：从全局 var 自取，引擎不转发、不解释。
- dispatch 收尾：`FAIL_LOG` 非空 → 打印 failed items 汇总 + exit 1（v1 UX 不变）。
- 接收方独立调用（不经 dispatch）时无 `FAIL_LOG`：接收方 MUST 自行降级（如 `default` 兜底路径或跳过日志）。

## Structural Errors

沿用 v1 `fail (printf ... MANIFEST)` 模式；消息一律含 manifest 路径与展开序号 `#N`（1-based，展开后序列中的位置）：

| 错误 | 消息（示意） |
|---|---|
| 未知顶层键 | `unknown top-level key '<key>' in <manifest>` |
| 未知 group | `unknown group '<name>' in <manifest>`（v1 原样） |
| 嵌套 group | `nested group '<name>' in <manifest>`（v1 原样） |
| item 缺 kind / kind 非标量 | `item #<N> missing or non-scalar kind in <manifest>` |
| items 元素非 map | `item #<N> not a map in <manifest>` |
| platforms 值域外 | `item #<N> invalid platform '<value>' in <manifest>` |

platforms 严格校验：值 MUST 属 go-task 平面值域（`windows` / `linux` / `darwin`，MAY 带 `/arch` 如 `windows/amd64`），与「未知 group → fail」同一防呆哲学——typo 拒绝静默吞 item。

## Boundary Behavior

- `items` 空或全部被过滤 → 静默 exit 0，不调 CALL。
- 迭代严格串行、按展开序；无并发选项（顺序是安装依赖的唯一表达，见 schema）。
- 实现零依赖：ADR-0001 全额适用（bash builtins + Windows 自带命令 + Task 进程内模板）。

## Receiver Playbook（说明性，非规范）

单 kind 接收方：

```yaml
# taskfile.d/scoop.yaml 片段：接收 scoop-app
  apply:
    requires:
      vars:
        - ITEM_JSON
    vars:
      ITEM:
        ref: 'fromJson .ITEM_JSON'
    cmds:
      - cmd: scoop install {{ .ITEM.name }}
```

混合 kind 接收方（按 kind 路由，基线 3）：

```yaml
  apply:
    requires:
      vars:
        - ITEM_JSON
    vars:
      ITEM:
        ref: 'fromJson .ITEM_JSON'
    cmds:
      - cmd: '{{ if eq .ITEM.kind "apt-package" }}apt install -y {{ .ITEM.name }}{{ else if eq .ITEM.kind "choco-package" }}choco install -y {{ .ITEM.name }}{{ else }}echo "unhandled kind: {{ .ITEM.kind }}" && exit 1{{ end }}'
```

## Implementation Notes（实测注记，非规范）

- for 循环 + `task:` vars 里 `ref: .ITEM` 整 map 透传不可用（nil pointer）；必须 `toJson` 字符串进、`ref: 'fromJson'` 出（02 Combo A 否决、Combo B 定案）。
- cmds 里 `{{.V}}` 后紧跟 `: ` 会让整个 taskfile YAML 解析失败；此类命令整体引号包裹。
- `map:` 形态仅纯 string 字段可用，叶子全退化 string；bool 一律 JSON 通道。
