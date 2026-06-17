class_name ChunkSpawner
extends Node

## Spawns LooseChunkBody instances and enforces a max body limit.

const LooseChunkBodyScene = preload("res://scripts/physics/loose_chunk_body.gd")

var terrain_defs: Array[TerrainDef]
var max_bodies := 500
var active_bodies: Array = []


func spawn_chunk(parent: Node, world_pos: Vector2, terrain: int, color_idx: int, velocity: Vector2) -> void:
	var color := Color.MAGENTA
	var mass_val := 1.0
	if terrain < terrain_defs.size() and terrain_defs[terrain] != null:
		var tdef: TerrainDef = terrain_defs[terrain]
		if color_idx < tdef.palette.size():
			color = tdef.palette[color_idx]
		mass_val = tdef.density

	# Enforce limit
	while active_bodies.size() >= max_bodies:
		var oldest = active_bodies.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var body: RigidBody2D = LooseChunkBodyScene.new()
	body.position = world_pos
	body.setup(color, 4.0, velocity, mass_val)
	parent.add_child(body)
	active_bodies.append(body)
	body.tree_exiting.connect(_on_body_freed.bind(body))


func _on_body_freed(body: RigidBody2D) -> void:
	active_bodies.erase(body)
