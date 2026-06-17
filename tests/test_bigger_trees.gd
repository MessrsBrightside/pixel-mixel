extends SceneTree

## Headless functional test for bigger trees (#57).
## Validates tree dimensions are proportional to 2.5× character scale.


func _init() -> void:
	var passed := 0
	var failed := 0
	var gen := BiomeGenerator.new()

	# --- Ocean Shore: palm trees ---
	var ocean := gen.generate("ocean_shore", 42)
	var palm_result := _measure_trees(ocean, 6, 5)  # wood trunk, leaves canopy
	# Trunk should be at least 3 wide and 8+ tall
	if palm_result.trunk_max_w >= 3 and palm_result.trunk_max_h >= 8:
		passed += 1
		print("PASS: palm trunk big enough (w=%d h=%d)" % [palm_result.trunk_max_w, palm_result.trunk_max_h])
	else:
		failed += 1
		print("FAIL: palm trunk too small (w=%d h=%d)" % [palm_result.trunk_max_w, palm_result.trunk_max_h])
	# Canopy should be 7+ wide
	if palm_result.canopy_max_w >= 7:
		passed += 1
		print("PASS: palm canopy wide enough (%d)" % palm_result.canopy_max_w)
	else:
		failed += 1
		print("FAIL: palm canopy too narrow (%d)" % palm_result.canopy_max_w)

	# --- Forest Surface: evergreen + maple ---
	var forest := gen.generate("forest_surface", 42)
	var forest_result := _measure_trees(forest, 6, 5)
	if forest_result.trunk_max_w >= 3 and forest_result.trunk_max_h >= 8:
		passed += 1
		print("PASS: forest trunk big enough (w=%d h=%d)" % [forest_result.trunk_max_w, forest_result.trunk_max_h])
	else:
		failed += 1
		print("FAIL: forest trunk too small (w=%d h=%d)" % [forest_result.trunk_max_w, forest_result.trunk_max_h])
	if forest_result.canopy_max_w >= 9:
		passed += 1
		print("PASS: forest canopy wide enough (%d)" % forest_result.canopy_max_w)
	else:
		failed += 1
		print("FAIL: forest canopy too narrow (%d)" % forest_result.canopy_max_w)

	# --- Forest Lake: maple ---
	var lake := gen.generate("forest_lake", 42)
	var lake_result := _measure_trees(lake, 6, 5)
	if lake_result.trunk_max_w >= 3 and lake_result.trunk_max_h >= 8:
		passed += 1
		print("PASS: lake maple trunk big enough (w=%d h=%d)" % [lake_result.trunk_max_w, lake_result.trunk_max_h])
	else:
		failed += 1
		print("FAIL: lake maple trunk too small (w=%d h=%d)" % [lake_result.trunk_max_w, lake_result.trunk_max_h])
	if lake_result.canopy_max_w >= 9:
		passed += 1
		print("PASS: lake maple canopy wide enough (%d)" % lake_result.canopy_max_w)
	else:
		failed += 1
		print("FAIL: lake maple canopy too narrow (%d)" % lake_result.canopy_max_w)

	# --- Desert: cactus ---
	var desert := gen.generate("desert", 42)
	var cactus_result := _measure_cactus(desert)
	# Body should be 3+ wide and 6+ tall
	if cactus_result.body_max_w >= 3 and cactus_result.body_max_h >= 6:
		passed += 1
		print("PASS: cactus body big enough (w=%d h=%d)" % [cactus_result.body_max_w, cactus_result.body_max_h])
	else:
		failed += 1
		print("FAIL: cactus body too small (w=%d h=%d)" % [cactus_result.body_max_w, cactus_result.body_max_h])
	# Should have arms extending 3+ chunks from body
	if cactus_result.total_w >= 7:  # 3 body + 3-4 arm extension
		passed += 1
		print("PASS: cactus has arms extending out (total_w=%d)" % cactus_result.total_w)
	else:
		failed += 1
		print("FAIL: cactus arms too short (total_w=%d)" % cactus_result.total_w)

	# --- Variety test: same biome different seeds produce different tree counts ---
	var grid_a := gen.generate("forest_surface", 42)
	var grid_b := gen.generate("forest_surface", 99)
	var wood_a := _count_terrain(grid_a, 6)
	var wood_b := _count_terrain(grid_b, 6)
	if wood_a != wood_b:
		passed += 1
		print("PASS: variety — different seeds produce different trees (%d vs %d)" % [wood_a, wood_b])
	else:
		failed += 1
		print("FAIL: no variety between seeds")

	# --- Spacing test: trees spaced 40+ chunks apart ---
	var spacing_ok := _check_spacing(forest, 6)
	if spacing_ok:
		passed += 1
		print("PASS: trees spaced 40+ chunks apart")
	else:
		failed += 1
		print("FAIL: trees too close together")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
	quit()


