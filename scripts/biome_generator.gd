class_name BiomeGenerator
extends RefCounted

## Top-level entry for biome generation. Creates grid, runs biome plugin + palette.


func generate(biome_name: String, seed_val: int) -> ChunkGrid:
	var grid := ChunkGrid.new(500, 144)
	var registry := BiomeRegistry.new()
	var biome := registry.get_biome(biome_name)
	if biome == null:
		push_error("Unknown biome: %s" % biome_name)
		return grid

	var runner := PipelineRunner.new()
	runner.add_plugin(biome)
	runner.add_plugin(PalettePlugin.new())
	runner.run(grid, seed_val)

	var sim := ChunkSimulator.new(seed_val)
	sim.simulate_until_settled(grid)

	return grid
