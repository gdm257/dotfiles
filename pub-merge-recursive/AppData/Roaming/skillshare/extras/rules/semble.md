---
urls:
  - name: semble
    url: https://raw.githubusercontent.com/gdm257/cc-plugins/refs/heads/main/plugins/semble/rules/semble.md
outputs:
  - ~/.claude/rules/semble.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
name: semble-user
---

- semble also supports git URL as path, not just local path: `semble search "save model to disk" https://github.com/owner/repo.git --top-k 10`
