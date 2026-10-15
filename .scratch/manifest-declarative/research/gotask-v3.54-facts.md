# go-task v3.54.0 能力事实清单

Provenance: research subagent（wayfinder 绘图阶段，2026-10-16），来源为 taskfile.dev v3.54.0 官方文档、go-task/task v3.54.0 源码/CHANGELOG 与 GitHub issues。供 03 / 04 设计引用；末尾单列未确认事项。

**版本锚点**：最新 stable 为 **v3.54.0**（2026-10-01 发布，GitHub Releases API 确认）。以下文档 URL 均为 v3.54.0 站点现行页面（taskfile.dev 已重构为 /docs/guide/* 与 /docs/reference/*）。`version:` 可写 `'3'` 或完整 semver；Task 会拒绝 schema version < 3 或 > 当前 Task 版本的 Taskfile（setup.go `doVersionChecks`）。

## Q1 动态任务分发（`task:` 字段能否用变量解析）

**结论：可以。`cmds` 中任务调用的 `task:` 字段是模板，在每次调用、编译该任务的 cmds 时用调用方作用域内的变量求值（运行期），不是全局 parse 期。**

- 官方 loops 文档明文："You can also **template the task name itself**"，示例 `task: check:{{.ITEM}}`（ITEM 为 for 循环变量）。因此 `task: "{{.VERB}}"`、`task: "{{.MANAGER}}:{{.VERB}}"` 均合法，解析发生在该 cmd 执行前。变量来源是调用方任务的已解析 vars（含 CLI 传入、dynamic `sh:` 变量）。
  - 佐证：https://taskfile.dev/docs/guide/loops （"Looping over tasks" 节）；https://taskfile.dev/docs/guide/dependencies （"Run task calls in order"/"Pass variables to a task"）。
  - ⚠️ 标注：官方示例以 for 循环形式给出；"裸" `task: '{{.VERB}}'`（非 for）没有单独的官方示例，但走的是同一条 cmd 编译路径，长期可用（置信度高，非逐字文档背书）。task.go 源码中段被截断未能逐行验证 `Cmd.Task` 模板化代码。
- `deps` 同样支持对象形式 `{task, vars, silent}`，for 循环 over deps 也是官方文档功能；但 **deps 的纯字符串条目里嵌模板未在文档中记载** —— 建议 deps 一律用对象形式。
- **官方"动态分发"惯用法是 wildcard task 名**：`start:*:*` 捕获段存入 `.MATCH` 数组（`{{index .MATCH 0}}`）。CLI 调用与 Taskfile 内 `task:`/deps 调用都能命中 wildcard 任务；多匹配时 Taskfile 中先定义者胜，父 Taskfile 优先。引入于 **v3.35.0**（2024-02-28，#836/#1489；#836 标题即 "dynamic task names"，closed completed）；v3.43.1 增强（wildcard 可匹配多个任务 #2072/#2121）。见 https://taskfile.dev/docs/guide/arguments （"Capture task-name inputs"）。
- 兜底 workaround：`cmd: task <name>` shell 出（无法调用 `internal: true` 任务，#1028 closed not_planned）；把任务输出当变量用（`sh: task --silent x`）仍是社区惯例，原生支持该需求的 #1439 closed duplicate。
- GitHub 上没有发现"请求 `task: '{{.VAR}}'` 解析"的 open issue —— 因为该能力本就存在；动态分发的诉求集中在 wildcards（已实现）。

## Q2 for + task + vars

**结论：完全支持，且是官方文档一等公民（v3.28.0 起 for over cmds/tasks，#82/#1220）。**

```yaml
cmds:
  - for: { var: ITEMS, as: ITEM }
    task: check
    vars: { ID: '{{.ITEM.id}}' }
```

- `for` 输入形式：字面量列表 / `var:`（引用数组或 map 变量）/ `split:` / `matrix:` / `sources:`、`generates:`（glob 展开）。`as:` 自定义循环变量名（默认 `ITEM`；map 迭代另有 `.KEY`，顺序不保证）。
- **列表为 map 列表时**：`.ITEM` 即单个 map，模板内 `{{.ITEM.id}}` 取子键（map 子键访问 `{{.MAP.A}}`、`{{index .ARRAY 0}}` 在 variables 文档明确）。从 JSON 字符串解析：`ref: 'fromJson .JSON'` 官方示例。
- **整 map 不字符串化传递**：任务调用 vars 里用 `ref:`（`vars: { SERVICES: { ref: .SERVICES } }`，官方示例即任务调用场景）；`ref` 内可写子键/索引/函数（无大括号），如 `ref: index .SELECTED 0`。⚠️ 标注：for 循环任务调用的 vars 里写 `ref: .ITEM` 这一组合没有官方示例（`ref` 在任务调用 vars 可用是明确的，与 for 组合未逐字背书）。
- `for: matrix`（v3.39.0 #1766/#1767/#1784）：笛卡尔积，`.ITEM.OS`/`.ITEM.ARCH`；matrix 值可 `ref:` 引其他变量（v3.42.0 #2065/#2069）；ref 里用 `keys`/`splitList` 等函数的修复在 v3.53.1（#2544/#2956）。docs 明言所有输入形式同样适用于 **deps 循环（并行）**；deps over for 于 v3.36.0（#1299/#1541）。
- 每次迭代可配 `if:` 过滤（v3.47.0+，条件按迭代求值）。
- 文档：https://taskfile.dev/docs/guide/loops ；https://taskfile.dev/docs/guide/variables （"Pass lists and maps"、"Parse JSON or YAML"）。

## Q3 wildcard/glob includes

**结论：`includes.taskfile:` 不支持 glob（`./taskfile.d/*.yaml` 不可用）；但 include 的 key 本身可用 wildcard（`'stack:*'`），被包含文件内可用 `.MATCH`。**

- glob path：现行文档只支持"文件路径或目录路径"（目录会自动查找支持的 Taskfile 文件名）。目录批量 include 是 **open feature request #1678**（"Wildcard-include tasks from a dir"，2024-06 提出，2026-06 仍活跃）→ v3.54.0 未实现。
- wildcard include key：`includes: { 'stack:*': { taskfile: ./Taskfile.stack.yml } }` 可让 `task stack:production:deploy` 命中，被包含任务内 `{{index .MATCH 0}}` 可用（issue #2732 在 v3.49.1 实测确认）。**限制**：include 自身的 `vars:` 里不能引用 `.MATCH`（#2732，2026-07 关闭——维护者结论是维持现状，建议显式传变量，不是代码修复）。⚠️ 标注：wildcard include key 未出现在 v3.54 重写后的 guide 文档中（疑为文档重构遗漏），依据是 issue 实测与旧文档；当前 https://taskfile.dev/docs/guide/includes 不含此节。
- N 个 sibling taskfiles 的现状最佳实践：逐条列出（namespace = include key）；可选项：`aliases`（namespace 别名）、`flatten: true`（去 namespace，v3.39.0 #1704；与根任务重名会报错）、`excludes`（v3.41.0 #1859；v3.53.1 起条目加 `:*` 可排除整个子 namespace，#2300/#2959）、`internal: true`（整文件内部化，CLI 不可直调）、`optional: true`、`dir:`、include 级 `vars:`（v3.43.1 起其中模板可解析 #2108/#2113）、`Taskfile_{{OS}}.yml` 按平台选择、remote taskfiles（v3.53.0/1 起 GA）。已知痛点：#2878（open）吐槽 taskfile+dir 要写两遍。
- 文档：https://taskfile.dev/docs/guide/includes ；https://taskfile.dev/docs/reference/schema ；issues：https://github.com/go-task/task/issues/1678 、/issues/2732 、/issues/2878 。

## Q4 status / sources / preconditions 与嵌套调用、run:

- **status**：shell 命令列表，**全部 exit 0 才跳过 cmds**；支持模板；`{{.CHECKSUM}}`（method: checksum 时）与 `{{.TIMESTAMP}}`（method: timestamp 时，Go time.Time，可 `.Unix`/`.Format`）"both can be used in `cmds` and `status`"（原文）。状态检查可能在**每次**该任务被调用时执行（要求快、只读）。任务被跳过时其 **deps 仍会先运行并各自做检查**。
- **sources/generates**：文件+glob，相对任务 `dir`；`exclude:` 条目按顺序放在所收窄的正 glob 之后（v3.32.0 #225/#1324）；`method:` checksum（默认）/timestamp/none，task 级覆盖根级；`use_gitignore`（v3.52.0 相关增强）；指纹存 `.task/`（建议 gitignore），`TASK_TEMP_DIR` 可重定位（v3.52.0 增 `--temp-dir`）；**按 label 分指纹**：`label: 'build-{{.MODE}}'` + 变量 → 不同 MODE 各存一份 checksum。sources+generates+status 可组合，**全部通过**才算 up-to-date。
- **preconditions**：`sh:`(+`msg:`) 或纯字符串列表，全部须 exit 0，否则任务失败并向调用者/依赖者传播失败；**被检查任务自己的 deps 会先跑完，然后才评估 preconditions**（要把检查放在需要保护的任务上）；`--force` 同时绕过 preconditions 与 up-to-date 检查。跳过可选工作（不报错）用 `if:`（task/cmd 级，v3.47.0 #2564）。
- **嵌套 `task:` 调用**：被调用任务走完整管线（先其 deps、再做自己的 up-to-date 检查）。`run:` 控制单次 invocation 内重复调用：`always`（默认，每次尝试）/ `once`（后续调用整体跳过，含其检查）/ `when_changed`（按调用 vars 集合去重）；可设在任务或 Taskfile 根。**跨 invocation 记忆只有 sources/status 指纹**。递归保护：单次运行任务调用上限 1000，超出 exit 204（源码 `MaximumTaskCall = 1000` + CLI 文档 exit 204）。
- `--status` 可只查不跑（任何任务 stale 则非零退出）；v3.53.1 起有 per-command `timeout`（exit 124 语义、exit 208）。
- 文档：https://taskfile.dev/docs/guide/up-to-date ；https://taskfile.dev/docs/guide/conditional-execution ；https://taskfile.dev/docs/guide/dependencies ；https://taskfile.dev/docs/reference/cli 。

## Q5 调用约定

- 语法：`task [options] [tasks...] [-- CLI_ARGS...]`。`VAR=value` 可混在任务名间，含空格要整体引号（`"NAME=Jane Doe"`），**同一次 invocation 的所有任务共享**；任务自身 `vars:` 优先级高于 CLI（resolution order 最后一级）。`--` 之后进 `CLI_ARGS`/`CLI_ARGS_LIST`。
- 命名空间：`ns:task`（ns 来自 include key）；namespace 别名；从被包含文件调根任务用前导冒号 `task: :build`；`flatten` 后无 ns。
- `--taskfile/-t <file>`：指定任意文件名/路径；`-t -` 从 stdin 读（v3.35.0 #1483）。⚠️ 标注（源码级、文档未明说）：只给 `-t` 不给 `-d` 时，工作目录默认为该 Taskfile 所在目录（`internal/flags` 与 `taskfile.NewRootNode` → `fsext.DefaultDir(entrypoint, dir)`，未逐行读 DefaultDir 实现，置信度高）。`--dir/-d` 另行指定运行目录；cwd 无 Taskfile 时向上搜索父目录；`--global/-g` 用家目录 Taskfile。
- `internal: true`：对 `--list`/`--list-all` 隐藏（JSON 输出同样隐藏），CLI 直调失败 **exit 202**；Taskfile 内 `task:`/deps 调用不受影响。include 级 `internal` 使整文件内部化。
- `aliases`：任务级别名可用于 CLI、Taskfile 内调用、与 namespace 别名组合；**wildcard 别名**（`aliases: [run:*]`）v3.47.0 起（#1900/#2234）。重名/重别名 exit 203。
- 退出码：200 任务不存在、202 internal、203 重名、204 超递归上限、205 用户取消/拒绝确认、206 缺必需变量、207 变量值非法、208 超时；`-x/--exit-code` 改为透传命令真实退出码。
- 变量校验：`requires: vars:` + `enum`/`enum.ref`（enum.ref v3.50.0；`--interactive` 可交互补全，enum 列表选择 v3.53.1 增强）。
- 文档：https://taskfile.dev/docs/guide/arguments ；https://taskfile.dev/docs/guide/running-tasks ；https://taskfile.dev/docs/guide/defining-tasks ；https://taskfile.dev/docs/reference/cli 。

## Q6 模板函数与限制

- 引擎：Go text/template + **slim-sprig**（https://sprig.taskfile.dev ，Task 维护的精简 fork，自 v3.0.0）——**不是完整 Masterminds/sprig**，缺的函数（如 crypto 类）不可用。
- v3.54.0 全量清单（https://taskfile.dev/docs/reference/templating ）：
  - 逻辑：`and or not`、`eq ne lt le gt ge`、`index len slice`
  - 字符串：`trim upper lower trunc repeat substr hasPrefix hasSuffix contains replace quote shellQuote`（别名 `q`）、`regexMatch regexReplaceAll regexReplaceAllLiteral regexSplit`（含 `*All` 变体）
  - 列表：`splitList join splitLines catLines splitArgs first last rest initial uniq sortAlpha append without has`
  - 数学：`add sub mul div mod max min randInt randIntN`
  - 日期：`now date toDate unixEpoch ago`
  - 系统：`OS ARCH numCPU`（numCPU v3.40.0 #1890，替代旧 `NUM_CPUS`）
  - 路径：`toSlash fromSlash joinPath relPath absPath`；env：`joinEnv`；URL：`joinUrl`
  - dict：`get keys hasKey dict merge`；默认值：`default coalesce empty`
  - 编码：`toJson toPrettyJson fromJson toYaml fromYaml b64enc b64dec`（`toYaml/fromYaml` 等 v3.44.0 #2217，同批：`uuid randInt randIntN CLI_ARGS_LIST`）
  - 类型：`atoi float64 toStrings`；调试：`spew*`、`print printf println`
- **`ref` 不是模板函数**：它是 `vars:`、`for: matrix:`、`requires: enum` 等字段里的 YAML 级关键字，作用是保类型传值（数组/map 不被渲染成字符串）；`ref:` 内写**无大括号**表达式，可含子键/索引/模板函数（`ref: index .SELECTED 0`、`ref: 'fromJson .JSON'`）。
- 特殊变量：`CLI_ARGS CLI_ARGS_LIST CLI_FORCE CLI_SILENT CLI_VERBOSE CLI_OFFLINE CLI_ASSUME_YES TASK ALIAS TASK_EXE ROOT_TASKFILE ROOT_DIR TASKFILE TASKFILE_DIR TASK_DIR USER_WORKING_DIR FILE_PATH_SEPARATOR PATH_LIST_SEPARATOR CHECKSUM TIMESTAMP ITEM EXIT_CODE TASK_VERSION`（CHECKSUM/TIMESTAMP 仅在配置了对应 up-to-date 检查的任务中注入）。
- 弃用（面向下一大版本）：`IsSH`（无替代）、`FromSlash→fromSlash`、`ToSlash→toSlash`、`ExeExt→exeExt`（https://taskfile.dev/docs/deprecations/template-functions ）。
- 变量解析顺序（低→高）：进程环境 → 特殊变量 → `env:` → 全局 `vars` → include 传入 vars → 被包含文件 vars → 调用 vars（CLI/任务调用）→ 任务自身 `vars`（最高）。dynamic `sh:` 变量结果按命令字符串缓存（同一命令只跑一次）；`ref:` 传数组/map；模板渲染必为字符串。

## 未确认/需实测的事项汇总

1. 非循环场景裸写 `task: '{{.VERB}}'`：机制与官方 for 示例相同，但无独立官方示例（高置信）。
2. deps 纯字符串条目内嵌模板：未文档化，用对象形式。
3. for 循环任务调用 vars 里 `ref: .ITEM`：组合未文档化。
4. wildcard include key（`'stack:*'`）：v3.49.1 issue 实测可用，但现行 v3.54 guide 文档无此节；include vars 内不可用 `.MATCH`（设计如此，#2732）。
5. `--taskfile` 隐式将 dir 设为 Taskfile 所在目录：源码路径推断（`fsext.DefaultDir`），未读实现体、文档未明说。
6. web_search 本环境不可用，issue 结论基于 GitHub REST API 检索（可能漏掉 discussions 区）。

## 关键版本速查（CHANGELOG）

v3.28.0 for 循环｜v3.32.0 sources exclude｜v3.35.0 wildcard 任务名 + stdin｜v3.36.0 deps 循环｜v3.38.0 ref GA｜v3.39.0 matrix + flatten includes｜v3.40.0 numCPU｜v3.41.0 includes excludes + TASK_DIR + CHECKSUM/TIMESTAMP 进 cmds｜v3.42.0 matrix ref｜v3.43.1 map vars GA + wildcard 多匹配 + include vars 模板解析｜v3.44.0 uuid/randInt/CLI_ARGS_LIST/toYaml/fromYaml｜v3.47.0 if: + wildcard 别名｜v3.50.0 enum.ref｜v3.52.0 secret/use_gitignore 增强/--temp-dir｜v3.53.1 remote GA + per-cmd timeout + excludes `ns:*`｜v3.54.0（2026-10-01，最新）
