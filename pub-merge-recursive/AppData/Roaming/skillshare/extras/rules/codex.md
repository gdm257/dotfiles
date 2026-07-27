---
outputs:
  - ~/.codex/AGENTS.md
---

If you're using codex, follow the instructions.

- WHEN `shell_command` tool call returned SSL errors or failed to read/write files outside the workspace THEN use `shell_command` argument `"sandbox_permissions": "require_escalated"` to privilege escalation.
- WHEN 你想使用 grep / rg / Select-String; IF 任何 instructions/rules/description/mcp/skills 声称能够替代 grep 或者比起 grep 更推荐其他工具; THEN 你应该遵循指令使用该工具，而不是使用 grep/rg/Select-String，推荐的工具通常有更丰富的功能，例如语义搜索、模糊搜索、graph、relationships 等，更适合 explore codebase，只有这些工具不可用或你确信你必须用 grep/rg/Select-String 才使用
- IF any MCP tool not found THEN Use `tool_search` tool to load deferred `mcp__*` tools.

## Windows约束
当前环境是 Windows 10 / pwsh7
- 默认禁止使用 Bash 语法，除非确定此shell处在 Linux 环境
- 不要使用 Bash 引号/转义习惯，在 PowerShell 命令里，复杂正则优先用单引号包裹。
- 如果正则本身同时包含单引号和双引号，优先拆成多个简单 rg 命令。
- 禁止使用 Bash heredoc + 重定向 `>` 例如 `cat > file << 'EOF'`，PowerShell 不支持。改用 PowerShell here-string 加管道 `|`。
- pwsh 中，语句块表达式（如 `foreach`、`if`）不能直接作为管道输入。 需要先使用 `$()` / `@()` 包裹，或先赋值给变量。 普通命令输出可直接进入管道，无需额外包裹。
- PowerShell 使用 `rg` 时，通配目录必须先用 `Get-ChildItem -Filter` 展开为真实路径，禁止直接把含 `*` 的搜索路径传给 `rg`。
- `rg` 正则包含 `|`、`(`、`)`、`\` 等字符时，用单引号包住 pattern，避免 `|` 被解析成 PowerShell 管道。
- Use `rg --pcre2` for regex look-around: `(?!...)`, `(?=...)`, `(?<!...)`, `(?<=...)`.
- 一句话:绝大多数情况下能用 `apply_patch` 就用 `apply_patch`。涉及多行、非 ASCII、或既有文件覆写的写入,没有理由走 shell 拼接,用 `apply_patch`。新建或大段改写源文件优先 `apply_patch`(原子、带校验);只有单行无引号/斜杠冲突的纯替换才用 `sed -i`;禁止对已跟踪既有文件直接 `open("w")` / `Out-File` / `Set-Content` 覆盖写——非原子,写失败会先截断丢数据，而且可能面临 PowerShell 编码、换行符、转义错误。
- In PowerShell, quote complex `rg` patterns with single quotes and escape `'` as `''`.
- Use `rg -F` for fixed strings; test complex commands before sharing.
- For broad file or text searches, prefer `rg` / `rg --files` over recursive `Get-ChildItem`. Start from the narrowest known directory. When searching large trees such as the user home directory, exclude high-noise directories like `.git`, `node_modules`, virtualenv folders, and package caches, and use `--hidden` only when hidden directories are relevant.
- 编码规范：脚本文件生成与读写必须使用 pwsh (PowerShell 7+) 且强制指定 `-Encoding UTF8`，防止 non-ASCII 字符乱码。PowerShell 5.1 的 -Encoding utf8 强制带 BOM，禁止使用 PowerShell 5.1 进行任何字符处理。
- When creating or writing text files from PowerShell, specify `-Encoding UTF8` when the cmdlet supports it.
- 管道与对象优先：在处理数据解析时，优先使用 PowerShell 的对象管道特性（如 `Select-Object`, `Where-Object`），避免过度依赖传统的文本截取。
- 需要在 `-Command` 脚本中使用 `$p/$i/$lines` 等变量时，必须确保这些 `$` 没有被外层 PowerShell展开：优先使用外层单引号，或用反引号转义 `$`。
- 如果外层 shell 也是 PowerShell，传给 `-Command` 的脚本优先用单引号包住，避免 `$变量` 被外层提前展开。
- 虽然本节包含大量 PowerShell 技巧，但记住，绝大部分情况下，使用 `apply_patch` tool 来修改文件，而不是 powershell 命令行。
