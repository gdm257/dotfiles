---
outputs:
  - ~/.claude/rules/skillshare.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
---

- `skillshare` is a tool that manages agents skills by providing a single source of truth for all your AI agents.
- Skillshare sets `.skillshare/skills/**` as single source of truth for project skills by default.
- Do NOT edit target agents' skill files (`SKILL.md` and bundles) directly if `.skillshare/` exists. You should change skillshare files (`.ruler/*.md`) and run `skillshare sync` to deploy to target agents.
