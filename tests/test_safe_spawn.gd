extends SceneTree

## Functional tests for safe spawn point logic.

const PlayerClass = preload("res://scripts/player.gd")
const ChunkGridClass = preload("res://scripts/chunk_grid.gd")
const TerrainDef = preload("res://scripts/terrain_def.gd")


func _init() -> void:
	var passed := 0
	var failed := 0
	var solid_def := TerrainDef.new()
	solid_def.passable = false
	var defs: Array[TerrainDef] = []
	defs.resize(4)
	defs[0] = null
	defs[1] = solid_def
	defs[2] = solid_def
	defs[3] = solid_def

	# --- Test: ocean shore spawn is on sand/dirt, NOT in water ---
	# Grid: left half water on top of sand, right half dry sand surface
	var grid := ChunkGridClass.new(64, 40)
	# Solid sand floor at row 25
	for x in range(64):
		for y in range(25, 40):
			grid.set_chunk(Vector2i(x, y), 1, 0, ChunkGridClass.State.STATIC)
	# Left half (x 0-31): water above the sand (rows 20-24)
	for x in range(32):
		for y in range(20, 25):
			grid.set_chunk(Vector2i(x, y), 2, 0, ChunkGridClass.State.LIQUID)

	var player := PlayerClass.new()
	player.chunk_grid = grid
	player.terrain_defs = defs
	var spawn := player.find_spawn_position()
	var spawn_cx: int = int(spawn.x) / 4
	# Should NOT spawn in the water columns (0-31)
	if spawn_cx >= 32:
		passed += 1
		print("PASS: ocean shore spawn is NOT in water (cx=%d)" % spawn_cx)
	else:
		failed += 1
		print("FAIL: ocean shore spawn is in water column, cx=%d" % spawn_cx)

	# --- Test: cave spawn is in open space ---
	# Grid: solid everywhere with liquid on top (no valid top-scan), cave opening in middle
	var cave_grid := ChunkGridClass.new(64, 40)
	# Fill solid
	for y in range(40):
		for x in range(64):
			cave_grid.set_chunk(Vector2i(x, y), 1, 0, ChunkGridClass.State.STATIC)
	# Put liquid on top rows (0-7) so _has_liquid_above fails for any surface found from top
	for y in range(0, 8):
		for x in range(64):
			cave_grid.set_chunk(Vector2i(x, y), 2, 0, ChunkGridClass.State.LIQUID)
	# Carve cave: rows 16-24 at columns 30-34 (floor at row 25)
	for y in range(16, 25):
		for x in range(30, 35):
			cave_grid.set_chunk(Vector2i(x, y), 0, 0, ChunkGridClass.State.STATIC)

	var cave_player := PlayerClass.new()
	cave_player.chunk_grid = cave_grid
	cave_player.terrain_defs = defs
	var cave_spawn := cave_player.find_spawn_position()
	var cave_cx: int = int(cave_spawn.x) / 4
	var cave_cy: int = int(cave_spawn.y) / 4
	# Should spawn at the cave floor (row 25) in columns 30-34
	if cave_cx >= 30 and cave_cx <= 34 and cave_cy == 25:
		passed += 1
		print("PASS: cave spawn is in open space (cx=%d, cy=%d)" % [cave_cx, cave_cy])
	else:
		failed += 1
		print("FAIL: cave spawn not in open space, cx=%d cy=%d" % [cave_cx, cave_cy])

	# --- Test: spawn has solid ground below ---
	# Reuse the simple grid from ocean test
	var ground_player := PlayerClass.new()
	ground_player.chunk_grid = grid
	ground_player.terrain_defs = defs
	var ground_spawn := ground_player.find_spawn_position()
	var ground_chunk_y: int = int(ground_spawn.y) / 4
	var below: Variant = grid.get_chunk(Vector2i(int(ground_spawn.x) / 4, ground_chunk_y))
	if below != null and below.terrain != 0 and below.state != ChunkGridClass.State.LIQUID:
		passed += 1
		print("PASS: spawn has solid ground below")
	else:
		failed += 1
		print("FAIL: spawn ground is not solid, chunk=%s" % str(below))

	# --- Test: spawn has enough air above for player height ---
	# HITBOX_H=32, CHUNK_SIZE=4 → needs 8 clear chunks above
	var air_spawn := ground_player.find_spawn_position()
	var air_cx: int = int(air_spawn.x) / 4
	var air_cy: int = int(air_spawn.y) / 4
	var air_clear := true
	for i in range(1, 9):  # 8 chunks above
		var check: Variant = grid.get_chunk(Vector2i(air_cx, air_cy - i))
		if check != null and check.terrain != 0 and check.state != ChunkGridClass.State.LIQUID:
			if defs.size() > check.terrain and defs[check.terrain] != null:
				if not defs[check.terrain].passable:
					air_clear = false
					break
			else:
				air_clear = false
				break
	if air_clear:
		passed += 1
		print("PASS: spawn has enough air above for player height")
	else:
		failed += 1
		print("FAIL: spawn does not have enough air above")

	# --- Test: if center is unsafe, spawns at offset position ---
	# Grid with center column having liquid above surface (underwater = unsafe)
	var blocked_grid := ChunkGridClass.new(64, 40)
	for y in range(30, 40):
		for x in range(64):
			blocked_grid.set_chunk(Vector2i(x, y), 1, 0, ChunkGridClass.State.STATIC)
	# Put liquid above center column only (makes center underwater)
	for y in range(25, 30):
		blocked_grid.set_chunk(Vector2i(32, y), 2, 0, ChunkGridClass.State.LIQUID)

	var blocked_player := PlayerClass.new()
	blocked_player.chunk_grid = blocked_grid
	blocked_player.terrain_defs = defs
	var blocked_spawn := blocked_player.find_spawn_position()
	var blocked_cx: int = int(blocked_spawn.x) / 4
	if blocked_cx != 32:
		passed += 1
		print("PASS: center unsafe, spawned at offset cx=%d" % blocked_cx)
	else:
		failed += 1
		print("FAIL: spawned at blocked center column cx=%d" % blocked_cx)

	# --- Summary ---
	print("")
	print("%d passed, %d failed" % [passed, failed])
	if failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	quit()
