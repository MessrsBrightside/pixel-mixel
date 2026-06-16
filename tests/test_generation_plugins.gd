extends SceneTree

## Headless tests for the 5 generation plugins.


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- SurfaceShapePlugin ---
	# Test: surface heights within bounds
	var grid := ChunkGrid.new(32, 24)
	var params: Dictionary = _run_surface(grid, 42)
	var heights: Array = params["surface_heights"]
	var all_valid := true
	for h in heights:
		if h < 0 or h >= 24:
			all_valid = false
			break
	if all_valid and heights.size() == 32:
		passed += 1
		print("PASS: surface plugin creates valid heights within bounds")
	else:
		failed += 1
		print("FAIL: surface heights invalid")

	# --- TerrainFillPlugin ---
	# Test: fills below surface, leaves above empty
	grid = ChunkGrid.new(32, 24)
	params = _run_surface(grid, 42)
	var fill := TerrainFillPlugin.new()
	fill.execute(grid, params)
	var fill_ok := true
	for x in range(32):
		var sy: int = heights[x]
		if sy > 0:
			var above = grid.get_chunk(Vector2i(x, sy - 1))
			if above.terrain != 0 or above.state != 0:
				fill_ok = false
		var at_surface = grid.get_chunk(Vector2i(x, sy))
		if at_surface.terrain != 0 or at_surface.state != ChunkGrid.State.STATIC:
			fill_ok = false
			break
	if fill_ok:
		passed += 1
		print("PASS: fill plugin fills below surface, leaves above empty")
	else:
		failed += 1
		print("FAIL: fill plugin incorrect")

	# Test: dirt/stone layering
	grid = ChunkGrid.new(32, 24)
	params = _run_surface(grid, 42)
	params["dirt_depth"] = 4
	fill.execute(grid, params)
	var layer_ok := true
	for x in range(32):
		var sy: int = params["surface_heights"][x]
		for dy in range(4):
			if sy + dy < 24:
				var c = grid.get_chunk(Vector2i(x, sy + dy))
				if c.terrain != 0:
					layer_ok = false
					break
		if sy + 4 < 24:
			var c = grid.get_chunk(Vector2i(x, sy + 4))
			if c.terrain != 1:
				layer_ok = false
		if not layer_ok:
			break
	if layer_ok:
		passed += 1
		print("PASS: fill plugin layers dirt then stone")
	else:
		failed += 1
		print("FAIL: fill plugin layering incorrect")

	# --- WaterPlacementPlugin ---
	# Test: water only in depressions
	grid = ChunkGrid.new(16, 16)
	params = {"rng": RandomNumberGenerator.new(), "seed": 42}
	params["rng"].seed = 42
	var manual_heights: Array[int] = []
	manual_heights.resize(16)
	for x in range(16):
		manual_heights[x] = 6
	for x in range(5, 11):
		manual_heights[x] = 10
	params["surface_heights"] = manual_heights
	params["water_level"] = 7
	var water := WaterPlacementPlugin.new()
	water.execute(grid, params)
	var water_ok := true
	for x in range(16):
		for y in range(16):
			var c = grid.get_chunk(Vector2i(x, y))
			if c.state == ChunkGrid.State.LIQUID:
				if manual_heights[x] <= params["water_level"]:
					water_ok = false
					break
		if not water_ok:
			break
	if water_ok:
		passed += 1
		print("PASS: water plugin only places liquid in depressions")
	else:
		failed += 1
		print("FAIL: water placed outside depressions")

	# --- LooseChunkPlugin ---
	# Test: density=0 produces no loose chunks
	grid = ChunkGrid.new(256, 24)
	params = _run_surface(grid, 42)
	params["density"] = 0.0
	var loose := LooseChunkPlugin.new()
	loose.execute(grid, params)
	var loose_count := 0
	for x in range(256):
		var sy: int = params["surface_heights"][x]
		if sy > 0:
			var c = grid.get_chunk(Vector2i(x, sy - 1))
			if c.state == ChunkGrid.State.LOOSE:
				loose_count += 1
	if loose_count == 0:
		passed += 1
		print("PASS: loose plugin density=0 produces no loose chunks")
	else:
		failed += 1
		print("FAIL: loose plugin density=0 produced %d chunks" % loose_count)

	# Test: density=1 produces many
	grid = ChunkGrid.new(256, 24)
	params = _run_surface(grid, 99)
	params["density"] = 1.0
	loose.execute(grid, params)
	loose_count = 0
	for x in range(256):
		var sy: int = params["surface_heights"][x]
		if sy > 0:
			var c = grid.get_chunk(Vector2i(x, sy - 1))
			if c.state == ChunkGrid.State.LOOSE:
				loose_count += 1
	if loose_count > 200:
		passed += 1
		print("PASS: loose plugin density=1 produces many chunks (%d)" % loose_count)
	else:
		failed += 1
		print("FAIL: loose plugin density=1 only produced %d" % loose_count)

	# --- PalettePlugin ---
	# Test: assigns valid color indices (0..3)
	grid = ChunkGrid.new(16, 16)
	params = _run_surface(grid, 42)
	fill.execute(grid, params)
	var palette := PalettePlugin.new()
	palette.execute(grid, params)
	var palette_ok := true
	for y in range(16):
		for x in range(16):
			var c = grid.get_chunk(Vector2i(x, y))
			if c.state != 0 or c.terrain != 0:
				if c.color < 0 or c.color > 3:
					palette_ok = false
					break
		if not palette_ok:
			break
	if palette_ok:
		passed += 1
		print("PASS: palette plugin assigns valid color indices (0-3)")
	else:
		failed += 1
		print("FAIL: palette plugin assigned invalid color index")

	# --- Full Pipeline Determinism ---
	var result_a := _run_full_pipeline(77)
	var result_b := _run_full_pipeline(77)
	if result_a == result_b:
		passed += 1
		print("PASS: full pipeline produces deterministic output")
	else:
		failed += 1
		print("FAIL: full pipeline not deterministic")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()


func _run_surface(grid: ChunkGrid, seed_val: int) -> Dictionary:
	var params: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	params["rng"] = rng
	params["seed"] = seed_val
	var surface := SurfaceShapePlugin.new()
	surface.execute(grid, params)
	return params


func _run_full_pipeline(seed_val: int) -> PackedByteArray:
	var grid := ChunkGrid.new(32, 24)
	var runner := PipelineRunner.new()
	runner.add_plugin(SurfaceShapePlugin.new())
	runner.add_plugin(TerrainFillPlugin.new())
	runner.add_plugin(WaterPlacementPlugin.new())
	runner.add_plugin(LooseChunkPlugin.new())
	runner.add_plugin(PalettePlugin.new())
	runner.run(grid, seed_val)
	var data := PackedByteArray()
	var size := grid.get_size()
	for y in range(size.y):
		for x in range(size.x):
			var c = grid.get_chunk(Vector2i(x, y))
			data.append(c.terrain)
			data.append(c.color)
			data.append(c.state)
	return data
