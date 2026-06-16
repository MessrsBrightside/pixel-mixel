extends SceneTree

## Headless functional test for forest surface biome generation.


func _init() -> void:
	var passed := 0
	var failed := 0

	# Test: grid is 500x144
	var gen := BiomeGenerator.new()
	var grid := gen.generate("forest_surface", 42)
	var size := grid.get_size()
	if size == Vector2i(500, 144):
		passed += 1
		print("PASS: biome grid is 500x144")
	else:
		failed += 1
		print("FAIL: biome grid size is %s (expected 500x144)" % str(size))

	# Test: deterministic — same seed = same output
	var grid2 := gen.generate("forest_surface", 42)
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

	# Test: grass layer present on surface
	var grass_count := 0
	for x in range(500):
		for y in range(144):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 4:
				grass_count += 1
				break
	if grass_count > 400:
		passed += 1
		print("PASS: grass on surface (%d columns have grass)" % grass_count)
	else:
		failed += 1
		print("FAIL: insufficient grass coverage (%d columns)" % grass_count)

	# Test: trees present (wood + leaves chunks)
	var wood_count := 0
	var leaves_count := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 6:
				wood_count += 1
			elif chunk.terrain == 5:
				leaves_count += 1
	if wood_count > 0 and leaves_count > 0:
		passed += 1
		print("PASS: trees present (wood=%d leaves=%d)" % [wood_count, leaves_count])
	else:
		failed += 1
		print("FAIL: no trees (wood=%d leaves=%d)" % [wood_count, leaves_count])

	# Test: all vegetation is passable (STATIC state — passable is on TerrainDef)
	var veg_not_static := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain in [4, 5, 6]:  # grass, leaves, wood
				if chunk.state != ChunkGrid.State.STATIC:
					veg_not_static += 1
	if veg_not_static == 0:
		passed += 1
		print("PASS: all vegetation chunks are STATIC")
	else:
		failed += 1
		print("FAIL: %d vegetation chunks not STATIC" % veg_not_static)

	# Test: stone exists underground
	var stone_count := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 2:
				stone_count += 1
	if stone_count > 0:
		passed += 1
		print("PASS: stone underground (%d chunks)" % stone_count)
	else:
		failed += 1
		print("FAIL: no stone found")

	# Test: BiomeRegistry returns ForestSurfaceBiome
	var registry := BiomeRegistry.new()
	var plugin := registry.get_biome("forest_surface")
	if plugin != null and plugin is ForestSurfaceBiome:
		passed += 1
		print("PASS: BiomeRegistry returns ForestSurfaceBiome")
	else:
		failed += 1
		print("FAIL: BiomeRegistry did not return correct plugin")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
