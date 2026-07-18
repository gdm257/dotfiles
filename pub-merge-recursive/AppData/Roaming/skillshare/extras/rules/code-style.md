---
outputs:
  - ~/.claude/rules/code-style.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
---

- code 与 comment 的风格、格式与详细程度应该与项目中已有代码保持一致。
- 大部分开源项目对注释的使用十分克制，除了 docstring 这种参数与类型标注，一般不会频繁使用多行注释。
- 除了项目整体风格，更要考虑当前文件的已有代码的风格，所修改的 diff 部分不应与该文件格格不入，而应该风格一致，看上去是本来就有的代码。
