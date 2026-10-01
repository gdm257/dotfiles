# Memories

## Sources gathered

- `CONTEXT.md` — read. Glossary covers the manifest system (Manifest / Run item / Defaults / Preset); no term touches OpenSpec schemas. Terms from `.scratch/spec-only-schema/spec.md` (new work / backfill) govern this change instead.
- `docs/adr/` — absent, skipped.
- openspec specs — inventory via `openspec list --specs`: `trellis-schemas` only. Read in full (`openspec show trellis-schemas --type spec`): defines the sibling custom schemas trellis / trellis-prd-only, including the precedent that shared instruction text matches spec-driven byte-for-byte. No spec covers spec-only; new capability, no near-duplicate.
- `.trellis/spec/` — absent, skipped.

## Constraints carried forward

- trellis-schemas requirement "Shared instruction text matches spec-driven" establishes the verbatim-copy invariant this change's spec must state for its own shared text (spec-driven memories, matt-pocock specs instruction).
- Capability naming follows the existing flat layout (`trellis-schemas` → `spec-only-schema`).
