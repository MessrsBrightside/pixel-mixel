class_name LooseChunkPlugin
extends GenerationPlugin

## Scatters LOOSE state chunks on terrain surfaces.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var surface_heights: Array = params["surface_heights"]
	var density: float = params.get("density", 0.05)
	var rng: RandomNumberGenerator = params["rng"]
	var size := grid.get_size()

	for x in range(size.x):
		var surface_y: int = surface_heights[x]
		if surface_y > 0 and rng.randf() < density:
			grid.set_chunk(Vector2i(x, surface_y - 1), 0, 0, ChunkGrid.State.LOOSE)
