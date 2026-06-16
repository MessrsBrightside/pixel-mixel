# ADR-003: Engine and Language

- Date: 2026-06-16
- Status: Accepted

## Context

Need to choose engine and primary language. The project has per-chunk physics and dynamic texture updates as hot paths.

## Decision

**Godot 4 with GDScript.** Optimize later via GDExtension or compute shaders only if profiling demands it.

## Consequences

- Consistent with not-terraria — shared tooling knowledge, agent infrastructure, testing patterns.
- GDScript is fast enough for the initial scope (world generation + static rendering). Loose chunk physics will need profiling once interactive.
- If the loose chunk simulation becomes a bottleneck, the chunk physics loop is an isolated system that can be ported to GDExtension without rewriting the rest.
