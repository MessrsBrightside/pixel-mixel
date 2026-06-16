class_name SurfaceShapePlugin
extends GenerationPlugin

## Generates terrain contour using noise. Stores heights in params["surface_heights"].


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var amplitude: float = params.get("amplitude", 5.0)
	var frequency: float = params.get("frequency", 0.05)
	var base_height: int = params.get("base_height", int(size.y * 0.6))
	var rng: RandomNumberGenerator = params["rng"]

	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = frequency

	var surface_heights: Array[int] = []
	surface_heights.resize(size.x)
	for x in range(size.x):
		var offset: float = noise.get_noise_1d(float(x)) * amplitude
		surface_heights[x] = clampi(base_height + int(offset), 0, size.y - 1)

	params["surface_heights"] = surface_heights
