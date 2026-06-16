# scripts/gen/

World generation plugins. Each extends `GenerationPlugin` and implements `execute(grid, params)`.

Pipeline order: SurfaceShape → TerrainFill → WaterPlacement → LooseChunk → Palette
