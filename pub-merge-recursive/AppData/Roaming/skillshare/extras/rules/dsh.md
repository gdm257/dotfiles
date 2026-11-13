---
outputs:
  - ~/.dsh/AGENTS.md
---

- Create git worktrees under `<repo-root>/.agents/worktrees/<name>/` by default, e.g. `git worktree add .agents/worktrees/<branch-or-task-slug> -b <branch>`. Add `.agents/worktrees/` to the repo's `.git/info/exclude` if not already there.
