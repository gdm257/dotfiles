---
enable: true
urls:
  - name: matt-pocock-domain
    url: https://raw.githubusercontent.com/mattpocock/skills/refs/heads/main/skills/engineering/setup-matt-pocock-skills/domain.md
    enable: true
  - name: matt-pocock-triage-labels
    url: https://raw.githubusercontent.com/mattpocock/skills/refs/heads/main/skills/engineering/setup-matt-pocock-skills/triage-labels.md
  - name: matt-pocock-issue-tracker-local
    url: https://raw.githubusercontent.com/mattpocock/skills/refs/heads/main/skills/engineering/setup-matt-pocock-skills/issue-tracker-local.md
outputs:
  - ~/.claude/rules/matt-pocock.md
  - ~/.codex/AGENTS.md
  - ~/.dsh/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
name: matt-pocock-user
---

- Do NOT run `/setup-matt-pocock-skills` or create `docs/agents/*.md` except user explicitly require it.
- Use local issue tracker if `docs/agents/issue-tracker.md` does not exist.
- Use default triage lables if `docs/agents/triage-labels.md` does not exist.
- `.scratch/<issue>/` 是草稿，只有当前会话正在进行的 issues、及其显式引用的 other issue (files) 才能参与决策。You MUST ignore 其余未提及的 issues。否则可能会给 codebase 引入错误的或过时的决策。
- Multi-context MAY be in any descendant directory, which generally keeps same with monorepo like `src/<context>/` `packages/<context>/`.
