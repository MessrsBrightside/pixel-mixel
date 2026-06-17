class_name LiquidSim
extends RefCounted

## Runtime grid simulation — handles LIQUID flow and LOOSE chunk gravity in dirty regions.

const CHUNK_PX := 4

var _dirty_regions: Array = []


func mark_dirty(center: Vector2i, radius: int = 20) -> void:
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
		# Bottom-to-top for falling
		for y in range(y1 - 1, y0 - 1, -1):
			for x in range(x0, x1):
				var pos := Vector2i(x, y)
				var chunk: Dictionary = grid.get_chunk(pos)
				if chunk.terrain == 0:
					continue
				if chunk.state == ChunkGrid.State.LOOSE:
					if _try_fall(grid, pos, chunk, size):
						moved = true
					elif _try_slide(grid, pos, chunk, size):
						moved = true
				elif chunk.state == ChunkGrid.State.LIQUID:
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
	var bc: Dictionary = grid.get_chunk(below)
	if bc.terrain == 0:
		grid.set_chunk(below, chunk.terrain, chunk.color, chunk.state)
		grid.set_chunk(pos, 0, 0, 0)
		return true
	# Loose sinks through liquid
	if chunk.state == ChunkGrid.State.LOOSE and bc.state == ChunkGrid.State.LIQUID:
		grid.set_chunk(below, chunk.terrain, chunk.color, chunk.state)
		grid.set_chunk(pos, bc.terrain, bc.color, bc.state)
		return true
	return false


func _try_slide(grid: ChunkGrid, pos: Vector2i, chunk: Dictionary, size: Vector2i) -> bool:
	# Sand-like: if can't fall straight, try diagonal down-left or down-right
	var dl := Vector2i(pos.x - 1, pos.y + 1)
	var dr := Vector2i(pos.x + 1, pos.y + 1)
	var can_dl: bool = dl.x >= 0 and dl.y < size.y and grid.get_chunk(dl).terrain == 0
	var can_dr: bool = dr.x < size.x and dr.y < size.y and grid.get_chunk(dr).terrain == 0
	var target: Vector2i
	if can_dl and can_dr:
		target = dl if randi() % 2 == 0 else dr
	elif can_dl:
		target = dl
	elif can_dr:
		target = dr
	else:
		return false
	grid.set_chunk(target, chunk.terrain, chunk.color, chunk.state)
	grid.set_chunk(pos, 0, 0, 0)
	return true


func _try_spread(grid: ChunkGrid, pos: Vector2i, chunk: Dictionary, size: Vector2i) -> bool:
	var left := Vector2i(pos.x - 1, pos.y)
	var right := Vector2i(pos.x + 1, pos.y)
	var can_left: bool = left.x >= 0 and grid.get_chunk(left).terrain == 0
	var can_right: bool = right.x < size.x and grid.get_chunk(right).terrain == 0
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
