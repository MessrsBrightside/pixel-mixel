extends SceneTree

## Headless functional test for grass dual-layer (solid base + decorative foreground).

const GRASS := 4
const GRASS_SOLID := 10


func _init() -> void:
	var passed := 0
	var failed := 0

	var terrain_defs := _load_terrain_defs()

	# Test: grass_solid blocks player movement (passable=false)
	var gs_def: TerrainDef = terrain_defs[GRASS_SOLID]
	if gs_def != null and not gs_def.passable:
		passed += 1
		print("PASS: grass_solid is non-passable (blocks player)")
	else:
		failed += 1
		print("FAIL: grass_solid should be non-passable")

	# Test: decorative grass doesn't block player (passable=true)
	var g_def: TerrainDef = terrain_defs[GRASS]
	if g_def != null and g_def.passable:
		passed += 1
		print("PASS: decorative grass is passable")
	else:
		failed += 1
		print("FAIL: decorative grass should be passable")

	# Test: decorative grass has foreground=true
	if g_def != null and g_def.foreground:
		passed += 1
		print("PASS: decorative grass has foreground=true")
	else:
		failed += 1
		print("FAIL: decorative grass should have foreground=true")

	# Test: grass_solid has foreground=false
	if gs_def != null and not gs_def.foreground:
		passed += 1
		print("PASS: grass_solid has foreground=false")
	else:
		failed += 1
		print("FAIL: grass_solid should have foreground=false")

	# Test: forest biome has both grass_solid and decorative grass
	var gen := BiomeGenerator.new()
	var grid := gen.generate("forest_surface", 42)
	var size := grid.get_size()
	var solid_count := 0
	var deco_count := 0
	for y in range(size.y):
		for x in range(size.x):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == GRASS_SOLID:
				solid_count += 1
			elif chunk.terrain == GRASS:
				deco_count += 1
	if solid_count > 0 and deco_count > 0:
		passed += 1
		print("PASS: forest has both grass_solid (%d) and decorative grass (%d)" % [solid_count, deco_count])
	else:
		failed += 1
		print("FAIL: forest missing grass types (solid=%d deco=%d)" % [solid_count, deco_count])

	# Test: grass_solid is below decorative grass in y-position
	var solid_below_deco := true
	for x in range(size.x):
		var lowest_deco_y := -1
		var highest_solid_y := size.y
		for y in range(size.y):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == GRASS:
				if lowest_deco_y == -1 or y > lowest_deco_y:
					lowest_deco_y = y
			elif chunk.terrain == GRASS_SOLID:
				if y < highest_solid_y:
					highest_solid_y = y
		# If column has both, solid should be at higher y (lower on screen = below)
		if lowest_deco_y >= 0 and highest_solid_y < size.y:
			if highest_solid_y <= lowest_deco_y:
				solid_below_deco = false
				break
	if solid_below_deco:
		passed += 1
		print("PASS: grass_solid is below decorative grass (higher y-value)")
	else:
		failed += 1
		print("FAIL: grass_solid should be below decorative grass")

	# Test: collision — TerrainCollision generates shapes for grass_solid but not decorative grass
	var test_grid := ChunkGrid.new(10, 20)
	# Place grass_solid at row 15
	for x in range(10):
		test_grid.set_chunk(Vector2i(x, 15), GRASS_SOLID, 0, ChunkGrid.State.STATIC)
	# Place decorative grass at row 14
	for x in range(10):
		test_grid.set_chunk(Vector2i(x, 14), GRASS, 0, ChunkGrid.State.STATIC)
	var tc := TerrainCollision.new()
	tc.grid = test_grid
	tc.terrain_defs = terrain_defs
	root.add_child(tc)
	tc.build_all()
	var shape_count := 0
	for region in tc.get_children():
		for child in region.get_children():
			if child is CollisionShape2D:
				shape_count += 1
	if shape_count > 0:
		passed += 1
		print("PASS: TerrainCollision generates shapes for grass_solid")
	else:
		failed += 1
		print("FAIL: TerrainCollision should generate shapes for grass_solid")
	var shapes_at_row14 := 0
	var row14_y_min := 14.0 * 4.0
	var row14_y_max := 15.0 * 4.0
	for region in tc.get_children():
		for child in region.get_children():
			if child is CollisionShape2D:
				if child.position.y > row14_y_min and child.position.y < row14_y_max:
					shapes_at_row14 += 1
	if shapes_at_row14 == 0:
		passed += 1
		print("PASS: no collision shapes at decorative grass row")
	else:
		failed += 1
		print("FAIL: decorative grass row should have no collision shapes")
	tc.queue_free()

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()


func _load_terrain_defs() -> Array[TerrainDef]:
	var defs: Array[TerrainDef] = []
	defs.resize(11)
	defs[0] = null
	defs[1] = load("res://resources/dirt.tres")
	defs[2] = load("res://resources/stone.tres")
	defs[3] = load("res://resources/water.tres")
	defs[4] = load("res://resources/grass.tres")
	defs[5] = load("res://resources/leaves.tres")
	defs[6] = load("res://resources/wood.tres")
	defs[7] = load("res://resources/sand.tres")
	defs[8] = load("res://resources/mushroom.tres")
	defs[9] = load("res://resources/cactus.tres")
	defs[10] = load("res://resources/grass_solid.tres")
	return defs
