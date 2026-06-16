class_name ChunkGrid
extends RefCounted

## Dense chunk grid. Each chunk stores terrain_type, color_index, state as 3 bytes.

enum State { STATIC = 0, LOOSE = 1, LIQUID = 2 }

const BYTES_PER_CHUNK := 3

var _width: int
var _height: int
var _data: PackedByteArray


func _init(width: int = 256, height: int = 144) -> void:
	_width = width
	_height = height
	_data = PackedByteArray()
	_data.resize(_width * _height * BYTES_PER_CHUNK)
	_data.fill(0)


func get_size() -> Vector2i:
	return Vector2i(_width, _height)


func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < _width and pos.y >= 0 and pos.y < _height


func set_chunk(pos: Vector2i, terrain: int, color: int, state: int) -> void:
	if not is_in_bounds(pos):
		return
	var idx := (pos.y * _width + pos.x) * BYTES_PER_CHUNK
	_data[idx] = terrain
	_data[idx + 1] = color
	_data[idx + 2] = state


func get_chunk(pos: Vector2i) -> Variant:
	if not is_in_bounds(pos):
		return null
	var idx := (pos.y * _width + pos.x) * BYTES_PER_CHUNK
	return {"terrain": _data[idx], "color": _data[idx + 1], "state": _data[idx + 2]}


func get_neighbors(pos: Vector2i) -> Array:
	var result: Array = []
	for offset in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var neighbor: Vector2i = pos + offset
		var chunk: Variant = get_chunk(neighbor)
		if chunk != null:
			result.append(chunk)
	return result


func iterate_region(rect: Rect2i) -> Array:
	var result: Array = []
	var x_start := maxi(rect.position.x, 0)
	var y_start := maxi(rect.position.y, 0)
	var x_end := mini(rect.position.x + rect.size.x, _width)
	var y_end := mini(rect.position.y + rect.size.y, _height)
	for y in range(y_start, y_end):
		for x in range(x_start, x_end):
			var idx := (y * _width + x) * BYTES_PER_CHUNK
			result.append({"pos": Vector2i(x, y), "terrain": _data[idx], "color": _data[idx + 1], "state": _data[idx + 2]})
	return result
