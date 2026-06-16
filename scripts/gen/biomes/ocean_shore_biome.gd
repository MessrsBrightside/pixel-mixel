class_name OceanShoreBiome
extends GenerationPlugin

## Generates ocean shore biome: sand beach sloping smoothly into water with palm trees.

const DIRT := 1
const STONE := 2
const WATER := 3
const GRASS := 4
const LEAVES := 5
const WOOD := 6
const SAND := 7
const GRASS_SOLID := 10


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var rng: RandomNumberGenerator = params["rng"]

	var beach_top_y := int(size.y * 0.4)
	var water_surface_y := int(size.y * 0.55)
	var ocean_deep_y := int(size.y * 0.8)

	# Surface: smooth slope from left (high) all the way down into ocean
	for x in range(size.x):
		var t := float(x) / float(size.x)
		# Smooth slope: starts at beach_top_y, ends at ocean_deep_y
		var surface_y := beach_top_y + int(t * t * (ocean_deep_y - beach_top_y))

		# Fill below surface
		for y in range(surface_y, size.y):
			var depth := y - surface_y
			if depth < 10:
				# Sand layer on top (LOOSE)
				grid.set_chunk(Vector2i(x, y), SAND, 0, ChunkGrid.State.LOOSE)
			else:
				# Stone below
				grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)

		# Water: fill above sand surface where surface is below water line
		if surface_y > water_surface_y:
			for y in range(water_surface_y, surface_y):
				grid.set_chunk(Vector2i(x, y), WATER, 0, ChunkGrid.State.LIQUID)

	# Far left: dirt zone with grass on top
	var dirt_zone := int(size.x * 0.08)
	for x in range(dirt_zone):
		var t := float(x) / float(size.x)
		var surface_y := beach_top_y + int(t * t * (ocean_deep_y - beach_top_y))
		# Replace sand with dirt
		for y in range(surface_y, mini(surface_y + 10, size.y)):
			grid.set_chunk(Vector2i(x, y), DIRT, 0, ChunkGrid.State.STATIC)
		# Grass solid on top
		if surface_y > 0:
			grid.set_chunk(Vector2i(x, surface_y - 1), GRASS_SOLID, 0, ChunkGrid.State.STATIC)

	# Palm trees on dry beach
	var next_tree_x := dirt_zone + 5
	var dry_limit := _find_water_start(water_surface_y, beach_top_y, ocean_deep_y, size.x)
	while next_tree_x < dry_limit - 5:
		var t := float(next_tree_x) / float(size.x)
		var surface_y := beach_top_y + int(t * t * (ocean_deep_y - beach_top_y))
		_place_palm_tree(grid, next_tree_x, surface_y, rng)
		next_tree_x += rng.randi_range(30, 50)


func _find_water_start(water_y: int, beach_top: int, ocean_deep: int, width: int) -> int:
	# Find x where surface dips below water line
	for x in range(width):
		var t := float(x) / float(width)
		var surface_y := beach_top + int(t * t * (ocean_deep - beach_top))
		if surface_y >= water_y:
			return x
	return width


func _place_palm_tree(grid: ChunkGrid, x: int, surface_y: int, rng: RandomNumberGenerator) -> void:
	var trunk_height := rng.randi_range(3, 5)
	for i in range(trunk_height):
		var ty := surface_y - 1 - i
		if ty >= 0:
			grid.set_chunk(Vector2i(x, ty), WOOD, 0, ChunkGrid.State.STATIC)
	var top_y := surface_y - 1 - trunk_height
	for lx in range(x - 1, x + 2):
		for ly in range(top_y - 1, top_y + 1):
			if grid.is_in_bounds(Vector2i(lx, ly)):
				grid.set_chunk(Vector2i(lx, ly), LEAVES, 0, ChunkGrid.State.STATIC)
