# Apply instruction for the `trellis` / `trellis-prd-only` OpenSpec schemas

Research date: 2026-09-30. Scope: primary sources only (agent definitions, bundled Trellis workflow doc, OpenSpec schemas and skills in this repo).

## Recommendation

Model the apply instruction on `trellis-implement.md`, but **embed its portable content directly** rather than routing to the agent or to a skill:

- Keep the universally applicable parts: the context-loading list, the forbidden git ops, the lint/typecheck verify step, and the code standards.
- Drop or rewrite the role-specific parts: the recursion guard (premised on being a dispatched sub-agent) becomes one agent-agnostic sentence ("implement yourself; do not dispatch sub-agents"), and the report format is dropped because `openspec-apply-change` already defines apply-phase output.
- Revise the earlier decision ("Call the Skill tool trellis-before-dev" + supplement) to **embed before-dev's steps as plain instructions, mentioning the skill only as an optional shortcut**. `openspec instructions apply` renders the instruction as prompt text to an arbitrary agent; "Call the Skill tool" only works in a Claude-Code session with that skill installed (the matt-pocock schema is the precedent, and its least portable part). The embedded steps are plain file reads any agent can follow.

Draft (verbatim candidate for both schemas; instruction body is 19 lines):

```yaml
apply:
  requires: [ <tasks artifact id> ]
  tracks: <tasks artifact file>
  instruction: |
    Implement this change's tasks yourself; do not dispatch sub-agents.
    First activate the Trellis task: run `uvx trellis-runtime task start
    <task-dir>` with the task directory the prd artifact points to (skip
    if it is already active). `start` is idempotent. If it errors with a
    session-identity hint, follow the hint, then retry.
    Before writing code:
    - Read every file in `contextFiles` from `openspec instructions apply --json`.
    - If `.trellis/workflow.md` exists, read it.
    - If `.trellis/spec/` exists, load it: run `uvx trellis-runtime
      get-context --mode packages`, read the index.md of every spec layer
      this change touches plus `.trellis/spec/guides/index.md`, then read
      the guideline files those indexes point to. If the
      `trellis-before-dev` skill is available, you may call it instead of
      doing this manually.
    - Read the change's design and implementation-plan artifacts when present.
    For non-trivial changes, state the change boundary before writing code.
    Then, for each pending task in order:
    - Follow existing code patterns; implement only what the task requires.
    - Verify with the project's lint and typecheck commands; fix failures
      before moving to the next task.
    - Mark the task complete in the tasks file as you go.
    Pause on blockers, unclear tasks, or issues that need artifact updates.
    Never run `git commit`, `git push`, or `git merge`; committing happens
    outside apply.
```

The same instruction serves `trellis` and `trellis-prd-only`: the prd-only variant simply has no design/implement artifacts, covered by "when present". Only `requires`/`tracks` differ per schema.

Amendment (2026-09-30, post-review): the draft's closing line cited "Trellis Phase 3.4" as the reason for the git ban. Dropped — the schema must not assume `workflow.md` has a specific structure (users may customize their workflow, moving or removing the commit phase). The ban itself stands on `trellis-implement.md`'s Forbidden Operations, not on workflow.md.


Amendment 2 (2026-09-30): replaced the `python ./.trellis/scripts/task.py` / `get_context.py` fallbacks with `uvx trellis-runtime` uniformly — one entry point, no dependency on vendored scripts.

Amendment 3 (2026-09-30): split the apply bullet — `.trellis/workflow.md` and `.trellis/spec/` are independent optional sources, not a chain. Loading guidelines is now gated on `.trellis/spec/` existing, not on workflow.md; neither is a hard dependency (only the task-directory mechanism is, and only for prd/design/implement placement).

Amendment 4 (2026-09-30): apply now activates the task first — `uvx trellis-runtime task start <task-dir>` before writing code (workflow step 1.4 moved into apply; idempotent, skipped if already active, retry per session-identity hint). `task finish` / `task archive` remain user-owned, outside apply.

