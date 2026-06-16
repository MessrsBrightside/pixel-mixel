extends SceneTree

## Headless functional test for desert biome generation.


func _init() -> void:
	var passed := 0
	var failed := 0

	var gen := BiomeGenerator.new()
	var grid := gen.generate("desert", 42)
	var size := grid.get_size()

	# Test: grid is 500x144
	if size == Vector2i(500, 144):
		passed += 1
		print("PASS: biome grid is 500x144")
	else:
		failed += 1
		print("FAIL: biome grid size is %s (expected 500x144)" % str(size))

	# Test: deterministic
	var grid2 := gen.generate("desert", 42)
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

	# Test: all sand chunks are LOOSE
	var sand_count := 0
	var sand_not_loose := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 7:
				sand_count += 1
				if chunk.state != ChunkGrid.State.LOOSE:
					sand_not_loose += 1
	if sand_count > 0 and sand_not_loose == 0:
		passed += 1
		print("PASS: all sand chunks are LOOSE (%d total)" % sand_count)
	else:
		failed += 1
		print("FAIL: sand state issue — %d sand, %d not LOOSE" % [sand_count, sand_not_loose])

	# Test: no water (zero LIQUID chunks)
	var liquid_count := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.state == ChunkGrid.State.LIQUID:
				liquid_count += 1
	if liquid_count == 0:
		passed += 1
		print("PASS: no water — zero LIQUID chunks")
	else:
		failed += 1
		print("FAIL: found %d LIQUID chunks" % liquid_count)

	# Test: cactus present (terrain=9)
	var cactus_count := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 9:
				cactus_count += 1
	if cactus_count > 0:
		passed += 1
		print("PASS: cactus present (%d chunks)" % cactus_count)
	else:
		failed += 1
		print("FAIL: no cactus found")

	# Test: stone underground
	var stone_found := false
	for x in range(0, 500, 50):
		var chunk = grid.get_chunk(Vector2i(x, 140))
		if chunk.terrain == 2:
			stone_found = true
			break
	if stone_found:
		passed += 1
		print("PASS: stone underground")
	else:
		failed += 1
		print("FAIL: no stone at bottom rows")

	# Test: sand forms dune shapes (surface height varies)
	var min_surface := 144
	var max_surface := 0
	for x in range(500):
		for y in range(144):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain != 0:
				if y < min_surface:
					min_surface = y
				if y > max_surface:
					max_surface = y
				break
	var height_range := max_surface - min_surface
	if height_range >= 10:
		passed += 1
		print("PASS: dune shapes — surface height varies by %d rows" % height_range)
	else:
		failed += 1
		print("FAIL: surface height range too flat (%d)" % height_range)

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
