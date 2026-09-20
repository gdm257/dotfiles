---
outputs:
  - ~/.claude/rules/git.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
---

Default commit convention:

- `type(scope): decription` Angular commit convention.
- Do NOT use `chore` `build` types except project require them.
- Find scope name from history or context.
- Use `BREAKING CHANGE` footer or `!` exclamation mark for breaking changes.
- Do NOT try to find key if you encounter a commit signature error, just skip signing.
