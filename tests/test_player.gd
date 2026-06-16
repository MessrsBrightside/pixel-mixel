extends SceneTree

## Functional tests for Player: gravity, ground collision, horizontal movement, jump, wall collision.

const PlayerClass = preload("res://scripts/player.gd")
const ChunkGridClass = preload("res://scripts/chunk_grid.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- Setup a small grid with a flat floor at row 20 ---
	var grid := ChunkGridClass.new(64, 40)
	# Fill row 20-39 as solid ground (terrain=1, color=0, state=STATIC)
	for y in range(20, 40):
		for x in range(64):
			grid.set_chunk(Vector2i(x, y), 1, 0, ChunkGridClass.State.STATIC)
	# Add a wall column at x=50 from row 15-19
	for y in range(15, 20):
		grid.set_chunk(Vector2i(50, y), 1, 0, ChunkGridClass.State.STATIC)

	# --- Test: find_spawn_position lands on surface ---
	var player := PlayerClass.new()
	player.chunk_grid = grid
	var spawn := player.find_spawn_position()
	# Center column is 32, surface at row 20 → y = 80px
	if spawn.y == 80.0:
		passed += 1
		print("PASS: find_spawn_position returns surface y=80")
	else:
		failed += 1
		print("FAIL: find_spawn_position y=%f, expected 80" % spawn.y)

	# --- Test: player falls with gravity (no ground above) ---
	player.position = Vector2(100, 40)  # Above ground (ground at y=80)
	player.velocity = Vector2.ZERO
	player.on_ground = false
	# Simulate 10 frames at 1/60
	for i in range(10):
		player._move(1.0 / 60.0)
		player.velocity.y += 600.0 / 60.0
	if player.position.y > 40.0:
		passed += 1
		print("PASS: player falls with gravity")
	else:
		failed += 1
		print("FAIL: player did not fall, y=%f" % player.position.y)

	# --- Test: player lands on ground ---
	player.position = Vector2(100, 70)  # Just above ground at y=80
	player.velocity = Vector2(0, 200)
	player.on_ground = false
	for i in range(30):
		player._move(1.0 / 60.0)
		if player.on_ground:
			break
		player.velocity.y += 600.0 / 60.0
	if player.on_ground:
		passed += 1
		print("PASS: player lands on ground")
	else:
		failed += 1
		print("FAIL: player did not land, y=%f on_ground=%s" % [player.position.y, str(player.on_ground)])

	# --- Test: horizontal movement ---
	player.position = Vector2(100, 80)  # On ground
	player.velocity = Vector2(120, 0)
	player.on_ground = true
	var start_x := player.position.x
	player._move(1.0 / 60.0)
	if player.position.x > start_x:
		passed += 1
		print("PASS: horizontal movement works")
	else:
		failed += 1
		print("FAIL: player did not move right, x=%f" % player.position.x)

	# --- Test: wall collision stops horizontal movement ---
	# Wall at chunk x=50 → pixel x=200. Place player just left of it.
	player.position = Vector2(199, 80)  # Just before wall
	player.velocity = Vector2(120, 0)
	player.on_ground = true
	var pre_x := player.position.x
	for i in range(10):
		player._move(1.0 / 60.0)
	# Player should not pass through the wall (pixel 200 = chunk 50)
	if player.position.x < 201.0:
		passed += 1
		print("PASS: wall collision stops player")
	else:
		failed += 1
		print("FAIL: player passed through wall, x=%f" % player.position.x)

	# --- Test: jump moves player upward ---
	player.position = Vector2(100, 80)
	player.velocity = Vector2(0, -250)  # Jump impulse
	player.on_ground = false
	var start_y := player.position.y
	player._move(1.0 / 60.0)
	if player.position.y < start_y:
		passed += 1
		print("PASS: jump moves player upward")
	else:
		failed += 1
		print("FAIL: jump did not move up, y=%f" % player.position.y)

	# --- Test: liquid chunks are passable ---
	# Place a liquid chunk at row 19 (just above ground)
	grid.set_chunk(Vector2i(30, 19), 3, 0, ChunkGridClass.State.LIQUID)
	player.position = Vector2(122, 76)  # chunk 30 area, at row 19 level
	player.velocity = Vector2(0, 100)
	player.on_ground = false
	player._move(1.0 / 60.0)
	# Player should move through the liquid
	if player.position.y > 76.0:
		passed += 1
		print("PASS: player passes through liquid")
	else:
		failed += 1
		print("FAIL: player blocked by liquid, y=%f" % player.position.y)

	# --- Summary ---
	print("")
	print("%d passed, %d failed" % [passed, failed])
	if failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	quit()
