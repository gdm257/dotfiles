---
outputs:
  - ~/.codex/AGENTS.md
---

If you're using codex, follow the instructions.

- Use `tool_search` tool to enable subagent tools (`spawn_agent` `wait_agent` `interrupt_agent` `list_agents` `send_message` `followup_task` etc) if you need spawn or manage subagent. V1 tools are Deferred until `tool_search`.
- WHEN `shell_command` tool call returned SSL errors or failed to read/write files outside the workspace THEN use `shell_command` argument `"sandbox_permissions": "require_escalated"` to privilege escalation.
- WHEN 你想使用 grep / rg / Select-String; IF 任何 instructions/rules/description/mcp/skills 声称能够替代 grep 或者比起 grep 更推荐其他工具; THEN 你应该遵循指令使用该工具，而不是使用 grep/rg/Select-String，推荐的工具通常有更丰富的功能，例如语义搜索、模糊搜索、graph、relationships 等，更适合 explore codebase，只有这些工具不可用或你确信你必须用 grep/rg/Select-String 才使用
