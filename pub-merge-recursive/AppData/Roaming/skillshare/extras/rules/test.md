---
outputs:
  - ~/.claude/rules/test.md
  - ~/.codex/AGENTS.md
  - ~/.config/opencode/AGENTS.md
  - ~/.omp/agent/AGENTS.md
  - ~/.zcode/AGENTS.md
---

- ONLY write unit tests. Consider smoke tests, E2E tests and integration tests only as a last resort.
- Keep zero external dependencies for tests.
- Tests should be run on all supported platforms.
- Time is of the essence, Time is money. Do NOT waste time to run CI during implementation especially for compiled languages; wait until all modifications are complete, then do centralized compilation and testing once.
- Do NOT use `cargo check` `cargo test` `cargo build` `make build` or similar CI commands during implementation, unless the user explicitly requests it, it is in a TDD workflow or the project uses scripting languages which don't need to compile or is extremely fast for build (e.g. JavaScript, TypeScript, Python). These commands will consume a large amount of time, and they should NOT use during implementation. To ensure the correctness, use LSP tools instead of CI commands.
