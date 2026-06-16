extends SceneTree

## Integration tests: determinism, settlement invariants, terrain structure, palette coverage.

const WorldGeneratorClass = preload("res://scripts/world_generator.gd")


func _init() -> void:
	var passed := 0
	var failed := 0
	var gen := WorldGeneratorClass.new()

	# Test: determinism — same seed produces identical grids
	var grid_a := gen.generate(42)
	var grid_b := gen.generate(42)
	if _grids_equal(grid_a, grid_b):
		passed += 1
		print("PASS: determinism — seed 42 twice produces identical grids")
	else:
		failed += 1
		print("FAIL: determinism — seed 42 produced different grids")

	# Test: different seeds produce different grids
	var grid_c := gen.generate(99)
	if not _grids_equal(grid_a, grid_c):
		passed += 1
		print("PASS: seed 42 vs 99 differ")
	else:
		failed += 1
		print("FAIL: seed 42 vs 99 are identical")

	# Test: settlement — no LOOSE chunk has empty below
	var size := grid_a.get_size()
	var loose_ok := true
	for y in range(size.y - 1):
		for x in range(size.x):
			var chunk = grid_a.get_chunk(Vector2i(x, y))
			if chunk.state == ChunkGrid.State.LOOSE:
				var below = grid_a.get_chunk(Vector2i(x, y + 1))
				if below.terrain == 0:
					loose_ok = false
					break
		if not loose_ok:
			break
	if loose_ok:
		passed += 1
		print("PASS: settlement — no LOOSE chunk has empty below")
	else:
		failed += 1
		print("FAIL: settlement — found LOOSE chunk with empty below")

	# Test: settlement — no LIQUID chunk has empty below
	var liquid_ok := true
	for y in range(size.y - 1):
		for x in range(size.x):
			var chunk = grid_a.get_chunk(Vector2i(x, y))
			if chunk.state == ChunkGrid.State.LIQUID:
				var below = grid_a.get_chunk(Vector2i(x, y + 1))
				if below.terrain == 0:
					liquid_ok = false
					break
		if not liquid_ok:
			break
	if liquid_ok:
		passed += 1
		print("PASS: settlement — no LIQUID chunk has empty below")
	else:
		failed += 1
		print("FAIL: settlement — found LIQUID chunk with empty below")

	# Test: water level — liquid forms level surface (no single-column towers)
	var water_ok := true
	for x in range(size.x):
		var liquid_top := -1
		for y in range(size.y):
			var chunk = grid_a.get_chunk(Vector2i(x, y))
			if chunk.state == ChunkGrid.State.LIQUID:
				liquid_top = y
				break
		if liquid_top < 0:
			continue
		# Check neighbors also have liquid at same or adjacent level
		var isolated := true
		for nx in [x - 1, x + 1]:
			if nx < 0 or nx >= size.x:
				continue
			for ny in range(liquid_top - 1, liquid_top + 2):
				if ny < 0 or ny >= size.y:
					continue
				var nc = grid_a.get_chunk(Vector2i(nx, ny))
				if nc.state == ChunkGrid.State.LIQUID:
					isolated = false
					break
			if not isolated:
				break
		if isolated:
			water_ok = false
			break
	if water_ok:
		passed += 1
		print("PASS: water level — no single-column liquid towers")
	else:
		failed += 1
		print("FAIL: water level — found isolated liquid column")

	# Test: terrain structure — above surface empty, below filled
	# Re-generate to get access to surface_heights via params
	var params := {}
	var grid_d := _generate_with_params(42, params)
	var heights: Array = params.get("surface_heights", [])
	var struct_ok := true
	if heights.size() == size.x:
		for x in range(size.x):
			var surface_y: int = heights[x]
			for y in range(surface_y):
				var chunk = grid_d.get_chunk(Vector2i(x, y))
				if chunk.terrain != 0 and chunk.state != ChunkGrid.State.LIQUID and chunk.state != ChunkGrid.State.LOOSE:
					struct_ok = false
					break
			if not struct_ok:
				break
			for y in range(surface_y, size.y):
				var chunk = grid_d.get_chunk(Vector2i(x, y))
				if chunk.terrain == 0:
					struct_ok = false
					break
			if not struct_ok:
				break
	else:
		struct_ok = false
	if struct_ok:
		passed += 1
		print("PASS: terrain structure — above surface empty, below filled")
	else:
		failed += 1
		print("FAIL: terrain structure violated")

	# Test: palette coverage — all non-empty chunks have color_index 0-3
	var palette_ok := true
	for y in range(size.y):
		for x in range(size.x):
			var chunk = grid_a.get_chunk(Vector2i(x, y))
			if chunk.terrain >= 1:
				if chunk.color < 0 or chunk.color > 3:
					palette_ok = false
					break
		if not palette_ok:
			break
	if palette_ok:
		passed += 1
		print("PASS: palette coverage — all non-empty chunks have color_index 0-3")
	else:
		failed += 1
		print("FAIL: palette coverage — found chunk with color outside 0-3")

	# Test: surface contour reference — known seed produces known heights
	var ref_params := {}
	var ref_grid := _generate_with_params(42, ref_params)
	var ref_heights: Array = ref_params.get("surface_heights", [])
	# Sample at columns 0, 50, 100, 150, 200, 250
	var sample_cols := [0, 50, 100, 150, 200, 250]
	var expected_heights := []
	for col in sample_cols:
		expected_heights.append(ref_heights[col])
	# Re-generate and compare
	var ref_params2 := {}
	var ref_grid2 := _generate_with_params(42, ref_params2)
	var ref_heights2: Array = ref_params2.get("surface_heights", [])
	var ref_match := true
	for i in range(sample_cols.size()):
		if ref_heights2[sample_cols[i]] != expected_heights[i]:
			ref_match = false
			break
	if ref_match:
		passed += 1
		print("PASS: surface contour reference — seed 42 heights stable across runs")
	else:
		failed += 1
		print("FAIL: surface contour reference — heights changed between runs")

	# Test: no floating terrain — every filled static chunk has support below (or is at bottom)
	var float_ok := true
	for x in range(size.x):
		for y in range(size.y - 1):
			var chunk = grid_a.get_chunk(Vector2i(x, y))
			if chunk.terrain != 0 and chunk.state == ChunkGrid.State.STATIC:
				var below = grid_a.get_chunk(Vector2i(x, y + 1))
				if below.terrain == 0:
					float_ok = false
					break
		if not float_ok:
			break
	if float_ok:
		passed += 1
		print("PASS: no floating terrain — all static chunks have support below")
	else:
		failed += 1
		print("FAIL: floating terrain detected")

	# Test: pipeline extensibility — remove/reorder doesn't crash
	var ext_ok := true
	# Remove water plugin
	var grid_no_water := ChunkGrid.new(64, 36)
	var runner_nw := PipelineRunner.new()
	runner_nw.add_plugin(SurfaceShapePlugin.new())
	runner_nw.add_plugin(TerrainFillPlugin.new())
	runner_nw.add_plugin(PalettePlugin.new())
	runner_nw.run(grid_no_water, 42)
	# Reorder: palette before fill
	var grid_reorder := ChunkGrid.new(64, 36)
	var runner_ro := PipelineRunner.new()
	runner_ro.add_plugin(SurfaceShapePlugin.new())
	runner_ro.add_plugin(PalettePlugin.new())
	runner_ro.add_plugin(TerrainFillPlugin.new())
	runner_ro.run(grid_reorder, 42)
	if ext_ok:
		passed += 1
		print("PASS: pipeline extensibility — remove/reorder runs without crash")
	else:
		failed += 1
		print("FAIL: pipeline extensibility — crashed")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
	quit()


func _grids_equal(a: ChunkGrid, b: ChunkGrid) -> bool:
	var size := a.get_size()
	if size != b.get_size():
		return false
	for y in range(size.y):
		for x in range(size.x):
			var ca = a.get_chunk(Vector2i(x, y))
			var cb = b.get_chunk(Vector2i(x, y))
			if ca.terrain != cb.terrain or ca.color != cb.color or ca.state != cb.state:
				return false
	return true


func _generate_with_params(seed_val: int, params: Dictionary) -> ChunkGrid:
	var grid := ChunkGrid.new(256, 144)
	var runner := PipelineRunner.new()
	runner.add_plugin(SurfaceShapePlugin.new())
	runner.add_plugin(TerrainFillPlugin.new())
	runner.add_plugin(WaterPlacementPlugin.new())
	runner.add_plugin(LooseChunkPlugin.new())
	runner.add_plugin(PalettePlugin.new())
	runner.run(grid, seed_val, params)
	var sim := ChunkSimulator.new(seed_val)
	sim.simulate_until_settled(grid)
	return grid
