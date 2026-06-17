class_name TerrainCollision
extends StaticBody2D

## Generates collision shapes from the chunk grid, split into regions.
## Adjacent solid chunks in the same row merge into wider rectangles.

const REGION_SIZE := 32
const CHUNK_PX := 4

var grid: ChunkGrid
var terrain_defs: Array[TerrainDef]

var _region_nodes: Dictionary = {}  # Vector2i -> Node2D


func build_all() -> void:
	var size := grid.get_size()
	var cols := ceili(float(size.x) / REGION_SIZE)
	var rows := ceili(float(size.y) / REGION_SIZE)
	for ry in range(rows):
		for rx in range(cols):
			_build_region(Vector2i(rx, ry))


func rebuild_region(region_pos: Vector2i) -> void:
	if _region_nodes.has(region_pos):
		var old: Node2D = _region_nodes[region_pos]
		remove_child(old)
		old.free()
		_region_nodes.erase(region_pos)
	_build_region(region_pos)


func _build_region(region_pos: Vector2i) -> void:
	var size := grid.get_size()
	var x_start := region_pos.x * REGION_SIZE
	var y_start := region_pos.y * REGION_SIZE
	var x_end := mini(x_start + REGION_SIZE, size.x)
	var y_end := mini(y_start + REGION_SIZE, size.y)

	var container := Node2D.new()
	container.name = "region_%d_%d" % [region_pos.x, region_pos.y]
	add_child(container)
	_region_nodes[region_pos] = container

	for y in range(y_start, y_end):
		var run_start := -1
		for x in range(x_start, x_end):
			var chunk: Variant = grid.get_chunk(Vector2i(x, y))
			if chunk != null and _is_collidable(chunk):
				if run_start == -1:
					run_start = x
			else:
				if run_start != -1:
					_add_rect(container, run_start, y, x - run_start)
					run_start = -1
		if run_start != -1:
			_add_rect(container, run_start, y, x_end - run_start)


func _add_rect(parent: Node2D, cx: int, cy: int, width_chunks: int) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width_chunks * CHUNK_PX, CHUNK_PX)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(
		cx * CHUNK_PX + (width_chunks * CHUNK_PX) * 0.5,
		cy * CHUNK_PX + CHUNK_PX * 0.5
	)
	parent.add_child(col)


func _is_collidable(chunk: Dictionary) -> bool:
	if chunk.terrain == 0:
		return false
	if chunk.state == ChunkGrid.State.LIQUID or chunk.state == ChunkGrid.State.LOOSE:
		return false
	if chunk.terrain > 0 and chunk.terrain < terrain_defs.size():
		var def: TerrainDef = terrain_defs[chunk.terrain]
		if def != null and def.passable:
			return false
	return true
