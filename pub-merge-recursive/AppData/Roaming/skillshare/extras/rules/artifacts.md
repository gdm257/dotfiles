---
outputs:
  - ~/.claude/rules/artifacts.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
---

## Artifacts
### Examples

常见的 Artifacts 包括但不限于：

- `AGENTS.md` `CLAUDE.md` `.claude/rules/*.md`
- Rulesync `.rulesync/rules/*.md`
- `SKILL.md`
- Kiro spec `.kiro/steering/*.md` `requirements.md` `tasks.md`
- Trellis task `workflow.md` `prd.md` `design.md` `implement.md`
- OpenSpec `proposal.md` `design.md` `specs/**/spec.md` `tasks.md`
- `intend/*.md`
- Other Spec-Driven-Development (SDD) artifacts
- Other workflow's artifacts

### Rules for writing artifacts

- **必须使用 LF 换行符、UTF-8 编码**
- **书写 artifacts 之前，必须先阅读相关 instructions，了解其结构与规则**。例如通过 skills、rules、specs。否则：产生 drift，artifacts 无法使用。
- **禁止引用绝对路径**。尤其是只适用于本机器的绝对路径。只有 `~/.config` 之类的硬编码在应用功能里的绝对路径才可使用。否则：会误导其他开发者。
- **禁止引用 git 不追踪的文件**。确信文件已追踪或者即将提交，才允许引用该文件。否则：其他开发者只看到无效路径。
- **书写正文时以中文为主**
- **保持英文（as-is）**
  1. **文件名**
  2. **Headings 标题**
  3. **结构化关键词**
  4. **需求契约关键词** —— `MUST` / `SHOULD` / `MAY` etc
  5. **技术术语 / 标识符** —— 函数名、变量名、CLI 命令、配置键、框架/库名等
  6. **SKILL.md and its resources**
- 你必须遵循上述规则，除非项目文件有特殊说明。
