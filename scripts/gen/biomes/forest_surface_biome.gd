class_name ForestSurfaceBiome
extends GenerationPlugin

## Generates forest surface biome: rolling hills with dense tree coverage.

const DIRT := 1
const STONE := 2
const GRASS := 4
const LEAVES := 5
const WOOD := 6
const GRASS_SOLID := 10


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var rng: RandomNumberGenerator = params["rng"]
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.015

	# Generate surface heights using noise for gentle rolling hills
	var surface: Array[int] = []
	surface.resize(size.x)
	for x in range(size.x):
		var h := noise.get_noise_1d(float(x))
		surface[x] = int(size.y * 0.35 + h * 12.0)

	# Fill terrain layers
	for x in range(size.x):
		var sy: int = surface[x]
		# Grass solid base (top 2 chunks — player stands on this)
		var solid_depth := 2
		for y in range(sy, mini(sy + solid_depth, size.y)):
			grid.set_chunk(Vector2i(x, y), GRASS_SOLID, 0, ChunkGrid.State.STATIC)
		# Dirt layer (~13 chunks)
		var dirt_start := sy + solid_depth
		var dirt_end := sy + solid_depth + 13
		for y in range(dirt_start, mini(dirt_end, size.y)):
			grid.set_chunk(Vector2i(x, y), DIRT, 0, ChunkGrid.State.STATIC)
		# Stone to bottom
		for y in range(mini(dirt_end, size.y), size.y):
			grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)

	# Place trees (one every 15-25 chunks)
	var next_tree_x := rng.randi_range(5, 15)
	while next_tree_x < size.x - 3:
		if rng.randf() < 0.5:
			_place_evergreen(grid, next_tree_x, surface[next_tree_x], rng)
		else:
			_place_maple(grid, next_tree_x, surface[next_tree_x], rng)
		next_tree_x += rng.randi_range(15, 25)

	# Scatter decorative grass blades above solid grass surface
	for x in range(size.x):
		if rng.randf() < 0.3:
			var blade_h := rng.randi_range(1, 2)
			for i in range(blade_h):
				var gy: int = surface[x] - 1 - i
				var above: Variant = grid.get_chunk(Vector2i(x, gy))
				if gy >= 0 and above != null and above.terrain == 0:
					grid.set_chunk(Vector2i(x, gy), GRASS, 0, ChunkGrid.State.STATIC)


func _place_evergreen(grid: ChunkGrid, x: int, surface_y: int, rng: RandomNumberGenerator) -> void:
	var trunk_h := rng.randi_range(5, 8)
	# Trunk
	for i in range(trunk_h):
		var ty := surface_y - 1 - i
		if ty >= 0:
			grid.set_chunk(Vector2i(x, ty), WOOD, 0, ChunkGrid.State.STATIC)
	# Triangular leaf canopy: 4-5 chunks tall, widest at bottom (~5 wide)
	var canopy_h := rng.randi_range(4, 5)
	var canopy_base_y := surface_y - 1 - trunk_h
	for row in range(canopy_h):
		var half_w: int = (canopy_h - row) # wider at bottom (row 0)
		for lx in range(x - half_w, x + half_w + 1):
			var ly := canopy_base_y - (canopy_h - 1 - row)
			if grid.is_in_bounds(Vector2i(lx, ly)):
				grid.set_chunk(Vector2i(lx, ly), LEAVES, 0, ChunkGrid.State.STATIC)


func _place_maple(grid: ChunkGrid, x: int, surface_y: int, rng: RandomNumberGenerator) -> void:
	var trunk_h := rng.randi_range(4, 6)
	# Trunk
	for i in range(trunk_h):
		var ty := surface_y - 1 - i
		if ty >= 0:
			grid.set_chunk(Vector2i(x, ty), WOOD, 0, ChunkGrid.State.STATIC)
	# Oval/round canopy: ~5 wide, 3-4 tall
	var canopy_h := rng.randi_range(3, 4)
	var canopy_top_y := surface_y - 1 - trunk_h - canopy_h + 1
	for row in range(canopy_h):
		var half_w: int
		if canopy_h == 3:
			half_w = [1, 2, 1][row]
		else:
			half_w = [1, 2, 2, 1][row]
		for lx in range(x - half_w, x + half_w + 1):
			var ly := canopy_top_y + row
			if grid.is_in_bounds(Vector2i(lx, ly)):
				grid.set_chunk(Vector2i(lx, ly), LEAVES, 0, ChunkGrid.State.STATIC)
