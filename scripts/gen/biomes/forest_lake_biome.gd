class_name ForestLakeBiome
extends GenerationPlugin

## Generates forest lake biome: central lake with sloped terrain, maple trees, and reeds.

const DIRT := 1
const STONE := 2
const WATER := 3
const GRASS := 4
const LEAVES := 5
const WOOD := 6
const GRASS_SOLID := 10


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var rng: RandomNumberGenerator = params["rng"]

	# Lake dimensions: 150-200 chunks wide, centered
	var lake_width := 175
	var lake_start := (size.x - lake_width) / 2
	var lake_end := lake_start + lake_width

	# Heights
	var land_surface_y := int(size.y * 0.35)  # flat land surface
	var lake_bottom_y := int(size.y * 0.55)   # lake floor
	var water_surface_y := int(size.y * 0.42) # water level

	# Slope transition zone (30 chunks on each side)
	var slope_width := 30

	# Compute surface height per column
	var surface: Array[int] = []
	surface.resize(size.x)
	for x in range(size.x):
		if x < lake_start - slope_width:
			# Flat land left
			surface[x] = land_surface_y
		elif x < lake_start:
			# Slope down to lake
			var t := float(x - (lake_start - slope_width)) / float(slope_width)
			surface[x] = land_surface_y + int(t * (water_surface_y - land_surface_y))
		elif x <= lake_end:
			# Lake floor
			surface[x] = lake_bottom_y
		elif x <= lake_end + slope_width:
			# Slope up from lake
			var t := 1.0 - float(x - lake_end) / float(slope_width)
			surface[x] = land_surface_y + int(t * (water_surface_y - land_surface_y))
		else:
			# Flat land right
			surface[x] = land_surface_y

	# Fill terrain
	for x in range(size.x):
		var sy: int = surface[x]
		var is_lake := x >= lake_start and x <= lake_end

		if is_lake:
			# Stone floor under lake
			for y in range(sy, size.y):
				grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)
			# Water fill
			for y in range(water_surface_y, sy):
				grid.set_chunk(Vector2i(x, y), WATER, 0, ChunkGrid.State.LIQUID)
		else:
			# Land: grass_solid top, dirt, then stone
			grid.set_chunk(Vector2i(x, sy), GRASS_SOLID, 0, ChunkGrid.State.STATIC)
			var dirt_end := sy + 14
			for y in range(sy + 1, mini(dirt_end, size.y)):
				grid.set_chunk(Vector2i(x, y), DIRT, 0, ChunkGrid.State.STATIC)
			for y in range(mini(dirt_end, size.y), size.y):
				grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)

	# Grass/reeds at waterline (1-2 chunks tall)
	for x in [lake_start, lake_start + 1, lake_end - 1, lake_end]:
		if x >= 0 and x < size.x:
			var reed_h := rng.randi_range(1, 2)
			for i in range(reed_h):
				var ry := water_surface_y - 1 - i
				if ry >= 0:
					grid.set_chunk(Vector2i(x, ry), GRASS, 0, ChunkGrid.State.STATIC)

	# Maple trees on land portions (every 40-70 chunks, not in water)
	var next_tree_x := rng.randi_range(5, 15)
	while next_tree_x < size.x - 7:
		if next_tree_x < lake_start - slope_width or next_tree_x > lake_end + slope_width:
			_place_maple(grid, next_tree_x, surface[next_tree_x], rng)
		next_tree_x += rng.randi_range(40, 70)


func _place_maple(grid: ChunkGrid, x: int, surface_y: int, rng: RandomNumberGenerator) -> void:
	var trunk_h := rng.randi_range(8, 12)
	var trunk_w := rng.randi_range(3, 5)
	var half_trunk := trunk_w / 2
	# Trunk
	for i in range(trunk_h):
		var ty := surface_y - 1 - i
		if ty >= 0:
			for tx in range(x - half_trunk, x + half_trunk + 1):
				if grid.is_in_bounds(Vector2i(tx, ty)):
					grid.set_chunk(Vector2i(tx, ty), WOOD, 0, ChunkGrid.State.STATIC)
	# Oval/round canopy: 9-13 wide, 6-9 tall, slightly irregular edges
	var canopy_w := rng.randi_range(9, 13)
	var canopy_h := rng.randi_range(6, 9)
	var canopy_top_y := surface_y - 1 - trunk_h - canopy_h + 1
	var half_cw := canopy_w / 2
	for row in range(canopy_h):
		var t := float(row) / float(canopy_h - 1) if canopy_h > 1 else 0.5
		var row_half: int = int(float(half_cw) * sin(t * PI))
		row_half = maxi(row_half, 1)
		var jitter := rng.randi_range(-1, 1)
		var ly := canopy_top_y + row
		for lx in range(x - row_half + jitter, x + row_half + jitter + 1):
			if grid.is_in_bounds(Vector2i(lx, ly)):
				grid.set_chunk(Vector2i(lx, ly), LEAVES, 0, ChunkGrid.State.STATIC)
