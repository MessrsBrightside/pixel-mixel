# Phase 1 Spec: Biomes & Destruction

## Goal

Generate five visually distinct biomes with varied terrain, vegetation, and structures. Add basic destruction via a blade attack. Each biome is generated in isolation with committed snapshot screenshots for review.

## Biomes (500×144 chunks each = 2000×576 px)

| Biome | Surface | Underground | Vegetation | Special |
|-------|---------|-------------|------------|---------|
| Ocean Shore | Sand beach sloping into water | Stone | Palm trees, grass | Tidal water line |
| Forest Surface | Dirt with grass top layer | Stone | Evergreen + maple trees, grass | Dense canopy |
| Forest Lake | Dirt/grass around central lake | Stone | Maple trees, reeds/grass | Water body |
| Cave | Stone ceiling + floor, open middle | N/A (all enclosed) | Mushrooms, moss | Stalactites |
| Desert | Sand (always loose, pre-settled) | Stone | Cactus, sparse grass | No water |

## New Terrain Types

| Type | State | Passable | Toughness | Notes |
|------|-------|----------|-----------|-------|
| Grass (organic) | Static | Yes | Low | Green chunks on dirt surface + decorative blades |
| Leaves | Static | Yes | Low | Tree canopy |
| Wood | Static | Yes | Medium | Tree trunks |
| Sand | Loose (always) | No | Low | Never static, pre-settled on generation |
| Mushroom | Static | Yes | Low | Cave decoration |
| Cactus | Static | Yes | Medium | Desert vegetation |

Existing types (dirt, stone, water) carry over from phase 0.

## Chunk Properties (additions)

- **Passable:** Chunk renders and can be destroyed, but does not block player movement. Used for trees, grass, mushrooms.
- **Toughness:** Float on TerrainDef. Determines how much blade power a chunk absorbs before going loose. Stone=high, dirt=medium, leaves/grass=low.

## Vegetation Structures

Trees and decorations are composed of chunks in the grid:
- **Palm tree:** Wood trunk (3-5 chunks tall), leaf canopy at top
- **Evergreen:** Narrow wood trunk, triangular leaf mass
- **Maple:** Wood trunk, round leaf canopy
- **Cactus:** Green cactus chunks, columnar shape with arms
- **Mushroom:** Stem + cap, 2-4 chunks tall
- **Grass blades:** 1-2 chunks tall, on dirt surface

All vegetation is passable — player walks through. When destroyed, chunks become loose.

## Z-Ordering

- Background: parallax layers (behind everything)
- Terrain: static ground chunks
- Trees: behind player (z_index < player)
- Player
- Grass/decorations: in front of player (z_index > player)
- Occasional foreground tree (z_index > player)

## Parallax Backgrounds

- One per biome (sky color, distant features)
- Source: godot-games assets if suitable, otherwise simple gradient + shapes
- Scrolls at reduced rate relative to camera

## Destruction (Blade Attack)

- **Trigger:** Left mouse click
- **Direction:** Arc toward cursor position relative to player
- **Power budget:** Attack starts with N power, sweeps through chunks in arc
- **Toughness drain:** Each chunk hit reduces power by its toughness value
- **Effect:** Chunks whose toughness is overcome → state changes to LOOSE
- **Result:** Overcome chunks fall with gravity, blade stops when power depleted

## Character

- Scale: 2.5× (up from 1.5×)
- Hitbox adjusted to match new visual size
- Existing movement (walk, jump, gravity) carries over

## Deliverables

1. Five biome generation plugins (one per biome)
2. New terrain type resources (.tres) with toughness + passable properties
3. Tree/vegetation structure generators
4. Parallax background system
5. Blade attack system
6. Character scale update
7. Snapshot screenshots of each biome committed to repo

## Acceptance Criteria

### Biome generation
- **Test:** Each biome generates deterministically (same seed = same output)
- **Screenshot:** Committed PNG for each biome at seed 42, reviewable in repo
- **Test:** No biome crashes or produces empty world

### Terrain types
- **Test:** Sand chunks are always LOOSE state after generation
- **Test:** Passable chunks do not block player movement
- **Test:** All new terrain defs load and have valid palettes + toughness values

### Vegetation
- **Test:** Trees are composed of correct chunk types (wood trunk + leaf canopy)
- **Test:** Vegetation chunks are passable (player collision ignores them)
- **Screenshot:** Each tree type visible in its biome snapshot

### Parallax
- **Test:** Background renders behind terrain
- **Screenshot:** Visible in biome snapshots

### Destruction
- **Test:** Click converts static chunks to loose within blade arc
- **Test:** Power depletes faster through high-toughness material
- **Test:** Blade stops (no more conversions) when power = 0
- **Test:** Freed chunks fall with gravity
- **Screenshot:** Before/after destruction captured for one biome

### Character
- **Test:** Character at 2.5× scale collides correctly
- **Test:** Character passes through passable chunks

## Screenshot Requirements

All screenshots committed to `screenshots/phase1/`:
- `ocean_shore_seed42.png`
- `forest_surface_seed42.png`
- `forest_lake_seed42.png`
- `cave_seed42.png`
- `desert_seed42.png`
- `destruction_before.png`
- `destruction_after.png`

Screenshots are generated headlessly and committed. Visual review by human before phase is marked complete.

## Out of Scope

- Biome transitions / stitching biomes together
- Dynamic world expansion
- Inventory / item pickup
- Sound, UI, menus
- Enemy AI
- Multiplayer