## Evidence

### 1. `trellis-implement.md` — what transfers vs what is role-specific

Source: `pub-merge-recursive/AppData/Roaming/skillshare/agents/trellis-implement.md` (byte-identical to `C:/Users/demo/.claude/agents/trellis-implement.md`).

Role-specific — do not copy verbatim:

- Recursion Guard (lines 10–16): "You are already the `trellis-implement` sub-agent that the main session dispatched… Do NOT spawn another `trellis-implement` or `trellis-check` sub-agent." The premise (being a dispatched sub-agent) is false for an OpenSpec apply run; the behavioral content ("do the work directly, never spawn implement/check") survives as draft line 1. `workflow.md` line 228 confirms dispatch is main-session-only, so an apply run inside the session must not dispatch.
- Report Format (lines 74–93): superseded by `openspec-apply-change/SKILL.md`'s own "Output During Implementation" / "Output On Completion" / "Output On Pause" contracts.
- The `Active task:` dispatch-prompt prefix (workflow.md lines 223, 229, 495) is a sub-agent-dispatch mechanism; not applicable to a single inline apply run.

Universally applicable — kept in draft:

- Context list (lines 18–24): `.trellis/workflow.md`, `.trellis/spec/`, task `prd.md`, `design.md` if exists, `implement.md` if exists.
- Forbidden Operations (lines 35–41): `git commit`, `git push`, `git merge` (frontmatter line 4: "No git commit allowed").
- Verify (lines 68–70): "Run project's lint and typecheck commands to verify changes."
- Code standards (lines 97–101): follow existing patterns, no unnecessary abstractions, only what's required.

### 2. Other trellis-* agents

`C:/Users/demo/.claude/agents/` and the in-repo `pub-merge-recursive/AppData/Roaming/skillshare/agents/` contain the same trellis set:

- `trellis-check.md` — reviews `git diff` against specs and task artifacts, self-fixes issues, runs typecheck/lint; has its own recursion guard and "Fix issues yourself" rule. Apply must not cause a dispatch of it — the draft's "do not dispatch sub-agents" covers this.
- `trellis-research.md` — search-and-persist only; writes to `{TASK_DIR}/research/`; "Any git operation (commit / push / branch / merge)" is forbidden. Independent corroboration that Trellis agents never commit.
- `spec-reviewer.md` — cross-spec consistency reviewer across generated specs; a read-only reviewer, irrelevant to apply.
- (The in-repo copy additionally contains `semble-search.md`; not Trellis-related.)

### 3. Bundled `workflow.md` — Phase 2 dispatch and the before-dev relationship

Source: `pub-merge-recursive/AppData/Roaming/skillshare/skills/trellis-workflow/resources/.trellis/workflow.md`.

- Sub-agent mode (lines 225–230, `[workflow-state:in_progress]`): `trellis-implement` / `trellis-research` are "sub-agent types only (Task/Agent tool, NOT Skill…)"; "Main-session default: dispatch implement/check sub-agents"; dispatch prompt starts with `Active task: <path>`; read order "jsonl entries -> `prd.md` -> `design.md` if present -> `implement.md` if present".
- Inline mode (lines 237–241, `[workflow-state:in_progress-inline]`; rationale comment lines 199–203): the main session edits code directly and "the inline workflow loads `trellis-before-dev` instead of injecting JSONL into a sub-agent"; read order prd → design → implement plus specs loaded by skills.
- Therefore **before-dev is the inline-mode substitute for the implement agent's context injection, not an additional main-session step**. An OpenSpec apply run is an inline run (the apply skill executes in the calling session), so the apply instruction plays the inline role: embed before-dev's content. That embedding is exactly the analog of the agent's own Context section, not a duplication of it.
- Commit placement: both flows end "… -> `trellis-update-spec` -> commit (Phase 3.4)" (lines 227, 238). Commit is a Phase 3.4 step after implement/check — supports the draft's prohibition inside apply.
- Step 1.3 note (line 432): for inline platforms, "Skip this step. Context is loaded directly by the `trellis-before-dev` skill in Phase 2." — again before-dev = inline context loading.

