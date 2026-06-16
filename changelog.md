# Changelog

## 2026-06-16

- [#8] Add test harness: WorldGenerator, integration tests (determinism, settlement, palette), snapshot regression, run_all_tests.sh
- [#5] Add generation plugins: SurfaceShape, TerrainFill, WaterPlacement, LooseChunk, Palette — all data-driven, no hardcoded terrain indices
- [#7] Add ChunkRenderer with palette color fill, static border logic, liquid transparency, and headless tests
- [#6] Add ChunkSimulator with gravity, liquid CA spread, and settlement detection
- [#4] Add GenerationPlugin base class and PipelineRunner with seeded RNG execution
- [#3] Add TerrainDef and LiquidDef resource classes with dirt, stone, and water definitions
- [#2] Add ChunkGrid data structure with dense PackedByteArray storage and full API
- Project setup: Godot project, AGENTS.md, folder structure, ADRs 001-012
