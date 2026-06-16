# Architecture

## Overview

pixel-mixel is a fully-destructible 2D platformer where the world is composed of small atomic chunks that can transition between static terrain and physics-driven particles.

## Core Concepts

### Chunk
The atomic unit. A 4×4 screen pixel block with a single color. Cannot be subdivided. Has three possible states:
- **Static** — Part of the terrain grid. Immovable. Rendered with black borders on exposed edges.
- **Loose** — Freed from the grid. Falls with gravity, piles up. No border.
- **Liquid** — Flows via cellular automata. Falls, spreads laterally. Semi-transparent. No border.

### Tile
A 16×16 screen pixel region composed of 4×4 chunks (a convenience unit matching Terraria's tile scale). Not a first-class data structure — just a mental model for scale.

### Chunk Grid
Dense storage: `PackedByteArray` at 3 bytes per chunk (terrain type, color index, state). Indexed by `Vector2i`. Default size 256×144 chunks (1024×576 screen pixels).

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    WorldGenerator                         │
│  (orchestrates: pipeline → simulate → settled grid)      │
└──────────────┬──────────────────────────┬───────────────┘
               │                          │
               ▼                          ▼
┌──────────────────────────┐  ┌───────────────────────────┐
│     PipelineRunner       │  │     ChunkSimulator        │
│  (executes plugins in    │  │  (ticks until settled)    │
│   sequence on grid)      │  │  - Gravity (loose)        │
└──────────┬───────────────┘  │  - Liquid CA (flow)       │
           │                  │  - Loose sinks in liquid   │
           ▼                  └───────────────────────────┘
┌──────────────────────────┐
│   Generation Plugins     │
│  ┌─ SurfaceShapePlugin   │
│  ├─ TerrainFillPlugin    │
│  ├─ WaterPlacementPlugin │
│  ├─ LooseChunkPlugin     │
│  └─ PalettePlugin        │
└──────────────────────────┘

┌──────────────────────────┐  ┌───────────────────────────┐
│      ChunkGrid           │  │     ChunkRenderer         │
│  (data structure)        │◄─┤  (reads grid → Image)     │
│  - get/set/neighbors     │  │  - 4×4px per chunk        │
│  - 3 bytes per chunk     │  │  - Border logic           │
└──────────────────────────┘  │  - Liquid transparency    │
                              └───────────────────────────┘

┌──────────────────────────┐
│     TerrainDef (Resource) │
│  - palette: Color[4]     │
│  - density: float        │
│  └─ LiquidDef            │
│     - viscosity           │
│     - transparency        │
└──────────────────────────┘
```

## Data Flow

1. **Generation:** `seed + params` → `PipelineRunner` → plugins write to `ChunkGrid` sequentially
2. **Simulation:** `ChunkSimulator` ticks the grid (mutates in place) until no movement
3. **Rendering:** `ChunkRenderer` reads grid state → produces `Image` → displays as texture
4. **Runtime (future):** Player actions mutate grid → simulator runs → renderer updates

## Dependency Direction

```
Generation → ChunkGrid ← Renderer
                 ↑
            Simulator
```

All systems depend on `ChunkGrid` (the data). None depend on each other. This allows independent testing and replacement.

## Key Principles

- **Plugin architecture** — New generation behavior = new file, not edits (ADR-006)
- **Data-driven terrains** — New terrain = new `.tres` Resource, no code (ADR-007)
- **Deterministic** — Same seed + params = identical world. Always (ADR-004)
- **Simulation-settled** — World isn't ready until physics converge (ADR-011)

## File Layout

```
pixel-mixel/
├── AGENTS.md              # Agent conventions
├── project.godot          # Godot config
├── changelog.md           # Change log
├── docs/
│   ├── adr/               # Architecture Decision Records
│   ├── phase-0-spec.md    # Current phase spec
│   └── architecture.md    # This file
├── scripts/
│   ├── chunk_grid.gd      # Core data structure
│   ├── terrain_def.gd     # Terrain Resource base
│   ├── liquid_def.gd      # Liquid Resource extension
│   ├── world_generator.gd # Top-level orchestrator
│   ├── gen/               # Generation plugins
│   ├── sim/               # Physics simulation
│   └── render/            # Rendering
├── resources/             # .tres terrain definitions
├── assets/                # Art, audio
├── scenes/                # Godot scenes
├── tests/                 # Headless test scripts
└── tools/                 # Dev utilities
```

## ADR Index

| # | Title | Status |
|---|-------|--------|
| 001 | Chunk Size (4×4px) | Accepted |
| 002 | Chunk States (static/loose/liquid) | Accepted |
| 003 | Engine (Godot 4 + GDScript) | Accepted |
| 004 | World Gen Architecture (deterministic, pure function) | Accepted |
| 005 | Terrain Visual Style (palette + borders) | Accepted |
| 006 | Plugin Architecture | Accepted |
| 007 | Open/Closed Principle | Accepted |
| 008 | Single Responsibility | Accepted |
| 009 | Dependency Inversion + Interface Segregation | Accepted |
| 010 | Liskov Substitution | Accepted |
| 011 | Simulation-Settled Generation | Accepted |
| 012 | Liquid Cellular Automata | Accepted |