### 4. `trellis-before-dev/SKILL.md` overlap with trellis-implement

Source: `pub-merge-recursive/AppData/Roaming/skillshare/skills/trellis-before-dev/SKILL.md`.

- Steps 1–6 (lines 10–35) restate trellis-implement's Context + Understand Specs sections concretely: read `prd.md` / `design.md` if present / `implement.md` if present (lines 11–13); discover packages via `get_context.py --mode packages` (step 2); read each relevant `<package>/<layer>/index.md` and follow its "Pre-Development Checklist" (steps 4–5); always read `.trellis/spec/guides/index.md` (step 6). The implement agent says only "read `.trellis/spec/`" — the draft embeds before-dev's procedure because it is the operational detail the agent's one-liner points at.
- Unique to before-dev: step 7 (line 38), "state the change boundary before writing code" for non-trivial tasks — absent from trellis-implement.md; kept in the draft as a one-line pointer.
- Line 51: the procedure is "**mandatory** before writing any code" — reflected in the draft's "Before writing code" block.

### 5. Existing apply instructions (convention)

- `pub-merge-recursive/AppData/Local/openspec/schemas/spec-driven/schema.yaml` lines 254–259: `apply:` with `requires: [tasks]`, `tracks: tasks.md`, and two lines of imperative prose ("Read context files, work through pending tasks, mark complete as you go. / Pause if you hit blockers or need clarification."). The draft keeps this shape (work-through / mark-as-you-go / pause) at trellis's higher rigor level.
- `pub-merge-recursive/AppData/Local/openspec/schemas/matt-pocock/schema.yaml` lines 178–182: apply is "Call the Skill tool \"implement\". / Read context files, work through pending tickets." — the skill-routing precedent, but it silently requires a Claude-Code session with the `implement` skill installed. The portable `openspec-apply-change` skill is what consumes apply instructions, hence embed + optional-skill-mention in the draft.

### 6. How `openspec-apply-change` consumes apply guidance

Source: `pub-merge-recursive/AppData/Roaming/skillshare/skills/openspec-apply-change/SKILL.md`.

- Step 3 fetches `openspec instructions apply --json`; step 5 displays the "Dynamic instruction from CLI". The instruction is **rendered as prompt text** to whichever agent runs the skill; nothing executes it as a tool call. So "Call the Skill tool X" works only if the running agent has both a Skill tool and that exact skill — confirming the portability concern.
- Step 4: "Read every file path listed under `contextFiles`" — the draft's first bullet reuses this channel, keeping artifact file names out of the instruction so it stays valid for both schemas' layouts.
- **No commit prohibition exists in the skill**: its Guardrails cover task scoping, checkbox discipline (`- [ ]` → `- [x]`), and pause conditions — nothing about git. The draft's git ban therefore introduces no inconsistency; it aligns apply with Trellis (trellis-implement Forbidden Operations, trellis-research git ban, workflow.md Phase 3.4 commit step).
- The skill's guardrails already say "Pause on errors, blockers, or unclear requirements" and "Update task checkbox immediately after completing each task" — the draft's pause/mark lines are consistent reinforcement, kept because the instruction must stand alone even for agents that skip the skill's boilerplate.

## Open questions

- `requires` / `tracks` values for the new schemas (which artifact holds the task list; whether trellis-prd-only tracks a different file) — decided by the schema-definition work, outside these sources.
- `python` vs `python3`: `workflow.md` uses `python3`, `trellis-before-dev/SKILL.md` uses `python`. The draft follows before-dev (Windows-friendlier); pick per target platform.
- Whether before-dev step 7's full change-boundary checklist (five bullets, lines 38–46) should be embedded in full or left as the draft's one-line pointer.
