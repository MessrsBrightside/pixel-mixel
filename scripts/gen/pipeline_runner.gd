class_name PipelineRunner
extends RefCounted

## Executes generation plugins in sequence with a seeded RNG.

var plugins: Array[GenerationPlugin] = []


func add_plugin(plugin: GenerationPlugin) -> void:
	plugins.append(plugin)


func run(grid: ChunkGrid, seed: int, params: Dictionary = {}) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	params["rng"] = rng
	params["seed"] = seed
	for plugin in plugins:
		plugin.execute(grid, params)