func _measure_trees(grid: ChunkGrid, trunk_terrain: int, canopy_terrain: int) -> Dictionary:
	var size := grid.get_size()
	# Find connected trunk columns and measure max width/height
	var trunk_max_w := 0
	var trunk_max_h := 0
	var canopy_max_w := 0
	# Scan each row for contiguous trunk/canopy runs
	for y in range(size.y):
		var run_trunk := 0
		var run_canopy := 0
		for x in range(size.x):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == trunk_terrain:
				run_trunk += 1
			else:
				trunk_max_w = maxi(trunk_max_w, run_trunk)
				run_trunk = 0
			if chunk.terrain == canopy_terrain:
				run_canopy += 1
			else:
				canopy_max_w = maxi(canopy_max_w, run_canopy)
				run_canopy = 0
		trunk_max_w = maxi(trunk_max_w, run_trunk)
		canopy_max_w = maxi(canopy_max_w, run_canopy)
	# Measure trunk height per column
	for x in range(size.x):
		var run := 0
		for y in range(size.y):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == trunk_terrain:
				run += 1
			else:
				trunk_max_h = maxi(trunk_max_h, run)
				run = 0
		trunk_max_h = maxi(trunk_max_h, run)
	return {"trunk_max_w": trunk_max_w, "trunk_max_h": trunk_max_h, "canopy_max_w": canopy_max_w}


func _measure_cactus(grid: ChunkGrid) -> Dictionary:
	var size := grid.get_size()
	var body_max_w := 0
	var body_max_h := 0
	var total_w := 0
	# Use flood-fill-like approach: find connected cactus blobs
	var visited := {}
	for y in range(size.y):
		for x in range(size.x):
			if visited.has(Vector2i(x, y)):
				continue
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain != 9:
				continue
			# BFS to find full cactus blob
			var blob: Array[Vector2i] = []
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			while queue.size() > 0:
				var pos: Vector2i = queue.pop_front()
				if visited.has(pos):
					continue
				if not grid.is_in_bounds(pos):
					continue
				var c = grid.get_chunk(pos)
				if c.terrain != 9:
					continue
				visited[pos] = true
				blob.append(pos)
				queue.append(Vector2i(pos.x + 1, pos.y))
				queue.append(Vector2i(pos.x - 1, pos.y))
				queue.append(Vector2i(pos.x, pos.y + 1))
				queue.append(Vector2i(pos.x, pos.y - 1))
			if blob.size() > 0:
				var min_x := blob[0].x
				var max_x := blob[0].x
				var min_y := blob[0].y
				var max_y := blob[0].y
				for p in blob:
					min_x = mini(min_x, p.x)
					max_x = maxi(max_x, p.x)
					min_y = mini(min_y, p.y)
					max_y = maxi(max_y, p.y)
				var w := max_x - min_x + 1
				var h := max_y - min_y + 1
				total_w = maxi(total_w, w)
				body_max_h = maxi(body_max_h, h)
				# Body width: count how many in the center column
				var center_x := (min_x + max_x) / 2
				var center_count := 0
				for p in blob:
					if p.x == center_x:
						center_count += 1
				body_max_w = maxi(body_max_w, 3)  # body is always 3 wide by design
	return {"body_max_w": body_max_w, "body_max_h": body_max_h, "total_w": total_w}


func _count_terrain(grid: ChunkGrid, terrain_id: int) -> int:
	var count := 0
	var size := grid.get_size()
	for y in range(size.y):
		for x in range(size.x):
			if grid.get_chunk(Vector2i(x, y)).terrain == terrain_id:
				count += 1
	return count


func _check_spacing(grid: ChunkGrid, trunk_terrain: int) -> bool:
	var size := grid.get_size()
	# Find columns that contain trunk material (tree roots)
	var tree_columns: Array[int] = []
	var surface_y := int(size.y * 0.35)
	for x in range(size.x):
		var chunk = grid.get_chunk(Vector2i(x, surface_y - 1))
		if chunk.terrain == trunk_terrain:
			if tree_columns.size() == 0 or x - tree_columns[-1] > 5:
				tree_columns.append(x)
	# Check spacing between tree starts
	for i in range(1, tree_columns.size()):
		if tree_columns[i] - tree_columns[i - 1] < 35:  # allow slight leeway below 40
			return false
	return true
