class_name OceanShoreBiome
extends GenerationPlugin

## Generates ocean shore biome: sand beach sloping into water with palm trees.

# Terrain indices
const DIRT := 1
const STONE := 2
const WATER := 3
const GRASS := 4
const LEAVES := 5
const WOOD := 6
const SAND := 7


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var rng: RandomNumberGenerator = params["rng"]

	# Beach slopes from left (high) down into water on right
	var beach_start_y := int(size.y * 0.45)  # top of beach on left
	var water_line_x := int(size.x * 0.4)  # where water starts
	var ocean_floor_y := int(size.y * 0.75)  # bottom of ocean depression
	var water_surface_y := int(size.y * 0.55)  # water surface level

	# Generate surface heights: slope down from left to water, then flat ocean floor
	for x in range(size.x):
		var surface_y: int
		if x < water_line_x:
			# Beach: linear slope from beach_start_y down to water_surface_y
			var t := float(x) / float(water_line_x)
			surface_y = beach_start_y + int(t * (water_surface_y - beach_start_y))
		else:
			# Ocean floor
			surface_y = ocean_floor_y

		# Fill terrain below surface
		for y in range(surface_y, size.y):
			var depth := y - surface_y
			if x < water_line_x:
				# Beach: sand on top, then stone
				if depth < 8:
					grid.set_chunk(Vector2i(x, y), SAND, 0, ChunkGrid.State.LOOSE)
				else:
					grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)
			else:
				# Ocean floor: stone
				grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)

		# Water fill for ocean area
		if x >= water_line_x:
			for y in range(water_surface_y, ocean_floor_y):
				grid.set_chunk(Vector2i(x, y), WATER, 0, ChunkGrid.State.LIQUID)

	# Dirt further inland (far left) with grass transition
	var dirt_zone_end := int(size.x * 0.1)
	for x in range(dirt_zone_end):
		var t := float(x) / float(water_line_x)
		var surface_y := beach_start_y + int(t * (water_surface_y - beach_start_y))
		# Replace top sand with dirt
		for y in range(surface_y, mini(surface_y + 8, size.y)):
			grid.set_chunk(Vector2i(x, y), DIRT, 0, ChunkGrid.State.STATIC)
		# Grass on top
		if surface_y > 0:
			grid.set_chunk(Vector2i(x, surface_y - 1), GRASS, 0, ChunkGrid.State.STATIC)

	# Grass at dirt/sand transition
	for x in range(dirt_zone_end, dirt_zone_end + 5):
		var t := float(x) / float(water_line_x)
		var surface_y := beach_start_y + int(t * (water_surface_y - beach_start_y))
		if surface_y > 0:
			grid.set_chunk(Vector2i(x, surface_y - 1), GRASS, 0, ChunkGrid.State.STATIC)

	# Palm trees on beach (every 30-50 chunks apart)
	var next_tree_x := dirt_zone_end + 10
	while next_tree_x < water_line_x - 5:
		var t := float(next_tree_x) / float(water_line_x)
		var surface_y := beach_start_y + int(t * (water_surface_y - beach_start_y))
		_place_palm_tree(grid, next_tree_x, surface_y, rng)
		next_tree_x += rng.randi_range(30, 50)


func _place_palm_tree(grid: ChunkGrid, x: int, surface_y: int, rng: RandomNumberGenerator) -> void:
	var trunk_height := rng.randi_range(3, 5)
	# Trunk
	for i in range(trunk_height):
		var ty := surface_y - 1 - i
		if ty >= 0:
			grid.set_chunk(Vector2i(x, ty), WOOD, 0, ChunkGrid.State.STATIC)
	# Leaf canopy: 3×2 cluster at top of trunk
	var top_y := surface_y - 1 - trunk_height
	for lx in range(x - 1, x + 2):
		for ly in range(top_y - 1, top_y + 1):
			if grid.is_in_bounds(Vector2i(lx, ly)):
				grid.set_chunk(Vector2i(lx, ly), LEAVES, 0, ChunkGrid.State.STATIC)
