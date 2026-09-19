---
outputs:
  - ~/.claude/rules/code-style.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
---

- 代码风格全方面对齐已有代码（就近原则），包括但不限于注释、命名、log、错误处理，除非已有代码风格与质量很糟糕。只有整体一致性强的代码才好 review 与被合并。
- 默认注释风格
    - 极简、极度克制。
    - 密度与 git 已有文件保持一致。
    - 禁止频繁使用多行注释。
    - 禁止使用括号进行说明。
    - 禁止使用冒号进行解释。
    - 禁止复述代码，要么总结，要么不写。
