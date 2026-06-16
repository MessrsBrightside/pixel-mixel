# ADR-002: Chunk State Model

- Date: 2026-06-16
- Status: Accepted

## Context

Chunks are not "destroyed" — they transition between states. The world needs to support terrain that can be broken free and then interacted with as physics objects.

## Decision

**Chunks have two primary states: static and loose.**

- **Static:** Part of the terrain grid. No physics. Rendered as part of the chunk texture. Collidable as solid ground.
- **Loose:** Freed from the grid. Subject to gravity and physics. Can be interacted with — picked up by the player, pushed by conveyor belts, carried by wind, etc.

## Consequences

- The terrain grid stores only static chunks. When a chunk becomes loose, it's removed from the grid and spawned as a physics entity.
- Loose chunks are individual physics bodies (or batched via particle systems with collision).
- Loose chunks retain their color/material type — they're the same "stuff," just mobile.
- Future interactions (pickup, conveyors, water flow, etc.) operate on loose chunks as a common entity type.
- Performance constraint: we need to cap or pool loose chunks. A large explosion freeing 500+ chunks simultaneously needs to remain playable.
- Loose chunks may re-settle into static state (e.g., sand piling up) — this is a future consideration, not required for initial scope.

## Alternatives Considered

- **Destroy on break (chunks vanish):** Simpler but loses the core interaction model.
- **Three states (static/loose/collected):** Premature. "Collected" is just a loose chunk entering inventory — handled by game logic, not the chunk system itself.
