class_name LooseChunkBody
extends RigidBody2D

## A freed chunk that flies as a RigidBody2D. Returns to grid when at rest.

const REST_THRESHOLD := 2.0
const REST_TIME := 2.0
const CHUNK_PX := 4

var _rest_timer := 0.0
var terrain_type: int = 0
var color_index: int = 0
var chunk_grid: ChunkGrid


func setup(color: Color, chunk_size: float, initial_velocity: Vector2, mass_val: float) -> void:
	mass = mass_val
	linear_velocity = initial_velocity
	gravity_scale = 1.0

	var shape := RectangleShape2D.new()
	shape.size = Vector2(chunk_size, chunk_size)
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(chunk_size, chunk_size)
	rect.position = Vector2(-chunk_size / 2.0, -chunk_size / 2.0)
	add_child(rect)


func _physics_process(delta: float) -> void:
	if linear_velocity.length() < REST_THRESHOLD:
		_rest_timer += delta
		if _rest_timer >= REST_TIME:
			_return_to_grid()
	else:
		_rest_timer = 0.0


func _return_to_grid() -> void:
	if chunk_grid != null and terrain_type > 0:
		var cx := int(global_position.x) / CHUNK_PX
		var cy := int(global_position.y) / CHUNK_PX
		var pos := Vector2i(cx, cy)
		if chunk_grid.is_in_bounds(pos):
			var existing := chunk_grid.get_chunk(pos)
			if existing.terrain == 0:
				chunk_grid.set_chunk(pos, terrain_type, color_index, ChunkGrid.State.LOOSE)
	queue_free()
