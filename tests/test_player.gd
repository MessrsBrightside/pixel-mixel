extends SceneTree

## Tests for Player: class structure, CollisionShape2D child, find_spawn_position, attack.

const PlayerClass = preload("res://scripts/player.gd")
const ChunkGridClass = preload("res://scripts/chunk_grid.gd")
const TerrainDef = preload("res://scripts/terrain_def.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- Test: Player extends CharacterBody2D ---
	var player := PlayerClass.new()
	if player is CharacterBody2D:
		passed += 1
		print("PASS: Player extends CharacterBody2D")
	else:
		failed += 1
		print("FAIL: Player does not extend CharacterBody2D")

	# --- Test: Player has CollisionShape2D child after _ready ---
	root.add_child(player)
	await process_frame
	var col_shape: CollisionShape2D = null
	for child in player.get_children():
		if child is CollisionShape2D:
			col_shape = child
			break
	if col_shape != null:
		passed += 1
		print("PASS: Player has CollisionShape2D child")
	else:
		failed += 1
		print("FAIL: Player missing CollisionShape2D child")

	# --- Test: CollisionShape2D has RectangleShape2D(10, 20) ---
	if col_shape and col_shape.shape is RectangleShape2D:
		var rect: RectangleShape2D = col_shape.shape
		if rect.size == Vector2(10, 20):
			passed += 1
			print("PASS: CollisionShape2D has RectangleShape2D(10, 20)")
		else:
			failed += 1
			print("FAIL: RectangleShape2D size=%s, expected (10, 20)" % str(rect.size))
	else:
		failed += 1
		print("FAIL: CollisionShape2D shape is not RectangleShape2D")

	# --- Test: find_spawn_position works ---
	var grid := ChunkGridClass.new(64, 40)
	for y in range(20, 40):
		for x in range(64):
			grid.set_chunk(Vector2i(x, y), 1, 0, ChunkGridClass.State.STATIC)
	player.chunk_grid = grid
	player.terrain_defs = _make_defs()
	var spawn := player.find_spawn_position()
	if spawn.y == 80.0:
		passed += 1
		print("PASS: find_spawn_position returns surface y=80")
	else:
		failed += 1
		print("FAIL: find_spawn_position y=%f, expected 80" % spawn.y)

	# --- Test: blade execute works ---
	var grid2 := ChunkGridClass.new(32, 32)
	grid2.set_chunk(Vector2i(16, 16), 1, 0, ChunkGridClass.State.STATIC)
	player.chunk_grid = grid2
	player.terrain_defs = _make_defs()
	player.global_position = Vector2(60, 64)
	var freed := player._blade.execute(grid2, Vector2(60, 64), Vector2(1, 0), 3.0, _make_defs())
	if freed > 0:
		passed += 1
		print("PASS: blade execute frees chunks when called")
	else:
		failed += 1
		print("FAIL: blade execute did not free any chunks")

	# --- Test: Constants are correct ---
	if player.SPEED == 120.0 and player.GRAVITY == 600.0 and player.JUMP_VELOCITY == -250.0:
		passed += 1
		print("PASS: Constants SPEED=120, GRAVITY=600, JUMP_VELOCITY=-250")
	else:
		failed += 1
		print("FAIL: Constants incorrect")

	# --- Summary ---
	print("")
	print("%d passed, %d failed" % [passed, failed])
	if failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	player.queue_free()
	quit()


func _make_defs() -> Array[TerrainDef]:
	var solid_def := TerrainDef.new()
	solid_def.passable = false
	solid_def.toughness = 1.0
	var defs: Array[TerrainDef] = []
	defs.resize(5)
	defs[0] = null
	defs[1] = solid_def
	defs[2] = solid_def
	defs[3] = null
	defs[4] = solid_def
	return defs
