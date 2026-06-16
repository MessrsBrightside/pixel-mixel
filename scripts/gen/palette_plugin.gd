class_name PalettePlugin
extends GenerationPlugin

## Assigns color_index to ALL chunks with terrain >= 1 (any non-empty terrain).


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var noise := FastNoiseLite.new()
	noise.seed = params.get("seed", 0) + 1000
	noise.frequency = 0.4

	for y in range(size.y):
		for x in range(size.x):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain >= 1:
				var n: float = absf(noise.get_noise_2d(x, y))
				var color_index: int = mini(int(n * 4.0), 3)
				grid.set_chunk(Vector2i(x, y), chunk.terrain, color_index, chunk.state)
