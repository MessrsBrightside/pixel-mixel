extends SceneTree

## Headless functional test for ocean shore biome generation.


func _init() -> void:
	var passed := 0
	var failed := 0

	# Test: BiomeGenerator produces 500x144 grid
	var gen := BiomeGenerator.new()
	var grid := gen.generate("ocean_shore", 42)
	var size := grid.get_size()
	if size == Vector2i(500, 144):
		passed += 1
		print("PASS: biome grid is 500x144")
	else:
		failed += 1
		print("FAIL: biome grid size is %s (expected 500x144)" % str(size))

	# Test: determinism — same seed = same grid
	var grid2 := gen.generate("ocean_shore", 42)
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

	# Test: sand chunks are ALL LOOSE state
	var sand_count := 0
	var sand_static := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 7:  # sand
				sand_count += 1
				if chunk.state != ChunkGrid.State.LOOSE:
					sand_static += 1
	if sand_count > 0 and sand_static == 0:
		passed += 1
		print("PASS: all %d sand chunks are LOOSE" % sand_count)
	else:
		failed += 1
		print("FAIL: sand_count=%d sand_static=%d" % [sand_count, sand_static])

	# Test: water chunks exist and are LIQUID
	var water_count := 0
	var water_not_liquid := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 3:  # water
				water_count += 1
				if chunk.state != ChunkGrid.State.LIQUID:
					water_not_liquid += 1
	if water_count > 0 and water_not_liquid == 0:
		passed += 1
		print("PASS: %d water chunks all LIQUID" % water_count)
	else:
		failed += 1
		print("FAIL: water_count=%d water_not_liquid=%d" % [water_count, water_not_liquid])

	# Test: palm trees exist (wood + leaves chunks present)
	var wood_count := 0
	var leaves_count := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 6:  # wood
				wood_count += 1
			if chunk.terrain == 5:  # leaves
				leaves_count += 1
	if wood_count > 0 and leaves_count > 0:
		passed += 1
		print("PASS: palm trees present (wood=%d leaves=%d)" % [wood_count, leaves_count])
	else:
		failed += 1
		print("FAIL: no palm trees (wood=%d leaves=%d)" % [wood_count, leaves_count])

	# Test: wood and leaves are STATIC
	var tree_not_static := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 5 or chunk.terrain == 6:
				if chunk.state != ChunkGrid.State.STATIC:
					tree_not_static += 1
	if tree_not_static == 0:
		passed += 1
		print("PASS: all tree chunks are STATIC")
	else:
		failed += 1
		print("FAIL: %d tree chunks not STATIC" % tree_not_static)

	# Test: grass exists and is STATIC
	var grass_count := 0
	var grass_not_static := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 4:  # grass
				grass_count += 1
				if chunk.state != ChunkGrid.State.STATIC:
					grass_not_static += 1
	if grass_count > 0 and grass_not_static == 0:
		passed += 1
		print("PASS: grass present (%d) and all STATIC" % grass_count)
	else:
		failed += 1
		print("FAIL: grass_count=%d grass_not_static=%d" % [grass_count, grass_not_static])

	# Test: stone underground exists
	var stone_count := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 2:  # stone
				stone_count += 1
	if stone_count > 0:
		passed += 1
		print("PASS: stone underground present (%d chunks)" % stone_count)
	else:
		failed += 1
		print("FAIL: no stone found")

	# Test: no LOOSE chunk has LIQUID directly below (sand sank past all water)
	var loose_above_liquid := 0
	for y in range(143):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain != 0 and chunk.state == ChunkGrid.State.LOOSE:
				var below_chunk = grid.get_chunk(Vector2i(x, y + 1))
				if below_chunk.state == ChunkGrid.State.LIQUID:
					loose_above_liquid += 1
	if loose_above_liquid == 0:
		passed += 1
		print("PASS: no LOOSE chunk has LIQUID directly below")
	else:
		failed += 1
		print("FAIL: %d LOOSE chunks still above LIQUID" % loose_above_liquid)

	# Test: sand exists at or below water level (it sank to the floor)
	var water_surface_y := int(144 * 0.55)  # matches biome code
	var sand_at_or_below_water := 0
	for y in range(water_surface_y, 144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 7:
				sand_at_or_below_water += 1
	if sand_at_or_below_water > 0:
		passed += 1
		print("PASS: sand exists at/below water level (%d chunks)" % sand_at_or_below_water)
	else:
		failed += 1
		print("FAIL: no sand at or below water level")

	# Test: simulation terminates (BiomeGenerator returns without hanging)
	var t_start := Time.get_ticks_msec()
	var _grid3 := gen.generate("ocean_shore", 99)
	var elapsed := Time.get_ticks_msec() - t_start
	if elapsed < 30000:
		passed += 1
		print("PASS: simulation terminates in %dms" % elapsed)
	else:
		failed += 1
		print("FAIL: simulation took too long (%dms)" % elapsed)

	# Test: BiomeRegistry returns correct plugin
	var registry := BiomeRegistry.new()
	var plugin := registry.get_biome("ocean_shore")
	if plugin != null and plugin is OceanShoreBiome:
		passed += 1
		print("PASS: BiomeRegistry returns OceanShoreBiome")
	else:
		failed += 1
		print("FAIL: BiomeRegistry did not return correct plugin")

	# Test: unknown biome returns null
	var unknown := registry.get_biome("nonexistent")
	if unknown == null:
		passed += 1
		print("PASS: unknown biome returns null")
	else:
		failed += 1
		print("FAIL: unknown biome did not return null")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
