# ADR-007: Open/Closed Principle

- Date: 2026-06-16
- Status: Accepted

## Context

Systems in this project will grow — new terrain types, new generation passes, new chunk interactions, new physics behaviors. We need to extend without rewriting.

## Decision

**All core systems are open for extension, closed for modification.**

Concretely:
- **World generation:** New behavior = new plugin. Never modify an existing plugin to add unrelated functionality.
- **Terrain types:** Adding a terrain type means providing palette data and material properties. The rendering and generation systems consume terrain definitions without being edited.
- **Chunk interactions:** New interactions (conveyor belts, water flow, etc.) are added as new systems that read/write chunk state. They don't require changes to the chunk data structure itself.

## Consequences

- Terrain types are data-driven — defined in resource files, not hardcoded in logic.
- Systems depend on interfaces/contracts, not concrete implementations.
- Adding new features should require creating new files, not editing existing ones (with rare exceptions for wiring/registration).
