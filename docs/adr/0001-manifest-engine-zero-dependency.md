# Manifest engine stays zero-dependency: bash builtins and Windows built-in commands only

manifest 引擎（`manifest:dispatch` 等）的实现 SHALL 只使用 bash builtins 与 Windows 自带命令；git-bash 发行版附带的 coreutils（`cat` `tr` `sed` `mktemp` `rm` 等）不算零依赖，禁止使用。理由是严格读法：只要机器装了能跑 Task 的 bash 就够，不额外要求 coreutils 在 PATH 中可用或版本一致。因此代码中会出现 `$(< file)`、`${var//\\//}`、`while read` 这类替代写法——这是刻意的，不要"修复"成 coreutils 调用。

## Considered Options

- 宽松零依赖（coreutils 与 bash 同发行版、视为可用）：被否决——coreutils 仍可能被精简安装或 PATH 污染影响，且 Task 的 `sh:` 解释器自带 go 实现的 coreutils，行为与系统版本有差异（如 `mktemp` 返回反斜杠路径）。

## Consequences

- 失败日志使用固定路径复用文件（每次运行开头 truncate），而非 `mktemp` 唯一文件；并发同时运行两个 dispatch 会共用该文件。出现并发需求时再升级。
- 新增命令需求时优先找 builtin；确需外部命令时仅允许 Windows 自带（如 `cmd` `powershell`），并在 ADR 或代码注释中记录例外。
