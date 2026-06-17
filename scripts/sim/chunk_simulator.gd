class_name ChunkSimulator
extends RefCounted

## Simulates loose and liquid chunks until the grid reaches equilibrium.

const ChunkGridClass = preload("res://scripts/chunk_grid.gd")

var _rng: RandomNumberGenerator


func _init(seed_value: int = 0) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value


func simulate_until_settled(grid: ChunkGrid, max_ticks: int = 10000) -> int:
	var ticks := 0
	while ticks < max_ticks:
		if not tick(grid):
			break
		ticks += 1
	return ticks


var dirty_min: Vector2i = Vector2i.ZERO
var dirty_max: Vector2i = Vector2i.ZERO
var _has_dirty: bool = false
var grid_size: Vector2i = Vector2i(500, 144)


func reset_dirty() -> void:
	_has_dirty = false
	dirty_min = grid_size
	dirty_max = Vector2i.ZERO


func tick(grid: ChunkGrid) -> bool:
	var moved := false
	var size := grid.get_size()
	# Bottom-to-top (highest y first), left-to-right
	for y in range(size.y - 1, -1, -1):
		for x in range(size.x):
			var pos := Vector2i(x, y)
			var chunk = grid.get_chunk(pos)
			if chunk == null or chunk.state == ChunkGridClass.State.STATIC:
				continue
			if chunk.state == ChunkGridClass.State.LOOSE:
				if _try_fall(grid, pos, chunk):
					moved = true
			elif chunk.state == ChunkGridClass.State.LIQUID:
				if _try_fall(grid, pos, chunk):
					moved = true
				elif _try_spread(grid, pos, chunk):
					moved = true
	return moved


func get_dirty_rect() -> Rect2i:
	if not _has_dirty:
		return Rect2i()
	return Rect2i(dirty_min, dirty_max - dirty_min + Vector2i.ONE)


func _mark_dirty(pos: Vector2i) -> void:
	_has_dirty = true
	dirty_min.x = mini(dirty_min.x, pos.x)
	dirty_min.y = mini(dirty_min.y, pos.y)
	dirty_max.x = maxi(dirty_max.x, pos.x)
	dirty_max.y = maxi(dirty_max.y, pos.y)


func _try_fall(grid: ChunkGrid, pos: Vector2i, chunk: Dictionary) -> bool:
	var below := Vector2i(pos.x, pos.y + 1)
	if not grid.is_in_bounds(below):
		return false
	var below_chunk = grid.get_chunk(below)
	if below_chunk == null or below_chunk.terrain == 0:
		grid.set_chunk(below, chunk.terrain, chunk.color, chunk.state)
		grid.set_chunk(pos, 0, 0, 0)
		_mark_dirty(pos)
		_mark_dirty(below)
		return true
	if chunk.state == ChunkGridClass.State.LOOSE and below_chunk.state == ChunkGridClass.State.LIQUID:
		grid.set_chunk(below, chunk.terrain, chunk.color, chunk.state)
		grid.set_chunk(pos, below_chunk.terrain, below_chunk.color, below_chunk.state)
		_mark_dirty(pos)
		_mark_dirty(below)
		return true
	return false


func _try_spread(grid: ChunkGrid, pos: Vector2i, chunk: Dictionary) -> bool:
	# Only spread if there's empty space AND empty below that space (seeks lowest point)
	var left := Vector2i(pos.x - 1, pos.y)
	var right := Vector2i(pos.x + 1, pos.y)
	var can_left := _is_empty(grid, left) and _has_floor(grid, left)
	var can_right := _is_empty(grid, right) and _has_floor(grid, right)
	# Prefer spreading toward a drop (empty below the target)
	var drop_left := can_left and _is_empty(grid, Vector2i(pos.x - 1, pos.y + 1))
	var drop_right := can_right and _is_empty(grid, Vector2i(pos.x + 1, pos.y + 1))
	var target: Vector2i
	if drop_left and drop_right:
		target = left if _rng.randi() % 2 == 0 else right
	elif drop_left:
		target = left
	elif drop_right:
		target = right
	elif can_left and can_right:
		# No drop either side — don't spread (prevents oscillation)
		return false
	elif can_left:
		# Only spread if there's a reason (uneven surface)
		if not _liquid_higher_than_neighbors(grid, pos):
			return false
		target = left
	elif can_right:
		if not _liquid_higher_than_neighbors(grid, pos):
			return false
		target = right
	else:
		return false
	grid.set_chunk(target, chunk.terrain, chunk.color, chunk.state)
	grid.set_chunk(pos, 0, 0, 0)
	_mark_dirty(pos)
	_mark_dirty(target)
	return true


func _has_floor(grid: ChunkGrid, pos: Vector2i) -> bool:
	var below := Vector2i(pos.x, pos.y + 1)
	if not grid.is_in_bounds(below):
		return true  # bottom of world = floor
	return not _is_empty(grid, below)


func _liquid_higher_than_neighbors(grid: ChunkGrid, pos: Vector2i) -> bool:
	# Check if this liquid column is taller than adjacent — spread to equalize
	var my_height := _liquid_column_height(grid, pos)
	var left_h := _liquid_column_height(grid, Vector2i(pos.x - 1, pos.y))
	var right_h := _liquid_column_height(grid, Vector2i(pos.x + 1, pos.y))
	return my_height > left_h + 1 or my_height > right_h + 1


func _liquid_column_height(grid: ChunkGrid, pos: Vector2i) -> int:
	var count := 0
	var y := pos.y
	while y >= 0:
		if not grid.is_in_bounds(Vector2i(pos.x, y)):
			break
		var c = grid.get_chunk(Vector2i(pos.x, y))
		if c == null or c.state != ChunkGridClass.State.LIQUID:
			break
		count += 1
		y -= 1
	return count


func _is_empty(grid: ChunkGrid, pos: Vector2i) -> bool:
	if not grid.is_in_bounds(pos):
		return false
	var chunk = grid.get_chunk(pos)
	return chunk != null and chunk.terrain == 0
