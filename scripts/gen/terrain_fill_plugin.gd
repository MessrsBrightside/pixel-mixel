class_name TerrainFillPlugin
extends GenerationPlugin

## Fills terrain below surface: dirt on top, stone below.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var surface_heights: Array = params["surface_heights"]
	var dirt_depth: int = params.get("dirt_depth", 12)

	for x in range(size.x):
		var surface_y: int = surface_heights[x]
		for y in range(surface_y, size.y):
			var terrain: int = 0 if y < surface_y + dirt_depth else 1
			grid.set_chunk(Vector2i(x, y), terrain, 0, ChunkGrid.State.STATIC)
