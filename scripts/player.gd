class_name Player
extends Node2D

## Player character with chunk-grid collision, gravity, jump, and animated sprites.

const CHUNK_SIZE := 4
const SPEED := 120.0
const GRAVITY := 600.0
const JUMP_VELOCITY := -250.0
const HITBOX_W := 16.0
const HITBOX_H := 32.0

const BladeAttackClass = preload("res://scripts/blade_attack.gd")

signal attacked

var velocity := Vector2.ZERO
var chunk_grid: ChunkGrid
var terrain_defs: Array[TerrainDef]
var on_ground := false
var _blade = BladeAttackClass.new()

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
	_idle_sprite.scale = Vector2(2.5, 2.5)
	_idle_sprite.offset = Vector2(-16, -23)
	add_child(_idle_sprite)

	_walk_sprite = Sprite2D.new()
	_walk_sprite.texture = load("res://assets/character/walk.png")
	_walk_sprite.hframes = 4
	_walk_sprite.vframes = 3
	_walk_sprite.frame = 4  # side row, first frame (row 1 * hframes + col 0)
	_walk_sprite.centered = false
	_walk_sprite.scale = Vector2(2.5, 2.5)
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if chunk_grid == null:
			return
		var dir := (get_global_mouse_position() - global_position).normalized()
		_blade.execute(chunk_grid, global_position, dir, 3.0, terrain_defs)
		_show_slash(dir)
		attacked.emit()


func _show_slash(dir: Vector2) -> void:
	var slash := Line2D.new()
	slash.width = 2.0
	slash.default_color = Color(1, 1, 1, 0.8)
	# Arc: 5 points in a fan
	var angle := dir.angle()
	var spread := 0.5  # radians
	for i in range(5):
		var a := angle - spread + (spread * 2.0 * i / 4.0)
		slash.add_point(Vector2.from_angle(a) * 40.0)
	get_parent().add_child(slash)
	slash.global_position = global_position
	# Remove after short time
	var timer := get_tree().create_timer(0.15)
	timer.timeout.connect(slash.queue_free)


func _move(delta: float) -> void:
	# Horizontal
	var new_x := position.x + velocity.x * delta
	if not _collides_at(Vector2(new_x, position.y)):
		position.x = new_x
	else:
		# Try step-up: can we move there if we go 1 chunk higher?
		var step_y := position.y - CHUNK_SIZE
		if on_ground and not _collides_at(Vector2(new_x, step_y)):
			position.x = new_x
			position.y = step_y
		else:
			# Try pushing loose chunks in movement direction
			_try_push_loose(new_x)
			velocity.x = 0.0

	# Vertical
	var new_y := position.y + velocity.y * delta
	if not _collides_at(Vector2(position.x, new_y)):
		position.y = new_y
		on_ground = false
	else:
		if velocity.y > 0:
			on_ground = true
			position.y = _snap_to_ground(position.x, new_y)
		else:
			on_ground = false
		velocity.y = 0.0


func _try_push_loose(target_x: float) -> void:
	## Push any loose chunks adjacent to player in movement direction
	if chunk_grid == null:
		return
	var push_dir := 1 if target_x > position.x else -1
	var edge_x: float = position.x + (HITBOX_W / 2.0) * push_dir
	var cx := int(edge_x) / CHUNK_SIZE + push_dir
	var cy_top := int(position.y - HITBOX_H) / CHUNK_SIZE
	var cy_bot := int(position.y - 1) / CHUNK_SIZE

	for cy in range(cy_top, cy_bot + 1):
		var pos := Vector2i(cx, cy)
		if not chunk_grid.is_in_bounds(pos):
			continue
		var chunk = chunk_grid.get_chunk(pos)
		if chunk.terrain != 0 and chunk.state == ChunkGrid.State.LOOSE:
			var dest := Vector2i(cx + push_dir, cy)
			if chunk_grid.is_in_bounds(dest):
				var dest_chunk = chunk_grid.get_chunk(dest)
				if dest_chunk.terrain == 0:
					chunk_grid.set_chunk(dest, chunk.terrain, chunk.color, chunk.state)
					chunk_grid.set_chunk(pos, 0, 0, 0)


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
	if chunk.terrain == 0:
		return false
	if chunk.state == ChunkGrid.State.LIQUID:
		return false
	if chunk.state == ChunkGrid.State.LOOSE:
		return true  # Loose chunks always block player
	if terrain_defs.size() > chunk.terrain and terrain_defs[chunk.terrain] != null:
		return not terrain_defs[chunk.terrain].passable
	return true


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
	var center: int = size.x / 2
	var chunks_needed: int = int(ceil(HITBOX_H / float(CHUNK_SIZE)))

	# Scan outward from center column
	var pos := _find_safe_surface(size, center, chunks_needed, 0, size.y)
	if pos != Vector2.ZERO:
		return pos

	# Fallback: scan from middle of grid vertically (cave scenario)
	var mid_y: int = size.y / 2
	pos = _find_safe_surface(size, center, chunks_needed, mid_y, size.y)
	if pos != Vector2.ZERO:
		return pos

	# Ultimate fallback
	return Vector2(center * CHUNK_SIZE + CHUNK_SIZE / 2.0, size.y * CHUNK_SIZE / 2.0)


func _find_safe_surface(size: Vector2i, center: int, chunks_needed: int, y_start: int, y_end: int) -> Vector2:
	for offset in range(size.x):
		var cols: Array[int] = []
		if offset == 0:
			cols.append(center)
		else:
			if center + offset < size.x:
				cols.append(center + offset)
			if center - offset >= 0:
				cols.append(center - offset)
		for cx in cols:
			for y in range(y_start, y_end):
				var chunk: Variant = chunk_grid.get_chunk(Vector2i(cx, y))
				if chunk == null:
					continue
				# Must be solid and non-liquid
				if chunk.terrain == 0 or chunk.state == ChunkGrid.State.LIQUID:
					continue
				if terrain_defs.size() > chunk.terrain and terrain_defs[chunk.terrain] != null:
					if terrain_defs[chunk.terrain].passable:
						continue
				# Found solid surface — check air above
				if not _has_clear_air(cx, y, chunks_needed):
					continue
				# Check not underwater (no liquid above)
				if _has_liquid_above(cx, y):
					continue
				return Vector2(cx * CHUNK_SIZE + CHUNK_SIZE / 2.0, y * CHUNK_SIZE)
	return Vector2.ZERO


func _has_clear_air(cx: int, surface_y: int, chunks_needed: int) -> bool:
	for i in range(1, chunks_needed + 1):
		var check_y: int = surface_y - i
		if check_y < 0:
			return true  # Above grid = air
		var chunk: Variant = chunk_grid.get_chunk(Vector2i(cx, check_y))
		if chunk == null:
			return true
		if chunk.terrain == 0:
			continue  # Empty = air
		if chunk.state == ChunkGrid.State.LIQUID:
			return false  # Liquid in body space = not safe
		if terrain_defs.size() > chunk.terrain and terrain_defs[chunk.terrain] != null:
			if terrain_defs[chunk.terrain].passable:
				continue  # Passable = ok
		return false  # Solid in body space = not safe
	return true


func _has_liquid_above(cx: int, surface_y: int) -> bool:
	for y in range(surface_y - 1, -1, -1):
		var chunk: Variant = chunk_grid.get_chunk(Vector2i(cx, y))
		if chunk == null:
			return false
		if chunk.terrain == 0:
			continue
		if chunk.state == ChunkGrid.State.LIQUID:
			return true
		# Hit a solid above — no liquid between it and surface
		return false
	return false
