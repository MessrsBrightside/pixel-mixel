# ADR-005: Terrain Visual Style

- Date: 2026-06-16
- Status: Accepted (revised)

## Context

Each chunk is 4×4 screen pixels, single solid color. Need to define how terrain looks intact and how borders work across states.

## Decision

- **Small palette per terrain type** (3-4 shades). Chunks within a terrain use noise to pick from the palette, giving a granular "pile of stuff" look.
- **Soft merge within same terrain.** Adjacent chunks of the same terrain type flow together — no border between them.
- **Black border (1px) on edges adjacent to air or other static chunks.** Any static chunk edge touching empty space OR a different static terrain type gets a black pixel border on that side.
- **Loose chunks have NO black border.** When freed, chunks are just their terrain color — a solid 4×4 block. Mixed loose piles of different terrain types are visually distinct by color alone, no outlines.

## Consequences

- The border is a property of being *static and exposed*, not intrinsic to the chunk.
- Border is recomputed from neighbor state — when a neighbor is destroyed, the newly-exposed edge gains a border.
- Loose chunks are visually simpler: just colored squares. Cheaper to render, and mixed piles look natural without hard outlines around every grain.
- Different terrain types in loose piles are distinguished by palette color alone.
- Loose chunks will eventually have material properties (density, weight) affecting physics behavior, but visual rendering is just flat color.
