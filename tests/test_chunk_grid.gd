extends SceneTree

## Headless tests for ChunkGrid data structure.

const ChunkGridClass = preload("res://scripts/chunk_grid.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# Test: get_size returns configured dimensions
	var grid = ChunkGridClass.new(256, 144)
	if grid.get_size() == Vector2i(256, 144):
		passed += 1
		print("PASS: get_size returns correct dimensions")
	else:
		failed += 1
		print("FAIL: get_size returned %s" % str(grid.get_size()))

	# Test: set/get round-trip
	grid.set_chunk(Vector2i(10, 20), 3, 7, ChunkGridClass.State.LOOSE)
	var chunk = grid.get_chunk(Vector2i(10, 20))
	if chunk != null and chunk.terrain == 3 and chunk.color == 7 and chunk.state == ChunkGridClass.State.LOOSE:
		passed += 1
		print("PASS: set/get round-trip")
	else:
		failed += 1
		print("FAIL: set/get round-trip got %s" % str(chunk))

	# Test: default chunk is all zeros
	var default_chunk = grid.get_chunk(Vector2i(0, 0))
	if default_chunk != null and default_chunk.terrain == 0 and default_chunk.color == 0 and default_chunk.state == 0:
		passed += 1
		print("PASS: default chunk is zeroed")
	else:
		failed += 1
		print("FAIL: default chunk got %s" % str(default_chunk))

	# Test: out-of-bounds get returns null
	var oob = grid.get_chunk(Vector2i(-1, 0))
	if oob == null:
		passed += 1
		print("PASS: OOB negative returns null")
	else:
		failed += 1
		print("FAIL: OOB negative got %s" % str(oob))

	oob = grid.get_chunk(Vector2i(256, 0))
	if oob == null:
		passed += 1
		print("PASS: OOB beyond width returns null")
	else:
		failed += 1
		print("FAIL: OOB beyond width got %s" % str(oob))

	# Test: out-of-bounds set does not crash
	grid.set_chunk(Vector2i(-5, -5), 1, 1, 1)
	grid.set_chunk(Vector2i(999, 999), 1, 1, 1)
	passed += 1
	print("PASS: OOB set does not crash")

	# Test: neighbors at interior position (4 neighbors)
	grid.set_chunk(Vector2i(5, 5), 1, 2, 0)
	grid.set_chunk(Vector2i(5, 4), 2, 3, 1)  # up
	grid.set_chunk(Vector2i(6, 5), 3, 4, 2)  # right
	grid.set_chunk(Vector2i(5, 6), 4, 5, 0)  # down
	grid.set_chunk(Vector2i(4, 5), 5, 6, 1)  # left
	var neighbors = grid.get_neighbors(Vector2i(5, 5))
	if neighbors.size() == 4:
		passed += 1
		print("PASS: interior neighbors count is 4")
	else:
		failed += 1
		print("FAIL: interior neighbors count is %d" % neighbors.size())

	# Test: neighbors at corner (0,0) — only 2 neighbors (right and down)
	var corner_neighbors = grid.get_neighbors(Vector2i(0, 0))
	if corner_neighbors.size() == 2:
		passed += 1
		print("PASS: corner (0,0) neighbors count is 2")
	else:
		failed += 1
		print("FAIL: corner (0,0) neighbors count is %d" % corner_neighbors.size())

	# Test: neighbors at edge (0,5) — 3 neighbors (up, right, down)
	var edge_neighbors = grid.get_neighbors(Vector2i(0, 5))
	if edge_neighbors.size() == 3:
		passed += 1
		print("PASS: edge (0,5) neighbors count is 3")
	else:
		failed += 1
		print("FAIL: edge (0,5) neighbors count is %d" % edge_neighbors.size())

	# Test: iterate_region returns correct count with pos
	var region = grid.iterate_region(Rect2i(0, 0, 4, 4))
	if region.size() == 16 and region[0].has("pos") and region[0].pos == Vector2i(0, 0):
		passed += 1
		print("PASS: iterate_region 4x4 returns 16 chunks with pos")
	else:
		failed += 1
		print("FAIL: iterate_region 4x4 returned %d chunks or missing pos" % region.size())

	# Test: iterate_region clamps to bounds
	var clamped = grid.iterate_region(Rect2i(-2, -2, 5, 5))
	if clamped.size() == 9:  # only 3x3 in bounds (0..2, 0..2)
		passed += 1
		print("PASS: iterate_region clamps to bounds correctly")
	else:
		failed += 1
		print("FAIL: iterate_region clamped returned %d (expected 9)" % clamped.size())

	# Test: is_in_bounds
	if grid.is_in_bounds(Vector2i(0, 0)) and grid.is_in_bounds(Vector2i(255, 143)):
		passed += 1
		print("PASS: is_in_bounds valid positions")
	else:
		failed += 1
		print("FAIL: is_in_bounds rejected valid positions")

	if not grid.is_in_bounds(Vector2i(-1, 0)) and not grid.is_in_bounds(Vector2i(256, 144)):
		passed += 1
		print("PASS: is_in_bounds rejects OOB positions")
	else:
		failed += 1
		print("FAIL: is_in_bounds accepted OOB positions")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
