# AGENTS.md

## Project

pixel-mixel — Godot 4 fully-destructible 2D platformer with chunk-based physics. GDScript.

## Architecture

See `docs/adr-*.md` for all architectural decisions. Key points:
- World is a grid of 4×4px chunks (16 per tile)
- Chunks are static, loose, or liquid
- World generation is a plugin pipeline: seed + plugins → chunk grid → simulate → settled world
- SOLID principles throughout — plugin architecture, single responsibility, data-driven terrain

## Metadata Convention

Every file created in this project MUST have a companion `<filename>.why.md` file in the same directory. No exceptions — scripts, scenes, images, resources, configs. This makes intent consistently discoverable via a single pattern: `find . -name "*.why.md"`.

### Format

```markdown
# <filename>

- Created: YYYY-MM-DD
- Intent: Why this file exists (one line)
- Issue: #<number> or "none"
- Status: active | deprecated | replaced-by:<path>
```

### Status Values
- `active` — File is live and in use
- `deprecated` — No longer used, pending removal
- `replaced-by:<path>` — Superseded by another file

### Lifecycle
- When creating a file → create its `.why.md` at the same time
- When a file becomes obsolete → update status to `deprecated` or `replaced-by:`
- Periodic cleanup: `find . -name "*.why.md" | xargs grep "deprecated"` → review and remove

## Scratch Folder

`scratch/` is gitignored. All short-lived files go here:
- Experiment scripts, temp outputs, draft diagrams, prototype code
- Scratch files do NOT need `.why.md` files (they're ephemeral by definition)

**Rule:** If it might be thrown away within a session → `scratch/`. If it survives and proves useful → promote to proper directory WITH metadata.

## Changelog

Every change to the project must be logged in `changelog.md` at the project root.

### Format

```markdown
## YYYY-MM-DD

- [#<issue>] Brief description of what changed
```

### Rules
- Append to the top (newest first)
- One bullet per logical change (not per file)
- Include the issue number if applicable
- Log it at commit time — not after the fact

## GitHub Workflow

- **GitHub Projects board** for phase-level tracking
- **GitHub Issues** for discrete implementation tasks
- Every PR references an issue
- Every issue references its phase

## Code Style

- GDScript with static typing
- Godot 4 conventions
- `class_name` for reusable classes
- Extract logic when a script exceeds ~100 lines
- Base classes define contracts for plugin/system interfaces

## Testing

- Deterministic seeded generation — same seed = same output
- Unit tests for invariants (nothing floating, water settled, etc.)
- Snapshot tests for visual regression (baseline PNGs committed)
- Test harness supports running generation with arbitrary params

## Key Directories

```
scripts/          — Runtime game scripts
scripts/gen/      — Generation plugin scripts
scripts/sim/      — Physics simulation scripts
scripts/render/   — Rendering scripts
resources/        — Terrain definitions, pipeline configs
tests/            — Test scripts and baselines
tools/            — Developer utilities
docs/             — ADRs, specs, retrospectives
scratch/          — Ephemeral experiments (gitignored)
```
