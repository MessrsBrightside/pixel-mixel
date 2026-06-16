# Changelog

## 2026-06-16

- [#22] Add toughness/passable properties to TerrainDef, create 6 new terrain resources (grass, leaves, wood, sand, mushroom, cactus)

- [#20] Add Player with chunk-grid collision, gravity, jump, horizontal movement, animated sprites
- [#19] Close test gaps: surface reference, no floating terrain, pipeline extensibility (55 tests total)
- Codebase audit: architecture doc, ADRs moved to docs/adr/, READMEs and .why.md for all files
- Replace Kenney robot with Snoblin pixel character, fix sprite alignment (vframes, offset, scale 1.5×)
- Loose chunks sink through liquid, fix liquid oscillation, interesting world presets
- Add main scene with live settlement visualization, camera zoom, WASD controls
- [#8] Add test harness: WorldGenerator, integration tests (determinism, settlement, palette), snapshot regression, run_all_tests.sh
- [#5] Add generation plugins: SurfaceShape, TerrainFill, WaterPlacement, LooseChunk, Palette — all data-driven
- [#7] Add ChunkRenderer with palette color fill, static border logic, liquid transparency
- [#6] Add ChunkSimulator with gravity, liquid CA spread, and settlement detection
- [#4] Add GenerationPlugin base class and PipelineRunner with seeded RNG execution
- [#3] Add TerrainDef and LiquidDef resource classes with dirt, stone, and water definitions
- [#2] Add ChunkGrid data structure with dense PackedByteArray storage and full API
- Project setup: Godot project, AGENTS.md, folder structure, ADRs 001-012
