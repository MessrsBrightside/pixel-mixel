class_name LiquidSim
extends RefCounted

## Runtime liquid simulation — only processes dirty regions near destroyed terrain.

const CHUNK_PX := 4

var _dirty_regions: Array = []  # Array of Rect2i (chunk coords)


func mark_dirty(center: Vector2i, radius: int = 15) -> void:
	var rect := Rect2i(center - Vector2i(radius, radius), Vector2i(radius * 2, radius * 2))
	_dirty_regions.append(rect)


func tick(grid: ChunkGrid) -> bool:
	if _dirty_regions.is_empty():
		return false
	var moved := false
	var size := grid.get_size()
	for region in _dirty_regions:
		var x0 := maxi(region.position.x, 0)
		var y0 := maxi(region.position.y, 0)
		var x1 := mini(region.end.x, size.x)
		var y1 := mini(region.end.y, size.y)
		# Bottom-to-top for falling, left-to-right
		for y in range(y1 - 1, y0 - 1, -1):
			for x in range(x0, x1):
				var pos := Vector2i(x, y)
				var chunk := grid.get_chunk(pos)
				if chunk.terrain == 0 or chunk.state != ChunkGrid.State.LIQUID:
					continue
				if _try_fall(grid, pos, chunk, size):
					moved = true
				elif _try_spread(grid, pos, chunk, size):
					moved = true
	if not moved:
		_dirty_regions.clear()
	return moved


func _try_fall(grid: ChunkGrid, pos: Vector2i, chunk: Dictionary, size: Vector2i) -> bool:
	var below := Vector2i(pos.x, pos.y + 1)
	if below.y >= size.y:
		return false
	var bc := grid.get_chunk(below)
	if bc.terrain == 0:
		grid.set_chunk(below, chunk.terrain, chunk.color, chunk.state)
		grid.set_chunk(pos, 0, 0, 0)
		return true
	return false


func _try_spread(grid: ChunkGrid, pos: Vector2i, chunk: Dictionary, size: Vector2i) -> bool:
	var left := Vector2i(pos.x - 1, pos.y)
	var right := Vector2i(pos.x + 1, pos.y)
	var can_left: bool = left.x >= 0 and grid.get_chunk(left).terrain == 0
	var can_right: bool = right.x < size.x and grid.get_chunk(right).terrain == 0
	# Prefer spreading toward a drop
	var drop_l: bool = can_left and pos.y + 1 < size.y and grid.get_chunk(Vector2i(left.x, pos.y + 1)).terrain == 0
	var drop_r: bool = can_right and pos.y + 1 < size.y and grid.get_chunk(Vector2i(right.x, pos.y + 1)).terrain == 0
	var target: Vector2i
	if drop_l and not drop_r:
		target = left
	elif drop_r and not drop_l:
		target = right
	elif drop_l and drop_r:
		target = left if randi() % 2 == 0 else right
	elif can_left and not can_right:
		target = left
	elif can_right and not can_left:
		target = right
	else:
		return false
	grid.set_chunk(target, chunk.terrain, chunk.color, chunk.state)
	grid.set_chunk(pos, 0, 0, 0)
	return true
