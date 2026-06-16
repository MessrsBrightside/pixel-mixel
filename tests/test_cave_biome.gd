extends SceneTree

## Headless functional test for cave biome generation.


func _init() -> void:
	var passed := 0
	var failed := 0

	var gen := BiomeGenerator.new()
	var grid := gen.generate("cave", 42)
	var size := grid.get_size()

	# Test: grid is 500x144
	if size == Vector2i(500, 144):
		passed += 1
		print("PASS: biome grid is 500x144")
	else:
		failed += 1
		print("FAIL: biome grid size is %s (expected 500x144)" % str(size))

	# Test: deterministic
	var grid2 := gen.generate("cave", 42)
	var identical := true
	for y in range(144):
		for x in range(500):
			var a = grid.get_chunk(Vector2i(x, y))
			var b = grid2.get_chunk(Vector2i(x, y))
			if a.terrain != b.terrain or a.color != b.color or a.state != b.state:
				identical = false
				break
		if not identical:
			break
	if identical:
		passed += 1
		print("PASS: deterministic — same seed = same output")
	else:
		failed += 1
		print("FAIL: non-deterministic output")

	# Test: ceiling solid (top 10 rows all stone)
	var ceiling_solid := true
	for y in range(10):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain != 2:
				ceiling_solid = false
				break
		if not ceiling_solid:
			break
	if ceiling_solid:
		passed += 1
		print("PASS: ceiling solid (top 10 rows all stone)")
	else:
		failed += 1
		print("FAIL: ceiling not solid stone in top rows")

	# Test: floor solid (bottom 10 rows all stone)
	var floor_solid := true
	for y in range(134, 144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain != 2:
				floor_solid = false
				break
		if not floor_solid:
			break
	if floor_solid:
		passed += 1
		print("PASS: floor solid (bottom 10 rows all stone)")
	else:
		failed += 1
		print("FAIL: floor not solid stone in bottom rows")

	# Test: open space in middle (empty chunks present)
	var empty_count := 0
	for y in range(50, 95):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 0:
				empty_count += 1
	if empty_count > 1000:
		passed += 1
		print("PASS: open space in middle (%d empty chunks)" % empty_count)
	else:
		failed += 1
		print("FAIL: insufficient open space (%d empty chunks)" % empty_count)

	# Test: mushrooms present (terrain=8)
	var mush_count := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 8:
				mush_count += 1
	if mush_count > 0:
		passed += 1
		print("PASS: mushrooms present (%d chunks)" % mush_count)
	else:
		failed += 1
		print("FAIL: no mushrooms found")

	# Test: stalactites present (stone chunks hanging below ceiling edge)
	var stalactite_found := false
	for x in range(500):
		# Check if there's stone below the general ceiling area but above the floor
		var found_gap := false
		for y in range(50, 90):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 2:
				# Stone in open area — could be stalactite or pillar
				# Verify it connects upward to ceiling
				var above = grid.get_chunk(Vector2i(x, y - 1))
				if above.terrain == 2:
					stalactite_found = true
					break
		if stalactite_found:
			break
	if stalactite_found:
		passed += 1
		print("PASS: stalactites present")
	else:
		failed += 1
		print("FAIL: no stalactites found")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
