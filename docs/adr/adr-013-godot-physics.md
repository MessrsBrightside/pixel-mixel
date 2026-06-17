# ADR-013: Godot Physics for Runtime (Hybrid Approach)

- Date: 2026-06-16
- Status: Accepted

## Context

The custom grid-based physics (cellular automata simulator) works for world generation settlement but fails at runtime gameplay:
- No velocity or momentum on loose chunks (they teleport, then fall straight down)
- Manual AABB collision is fragile and limited (no slopes, no bounce, no friction)
- Performance issues from coupling simulation to rendering
- "Flying chunks" require float-position tracking that the grid can't express

## Decision

**Use Godot's built-in physics for runtime gameplay. Keep grid-based simulation for world generation only.**

- **Player:** `CharacterBody2D` with `move_and_slide()`
- **Terrain collision:** `StaticBody2D` with collision polygons generated from chunk grid edges. Regenerated per-region on destruction.
- **Loose chunks:** Spawned as `RigidBody2D` nodes with velocity when freed. Fly, bounce, settle. Optionally snap back to grid at rest.
- **World generation:** Grid simulator still runs during generation to settle sand/water. At runtime, Godot physics takes over.

## Consequences

- Player movement becomes responsive with built-in slope handling, one-way platforms, etc.
- Freed chunks have real arcs, bounce, and momentum
- Collision regeneration on destruction is the main complexity (per-region, not whole-world)
- RigidBody2D count capped at ~500-1000 for performance (older chunks at rest get removed or re-gridded)
- Liquid simulation remains grid-based (cellular automata for water flow)
