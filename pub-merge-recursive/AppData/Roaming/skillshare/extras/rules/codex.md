---
outputs:
  - ~/.codex/AGENTS.md
---

If you're using codex, follow the instructions.

- Use `tool_search` tool to enable subagent tools (`spawn_agent` `wait_agent` `interrupt_agent` `list_agents` `send_message` `followup_task` etc) if you need spawn or manage subagent. V1 tools are Deferred until `tool_search`.
- WHEN `shell_command` tool call returned SSL errors or failed to read/write files outside the workspace THEN use `shell_command` argument `"sandbox_permissions": "require_escalated"` to privilege escalation.
