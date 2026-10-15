# dispatch-fixture 实测结论

针对 `.scratch/manifest-declarative/issues/02-verify-dispatch-mechanics.md` 三个 go-task 未逐字背书组合的本地验证。fixture 全部位于 `.scratch/manifest-declarative/research/dispatch-fixture/`，LF + UTF-8，仅用 task + bash builtins（echo/printf/`$(< file)`），符合 ADR-0001 零依赖约束。

## task --version

```console
$ task --version
3.54.0
```

共享样例 `dispatch-fixture/sample.manifest.yaml`：`items` 为三个多字段 map（name/sudo/version），其中 bat 故意缺 `sudo` 作为 missing-key 探针。

## Combo A — for 循环 ref 整 map 透传: FAILED

fixture: `dispatch-fixture/combo-a.taskfile.yml`（根因探针: `dispatch-fixture/probe.taskfile.yml`、`dispatch-fixture/probe-auto.taskfile.yml`）

```yaml
vars:
  MANIFEST: sample.manifest.yaml
  _YAML:
    sh: 'printf "%s" "$(< "{{.MANIFEST}}")"'
  _MANIFEST:
    ref: "fromYaml ._YAML"
  ITEMS:
    ref: "._MANIFEST.items"
tasks:
  dispatch:
    cmds:
      - for: { var: ITEMS, as: ITEM }
        task: recv
        vars:
          ITEM:
            ref: .ITEM          # ← 本组合被测点
  recv:
    internal: true
    cmds:
      - echo "name={{.ITEM.name}}"
```

observed output:

```console
$ task -t combo-a.taskfile.yml dispatch
task: Failed to run task "dispatch": template: :1:18: executing "" at <.ITEM.name>: nil pointer evaluating interface {}.name
```

结论：cmd 级 `vars:` 里的 `ref:` 在求值上下文中**看不到 for 循环变量**，`.ITEM` 解析为 nil pointer 传入 receiver，嵌套 key 访问直接失败。三个根因探针：

1. 改名排除自遮蔽（`as: ITM` + `ref: .ITM`）→ 同样报错，排除变量名遮蔽假设。
2. 字符串模板形态 `ITEM: "{{.ITM}}"` → 传入被字符串化的 map，receiver 报 `can't evaluate field name in type interface {}`（模板字符串能看到循环变量，但值退化为 string）。
3. 不传 vars → receiver 中 `.ITEM` 为 nil，`{{toJson .ITEM}}` 输出 `null`、`{{.ITEM.name}}` 静默输出空串（不报错）。即循环变量不会自动透传给被调 task。

最小可行替代（现行引擎同款，`dispatch-fixture/probe.taskfile.yml` 的 `engine-map` 已验证）：`vars: { ITEM: { map: { name: "{{.ITM.name}}" } } }` 可用，但所有叶子值退化为 string——`sudo: false` 变成非空串 `"false"`，裸 `{{if .ITEM.sudo}}` 判定为真（fzf 实测 `if_bare=yes`），必须改用 `eq .ITEM.sudo "true"` 比较。

## Combo B — toJson/fromJson 透传: WORKS

fixture: `dispatch-fixture/combo-b.taskfile.yml`

```yaml
  dispatch:
    cmds:
      - for: { var: ITEMS, as: ITEM }
        task: recv
        vars:
          ITEM_JSON: "{{toJson .ITEM}}"   # 循环变量 → JSON 字符串
  recv:
    internal: true
    vars:
      ITEM:
        ref: "fromJson .ITEM_JSON"        # task 级 ref 还原为 map
    cmds:
      - echo "json={{toJson .ITEM}}"
      - echo "sudo={{if .ITEM.sudo}}yes{{else}}no{{end}}"
```

observed output（三个 item 依次）：

```console
json={name:ripgrep,sudo:true,version:14.1.0}
name=ripgrep
sudo=yes
json={name:fzf,sudo:false,version:0.44.0}
sudo=no
json={name:bat,version:0.24.0}
sudo=no
```

