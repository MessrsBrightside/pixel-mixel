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


func _try_fall(grid: ChunkGrid, pos: Vector2i, chunk: Dictionary) -> bool:
	var below := Vector2i(pos.x, pos.y + 1)
	if not grid.is_in_bounds(below):
		return false
	var below_chunk = grid.get_chunk(below)
	if below_chunk == null or below_chunk.terrain != 0:
		return false
	grid.set_chunk(below, chunk.terrain, chunk.color, chunk.state)
	grid.set_chunk(pos, 0, 0, 0)
	return true


func _try_spread(grid: ChunkGrid, pos: Vector2i, chunk: Dictionary) -> bool:
	var left := Vector2i(pos.x - 1, pos.y)
	var right := Vector2i(pos.x + 1, pos.y)
	var can_left := _is_empty(grid, left)
	var can_right := _is_empty(grid, right)
	if not can_left and not can_right:
		return false
	var target: Vector2i
	if can_left and can_right:
		target = left if _rng.randi() % 2 == 0 else right
	elif can_left:
		target = left
	else:
		target = right
	grid.set_chunk(target, chunk.terrain, chunk.color, chunk.state)
	grid.set_chunk(pos, 0, 0, 0)
	return true


func _is_empty(grid: ChunkGrid, pos: Vector2i) -> bool:
	if not grid.is_in_bounds(pos):
		return false
	var chunk = grid.get_chunk(pos)
	return chunk != null and chunk.terrain == 0
