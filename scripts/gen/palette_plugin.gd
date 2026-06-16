class_name PalettePlugin
extends GenerationPlugin

## Assigns color_index to all filled chunks using seeded noise for grainy look.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var rng: RandomNumberGenerator = params["rng"]

	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.4

	for y in range(size.y):
		for x in range(size.x):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 0 and chunk.color == 0 and chunk.state == 0:
				continue
			var n: float = noise.get_noise_2d(float(x), float(y))
			var color_index: int = clampi(int((n + 1.0) * 2.0), 0, 3)
			grid.set_chunk(Vector2i(x, y), chunk.terrain, color_index, chunk.state)
