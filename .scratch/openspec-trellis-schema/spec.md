# OpenSpec Trellis Schemas

**Status:** ready-for-agent

## Problem Statement

OpenSpec 的 change 流程（spec-driven）与 Trellis 的任务规划流程（`.trellis/tasks/` 下的 prd / design / implement）是两套并行系统。在已经跑过 Trellis 的项目里用 OpenSpec 管理变更，规划文件会被迫写在 `openspec/changes/` 下，与 `.trellis/` 的任务目录脱节：要么双写两套任务系统导致状态漂移，要么放弃 OpenSpec 的能力归档（specs archive / validate）。用户需要一种把两者接起来的工作流：Trellis 管"任务与规划文件"，OpenSpec 管"change 生命周期与行为 spec 归档"。

## Solution

新增两个 OpenSpec custom workflow schema（`trellis` 全量版、`trellis-prd-only` 轻量版），仿照已有的 `matt-pocock` schema 的 index 模式：change 目录内的 artifact 只是指向 `.trellis/tasks/<task>/` 下真实文件的薄指针，规划文件按 Trellis 自己的设计落在 `.trellis/`；`specs/**` delta specs 仍生成在 change 内（原样复用 spec-driven 的 instruction），保住 OpenSpec 的能力归档；apply 阶段内嵌 trellis-implement agent 的可移植约束与 trellis-before-dev 的加载流程（skill 仅作可选捷径）。schema 安装于 openspec 的 schemas 目录并随 dotfiles 仓库追踪。

## User Stories

1. As a 使用 Trellis 的开发者, I want 一个名为 `trellis` 的 OpenSpec schema, so that 我能在 `.trellis/` 内按 Trellis 原生流程写 prd / design / implement，同时让 OpenSpec 追踪 change 状态。
2. As a 使用 Trellis 的开发者, I want change 目录里的 prd / design / implement 只是指向 `.trellis/tasks/<task>/` 的指针, so that 两套系统不产生重复的规划文件。
3. As a 使用 Trellis 的开发者, I want `openspec status` 能看到 prd / design / implement 三个 artifact 各自的完成进度, so that 我不用翻 `.trellis/` 就知道 change 推进到哪一步。
4. As a 使用 Trellis 的开发者, I want trellis schema 仍然生成 spec-driven 式的 `specs/**` delta specs, so that change 归档后能力规格进入 `openspec/specs/` 主库。
5. As a 使用 Trellis 的开发者, I want 一个 `trellis-prd-only` schema 变体, so that 轻量任务只写 prd.md 不必凑 design.md 和 implement.md。
6. As a 使用 Trellis 的开发者, I want 第一个 artifact 是 memories（glossary / ADR / openspec specs / `.trellis/spec/` 四源采集）, so that 规划前先加载仓库既有上下文，且 `.trellis/spec/` 编码约定被当作硬约束。
7. As a 使用 Trellis 的开发者, I want prd artifact 的 instruction 自己创建 Trellis 任务目录（经 trellis-runtime）, so that 任务目录、task.json 与 prd.md 由同一入口产生。
8. As a 使用 Trellis 的开发者, I want 项目没有 `.trellis/` 时 schema 停下来告知前置条件, so that schema 不会静默越权初始化项目。
9. As an agent, I want apply instruction 内嵌 trellis-implement 的可移植内容（上下文加载清单、禁 git commit/push/merge、lint/typecheck 验证、不派发 sub-agent）与 trellis-before-dev 的加载流程（skill 仅作可选捷径）, so that 任意 agent 拿到渲染后的 apply instruction 都能直接执行，不依赖特定 skill 安装或 sub-agent 机制。
10. As an agent, I want implement artifact 的 instruction 规定 checkbox 格式, so that 进度可被逐项勾选追踪。
11. As a 维护 dotfiles 的开发者, I want 两个 schema 进 dotfiles 仓库的 pub-merge-recursive 树, so that schema 随发布机制部署到任何机器且不丢失。
12. As a 维护 schema 的开发者, I want memories 与 specs 的 instruction 从现有 schema 原样拷贝, so that 三处 schema 的公共文本不产生分叉维护。
13. As a 维护 schema 的开发者, I want schema instruction 全英文, so that 与 spec-driven / matt-pocock 等既有 schemas 保持一致。
14. As an agent, I want 指针模板仿照 matt-pocock 的 stub 样式（注释 + 相对路径占位）, so that 生成的 index 文件形态与既有 schema 一致。
15. As a 使用 Trellis 的开发者, I want 任务目录创建统一使用 `uvx trellis-runtime task create`, so that 不依赖 npm 安装的 `trellis` CLI，也不依赖项目内 vendor 的 `.trellis/scripts/*.py`。
16. As a 使用 Trellis 的开发者, I want prd-only 变体的 apply 在无 implement.md 时按 prd 的 acceptance criteria 逐条实现, so that 轻量任务也有明确的完工判据。

