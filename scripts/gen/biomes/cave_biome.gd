class_name CaveBiome
extends GenerationPlugin

## Generates cave biome: stone ceiling + floor, open middle, stalactites, mushrooms, pillars.

const STONE := 2
const MUSHROOM := 8


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var rng: RandomNumberGenerator = params["rng"]

	var ceiling_base := 45
	var floor_base := 100

	# Compute irregular ceiling/floor edges per column using noise
	var ceiling_edge: Array[int] = []
	var floor_edge: Array[int] = []
	ceiling_edge.resize(size.x)
	floor_edge.resize(size.x)

	for x in range(size.x):
		var noise_c := sin(x * 0.1) * 3.0 + sin(x * 0.03) * 2.0
		ceiling_edge[x] = ceiling_base + int(noise_c)
		var noise_f := sin(x * 0.08 + 1.5) * 3.0 + sin(x * 0.025 + 0.7) * 2.0
		floor_edge[x] = floor_base + int(noise_f)

	# Fill ceiling (rows 0 to ceiling_edge) and floor (floor_edge to bottom)
	for x in range(size.x):
		for y in range(ceiling_edge[x]):
			grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)
		for y in range(floor_edge[x], size.y):
			grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)

	# Stalactites: stone columns hanging from ceiling
	var next_stal := rng.randi_range(20, 40)
	while next_stal < size.x:
		var length := rng.randi_range(3, 8)
		var start_y := ceiling_edge[next_stal]
		for i in range(length):
			var sy := start_y + i
			if sy < floor_edge[next_stal]:
				grid.set_chunk(Vector2i(next_stal, sy), STONE, 0, ChunkGrid.State.STATIC)
		next_stal += rng.randi_range(20, 40)

	# Mushrooms on floor
	var next_mush := rng.randi_range(10, 20)
	while next_mush < size.x - 2:
		var height := rng.randi_range(2, 4)
		var base_y := floor_edge[next_mush]
		# Stem
		for i in range(height):
			var my := base_y - 1 - i
			if my > ceiling_edge[next_mush]:
				grid.set_chunk(Vector2i(next_mush, my), MUSHROOM, 0, ChunkGrid.State.STATIC)
		# Cap (wider: 3 chunks at top)
		var cap_y := base_y - height
		if cap_y > ceiling_edge[next_mush]:
			for dx in range(-1, 2):
				var cx: int = next_mush + dx
				if cx >= 0 and cx < size.x:
					grid.set_chunk(Vector2i(cx, cap_y), MUSHROOM, 0, ChunkGrid.State.STATIC)
		next_mush += rng.randi_range(10, 20)

	# Stone pillars connecting floor to ceiling (every ~80-150 chunks)
	var next_pillar := rng.randi_range(80, 150)
	while next_pillar < size.x:
		for y in range(ceiling_edge[next_pillar], floor_edge[next_pillar]):
			grid.set_chunk(Vector2i(next_pillar, y), STONE, 0, ChunkGrid.State.STATIC)
		next_pillar += rng.randi_range(80, 150)
