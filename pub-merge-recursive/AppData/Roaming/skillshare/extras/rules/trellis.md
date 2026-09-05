---
enable: true
urls:
  - name: trellis
    url: https://raw.githubusercontent.com/mindfold-ai/Trellis/refs/heads/main/packages/cli/src/templates/markdown/agents.md
outputs:
  - ~/.claude/rules/trellis.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
name: trellis-runtime
---

Do NOT use `python3 ./.trellis/scripts/<name>.py` — the project has no `.trellis/scripts/`.
Replace every occurrence with `uvx trellis-runtime <name>` (same flags)
E.g. `uvx trellis-runtime get-context`

- task.py → task
- get_context.py → get-context
- add_session.py → add-session
- get_developer.py → get-developer
- init_developer.py → init-developer

These instructions are for AI assistants working in this project.

If project is managed by Trellis. The working knowledge you need lives under `.trellis/`:

- `.trellis/workflow.md` — development phases, when to create tasks, skill routing
- `.trellis/spec/` — package- and layer-scoped coding guidelines (read before writing code in a given layer)
- `.trellis/workspace/` — per-developer journals and session traces
- `.trellis/tasks/` — active and archived tasks (PRDs, research, jsonl context)

If a Trellis command is available on your platform (e.g. `/trellis:finish-work`, `/trellis:continue`), prefer it over manual steps. Not every platform exposes every command.
