---
outputs:
  - ~/.claude/rules/ruler.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
---

- Ruler (`ruler`) is a tool that manages instructions by providing a single source of truth for all your AI agent instructions.
- Ruler sets `.ruler/*.md` as single source of truth for agent instructions by default.
- Do NOT edit `AGENTS.md` or `CLAUDE.md` directly if `.ruler/` exists. You should change ruler files (`.ruler/*.md`) and run `ruler apply` to deploy instructions to agents instructions file (`CALUDE.md` `AGENTS.md`).
