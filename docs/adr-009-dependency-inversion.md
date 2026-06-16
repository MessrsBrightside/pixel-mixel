# ADR-009: Dependency Inversion and Interface Segregation

- Date: 2026-06-16
- Status: Accepted

## Context

GDScript lacks formal interfaces but supports duck typing and base classes. We need systems to depend on abstractions so they can be tested and swapped independently.

## Decision

**Systems depend on abstract base classes, not concrete implementations.**

- Generation plugins extend a base `GenerationPlugin` class with a defined contract.
- Terrain types are `Resource` definitions — systems read properties, never check `if terrain == "dirt"`.
- The chunk grid exposes a narrow API (get/set/query neighbors). Consumers don't reach into its internals.

**Interfaces are segregated by consumer need:**
- The renderer only needs read access to chunk state + neighbor info.
- The physics system only needs to remove chunks from grid and spawn loose entities.
- Generation only needs write access to an empty grid.

## Consequences

- Base classes define the contract. Concrete plugins/systems implement it.
- No system knows more about another than it needs to.
- Mock/stub implementations are trivial for testing — pass a fake grid, verify output.
- Terrain definitions as Resources means the editor can create new terrains without code.
