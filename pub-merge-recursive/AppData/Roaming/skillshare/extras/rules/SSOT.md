---
outputs:
  - ~/.claude/rules/SSOT.md
  - ~/.codex/AGENTS.md
  - ~/.dsh/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
---

**文档与 codebase 的关系**

- `GLOSSARY.md`、`docs/adr/`、`openspec/specs/` 等是固化决策的文档（如存在）：GLOSSARY 定语言，ADR 记录难逆的架构权衡，specs 像回归测试一样锁定行为契约、防止改坏 codebase。
- 决策真身在 codebase；codebase 与固化文档不一致时，优先怀疑 codebase 被改坏（小概率是文档 drift），并报告这个分歧。
- 固化文档只经各自工作流修改（specs 走 openspec，GLOSSARY / ADR 走 domain-modeling），实现改动里不顺手改；确认是 drift 时，单独走对应工作流更新。

**Skills**

- `skillshare` is a tool that manages agents skills by providing a single source of truth for all your AI agents.
- Skillshare sets `.skillshare/skills/**` as single source of truth for project skills by default.
- Do NOT edit target agents' skill files (`SKILL.md` and bundles) directly if `.skillshare/` exists. You should change skillshare files and run `skillshare sync` to deploy to target agents.
