---
enable: true
urls:
  - name: codebase-memory
    url: https://raw.githubusercontent.com/gdm257/cc-plugins/refs/heads/main/plugins/codebase-memory/rules/codebase-memory.md
  - name: codebase-memory-reminder
    url: https://raw.githubusercontent.com/gdm257/cc-plugins/refs/heads/main/plugins/codebase-memory/rules/session-start-reminder.md
outputs:
  - ~/.claude/rules/codebase-memory.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
name: codebase-memory-user
---

## Tools

- You can run `codebase-memory-mcp -h` to list all tools.
- Tools: index_repository, search_graph, query_graph, trace_path,
  get_code_snippet, get_graph_schema, get_architecture, search_code,
  list_projects, delete_project, index_status, detect_changes,
  manage_adr, ingest_traces

## Use tools by MCP or CLI

- 如果 codebase-memory MCP tools 不存在或不可用，可以通过 `codebase-memory-mcp cli` 来代替，它们使用相同的 tool name 且功能完全相同。
- `codebase-memory-mcp cli <tool> [json]`，通过命令行参数传入 json string。
- `codebase-memory-mcp cli <tool> [<(cat json)]`，通过 stdin 传入 json string。
- cli 相比 MCP server 缺少 watch 文件修改时自动更新索引的功能。因此，你必须在第一次搜索前、文件修改后的下次搜索前，使用 `index_repository` tool 来更新索引，否则搜索结果可能是过时的。

```
# Pass in json string by argumnent
'{"repo_path": "."}'

# Pass in json string by stdin
codebase-memory-mcp cli index_repository <(cat '{"repo_path": "."}')
echo '{"repo_path": "."}' | codebase-memory-mcp cli index_repository
```
