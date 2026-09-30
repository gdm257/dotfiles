## Purpose

Defines two custom OpenSpec workflow schemas (trellis, trellis-prd-only) that run change planning inside a project's Trellis task directory while keeping OpenSpec's delta-spec and archive pipeline intact.

## ADDED Requirements

### Requirement: Schemas are discoverable by the OpenSpec CLI

The schemas SHALL be installed under the OpenSpec schemas directory with names `trellis` and `trellis-prd-only`, so that `openspec schemas` lists both.

#### Scenario: Listing schemas

- **WHEN** `openspec schemas` runs after installation
- **THEN** both `trellis` and `trellis-prd-only` appear in the output

### Requirement: trellis schema artifact chain

The `trellis` schema SHALL define artifacts `memories`, `prd`, `design`, `implement`, `specs` with dependency edges memories->prd, prd->design, prd->specs, design+specs->implement, and apply requiring `implement`.

#### Scenario: Creating a change with the trellis schema

- **WHEN** `openspec new change <name> --schema trellis` runs and `openspec status --change <name> --json` is inspected
- **THEN** the five artifacts appear with exactly those requires edges and applyRequires is `["implement"]`

### Requirement: trellis-prd-only schema artifact chain

The `trellis-prd-only` schema SHALL define artifacts `memories`, `prd`, `specs` with edges memories->prd, prd->specs, and apply requiring `specs`.

#### Scenario: Creating a change with the prd-only schema

- **WHEN** `openspec new change <name> --schema trellis-prd-only` runs and status is inspected
- **THEN** the three artifacts appear with exactly those requires edges and applyRequires is `["specs"]`

### Requirement: Planning artifacts are pointers into the Trellis task directory

The prd, design, and implement artifacts SHALL generate stub files in the change directory that point at the corresponding files under `.trellis/tasks/<task>/`, and their instructions SHALL place the real planning content in that Trellis task directory, creating it via trellis-runtime rather than the npm `trellis` command.

#### Scenario: Rendering the prd instruction

- **WHEN** `openspec instructions prd --change <name>` renders for either schema
- **THEN** the instruction requires `.trellis/` and a developer identity to exist (stopping with guidance instead of silently initializing when missing) and creates the task directory via `uvx trellis-runtime task create`

### Requirement: Shared instruction text matches spec-driven

The memories and specs artifacts of both schemas SHALL carry instruction text identical to the current `spec-driven` schema's memories and specs artifacts, preserving the delta-spec format rules (`#### Scenario` headings, `## Purpose`, store-aware root, skip_specs opt-out).

#### Scenario: Diffing shared instructions

- **WHEN** the rendered memories and specs instructions of `trellis` or `trellis-prd-only` are compared with those of `spec-driven`
- **THEN** the texts are identical

### Requirement: Apply embeds the inline implement procedure

The apply instruction of both schemas SHALL be agent-agnostic embedded guidance modeled on the trellis-implement agent definition: activate the Trellis task via trellis-runtime before writing code, load context (contextFiles, `.trellis/workflow.md` and `.trellis/spec/` as independent optional sources, each gated on existence, plus the change's planning artifacts when present), state the change boundary for non-trivial changes, work through the task checklist in order with lint/typecheck verification per task, forbid `git commit`, `git push`, and `git merge`, and forbid dispatching sub-agents. The `trellis-before-dev` skill MAY be mentioned only as an optional shortcut, never as the required entry point.

#### Scenario: Rendering apply guidance

- **WHEN** apply guidance is rendered for either schema
- **THEN** it embeds the context-loading and verification steps as plain instructions, mentions `trellis-before-dev` only as an optional shortcut, and forbids git commit/push/merge and sub-agent dispatch
