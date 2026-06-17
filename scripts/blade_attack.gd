class_name BladeAttack
extends RefCounted

## Narrow blade attack that frees chunks and spawns them as RigidBody2D.

const RANGE := 15
const ARC_ANGLE := deg_to_rad(10.0)
const RAY_COUNT := 3
const LAUNCH_SPEED := 200.0

var chunk_spawner: ChunkSpawner
var spawn_parent: Node


var _destroyed_positions: Array = []


func execute(grid: ChunkGrid, origin: Vector2, direction: Vector2, power: float, terrain_defs: Array[TerrainDef]) -> int:
	var freed := 0
	var remaining_power := power
	var half_arc := ARC_ANGLE / 2.0
	var base_angle := direction.angle()
	_destroyed_positions.clear()

	for i in range(RAY_COUNT):
		var t := float(i) / float(RAY_COUNT - 1)
		var angle := base_angle - half_arc + t * ARC_ANGLE
		var ray_dir := Vector2(cos(angle), sin(angle))
		freed += _cast_ray(grid, origin, ray_dir, remaining_power, terrain_defs, direction)

	# Collapse unsupported structures above destroyed chunks
	if _destroyed_positions.size() > 0 and chunk_spawner != null:
		var sc := StructureCollapse.new()
		sc.check_collapse(grid, _destroyed_positions, chunk_spawner, spawn_parent, terrain_defs)

	return freed


func _cast_ray(grid: ChunkGrid, origin: Vector2, dir: Vector2, power: float, terrain_defs: Array[TerrainDef], attack_dir: Vector2) -> int:
	var freed := 0
	var remaining := power
	var chunk_size := 4.0

	for step in range(RANGE):
		var sample := origin + dir * (step + 1) * chunk_size
		var cx := int(sample.x) / 4
		var cy := int(sample.y) / 4
		var pos := Vector2i(cx, cy)

		if not grid.is_in_bounds(pos):
			break

		var chunk: Variant = grid.get_chunk(pos)
		if chunk == null:
			break
		if chunk.terrain == 0 or chunk.state == ChunkGrid.State.LIQUID:
			continue

		var tdef: TerrainDef = terrain_defs[chunk.terrain] if chunk.terrain < terrain_defs.size() else null
		if tdef == null:
			continue

		var toughness: float = tdef.toughness
		if remaining >= toughness:
			remaining -= toughness
			# Clear from grid
			grid.set_chunk(pos, 0, 0, 0)
			_destroyed_positions.append(pos)
			# Spawn as RigidBody2D with velocity
			if chunk_spawner != null and spawn_parent != null:
				var world_pos := Vector2(cx * chunk_size + 2, cy * chunk_size + 2)
				var vel := attack_dir * LAUNCH_SPEED + Vector2(randf_range(-30, 30), randf_range(-80, -20))
				chunk_spawner.spawn_chunk(spawn_parent, world_pos, chunk.terrain, chunk.color, vel)
			freed += 1
		else:
			break

	return freed
