# ADR-001: Chunk Size

- Date: 2026-06-16
- Status: Accepted (revised)

## Context

The game world is composed of "tiles" (16×16 screen pixels, matching Terraria's tile size). Each tile is subdivided into atomic chunks — the smallest destructible unit. A chunk is a single solid color and cannot be partially destroyed.

We need a chunk size that balances destruction fidelity, visual quality, memory cost, and consistent feel across devices.

## Decision

**4×4 screen pixels per chunk.** Each tile contains 4×4 = 16 chunks.

## Rationale for Revision

Originally chose 2×2 (64 chunks/tile). Revised to 4×4 because:
- At 4×4, a chunk is large enough to have a 1px black border on exposed edges while still reading as its terrain color (the interior 2×2 area carries the palette color).
- At 2×2, a border would consume the entire chunk visually.
- 4×4 gives a chunkier, more readable destruction aesthetic that suits the "pile of things" look.

## Consequences

- 16 chunks per tile. A small world (400×240 tiles) costs ~1.5 MB for chunk data.
- Destruction is coarser than 2×2 but still sub-tile. A single tile breaks into 16 pieces.
- Each chunk rendered at 4×4 screen pixels can show a 1px black border on exposed sides and still have visible terrain color fill.
- Loose chunks as physics bodies: 16 per tile keeps particle counts very manageable.

## Alternatives Considered

- **2×2 chunks (64/tile):** Too small to carry both a border and a visible fill color. Finer destruction but border rendering breaks down.
- **1×1 chunks (256/tile):** Maximum fidelity, maximum cost. Border concept doesn't apply at single-pixel scale.