## Implementation Decisions

- 两个 schema：`trellis`（全量）与 `trellis-prd-only`（轻量），各自含 `schema.yaml` + `templates/`，安装于 openspec schemas 目录下的同名子目录，并在 dotfiles 仓库的 pub-merge-recursive 对应路径追踪。
- `trellis` artifact 链与依赖：`memories`（无依赖）→ `prd`（依赖 memories）→ `design`（依赖 prd）→ `implement`（依赖 design 与 specs）→ `specs`（依赖 prd）；`apply` requires implement。
- `trellis-prd-only` artifact 链：`memories` → `prd` → `specs`；`apply` requires specs。
- `memories` instruction 从当前 spec-driven schema 原样拷贝（含 `.trellis/spec/` 布局发现与 "missing sources skipped silently" 约定）。
- `specs` instruction 从当前 spec-driven schema 原样拷贝（delta operations、`#### Scenario` 四井号、`## Purpose`、store-aware root、skip_specs 规则全套）。
- `prd` / `design` / `implement` 为内嵌英文 instruction（不调用 trellis-brainstorm skill，其提示词被否决），只保留生成 artifact 所需内容，风格对标 to-tickets 的克制程度：
  - prd：硬前置（`.trellis/` 不存在则停下告知，参照 trellis-init skill 的方式描述初始化但不使用 `trellis` 命令）；经 trellis-runtime 创建任务目录；prd.md 章节契约（goal / confirmed facts / requirements / acceptance criteria / out of scope / open questions）。
  - design：架构与边界、数据流与契约、兼容与迁移、关键 trade-offs。
  - implement：有序 checkbox checklist（`- [ ]` 格式）、validation commands、risky files。
  - 三个 artifact 同时在 change 目录生成指针 stub（指向 `.trellis/tasks/<task>/` 对应文件）。
- `apply` instruction 内嵌（不路由）：参考 trellis-implement agent 的可移植内容——读 contextFiles、读 `.trellis/workflow.md` 与 `.trellis/spec/`（get_context packages → layer index → Pre-Development Checklist → guides）、读规划 artifacts（when present）、非 trivial 任务先陈述 change boundary、逐任务实现并勾选、lint/typecheck 验证、禁 `git commit/push/merge`、不派发 sub-agent；`trellis-before-dev` skill 仅作可选捷径提及。role 专属内容（recursion guard 前提、report format）剔除。完整草案与依据见 `.scratch/openspec-trellis-schema/research/apply-instruction.md`。
- trellis schema 的 design/implement 仅复杂任务实质填充（instruction 写明轻量任务可跳过实质内容，但 artifact 仍生成以保证依赖链完整）。
- 不新增 README（matt-pocock schema 无 README，保持一致；schema 非直接 fork，来源以 instruction 文本一致性隐含）。

## Testing Decisions

- 好的测试只测外部行为：openspec CLI 是 schema 的唯一消费者，因此唯一测试 seam 是 openspec CLI 本身，不引入新 seam。
- 验证方式：schema 落盘后运行 `openspec schemas` 确认两个新 schema 被识别；在临时 change 上以 `--schema trellis` 与 `--schema trellis-prd-only` 分别渲染 instructions，确认 artifact 链与 instruction 完整；对临时 change 跑 `openspec validate` 通过。
- Prior art：无既有测试（schemas 目录全是声明式 YAML）；此验证为一次性 smoke，不落自动化测试。

## Out of Scope

- 不修改 spec-driven / matt-pocock / matt-pocock-wayfinder 既有 schemas。
- 不做 openspec change 与 `.trellis/tasks/` task.json 的生命周期双向同步（不调 task start/finish/archive）。
- 不重写 trellis-brainstorm skill 本身。
- 不将 trellis / trellis-prd-only 设为任何机器或项目的默认 schema。
- 不为两个新 schema 建自动化测试或 CI。

## Further Notes

- 决策脉络见本次 grilling 会话：`.trellis/` 为规划文件的唯一真身、OpenSpec change 只作 index、specs 复用、brainstorm skill 弃用改内嵌、`trellis` npm 命令弃用改 trellis-runtime。
- trellis-prd-only 与 trellis 的差异仅规划 artifact 集合与 apply 的 requires；memories、specs、apply 的 instruction 文本完全相同（"when present" 覆盖 prd-only 无 design/implement 的情形），便于同步维护。
