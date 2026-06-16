extends SceneTree

## Headless tests for generation plugins.


func _init() -> void:
	var passed := 0
	var failed := 0

	# Test: surface heights are within grid bounds
	var grid := ChunkGrid.new(32, 20)
	var params := {"seed": 42, "rng": _make_rng(42)}
	var surface := SurfaceShapePlugin.new()
	surface.execute(grid, params)
	var heights: Array = params["surface_heights"]
	var all_in_bounds := true
	for h in heights:
		if h < 0 or h >= 20:
			all_in_bounds = false
			break
	if all_in_bounds and heights.size() == 32:
		passed += 1
		print("PASS: surface heights are within grid bounds")
	else:
		failed += 1
		print("FAIL: surface heights out of bounds or wrong count")

	# Test: fill — all chunks below surface are filled, above are empty
	grid = ChunkGrid.new(32, 20)
	params = {"seed": 42, "rng": _make_rng(42)}
	surface.execute(grid, params)
	var fill := TerrainFillPlugin.new()
	fill.execute(grid, params)
	var fill_correct := true
	for x in range(32):
		var surface_y: int = params["surface_heights"][x]
		for y in range(surface_y):
			if grid.get_chunk(Vector2i(x, y)).terrain != 0:
				fill_correct = false
				break
		for y in range(surface_y, 20):
			if grid.get_chunk(Vector2i(x, y)).terrain == 0:
				fill_correct = false
				break
	if fill_correct:
		passed += 1
		print("PASS: fill — below surface filled, above empty")
	else:
		failed += 1
		print("FAIL: fill correctness violated")

	# Test: water only placed in depressions below water_level
	grid = ChunkGrid.new(32, 20)
	params = {"seed": 42, "rng": _make_rng(42), "water_level": 10, "water_terrain_index": 2}
	surface.execute(grid, params)
	fill.execute(grid, params)
	var water := WaterPlacementPlugin.new()
	water.execute(grid, params)
	var water_correct := true
	for x in range(32):
		var surface_y: int = params["surface_heights"][x]
		for y in range(20):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.state == ChunkGrid.State.LIQUID:
				if y < 10 or surface_y <= 10:
					water_correct = false
					break
	if water_correct:
		passed += 1
		print("PASS: water only placed in depressions below water_level")
	else:
		failed += 1
		print("FAIL: water placed incorrectly")

	# Test: loose count matches density approximately
	grid = ChunkGrid.new(256, 144)
	params = {"seed": 42, "rng": _make_rng(42), "loose_density": 0.1, "loose_terrain_index": 0}
	surface.execute(grid, params)
	fill.execute(grid, params)
	var loose := LooseChunkPlugin.new()
	loose.execute(grid, params)
	var loose_count := 0
	for x in range(256):
		var surface_y: int = params["surface_heights"][x]
		if surface_y > 0:
			var chunk = grid.get_chunk(Vector2i(x, surface_y - 1))
			if chunk.state == ChunkGrid.State.LOOSE:
				loose_count += 1
	var expected := int(256 * 0.1)
	if loose_count > expected / 3 and loose_count < expected * 3:
		passed += 1
		print("PASS: loose count (%d) matches density ~10%% of 256" % loose_count)
	else:
		failed += 1
		print("FAIL: loose count %d outside expected range" % loose_count)

	# Test: palette — ALL non-empty chunks have color_index 0-3
	grid = ChunkGrid.new(32, 20)
	params = {"seed": 42, "rng": _make_rng(42)}
	surface.execute(grid, params)
	fill.execute(grid, params)
	var palette := PalettePlugin.new()
	palette.execute(grid, params)
	var palette_ok := true
	var colored_count := 0
	for y in range(20):
		for x in range(32):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain >= 1:
				colored_count += 1
				if chunk.color < 0 or chunk.color > 3:
					palette_ok = false
	if palette_ok and colored_count > 0:
		passed += 1
		print("PASS: palette — all %d non-empty chunks have color_index 0-3" % colored_count)
	else:
		failed += 1
		print("FAIL: palette — palette_ok=%s colored_count=%d" % [palette_ok, colored_count])

	# Test: palette colors ALL terrain types (add terrain_index=5 manually)
	grid = ChunkGrid.new(4, 4)
	grid.set_chunk(Vector2i(0, 0), 1, 0, ChunkGrid.State.STATIC)
	grid.set_chunk(Vector2i(1, 0), 2, 0, ChunkGrid.State.STATIC)
	grid.set_chunk(Vector2i(2, 0), 5, 0, ChunkGrid.State.STATIC)  # novel terrain
	params = {"seed": 42, "rng": _make_rng(42)}
	palette.execute(grid, params)
	var all_colored := true
	for x in range(3):
		var chunk = grid.get_chunk(Vector2i(x, 0))
		if chunk.color < 0 or chunk.color > 3:
			all_colored = false
	if all_colored:
		passed += 1
		print("PASS: palette colors all terrain types including novel index=5")
	else:
		failed += 1
		print("FAIL: palette skipped some terrain types")

	# Test: full pipeline determinism — same seed = same grid
	var grid_a := ChunkGrid.new(32, 20)
	var grid_b := ChunkGrid.new(32, 20)
	_run_full_pipeline(grid_a, 77)
	_run_full_pipeline(grid_b, 77)
	var identical := true
	for y in range(20):
		for x in range(32):
			var ca = grid_a.get_chunk(Vector2i(x, y))
			var cb = grid_b.get_chunk(Vector2i(x, y))
			if ca.terrain != cb.terrain or ca.color != cb.color or ca.state != cb.state:
				identical = false
				break
	if identical:
		passed += 1
		print("PASS: full pipeline determinism — same seed = same grid")
	else:
		failed += 1
		print("FAIL: same seed produced different grids")

	# Test: adding new terrain type works without code changes
	grid = ChunkGrid.new(16, 16)
	params = {"seed": 42, "rng": _make_rng(42), "amplitude": 2, "base_height": 8}
	params["layers"] = [
		{"terrain_index": 3, "depth": 4},
		{"terrain_index": 7, "depth": -1},
	]
	surface.execute(grid, params)
	fill.execute(grid, params)
	palette.execute(grid, params)
	var novel_ok := true
	var found_3 := false
	var found_7 := false
	for y in range(16):
		for x in range(16):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 3:
				found_3 = true
				if chunk.color < 0 or chunk.color > 3:
					novel_ok = false
			if chunk.terrain == 7:
				found_7 = true
				if chunk.color < 0 or chunk.color > 3:
					novel_ok = false
	if novel_ok and found_3 and found_7:
		passed += 1
		print("PASS: new terrain types work without code changes")
	else:
		failed += 1
		print("FAIL: novel terrains — ok=%s found_3=%s found_7=%s" % [novel_ok, found_3, found_7])

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()


func _make_rng(seed_val: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	return rng


func _run_full_pipeline(grid: ChunkGrid, seed_val: int) -> void:
	var runner := PipelineRunner.new()
	runner.add_plugin(SurfaceShapePlugin.new())
	runner.add_plugin(TerrainFillPlugin.new())
	runner.add_plugin(WaterPlacementPlugin.new())
	runner.add_plugin(LooseChunkPlugin.new())
	runner.add_plugin(PalettePlugin.new())
	runner.run(grid, seed_val)
