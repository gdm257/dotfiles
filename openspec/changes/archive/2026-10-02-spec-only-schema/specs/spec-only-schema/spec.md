## Purpose

Defines the `spec-only` OpenSpec workflow schema, which produces delta specs and nothing else: requirements come straight from chat-driven new work or are backfilled from existing code, commits, or another framework's artifacts, with no planning artifacts and no apply phase.

## ADDED Requirements

### Requirement: Schema is discoverable by the OpenSpec CLI

The schema SHALL be installed under the OpenSpec schemas directory with name `spec-only`, so that `openspec schemas` lists it with artifact chain `memories → specs`.

#### Scenario: Listing schemas

- **WHEN** `openspec schemas` runs after installation
- **THEN** `spec-only` appears with description covering both chat-driven ideas and backfill, and artifacts `memories → specs`

### Requirement: Artifact chain is memories then specs only

The `spec-only` schema SHALL define exactly two artifacts, `memories` and `specs`, with the single dependency edge memories->specs, and SHALL define no apply instruction.

#### Scenario: Creating a change with the schema

- **WHEN** `openspec new change <name> --schema spec-only` runs and `openspec status --change <name> --json` is inspected
- **THEN** exactly the two artifacts appear with that edge, and no planning artifact (proposal, design, tasks, tickets, prd) is scaffolded

#### Scenario: Apply degrades gracefully

- **WHEN** all artifacts are complete and apply guidance is rendered
- **THEN** the CLI reports planning complete and points at implementation, without requiring an apply instruction

### Requirement: Requirements come from a chat-named source

The specs instruction SHALL name two sources, chosen in the chat: new work (ideas not yet built, drafted as a behavior contract) and backfill (behavior that already exists as code, commits, or another framework's artifacts, distilled to observable behavior with implementation detail and the source framework's process dropped).

#### Scenario: Rendering the source section

- **WHEN** `openspec instructions specs --change <name> --schema spec-only` renders
- **THEN** the instruction opens by naming the two sources and defines backfill as distilling observable behavior only

### Requirement: Shared instruction text stays mechanically syncable

The memories instruction SHALL be identical to the current `spec-driven` schema's memories instruction. The specs instruction SHALL be identical to the current `matt-pocock` schema's specs instruction except for: the prepended source section, the proposal references rewritten to `identified above`, the skip_specs paragraph's final sentence replaced with asking the user when no capabilities were identified, and a trailing completion line. The `propose-capabilities` marker comments SHALL be retained.

#### Scenario: Diffing shared instructions

- **WHEN** the rendered memories instruction is compared with spec-driven's
- **THEN** the texts are identical

#### Scenario: Diffing the specs instruction

- **WHEN** the specs instruction is diffed against matt-pocock's
- **THEN** the only differences are the sanctioned source section, the identified-above rewrites, the skip_specs final sentence, and the trailing completion line

### Requirement: Zero-delta changes resolve through skip_specs or the user

The specs instruction SHALL preserve the `skip_specs: true` opt-out for zero-delta changes and SHALL direct the agent to ask the user before writing anything when no capabilities were identified and `skip_specs` is not set.

#### Scenario: No capabilities identified

- **WHEN** the instruction is followed for a change where capability research finds nothing to add or modify
- **THEN** the agent either finds `skip_specs: true` in the change's `.openspec.yaml` or asks the user, never invents a requirement to satisfy validation

### Requirement: Completion is gated on validation

The specs instruction SHALL end with the completion criterion that every identified capability has a spec file and `openspec validate` passes.

#### Scenario: Finishing the specs artifact

- **WHEN** the agent believes the specs artifact is done
- **THEN** it verifies `openspec validate` passes for the change before declaring completion
