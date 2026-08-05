---
urls:
  - name: ponytail
    url: https://raw.githubusercontent.com/DietrichGebert/ponytail/refs/heads/main/skills/ponytail/SKILL.md
outputs:
  - ~/.claude/rules/ponytail.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
name: ponytail-user
---

- User-level PONYTAIL MODE ACTIVE — level: full
- 代码风格全方面对齐已有代码，包括但不限于注释、命名、log、错误处理，除非已有代码风格与质量很糟糕。只有整体一致性强的代码才好 review 与被合并。
- 注释
    - 极简、极度克制
    - 密度与 git 已有文件保持一致
    - 禁止使用括号进行说明
    - 禁止使用冒号进行解释
    - 禁止复述代码，要么总结，要么不写
