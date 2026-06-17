class_name BladeAttack
extends RefCounted

## Fan-shaped blade attack that frees chunks based on power vs toughness.

const RANGE := 15
const ARC_ANGLE := deg_to_rad(10.0)
const RAY_COUNT := 3
const START_OFFSET := 2


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
	# Kick direction in chunk units
	var kick_x := int(sign(dir.x)) * 2
	var kick_y := int(sign(dir.y))

	for step in range(START_OFFSET, RANGE):
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
			continue

		var tdef: TerrainDef = terrain_defs[chunk.terrain] if chunk.terrain < terrain_defs.size() else null
		if tdef == null:
			continue

		var toughness: float = tdef.toughness
		if remaining >= toughness:
			remaining -= toughness
			# Free the chunk and kick it in attack direction
			grid.set_chunk(pos, 0, 0, 0)
			var dest := Vector2i(pos.x + kick_x, pos.y + kick_y)
			if grid.is_in_bounds(dest) and grid.get_chunk(dest).terrain == 0:
				grid.set_chunk(dest, chunk.terrain, chunk.color, ChunkGrid.State.LOOSE)
			else:
				# Can't kick, just leave in place as loose
				grid.set_chunk(pos, chunk.terrain, chunk.color, ChunkGrid.State.LOOSE)
			freed += 1
		else:
			break

	return freed
