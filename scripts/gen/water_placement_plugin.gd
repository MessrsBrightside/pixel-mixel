class_name WaterPlacementPlugin
extends GenerationPlugin

## Places liquid chunks in depressions below water_level. Terrain index from params.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var surface_heights: Array = params["surface_heights"]
	var water_level: int = params.get("water_level", int(grid.get_size().y * 0.55))
	var terrain_index: int = params.get("water_terrain_index", 2)
	var size := grid.get_size()

	for x in range(size.x):
		var surface_y: int = surface_heights[x]
		if surface_y > water_level:
			for y in range(water_level, surface_y):
				grid.set_chunk(Vector2i(x, y), terrain_index, 0, ChunkGrid.State.LIQUID)
