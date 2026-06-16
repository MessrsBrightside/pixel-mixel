# Changelog

## 2026-06-16

- [#28] Parallax background system: procedural gradient textures per biome, ParallaxBG class, integrated in main.gd, tests

- [#29] Blade attack destruction system: fan-shaped arc frees chunks based on power vs toughness, left-click input, re-render on attack, before/after screenshots, tests

- [#27] Desert biome: sand dunes with noise, cactus columns with arms, sparse dead grass, stone underground, key 0 in main.gd, screenshot, tests

- [#26] Cave biome: stone ceiling/floor with noise-varied edges, stalactites, mushrooms, stone pillars, key 9 in main.gd, screenshot, tests

- [#25] Forest Lake biome: central water depression, sloped terrain, maple trees on land, grass/reeds at waterline, key 8 in main.gd, screenshot, tests

- [#24] Forest Surface biome: noise-based rolling hills, grass/dirt/stone layers, evergreen + maple trees, grass blades, key 7 in main.gd, screenshot, tests

- [#23] Ocean Shore biome: sand beach sloping into water, palm trees, BiomeGenerator, BiomeRegistry, screenshot tool, key 6 in main.gd, terrain_defs expanded to all 9 types

- [#30] Character scale 2.5x, hitbox 16×32, passable chunk collision (terrain_defs-aware _is_solid)

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
