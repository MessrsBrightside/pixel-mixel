# ADR-004: World Generation Scope

- Date: 2026-06-16
- Status: Accepted

## Context

Need to define initial world generation scope. The goal is a testable, visually appealing small world — not a full game world yet.

## Decision

**Small fixed sandbox world with three zones: sky, surface, underground.**

- World size: small (exact dimensions TBD — think "fits on a few screens")
- Zones: sky (empty), surface (terrain boundary with contour), underground (solid with variation)
- Seeded generation: deterministic output for a given seed
- Harness-first: generation parameters are exposed and controllable so we can write regression tests against known seeds/configs

## Consequences

- World gen is a pure function: seed + params → chunk grid. Easy to test, easy to snapshot.
- No dynamic expansion yet — the world is fully generated up front.
- The harness lets us catalog visual outputs and catch regressions as we change generation algorithms.
- "Looks good" is validated via snapshot tests against known-good baselines (same pattern as not-terraria).
- Future: dynamic expansion is a separate system that calls the same generation functions for new regions.

## Open Questions (deferred)

- How many terrain types at launch? (Next question)
- Exact world dimensions in tiles/chunks?
- Cave generation algorithm (Perlin worms, cellular automata, etc.)?
