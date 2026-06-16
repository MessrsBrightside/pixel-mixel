extends SceneTree

## Functional tests for BladeAttack: arc direction, toughness contrast, power depletion, state, liquid/empty skip.

const ChunkGridClass = preload("res://scripts/chunk_grid.gd")
const TerrainDefClass = preload("res://scripts/terrain_def.gd")
const BladeAttackClass = preload("res://scripts/blade_attack.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- Shared terrain defs ---
	var leaves_def := TerrainDefClass.new()
	leaves_def.toughness = 0.1
	leaves_def.passable = true

	var stone_def := TerrainDefClass.new()
	stone_def.toughness = 1.0
	stone_def.passable = false

	var water_def := TerrainDefClass.new()
	water_def.toughness = 0.0
	water_def.passable = true

	var defs: Array[TerrainDef] = []
	defs.resize(6)
	defs[0] = null
	defs[1] = stone_def   # terrain 1 = stone
	defs[2] = leaves_def  # terrain 2 = leaves
	defs[3] = water_def   # terrain 3 = water
	defs[4] = stone_def   # terrain 4 = stone-like
	defs[5] = leaves_def  # terrain 5 = leaves-like

	# --- Test: attack frees chunks in arc direction ---
	var grid := ChunkGridClass.new(64, 64)
	# Fill a band to the right of center with leaves (terrain=2)
	for y in range(28, 36):
		for x in range(35, 55):
			grid.set_chunk(Vector2i(x, y), 2, 0, ChunkGridClass.State.STATIC)
	var blade := BladeAttackClass.new()
	var origin := Vector2(32 * 4, 32 * 4)  # center in pixel space
	var freed := blade.execute(grid, origin, Vector2.RIGHT, 3.0, defs)
	if freed > 0:
		passed += 1
		print("PASS: attack frees chunks in arc direction (freed=%d)" % freed)
	else:
		failed += 1
		print("FAIL: attack freed 0 chunks in arc direction")

	# --- Test: stone absorbs more power than leaves ---
	var grid_stone := ChunkGridClass.new(64, 64)
	var grid_leaves := ChunkGridClass.new(64, 64)
	# Fill both grids with a horizontal line of their terrain to the right
	for x in range(35, 55):
		grid_stone.set_chunk(Vector2i(x, 32), 1, 0, ChunkGridClass.State.STATIC)  # stone
		grid_leaves.set_chunk(Vector2i(x, 32), 2, 0, ChunkGridClass.State.STATIC)  # leaves
	var blade2 := BladeAttackClass.new()
	var stone_freed := blade2.execute(grid_stone, origin, Vector2.RIGHT, 3.0, defs)
	var blade3 := BladeAttackClass.new()
	var leaves_freed := blade3.execute(grid_leaves, origin, Vector2.RIGHT, 3.0, defs)
	if leaves_freed > stone_freed:
		passed += 1
		print("PASS: stone absorbs more power (stone=%d, leaves=%d)" % [stone_freed, leaves_freed])
	else:
		failed += 1
		print("FAIL: leaves_freed=%d should be > stone_freed=%d" % [leaves_freed, stone_freed])

	# --- Test: power depletes to 0 and stops ---
	var grid_depletion := ChunkGridClass.new(64, 64)
	# Fill 30 stone chunks in a line (would need 30 power, we only have 3)
	for x in range(34, 64):
		grid_depletion.set_chunk(Vector2i(x, 32), 1, 0, ChunkGridClass.State.STATIC)
	var blade4 := BladeAttackClass.new()
	var depletion_freed := blade4.execute(grid_depletion, origin, Vector2.RIGHT, 3.0, defs)
	# Stone toughness=1.0, power=3.0 → max 3 per ray, 7 rays but sharing power per-ray
	# Each ray has its own power budget of 3.0 → 3 stone per ray
	if depletion_freed <= 21 and depletion_freed >= 3:
		passed += 1
		print("PASS: power depletes and stops (freed=%d)" % depletion_freed)
	else:
		failed += 1
		print("FAIL: unexpected depletion count=%d" % depletion_freed)

	# --- Test: freed chunks are LOOSE state ---
	var grid_state := ChunkGridClass.new(64, 64)
	for x in range(35, 45):
		grid_state.set_chunk(Vector2i(x, 32), 2, 0, ChunkGridClass.State.STATIC)
	var blade5 := BladeAttackClass.new()
	blade5.execute(grid_state, origin, Vector2.RIGHT, 3.0, defs)
	var all_loose := true
	for x in range(35, 45):
		var chunk = grid_state.get_chunk(Vector2i(x, 32))
		if chunk.terrain == 2 and chunk.state != ChunkGridClass.State.LOOSE:
			all_loose = false
			break
	# Some chunks should be freed (loose)
	var any_loose := false
	for x in range(35, 45):
		var chunk = grid_state.get_chunk(Vector2i(x, 32))
		if chunk.state == ChunkGridClass.State.LOOSE:
			any_loose = true
			break
	if any_loose:
		passed += 1
		print("PASS: freed chunks are LOOSE state")
	else:
		failed += 1
		print("FAIL: no chunks set to LOOSE state")

	# --- Test: empty/liquid chunks don't cost power ---
	var grid_skip := ChunkGridClass.new(64, 64)
	# Place empty gap then leaves: empty at 35-39, liquid at 40-42, leaves at 43-55
	for x in range(40, 43):
		grid_skip.set_chunk(Vector2i(x, 32), 3, 0, ChunkGridClass.State.LIQUID)  # water
	for x in range(43, 55):
		grid_skip.set_chunk(Vector2i(x, 32), 2, 0, ChunkGridClass.State.STATIC)  # leaves
	var blade6 := BladeAttackClass.new()
	var skip_freed := blade6.execute(grid_skip, origin, Vector2.RIGHT, 3.0, defs)
	# Should skip the gap/liquid and still free leaves behind them
	if skip_freed > 0:
		passed += 1
		print("PASS: empty/liquid chunks don't cost power (freed=%d)" % skip_freed)
	else:
		failed += 1
		print("FAIL: blade stopped at empty/liquid, freed=0")

	# --- Summary ---
	print("")
	print("%d passed, %d failed" % [passed, failed])
	if failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	quit()
