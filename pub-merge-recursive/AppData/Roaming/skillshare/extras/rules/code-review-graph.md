---
enable: false
urls:
  - name: code-review-graph
    url: https://raw.githubusercontent.com/gdm257/cc-plugins/refs/heads/main/plugins/code-review-graph/rules/code-review-graph.md
outputs:
  - ~/.claude/rules/code-review-graph.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
name: code-review-graph-user
---

- WHEN 第一次调用任意 Code-Review-Graph MCP tools THEN 你必须先调用一次 `build_or_update_graph_tool`，否则搜索结果可能不完整或不新鲜。之后无需调用第二次 `build_or_update_graph_tool`，除非显式要求。
