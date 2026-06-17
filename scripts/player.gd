class_name Player
extends CharacterBody2D

## Player character using CharacterBody2D physics with animated sprites.

const CHUNK_SIZE := 4
const SPEED := 120.0
const GRAVITY := 600.0
const JUMP_VELOCITY := -250.0

signal attacked

var chunk_grid: ChunkGrid
var terrain_defs: Array[TerrainDef]
var _blade: BladeAttack = BladeAttack.new()
var chunk_spawner: ChunkSpawner

var _idle_sprite: Sprite2D
var _walk_sprite: Sprite2D
var _facing_right := true


func _ready() -> void:
	var col_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 20)
	col_shape.shape = rect
	col_shape.position = Vector2(0, -10)  # shift up so bottom of hitbox = node position
	add_child(col_shape)

	_idle_sprite = Sprite2D.new()
	_idle_sprite.texture = load("res://assets/character/idle.png")
	_idle_sprite.hframes = 2
	_idle_sprite.vframes = 3
	_idle_sprite.frame = 2
	_idle_sprite.centered = false
	_idle_sprite.scale = Vector2(2.5, 2.5)
	_idle_sprite.offset = Vector2(-16, -23)
	add_child(_idle_sprite)

	_walk_sprite = Sprite2D.new()
	_walk_sprite.texture = load("res://assets/character/walk.png")
	_walk_sprite.hframes = 4
	_walk_sprite.vframes = 3
	_walk_sprite.frame = 4
	_walk_sprite.centered = false
	_walk_sprite.scale = Vector2(2.5, 2.5)
	_walk_sprite.offset = Vector2(-16, -23)
	_walk_sprite.visible = false
	add_child(_walk_sprite)


func _physics_process(delta: float) -> void:
	if chunk_grid == null:
		return
	var input_dir := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir += 1.0

	velocity.x = input_dir * SPEED
	velocity.y += GRAVITY * delta

	var jump_pressed := Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE)
	if is_on_floor() and jump_pressed:
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	_update_animation(input_dir)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if chunk_grid == null:
			return
		var dir := (get_global_mouse_position() - global_position).normalized()
		var origin := global_position
		_blade.chunk_spawner = chunk_spawner
		_blade.spawn_parent = get_parent()
		_blade.execute(chunk_grid, origin, dir, 3.0, terrain_defs)
		_show_slash(dir)
		attacked.emit()


func _show_slash(dir: Vector2) -> void:
	var slash := Line2D.new()
	slash.width = 2.0
	slash.default_color = Color(1, 1, 1, 0.9)
	slash.z_index = 10
	var angle := dir.angle()
	var spread := 0.2
	for i in range(5):
		var a := angle - spread + (spread * 2.0 * i / 4.0)
		slash.add_point(Vector2.from_angle(a) * 50.0)
	get_parent().add_child(slash)
	slash.global_position = global_position + Vector2(0, -10)
	var timer := get_tree().create_timer(0.12)
	timer.timeout.connect(slash.queue_free)


func _update_animation(input_dir: float) -> void:
	var side_row := 1
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
	var chunks_needed: int = int(ceil(20.0 / float(CHUNK_SIZE)))

	var pos := _find_safe_surface(size, center, chunks_needed, 0, size.y)
	if pos != Vector2.ZERO:
		return pos

	var mid_y: int = size.y / 2
	pos = _find_safe_surface(size, center, chunks_needed, mid_y, size.y)
	if pos != Vector2.ZERO:
		return pos

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
				if chunk.terrain == 0 or chunk.state == ChunkGrid.State.LIQUID:
					continue
				if terrain_defs.size() > chunk.terrain and terrain_defs[chunk.terrain] != null:
					if terrain_defs[chunk.terrain].passable:
						continue
				if not _has_clear_air(cx, y, chunks_needed):
					continue
				if _has_liquid_above(cx, y):
					continue
				return Vector2(cx * CHUNK_SIZE + CHUNK_SIZE / 2.0, y * CHUNK_SIZE)
	return Vector2.ZERO


func _has_clear_air(cx: int, surface_y: int, chunks_needed: int) -> bool:
	for i in range(1, chunks_needed + 1):
		var check_y: int = surface_y - i
		if check_y < 0:
			return true
		var chunk: Variant = chunk_grid.get_chunk(Vector2i(cx, check_y))
		if chunk == null:
			return true
		if chunk.terrain == 0:
			continue
		if chunk.state == ChunkGrid.State.LIQUID:
			return false
		if terrain_defs.size() > chunk.terrain and terrain_defs[chunk.terrain] != null:
			if terrain_defs[chunk.terrain].passable:
				continue
		return false
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
		return false
	return false
