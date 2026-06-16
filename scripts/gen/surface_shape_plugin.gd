class_name SurfaceShapePlugin
extends GenerationPlugin

## Generates terrain surface contour using FastNoiseLite and stores heights in params.


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var amplitude: int = params.get("amplitude", 5)
	var frequency: float = params.get("frequency", 0.05)
	var size := grid.get_size()
	var base_height: int = params.get("base_height", int(size.y * 0.6))

	var noise := FastNoiseLite.new()
	noise.seed = params.get("seed", 0)
	noise.frequency = frequency

	var surface_heights: Array[int] = []
	surface_heights.resize(size.x)
	for x in range(size.x):
		surface_heights[x] = clampi(base_height + int(noise.get_noise_1d(x) * amplitude), 0, size.y - 1)

	params["surface_heights"] = surface_heights
