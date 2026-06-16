# ADR-011: Simulation-Settled Generation

- Date: 2026-06-16
- Status: Accepted

## Context

The world generator places water and loose chunks in initial positions. These need to obey physics (water flows, loose chunks fall) before the world is considered "ready." We don't want the player to load into a world where water is floating mid-air.

## Decision

**World generation includes a simulation phase that runs until the world reaches equilibrium.** The generator pipeline is: place → simulate → settle → done.

- After plugins place all chunks (static, loose, liquid), the physics simulation runs.
- Loose chunks fall and pile up. Liquid chunks flow and fill basins.
- Simulation ticks until no chunk has moved for N consecutive frames (settled).
- The settled state is the initial world the player sees.

## Consequences

- The simulation system must exist in phase 0 — it's not deferred.
- Determinism is critical: same seed + same params + same simulation rules = identical settled world. The sim must be deterministic (fixed-step, no float drift, ordered evaluation).
- Snapshot tests capture the *settled* output, not the raw plugin output.
- Generation time is longer (sim must converge), but this is offline/load-time work.
- The same simulation that settles the world at gen-time is the one that runs during gameplay when the player breaks things. One system, two contexts.
