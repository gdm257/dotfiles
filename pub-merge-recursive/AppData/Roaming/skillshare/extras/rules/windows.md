---
enable: true
outputs:
  - ~/.claude/rules/windows.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
---

- To press output, redirect stdout/stderr to `/dev/null` (try unix style first) or `$null` (powershell). Do NOT redirect to `nul`! Correct: `echo foo > /dev/null`; Wrong: `echo hello >nul`
