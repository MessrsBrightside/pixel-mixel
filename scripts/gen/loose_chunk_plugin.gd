class_name LooseChunkPlugin
extends GenerationPlugin

## Scatters loose chunks above surface so they fall during simulation.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var surface_heights: Array = params["surface_heights"]
	var density: float = params.get("loose_density", 0.05)
	var terrain_index: int = params.get("loose_terrain_index", 1)
	var rng: RandomNumberGenerator = params["rng"]
	var size := grid.get_size()

	for x in range(size.x):
		var surface_y: int = surface_heights[x]
		if rng.randf() < density and surface_y > 5:
			# Place 2-4 chunks above surface so they visibly fall
			var drop_height: int = rng.randi_range(2, 5)
			var place_y: int = surface_y - drop_height
			if place_y >= 0:
				grid.set_chunk(Vector2i(x, place_y), terrain_index, 0, ChunkGrid.State.LOOSE)
