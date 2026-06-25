---
outputs:
  - ~/.claude/rules/artifacts.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
---

# User-level memory (applies to all projects)

## 项目文档产物语言约定

OpenSpec artifacts(`proposal.md` / `design.md` / `specs/**/spec.md` / `tasks.md`)与 steering 文档(`.claude/rules/steering/*.md`)主体使用中文撰写。

**保持英文,不翻译:**

1. **结构化关键词**
   - OpenSpec:`## Why` / `## What Changes` / `## Capabilities` / `### New Capabilities` / `## Impact`(CLI 解析依赖,翻译会破坏解析)
   - steering:模板预定义 section heading(`## Philosophy` / `## Endpoint Pattern` / `## Authentication` / `## Classification` / `## Error Shape` 等)
2. **需求契约关键词** —— `MUST` / `SHOULD` / `MAY`(OpenSpec spec 合同语句保留英文关键词,周围散文中文)
3. **技术术语 / 标识符** —— 文件名、函数名、CLI 命令、配置键、框架/库名等
4. **所有 code block / JSON 示例** —— 原样保留

**使用中文撰写:** 解释、rationale、决策说明、模式描述散文、模板占位(如 `[Purpose:...]`、`[our method] because [reason]`)的填充内容。模板名(`api-standards` / `testing` / `security` / `database` / `error-handling` / `authentication` / `deployment`)作为文件标识也保持英文。
