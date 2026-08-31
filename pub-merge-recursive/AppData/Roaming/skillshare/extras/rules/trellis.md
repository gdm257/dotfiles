---
enable: true
urls:
  - name: trellis
    url: https://raw.githubusercontent.com/mindfold-ai/Trellis/refs/heads/main/packages/cli/src/templates/markdown/agents.md
outputs:
  - ~/.claude/rules/trellis.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
name: trellis-runtime
---

Do NOT use `python3 ./.trellis/scripts/<name>.py` — the project has no .trellis/scripts/.
Replace every occurrence with `uvx trellis-runtime <name>` (same flags)
E.g. `uvx trellis-runtime get-context`

- task.py → task
- get_context.py → get-context
- add_session.py → add-session
- get_developer.py → get-developer
- init_developer.py → init-developer
