# Dotfiles Taskfile

用 Task 批量执行机器配置命令的 dotfiles 仓库。manifest 体系是其核心运行模型。

## Language

**Manifest**:
一个声明式 YAML 文件，声明机器上应存在的一批资源（item）。只声明「有什么」，不声明命令如何拼装与执行。
_Avoid_: taskfile, playbook

**Item**:
Manifest 中声明一个资源的条目：恰有一个 kind，其余字段开放，由接收方 task 按 kind 解释。
_Avoid_: run item, step, entry

**Kind**:
Item 的类型标识，形如 `<manager>-<resource>`（如 `scoop-app`），小写 kebab-case。值域与字段含义由接收方 task 解释，引擎不校验。
_Avoid_: type, preset

**Group**:
Manifest 中 `groups.<name>` 下的 item 列表，仅作组织与复用，无自身顺序语义。`items` 中的引用条目（`{ group: <name> }`）展开为该列表，不允许嵌套。
_Avoid_: category, tag

**Receiver**:
接收引擎透传的单个 item 并就地决定其执行语义（命令拼装、容错、提权）的 task。新 manager 只需新增一个 receiver，manifest 与引擎不变。
_Avoid_: apply task, handler, runner
