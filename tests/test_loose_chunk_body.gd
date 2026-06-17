extends SceneTree

## Functional tests for LooseChunkBody and ChunkSpawner.

const LooseChunkBodyClass = preload("res://scripts/physics/loose_chunk_body.gd")
const ChunkSpawnerClass = preload("res://scripts/physics/chunk_spawner.gd")
const TerrainDefClass = preload("res://scripts/terrain_def.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- Test: LooseChunkBody creates with collision shape ---
	var body := LooseChunkBodyClass.new()
	body.setup(Color.RED, 4.0, Vector2(100, -50), 2.0)
	var has_collision := false
	for child in body.get_children():
		if child is CollisionShape2D:
			has_collision = true
			break
	if has_collision:
		passed += 1
		print("PASS: LooseChunkBody creates with collision shape")
	else:
		failed += 1
		print("FAIL: LooseChunkBody missing collision shape")
	body.free()

	# --- Test: setup assigns velocity and mass ---
	var body2 := LooseChunkBodyClass.new()
	body2.setup(Color.BLUE, 4.0, Vector2(200, -100), 3.5)
	var vel_ok := body2.linear_velocity == Vector2(200, -100)
	var mass_ok := body2.mass == 3.5
	if vel_ok and mass_ok:
		passed += 1
		print("PASS: setup assigns velocity=%s and mass=%s" % [body2.linear_velocity, body2.mass])
	else:
		failed += 1
		print("FAIL: velocity=%s (expected 200,-100), mass=%s (expected 3.5)" % [body2.linear_velocity, body2.mass])
	body2.free()

	# --- Test: ChunkSpawner respects max_bodies limit ---
	var spawner := ChunkSpawnerClass.new()
	var tdef := TerrainDefClass.new()
	tdef.palette = [Color.GREEN, Color.DARK_GREEN]
	tdef.density = 1.5
	var defs: Array[TerrainDef] = [null, tdef]
	spawner.terrain_defs = defs
	spawner.max_bodies = 5

	var parent_node := Node2D.new()
	root.add_child(parent_node)

	for i in range(10):
		spawner.spawn_chunk(parent_node, Vector2(i * 10, 0), 1, 0, Vector2.RIGHT * 50)

	if spawner.active_bodies.size() <= 5:
		passed += 1
		print("PASS: ChunkSpawner respects max_bodies (active=%d)" % spawner.active_bodies.size())
	else:
		failed += 1
		print("FAIL: ChunkSpawner has %d bodies, expected <= 5" % spawner.active_bodies.size())

	parent_node.queue_free()

	# --- Summary ---
	print("")
	print("%d passed, %d failed" % [passed, failed])
	if failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	quit()
