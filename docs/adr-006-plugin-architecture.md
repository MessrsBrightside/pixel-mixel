# ADR-006: Modular Plugin Architecture

- Date: 2026-06-16
- Status: Accepted

## Context

The world generator is not a single hardcoded algorithm — it's a system that composes generators. Future needs include different biomes, cave systems, ore placement, structures, etc. We need an architecture that allows adding new generation behavior without modifying existing code.

## Decision

**The world generator is a pipeline of composable plugins.** Each plugin implements a common interface and operates on the chunk grid. Plugins are registered, ordered, and executed in sequence.

Example pipeline for phase 0:
1. `SurfaceShapePlugin` — defines terrain contour (where sky meets ground)
2. `TerrainFillPlugin` — fills zones with terrain types (dirt near surface, stone below)
3. `PalettePlugin` — assigns chunk colors from terrain palettes using noise

New behavior (caves, ores, trees) is added by writing a new plugin and inserting it into the pipeline. Existing plugins are never modified to accommodate new ones.

## Consequences

- Adding a cave system means writing `CaveCarverPlugin`, not editing `TerrainFillPlugin`.
- Plugin order matters — carvers run after fill, decorators run after carvers.
- Each plugin has a clear, testable responsibility. Can be snapshot-tested in isolation.
- The pipeline configuration is data — can be swapped for testing or different world presets.
