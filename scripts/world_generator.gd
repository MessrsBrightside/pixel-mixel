class_name WorldGenerator
extends RefCounted

## Top-level entry point: creates grid, runs generation pipeline, simulates to settlement.


func generate(seed: int, params: Dictionary = {}) -> ChunkGrid:
	var width: int = params.get("width", 256)
	var height: int = params.get("height", 144)
	var grid := ChunkGrid.new(width, height)

	var runner := PipelineRunner.new()
	runner.add_plugin(SurfaceShapePlugin.new())
	runner.add_plugin(TerrainFillPlugin.new())
	runner.add_plugin(WaterPlacementPlugin.new())
	runner.add_plugin(LooseChunkPlugin.new())
	runner.add_plugin(PalettePlugin.new())
	runner.run(grid, seed, params)

	var sim := ChunkSimulator.new(seed)
	sim.simulate_until_settled(grid)

	return grid
