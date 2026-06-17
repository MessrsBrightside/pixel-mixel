class_name LooseChunkBody
extends RigidBody2D

## A freed chunk that flies as a RigidBody2D and auto-frees when at rest.

const REST_THRESHOLD := 5.0
const REST_TIME := 3.0

var _rest_timer := 0.0


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
			queue_free()
	else:
		_rest_timer = 0.0
