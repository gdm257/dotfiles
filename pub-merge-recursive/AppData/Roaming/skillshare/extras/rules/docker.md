---
enable: true
outputs:
  - ~/.claude/rules/docker.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
name: docker-user
----
- `compose.yaml` follows compose v2 specification.
- `${VAR_NAME}` should be a required variable.
- `${VAR_NAME:-}` should be a optional variable.
- `${VAR_NAME:-default}` should be a optional variable.
