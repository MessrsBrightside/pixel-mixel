class_name TerrainCollision
extends StaticBody2D

## Generates collision shapes from the chunk grid, split into regions.
## Adjacent solid chunks in the same row merge into wider rectangles.

const REGION_SIZE := 32
const CHUNK_PX := 4

var grid: ChunkGrid
var terrain_defs: Array[TerrainDef]

var _region_shapes: Dictionary = {}  # Vector2i -> Array[CollisionShape2D]


func build_all() -> void:
	var size := grid.get_size()
	var cols := ceili(float(size.x) / REGION_SIZE)
	var rows := ceili(float(size.y) / REGION_SIZE)
	for ry in range(rows):
		for rx in range(cols):
			_build_region(Vector2i(rx, ry))


func rebuild_region(region_pos: Vector2i) -> void:
	if _region_shapes.has(region_pos):
		var shapes: Array = _region_shapes[region_pos]
		for s in shapes:
			remove_child(s)
			s.free()
		_region_shapes.erase(region_pos)
	_build_region(region_pos)


func _build_region(region_pos: Vector2i) -> void:
	var size := grid.get_size()
	var x_start := region_pos.x * REGION_SIZE
	var y_start := region_pos.y * REGION_SIZE
	var x_end := mini(x_start + REGION_SIZE, size.x)
	var y_end := mini(y_start + REGION_SIZE, size.y)

	var shapes: Array = []

	for y in range(y_start, y_end):
		var run_start := -1
		for x in range(x_start, x_end):
			var chunk: Variant = grid.get_chunk(Vector2i(x, y))
			if chunk != null and _is_collidable(chunk):
				if run_start == -1:
					run_start = x
			else:
				if run_start != -1:
					shapes.append(_add_rect(run_start, y, x - run_start))
					run_start = -1
		if run_start != -1:
			shapes.append(_add_rect(run_start, y, x_end - run_start))

	_region_shapes[region_pos] = shapes


func _add_rect(cx: int, cy: int, width_chunks: int) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width_chunks * CHUNK_PX, CHUNK_PX)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(
		cx * CHUNK_PX + (width_chunks * CHUNK_PX) * 0.5,
		cy * CHUNK_PX + CHUNK_PX * 0.5
	)
	add_child(col)
	return col


func _is_collidable(chunk: Dictionary) -> bool:
	if chunk.terrain == 0:
		return false
	if chunk.state == ChunkGrid.State.LIQUID:
		return false
	if chunk.terrain > 0 and chunk.terrain < terrain_defs.size():
		var def: TerrainDef = terrain_defs[chunk.terrain]
		if def != null and def.passable:
			return false
	return true
