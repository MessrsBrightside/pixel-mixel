class_name WaterPlacementPlugin
extends GenerationPlugin

## Places liquid chunks in surface depressions below water_level.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var surface_heights: Array = params["surface_heights"]
	var size := grid.get_size()

	var avg_surface: int = 0
	for h in surface_heights:
		avg_surface += h
	avg_surface = avg_surface / surface_heights.size()

	var water_level: int = params.get("water_level", avg_surface - 3)

	for x in range(size.x):
		var surface_y: int = surface_heights[x]
		if surface_y > water_level:
			for y in range(water_level, surface_y):
				grid.set_chunk(Vector2i(x, y), 2, 0, ChunkGrid.State.LIQUID)
