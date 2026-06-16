# ADR-008: Single Responsibility

- Date: 2026-06-16
- Status: Accepted

## Context

GDScript projects tend to accumulate god-scripts. With terrain rendering, generation, physics, and interaction all touching chunk data, boundaries must be explicit from the start.

## Decision

**Each script/class has exactly one reason to change.**

- A generation plugin generates. It does not render.
- The chunk grid stores state. It does not know how to draw itself.
- The renderer reads chunk state and draws. It does not mutate state.
- The physics system moves loose chunks. It does not decide when chunks become loose.

## Consequences

- More files, smaller scripts. Each under ~100 lines where possible.
- Clear dependency direction: generation → grid ← renderer, grid ← physics.
- Testing is granular — test generation without rendering, test rendering with mock grid data.