结论：map 保真。receiver 的 `ref: 'fromJson .ITEM_JSON'` 在 task 级 `vars:` 中可以正常引用 caller 传入的 var；`toJson` round-trip 完整，嵌套访问 `{{.ITEM.name}}`、bool 判定 `{{if .ITEM.sudo}}`（true→yes / false→no / missing→no）全部正确。

## Combo C — 裸动态 task 名: WORKS

fixture: `dispatch-fixture/combo-c.taskfile.yml` + `dispatch-fixture/ns.tasks.yml`（经 `includes: {ns: ...}` 提供命名空间）

```yaml
  call:
    cmds:
      - task: "{{.CALL}}"
        vars:
          GREETING: hi
```

observed output:

```console
$ task -t combo-c.taskfile.yml call CALL=hello
hello: hi
$ task -t combo-c.taskfile.yml call CALL=ns:hello
ns:hello: hi
$ task -t combo-c.taskfile.yml call CALL=nope
task: Failed to run task "call": task: Task "nope" does not exist   # exit 200
```

结论：cmds 中 `task:` 字段在运行时从 var 解析，普通名与 `ns:hello` 命名空间名均可，`vars:`（GREETING: hi）随调用正常传递；未知名报干净错误 exit 200。

## Gotchas

- **YAML plain-scalar colon 陷阱（本次最大的坑）**：`- echo "hello: {{.GREETING}}"` 会让整个 taskfile 解析失败，报 `yaml: line N: found unexpected end of stream`。原因：该 scalar 以 `echo` 开头而非引号，`hello:` 的 colon+space 使其变成 map key，其中的 `"` 成为未闭合引号。修法：整条命令加引号 `- 'echo "hello: {{.GREETING}}"'`。凡 shell 字符串里含 `key: value` 展开都必须这样包。
- missing key 渲染为空串（missingkey zero 语义），`{{if .ITEM.sudo}}` 对 missing 取 false，可选字段安全；但 nil var 的嵌套访问是**静默空串**，只有类型不符（string/typed-nil）才报错——契约层要靠 `toJson`/`hasKey` 显式断言而非等报错。
- `echo "json={{toJson .ITEM}}"` 的 stdout 里 JSON 引号被 shell 吃掉（内层 `"` 提前终止外层双引号串），stdout 显示 `{name:ripgrep,...}`；task 打印的命令行（stderr）可见真实 JSON。观察输出时用 `echo 'json={{toJson .ITEM}}'` 更忠实。
- `ref:` 在 cmd 级 `vars:` 里看不到循环变量（Combo A），在 task 级 `vars:` 里可正常引用 caller var（Combo B）；写法必须是裸表达式 `ref: .ITEM` / `ref: "fromYaml ._YAML"`，不要套 `{{ }}`。
- `$(< file)` + `printf "%s"` 在 Windows task 内建 shell 下可用，无需 cat；动态 `sh:` var 值里的 `{{.MANIFEST}}` 模板展开正常。
- `internal: true` 的 receiver 可被 `task:` 派发调用，仅 CLI 直呼被拒。
- exit codes：taskfile YAML 解析失败 109；task 不存在 200；模板求值失败非零（实测 201）。

## 结论

1. **item 透传契约采用 Combo B 形态**（`vars: { ITEM_JSON: "{{toJson .ITEM}}" }` + receiver `ref: "fromJson .ITEM_JSON"`）：唯一保真的整 map 透传，类型（bool/string）与嵌套访问全程成立。Combo A 的 `ref: .ITEM` 在 v3.54.0 下不可用（ref 求值上下文不含循环变量），不能进契约。
2. 扁平、纯 string 字段的 item 可继续用现行 `map:` 形态，但必须以 `eq .V "true"` 取代裸 `if .V` 判 bool（stringification 陷阱已实测）。
3. **动态派发名安全**：`task: "{{.CALL}}"` 运行时解析，支持 `ns:name` 命名空间与未知名干净报错（exit 200），新引擎可放心用 manifest 字段决定目标 task。
4. fixture taskfile 书写规范固化：含 `key: value` 展开的 shell 命令一律整体加 YAML 引号（`- 'echo "..."'`），文件保持 LF。
