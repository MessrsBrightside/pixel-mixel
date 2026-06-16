class_name TerrainFillPlugin
extends GenerationPlugin

## Fills terrain below surface using data-driven layers. No hardcoded terrain indices.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var surface_heights: Array = params["surface_heights"]
	var layers: Array = params.get("layers", [
		{"terrain_index": 1, "depth": 12},
		{"terrain_index": 2, "depth": -1},
	])
	var size := grid.get_size()

	for x in range(size.x):
		var surface_y: int = surface_heights[x]
		var y := surface_y
		for layer in layers:
			if y >= size.y:
				break
			var terrain_index: int = layer["terrain_index"]
			var depth: int = layer["depth"]
			var end_y: int = size.y if depth == -1 else mini(y + depth, size.y)
			for fill_y in range(y, end_y):
				grid.set_chunk(Vector2i(x, fill_y), terrain_index, 0, ChunkGrid.State.STATIC)
			y = end_y
