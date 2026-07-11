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
Replace every occurrence with `uvx --from trellis-runtime trellis-<name>` (same flags)
E.g. `uvx --from trellis-runtime trellis-get-context`

- task.py → trellis-task
- get_context.py → trellis-get-context
- add_session.py → trellis-add-session
- get_developer.py → trellis-get-developer
- init_developer.py → trellis-init-developer
