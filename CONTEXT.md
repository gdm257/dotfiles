# Dotfiles Taskfile

用 Task 批量执行机器配置命令的 dotfiles 仓库。manifest 体系是其核心运行模型。

## Language

**Manifest**:
一个声明式 YAML 文件，描述一批用同一 entrypoint 执行的命令。
_Avoid_: taskfile, playbook

**Run item**:
Manifest 中 `run` 列表里的一项，对应一条最终执行的命令。
_Avoid_: step, entry

**Defaults**:
Manifest 顶层的字段声明，作为所有 run item 未声明字段的回退值。
_Avoid_: global, base

**Preset**:
一组可命名的 defaults 覆盖，run item 通过 `preset` 字段按名引用；未引用时完全不参与解析。字段优先级为 run item > preset > defaults。
_Avoid_: profile, template, variant
