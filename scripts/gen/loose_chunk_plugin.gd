class_name LooseChunkPlugin
extends GenerationPlugin

## Scatters loose chunks on surface positions. Terrain index from params.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var surface_heights: Array = params["surface_heights"]
	var density: float = params.get("loose_density", 0.05)
	var terrain_index: int = params.get("loose_terrain_index", 0)
	var rng: RandomNumberGenerator = params["rng"]
	var size := grid.get_size()

	for x in range(size.x):
		var surface_y: int = surface_heights[x]
		if rng.randf() < density and surface_y > 0:
			grid.set_chunk(Vector2i(x, surface_y - 1), terrain_index, 0, ChunkGrid.State.LOOSE)
