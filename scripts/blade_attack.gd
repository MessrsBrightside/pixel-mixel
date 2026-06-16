class_name BladeAttack
extends RefCounted

## Fan-shaped blade attack that frees chunks based on power vs toughness.

const RANGE := 20
const ARC_ANGLE := deg_to_rad(30.0)
const RAY_COUNT := 7


func execute(grid: ChunkGrid, origin: Vector2, direction: Vector2, power: float, terrain_defs: Array[TerrainDef]) -> int:
	var freed := 0
	var remaining_power := power
	var half_arc := ARC_ANGLE / 2.0
	var base_angle := direction.angle()

	for i in range(RAY_COUNT):
		var t := float(i) / float(RAY_COUNT - 1)  # 0.0 to 1.0
		var angle := base_angle - half_arc + t * ARC_ANGLE
		var ray_dir := Vector2(cos(angle), sin(angle))
		freed += _cast_ray(grid, origin, ray_dir, remaining_power, terrain_defs)

	return freed


func _cast_ray(grid: ChunkGrid, origin: Vector2, dir: Vector2, power: float, terrain_defs: Array[TerrainDef]) -> int:
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
		if chunk.state == ChunkGrid.State.LOOSE:
			continue  # Already loose

		var tdef: TerrainDef = terrain_defs[chunk.terrain] if chunk.terrain < terrain_defs.size() else null
		if tdef == null:
			continue

		var toughness: float = tdef.toughness
		if remaining >= toughness:
			remaining -= toughness
			grid.set_chunk(pos, chunk.terrain, chunk.color, ChunkGrid.State.LOOSE)
			freed += 1
		else:
			break  # Power exhausted

	return freed
