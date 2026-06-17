extends SceneTree

## Headless tests for TerrainCollision shape generation.

const ChunkGridClass = preload("res://scripts/chunk_grid.gd")
const TerrainDefClass = preload("res://scripts/terrain_def.gd")
const TerrainCollisionClass = preload("res://scripts/physics/terrain_collision.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# Build terrain defs array matching project indices
	var defs: Array[TerrainDef] = []
	defs.resize(11)
	defs[0] = null
	# Solid terrains: dirt=1, stone=2, sand=7, grass_solid=10
	for idx in [1, 2, 7, 10]:
		var d := TerrainDefClass.new()
		d.passable = false
		defs[idx] = d
	# Water=3 (passable, but we use state=LIQUID to exclude)
	var water_def := TerrainDefClass.new()
	water_def.passable = true
	defs[3] = water_def
	# Passable terrains: grass=4, leaves=5, wood=6, mushroom=8, cactus=9
	for idx in [4, 5, 6, 8, 9]:
		var d := TerrainDefClass.new()
		d.passable = true
		defs[idx] = d

	# --- Test: solid terrain generates collision shapes ---
	var grid := ChunkGridClass.new(32, 32)
	grid.set_chunk(Vector2i(0, 0), 1, 0, ChunkGridClass.State.STATIC)  # dirt
	grid.set_chunk(Vector2i(1, 0), 2, 0, ChunkGridClass.State.STATIC)  # stone
	grid.set_chunk(Vector2i(2, 0), 7, 0, ChunkGridClass.State.STATIC)  # sand
	var tc := TerrainCollisionClass.new()
	tc.grid = grid
	tc.terrain_defs = defs
	root.add_child(tc)
	tc.build_all()
	# 3 adjacent solid chunks in row 0 → 1 merged shape
	var shapes := _count_collision_shapes(tc)
	if shapes == 1:
		passed += 1
		print("PASS: solid terrain generates 1 merged collision shape for 3 adjacent chunks")
	else:
		failed += 1
		print("FAIL: expected 1 collision shape, got %d" % shapes)
	tc.queue_free()

	# --- Test: passable terrain does NOT generate collision ---
	grid = ChunkGridClass.new(32, 32)
	grid.set_chunk(Vector2i(0, 0), 4, 0, ChunkGridClass.State.STATIC)  # grass (passable)
	grid.set_chunk(Vector2i(1, 0), 5, 0, ChunkGridClass.State.STATIC)  # leaves
	grid.set_chunk(Vector2i(2, 0), 6, 0, ChunkGridClass.State.STATIC)  # wood
	grid.set_chunk(Vector2i(3, 0), 8, 0, ChunkGridClass.State.STATIC)  # mushroom
	grid.set_chunk(Vector2i(4, 0), 9, 0, ChunkGridClass.State.STATIC)  # cactus
	tc = TerrainCollisionClass.new()
	tc.grid = grid
	tc.terrain_defs = defs
	root.add_child(tc)
	tc.build_all()
	shapes = _count_collision_shapes(tc)
	if shapes == 0:
		passed += 1
		print("PASS: passable terrain does NOT generate collision")
	else:
		failed += 1
		print("FAIL: passable terrain generated %d shapes (expected 0)" % shapes)
	tc.queue_free()

	# --- Test: liquid does NOT generate collision ---
	grid = ChunkGridClass.new(32, 32)
	grid.set_chunk(Vector2i(0, 0), 3, 0, ChunkGridClass.State.LIQUID)  # water
	grid.set_chunk(Vector2i(1, 0), 1, 0, ChunkGridClass.State.LIQUID)  # dirt as liquid
	tc = TerrainCollisionClass.new()
	tc.grid = grid
	tc.terrain_defs = defs
	root.add_child(tc)
	tc.build_all()
	shapes = _count_collision_shapes(tc)
	if shapes == 0:
		passed += 1
		print("PASS: liquid does NOT generate collision")
	else:
		failed += 1
		print("FAIL: liquid generated %d shapes (expected 0)" % shapes)
	tc.queue_free()

	# --- Test: rebuild_region clears and regenerates ---
	grid = ChunkGridClass.new(32, 32)
	grid.set_chunk(Vector2i(0, 0), 1, 0, ChunkGridClass.State.STATIC)
	tc = TerrainCollisionClass.new()
	tc.grid = grid
	tc.terrain_defs = defs
	root.add_child(tc)
	tc.build_all()
	# Modify grid: remove the solid chunk
	grid.set_chunk(Vector2i(0, 0), 0, 0, ChunkGridClass.State.STATIC)
	tc.rebuild_region(Vector2i(0, 0))
	# Old region node is queue_freed but new one should have 0 shapes
	shapes = _count_collision_shapes(tc)
	if shapes == 0:
		passed += 1
		print("PASS: rebuild_region clears and regenerates (0 shapes after removal)")
	else:
		failed += 1
		print("FAIL: rebuild_region still has %d shapes after clearing chunk" % shapes)
	tc.queue_free()

	# --- Test: empty region has no collision shapes ---
	grid = ChunkGridClass.new(32, 32)
	tc = TerrainCollisionClass.new()
	tc.grid = grid
	tc.terrain_defs = defs
	root.add_child(tc)
	tc.build_all()
	shapes = _count_collision_shapes(tc)
	if shapes == 0:
		passed += 1
		print("PASS: empty region has no collision shapes")
	else:
		failed += 1
		print("FAIL: empty region has %d shapes (expected 0)" % shapes)
	tc.queue_free()

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
	quit()


func _count_collision_shapes(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is CollisionShape2D:
			count += 1
		count += _count_collision_shapes(child)
	return count
