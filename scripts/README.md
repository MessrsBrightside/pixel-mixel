# scripts/

Runtime game scripts.

- `chunk_grid.gd` — Core data structure (position → chunk)
- `terrain_def.gd` / `liquid_def.gd` — Terrain type definitions (Resource base classes)
- `world_generator.gd` — Top-level pipeline orchestrator
- `player.gd` — Player character with chunk-grid collision, gravity, jump
- `gen/` — Generation plugins
- `sim/` — Physics simulation
- `render/` — Rendering
