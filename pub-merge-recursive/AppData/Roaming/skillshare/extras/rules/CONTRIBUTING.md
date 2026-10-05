---
outputs:
  - ~/.claude/rules/CONTRIBUTING.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
---
This is the inline CONTRIBUTING.md for all projects. You should treat this as extra guidelines or a fallback if `CONTRIBUTING.md` does not exist in project directory.

Source related guidelines and standards if it exists; missing sources are skipped silently, never created.

- `GLOSSARY-MAP.md` `CONTEXT-MAP.md`
- `GLOSSARY.md` `CONTEXT.md`
- `docs/adr/`
- `**/docs/adr/`
- `**/AGENTS.md`
- `**/CLAUDE.md`
- `openspec list --specs` or `openspec/specs/`
- `.trellis/spec/**/index.md`
- Call the Skill tool "open-code-review-delegate", and run `ocr` to find rules
