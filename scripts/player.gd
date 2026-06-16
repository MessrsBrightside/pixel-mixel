class_name Player
extends Node2D

## Player character with chunk-grid collision, gravity, jump, and animated sprites.

const CHUNK_SIZE := 4
const SPEED := 120.0
const GRAVITY := 600.0
const JUMP_VELOCITY := -250.0
const HITBOX_W := 20.0
const HITBOX_H := 34.0

var velocity := Vector2.ZERO
var chunk_grid: ChunkGrid
var on_ground := false

var _idle_sprite: Sprite2D
var _walk_sprite: Sprite2D
var _facing_right := true


func _ready() -> void:
	_idle_sprite = Sprite2D.new()
	_idle_sprite.texture = load("res://assets/character/idle.png")
	_idle_sprite.hframes = 2
	_idle_sprite.vframes = 3
	_idle_sprite.frame = 2  # side row, first frame (row 1 * hframes + col 0)
	_idle_sprite.centered = false
	_idle_sprite.scale = Vector2(1.5, 1.5)
	_idle_sprite.offset = Vector2(-16, -23)
	add_child(_idle_sprite)

	_walk_sprite = Sprite2D.new()
	_walk_sprite.texture = load("res://assets/character/walk.png")
	_walk_sprite.hframes = 4
	_walk_sprite.vframes = 3
	_walk_sprite.frame = 4  # side row, first frame (row 1 * hframes + col 0)
	_walk_sprite.centered = false
	_walk_sprite.scale = Vector2(1.5, 1.5)
	_walk_sprite.offset = Vector2(-16, -23)
	_walk_sprite.visible = false
	add_child(_walk_sprite)


func _process(delta: float) -> void:
	if chunk_grid == null:
		return
	var input_dir := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir += 1.0

	velocity.x = input_dir * SPEED
	velocity.y += GRAVITY * delta

	if on_ground and (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE)):
		velocity.y = JUMP_VELOCITY

	_move(delta)
	_update_animation(input_dir)


func _move(delta: float) -> void:
	# Horizontal
	var new_x := position.x + velocity.x * delta
	if not _collides_at(Vector2(new_x, position.y)):
		position.x = new_x
	else:
		velocity.x = 0.0

	# Vertical
	var new_y := position.y + velocity.y * delta
	if not _collides_at(Vector2(position.x, new_y)):
		position.y = new_y
		on_ground = false
	else:
		if velocity.y > 0:
			on_ground = true
			# Snap to top of solid chunk
			position.y = _snap_to_ground(position.x, new_y)
		else:
			on_ground = false
		velocity.y = 0.0


func _collides_at(pos: Vector2) -> bool:
	# AABB corners in pixel space (hitbox centered horizontally, bottom at pos)
	var left := pos.x - HITBOX_W / 2.0
	var right := pos.x + HITBOX_W / 2.0
	var top := pos.y - HITBOX_H
	var bottom := pos.y

	# Convert to chunk coords and check all chunks the AABB overlaps
	var cx_min := int(left) / CHUNK_SIZE
	var cx_max := int(right - 0.01) / CHUNK_SIZE
	var cy_min := int(top) / CHUNK_SIZE
	var cy_max := int(bottom - 0.01) / CHUNK_SIZE

	for cy in range(cy_min, cy_max + 1):
		for cx in range(cx_min, cx_max + 1):
			if _is_solid(Vector2i(cx, cy)):
				return true
	return false


func _is_solid(chunk_pos: Vector2i) -> bool:
	var chunk: Variant = chunk_grid.get_chunk(chunk_pos)
	if chunk == null:
		return true  # OOB = solid (walls)
	return chunk.terrain != 0 and chunk.state != ChunkGrid.State.LIQUID


func _snap_to_ground(px: float, attempted_y: float) -> float:
	# Find the topmost solid chunk row under the player's feet
	var cy_start := int(position.y - 0.01) / CHUNK_SIZE
	var cy_end := int(attempted_y) / CHUNK_SIZE
	var left := px - HITBOX_W / 2.0
	var right := px + HITBOX_W / 2.0
	var cx_min := int(left) / CHUNK_SIZE
	var cx_max := int(right - 0.01) / CHUNK_SIZE
	for cy in range(cy_start, cy_end + 1):
		for cx in range(cx_min, cx_max + 1):
			if _is_solid(Vector2i(cx, cy)):
				return float(cy * CHUNK_SIZE)
	return attempted_y


func _update_animation(input_dir: float) -> void:
	var side_row := 1  # middle row = side-facing
	if input_dir != 0.0:
		_facing_right = input_dir > 0.0
		_idle_sprite.visible = false
		_walk_sprite.visible = true
		var walk_frame := (int(Engine.get_process_frames() / 8)) % 4
		_walk_sprite.frame = side_row * 4 + walk_frame
		_walk_sprite.flip_h = not _facing_right
	else:
		_idle_sprite.visible = true
		_walk_sprite.visible = false
		var idle_frame := (int(Engine.get_process_frames() / 30)) % 2
		_idle_sprite.frame = side_row * 2 + idle_frame
		_idle_sprite.flip_h = not _facing_right


func find_spawn_position() -> Vector2:
	if chunk_grid == null:
		return Vector2.ZERO
	var size := chunk_grid.get_size()
	var cx: int = size.x / 2
	for y in range(size.y):
		if _is_solid(Vector2i(cx, y)):
			return Vector2(cx * CHUNK_SIZE + CHUNK_SIZE / 2.0, y * CHUNK_SIZE)
	return Vector2(cx * CHUNK_SIZE, size.y * CHUNK_SIZE / 2.0)
