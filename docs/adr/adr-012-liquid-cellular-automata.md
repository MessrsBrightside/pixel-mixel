# ADR-012: Liquid Simulation via Cellular Automata

- Date: 2026-06-16
- Status: Accepted

## Context

Water chunks need to flow and settle. Need a simulation approach that is deterministic, simple to implement, and converges to equilibrium.

## Decision

**Liquid simulation uses cellular automata.** Each liquid chunk evaluates its neighbors per tick and moves according to simple rules:

1. If empty below → fall
2. If blocked below and empty to the side → spread laterally
3. Evaluation order is fixed (e.g., left-to-right, bottom-to-top) for determinism

## Consequences

- Deterministic by construction — fixed evaluation order, no randomness in flow.
- Converges naturally: when no liquid chunk can move, the system is settled.
- No pressure simulation — water won't flow upward through U-bends. Acceptable for phase 0.
- Can be replaced with a pressure-based system later (open/closed — new plugin, same interface).
