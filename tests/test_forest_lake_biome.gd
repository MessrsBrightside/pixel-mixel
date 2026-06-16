extends SceneTree

## Headless functional test for forest lake biome generation.


func _init() -> void:
	var passed := 0
	var failed := 0

	var gen := BiomeGenerator.new()
	var grid := gen.generate("forest_lake", 42)
	var size := grid.get_size()

	# Test: grid is 500x144
	if size == Vector2i(500, 144):
		passed += 1
		print("PASS: biome grid is 500x144")
	else:
		failed += 1
		print("FAIL: biome grid size is %s (expected 500x144)" % str(size))

	# Test: deterministic
	var grid2 := gen.generate("forest_lake", 42)
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

	# Test: water body present (significant LIQUID count)
	var liquid_count := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.state == ChunkGrid.State.LIQUID:
				liquid_count += 1
	if liquid_count > 1000:
		passed += 1
		print("PASS: water body present (%d LIQUID chunks)" % liquid_count)
	else:
		failed += 1
		print("FAIL: insufficient water (%d LIQUID chunks)" % liquid_count)

	# Test: trees present on land (wood + leaves)
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

	# Test: grass at waterline
	var grass_near_water := 0
	for y in range(144):
		for x in range(500):
			var chunk = grid.get_chunk(Vector2i(x, y))
			if chunk.terrain == 4 and chunk.state == ChunkGrid.State.STATIC:
				# Check if adjacent to a liquid chunk
				var neighbors := grid.get_neighbors(Vector2i(x, y))
				for n in neighbors:
					if n.state == ChunkGrid.State.LIQUID:
						grass_near_water += 1
						break
	if grass_near_water > 0:
		passed += 1
		print("PASS: grass at waterline (%d chunks)" % grass_near_water)
	else:
		failed += 1
		print("FAIL: no grass at waterline")

	# Test: stone underground
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

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
