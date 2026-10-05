# Manifest run group support

Status: ready-for-agent

## Problem Statement

Manifest 的 `run` 列表中大量直接条目重复引用同一批相关软件（如 downloader、cloud-storage），清单冗长且难以按用途组织。用户希望能把相关 run item 收敛进 group，再由 `run` 按名引用。

## Solution

`run` 列表支持 `{ group: <name> }` 条目：执行时纯展开为 `groups.<name>` 下的 run item 列表，各条目按既有解析规则（run item > preset > defaults）执行。不嵌套、不覆盖字段；引用不存在的 group 报错。既有直接条目行为不变（向下兼容）。

## User Stories

1. As a dotfiles 维护者, I want 在 manifest 中定义 group 收敛同类 run item, so that 清单按用途组织、不再冗长
2. As a dotfiles 维护者, I want `run` 中以 `{ group: <name> }` 引用 group, so that 一行即可执行整组命令
3. As a dotfiles 维护者, I want group 条目按声明顺序纯展开, so that 执行顺序可预测
4. As a dotfiles 维护者, I want group 内条目沿用 run item > preset > defaults 的解析规则, so that group 内写法与直接条目完全一致
5. As a dotfiles 维护者, I want 引用不存在的 group 时报错并指明 group 名, so that 拼写错误立即暴露而非静默跳过
6. As a dotfiles 维护者, I want group 内出现嵌套 group 时报错, so that 语义保持简单（纯展开）
7. As a dotfiles 维护者, I want 旧格式 manifest（无 `groups`、直接条目）行为完全不变, so that 既有清单无需迁移
8. As a dotfiles 维护者, I want group 内条目可被注释掉, so that 能临时停用单个软件而不破坏组结构

## Implementation Decisions

- 修改 manifest 运行器（Taskfile 的 `run:manifest` 任务），在迭代 `run` 前把 group 条目展开为扁平 run item 列表
- 展开是纯替换：group 条目本身不携带任何字段覆盖
- 未知 group 与嵌套 group 均为执行期错误，错误信息包含 group 名与 manifest 路径
- manifest 文件格式新增顶层可选 `groups` map；未声明时行为不变

## Testing Decisions

- 只测外部行为：单一 seam —— 端到端执行 `run:manifest` 并断言生成的命令序列
- fixture manifest 覆盖三种形态：含 group 的清单、引用未知 group 的清单、旧格式清单
- 不测内部模板展开细节
- 无既有测试先例（仓库当前零测试），以最小 fixture 断言为准

## Out of Scope

- group 嵌套 group
- group 级或 group 条目级的字段覆盖（prefix/suffix 等）
- 除 `run:manifest` 外其他任务的行为变化
- manifest 格式的其他扩展

## Further Notes

- 术语见 GLOSSARY.md（Manifest / Run item / Preset / Defaults / Group）
- OpenSpec delta spec: openspec/changes/manifest-run-group/specs/manifest-groups/spec.md
