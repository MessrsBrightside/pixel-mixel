extends SceneTree

## Functional tests for StructureCollapse: trunk collapse, below-cut stability, canopy propagation, non-passable immunity.

const ChunkGridClass = preload("res://scripts/chunk_grid.gd")
const TerrainDefClass = preload("res://scripts/terrain_def.gd")
const StructureCollapseClass = preload("res://scripts/structure_collapse.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- Shared terrain defs ---
	# 0 = empty, 1 = stone (non-passable), 2 = wood (passable), 3 = leaves (passable)
	var stone_def := TerrainDefClass.new()
	stone_def.toughness = 1.0
	stone_def.passable = false
	stone_def.palette = [Color.GRAY]

	var wood_def := TerrainDefClass.new()
	wood_def.toughness = 0.5
	wood_def.passable = true
	wood_def.palette = [Color.BROWN]

	var leaves_def := TerrainDefClass.new()
	leaves_def.toughness = 0.1
	leaves_def.passable = true
	leaves_def.palette = [Color.GREEN]

	var defs: Array[TerrainDef] = []
	defs.resize(4)
	defs[0] = null
	defs[1] = stone_def
	defs[2] = wood_def
	defs[3] = leaves_def

	# --- Test: destroy trunk chunk → chunks above collapse ---
	var grid := ChunkGridClass.new(32, 32)
	# Stone ground at row 20
	for x in range(32):
		grid.set_chunk(Vector2i(x, 20), 1, 0, ChunkGridClass.State.STATIC)
	# Tree trunk: wood at column 10, rows 15-19 (above ground)
	for y in range(15, 20):
		grid.set_chunk(Vector2i(10, y), 2, 0, ChunkGridClass.State.STATIC)

	# Destroy the trunk at row 17 (middle of trunk)
	var destroyed: Array[Vector2i] = [Vector2i(10, 17)]
	grid.set_chunk(Vector2i(10, 17), 0, 0, 0)

	var collapse := StructureCollapseClass.new()
	collapse.check_collapse(grid, destroyed, null, null, defs)

	# Chunks above the cut (rows 15, 16) should be gone
	var above_collapsed := true
	for y in range(15, 17):
		var chunk = grid.get_chunk(Vector2i(10, y))
		if chunk.terrain != 0:
			above_collapsed = false
			break
	if above_collapsed:
		passed += 1
		print("PASS: trunk chunks above cut collapse")
	else:
		failed += 1
		print("FAIL: trunk chunks above cut did not collapse")

	# --- Test: chunks BELOW the cut remain static ---
	var below_intact := true
	for y in range(18, 20):
		var chunk = grid.get_chunk(Vector2i(10, y))
		if chunk.terrain != 2:
			below_intact = false
			break
	if below_intact:
		passed += 1
		print("PASS: chunks below cut remain static")
	else:
		failed += 1
		print("FAIL: chunks below cut were incorrectly removed")

	# --- Test: connected canopy collapses when trunk is severed ---
	var grid2 := ChunkGridClass.new(32, 32)
	# Ground
	for x in range(32):
		grid2.set_chunk(Vector2i(x, 20), 1, 0, ChunkGridClass.State.STATIC)
	# Trunk at column 10, rows 15-19
	for y in range(15, 20):
		grid2.set_chunk(Vector2i(10, y), 2, 0, ChunkGridClass.State.STATIC)
	# Canopy (leaves) at row 14, columns 8-12
	for x in range(8, 13):
		grid2.set_chunk(Vector2i(x, 14), 3, 0, ChunkGridClass.State.STATIC)

	# Destroy trunk at row 17
	grid2.set_chunk(Vector2i(10, 17), 0, 0, 0)
	var destroyed2: Array[Vector2i] = [Vector2i(10, 17)]
	var collapse2 := StructureCollapseClass.new()
	collapse2.check_collapse(grid2, destroyed2, null, null, defs)

	# Canopy should be gone
	var canopy_collapsed := true
	for x in range(8, 13):
		var chunk = grid2.get_chunk(Vector2i(x, 14))
		if chunk.terrain != 0:
			canopy_collapsed = false
			break
	if canopy_collapsed:
		passed += 1
		print("PASS: connected canopy collapses when trunk severed")
	else:
		failed += 1
		print("FAIL: canopy did not collapse when trunk severed")

	# --- Test: non-passable chunks are not affected ---
	var grid3 := ChunkGridClass.new(32, 32)
	# Ground
	for x in range(32):
		grid3.set_chunk(Vector2i(x, 20), 1, 0, ChunkGridClass.State.STATIC)
	# Stone column at x=10, rows 15-19
	for y in range(15, 20):
		grid3.set_chunk(Vector2i(10, y), 1, 0, ChunkGridClass.State.STATIC)

	# Destroy at row 17
	grid3.set_chunk(Vector2i(10, 17), 0, 0, 0)
	var destroyed3: Array[Vector2i] = [Vector2i(10, 17)]
	var collapse3 := StructureCollapseClass.new()
	collapse3.check_collapse(grid3, destroyed3, null, null, defs)

	# Stone chunks above should remain (non-passable, not affected)
	var stone_intact := true
	for y in range(15, 17):
		var chunk = grid3.get_chunk(Vector2i(10, y))
		if chunk.terrain != 1:
			stone_intact = false
			break
	if stone_intact:
		passed += 1
		print("PASS: non-passable chunks are not affected")
	else:
		failed += 1
		print("FAIL: non-passable chunks were incorrectly collapsed")

	# --- Summary ---
	print("")
	print("%d passed, %d failed" % [passed, failed])
	if failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	quit()
