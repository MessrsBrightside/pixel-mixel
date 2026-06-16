# Phase 0 Spec: World Generation

## Goal

A seeded world generator that produces a small platformer world with static terrain, loose chunks, and water — simulated to equilibrium — rendered correctly on screen.

## Deliverables

### 1. World Generator Pipeline

A configurable pipeline that takes a seed + plugin list and outputs a settled chunk grid.

**Plugins for phase 0:**
- `SurfaceShapePlugin` — generates terrain contour (height map separating sky from ground)
- `TerrainFillPlugin` — fills surface layer with dirt, below with stone
- `WaterPlacementPlugin` — places water sources in depressions/basins
- `LooseChunkPlugin` — scatters loose chunks (gravel/debris on surfaces or in cavities)
- `PalettePlugin` — assigns chunk colors from per-terrain palettes via noise

### 2. Chunk Grid

Data structure storing the world state:
- Position → chunk (terrain type, color, state)
- States: static, loose, liquid
- API: get, set, query neighbors, iterate region

### 3. Physics Simulation

Runs after generation plugins complete. Ticks until settled (no movement for N frames).
- **Loose chunks:** fall with gravity, pile on surfaces
- **Liquid chunks:** cellular automata — fall, spread laterally, settle in basins
- **Static chunks:** immovable (not affected by simulation)
- Deterministic: fixed evaluation order, no randomness in tick logic

### 4. Renderer

Draws the settled chunk grid to screen:
- Each chunk = 4×4 screen pixels
- Static chunks: terrain palette color + 1px black border on edges exposed to air or different terrain
- Same-terrain adjacency: no border between them (visual merge)
- Loose chunks: terrain palette color, no border
- Liquid chunks: water palette color, no border, semi-transparent (TBD)

### 5. Test Harness

Proves the system works and catches regressions.

## Acceptance Criteria

### Generation is deterministic
- **Test:** Generate world with seed X. Generate again with seed X. Chunk grids are byte-identical.
- **Test:** Generate with seed X vs seed Y. Grids differ.

### Surface contour is correct
- **Test:** For a known seed, the surface height at each column matches expected values (unit test against hardcoded expectations for a reference seed).
- **Test:** No floating terrain — all surface chunks connect to ground below.

### Terrain fill is correct
- **Test:** All chunks above surface are empty (sky). All chunks below surface are filled.
- **Test:** Dirt occupies the top N rows below surface. Stone fills below dirt.

### Water settles correctly
- **Test:** After simulation, no water chunk has an empty space below it (all water has fallen).
- **Test:** Water fills basins to a level surface (no single-column towers of water).
- **Test:** Water does not exist above the terrain surface (it flowed down).

### Loose chunks settle correctly
- **Test:** After simulation, no loose chunk has empty space below it (all have fallen).
- **Test:** Loose chunks pile on top of static terrain or other settled loose chunks.

### Rendering is correct
- **Test:** Snapshot of settled world for seed X matches committed baseline PNG.
- **Test:** Border pixels exist only on chunk edges adjacent to air or different terrain.
- **Test:** No border between adjacent same-terrain static chunks.
- **Test:** Loose and liquid chunks render without borders.

### Pipeline is extensible
- **Test:** Adding a no-op plugin to the pipeline does not change output.
- **Test:** Removing a plugin from the pipeline produces a different (but valid) world.
- **Test:** Plugin order can be rearranged without runtime errors (output changes but system doesn't crash).

## World Parameters (phase 0 defaults)

| Parameter | Value |
|-----------|-------|
| World width | 64 tiles (256 chunks / 1024 px) |
| World height | 36 tiles (144 chunks / 576 px) |
| Chunk size | 4×4 screen pixels |
| Tile size | 16×16 screen pixels (4×4 chunks) |
| Terrain types | dirt, stone |
| Liquid types | water |
| Surface variance | gentle hills (noise-driven) |
| Dirt depth | ~3-5 tiles below surface |
| Water | placed in surface depressions |

### Character movement
- **Test:** Character stands on terrain surface (not falling through)
- **Test:** Left/right input moves character horizontally
- **Test:** Character stops at solid terrain (collision)
- **Test:** Character falls when no terrain below (gravity)
- **Test:** Jump input launches character upward, gravity brings them back

## Out of Scope

- Destruction / breaking chunks free during gameplay
- Conveyor belts, pickup, or any chunk interaction beyond settle physics
- Dynamic world expansion
- Biomes, caves, ores
- Sound, UI, menus

## Task Graph

```
┌─────────────────────┐
│ 1. Project Setup    │  Godot project, folder structure, AGENTS.md, git
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 2. Chunk Grid       │  Data structure: position → (terrain, color, state)
│                     │  API: get/set/neighbors/iterate
└────────┬────────────┘
         │
    ┌────┴────────────────────┐
    ▼                         ▼
┌──────────────────┐  ┌──────────────────────┐
│ 3. Terrain Defs  │  │ 4. Plugin Base Class  │
│ (Resource files) │  │ + Pipeline Runner     │
└────────┬─────────┘  └────────┬─────────────┘
         │                     │
         └────────┬────────────┘
                  ▼
┌─────────────────────────────────────┐
│ 5. Generation Plugins               │
│  a. SurfaceShapePlugin              │
│  b. TerrainFillPlugin               │
│  c. WaterPlacementPlugin            │
│  d. LooseChunkPlugin                │
│  e. PalettePlugin                   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ 6. Physics Simulation               │
│  a. Gravity (loose chunks fall)     │
│  b. Liquid CA (water flows/settles) │
│  c. Settlement detection (stable?)  │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ 7. Renderer                         │
│  a. Chunk → 4×4 px with palette     │
│  b. Border logic (exposed edges)    │
│  c. Liquid rendering                │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ 8. Test Harness                     │
│  a. Determinism tests               │
│  b. Settlement invariant tests      │
│  c. Snapshot baseline + comparison  │
└─────────────────────────────────────┘
```

### Dependencies

| Task | Depends on |
|------|-----------|
| 2. Chunk Grid | 1 |
| 3. Terrain Defs | 1 |
| 4. Plugin Base + Pipeline | 2 |
| 5. Generation Plugins | 2, 3, 4 |
| 6. Physics Simulation | 2 |
| 7. Renderer | 2, 3 |
| 8. Test Harness | 5, 6, 7 |

### Parallelism

- Tasks 3 and 4 can run in parallel (both depend only on 1+2).
- Task 6 and 7 can start once task 2 is done (don't need generation plugins to develop/test with mock data).
- Task 5's sub-plugins (a–e) are independent of each other once the base class exists.

