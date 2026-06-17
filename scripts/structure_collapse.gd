class_name StructureCollapse
extends RefCounted

## After chunks are destroyed, collapse unsupported passable structures above.

func check_collapse(grid: ChunkGrid, destroyed_positions: Array, chunk_spawner: ChunkSpawner, parent: Node, terrain_defs: Array[TerrainDef]) -> void:
	var to_free: Dictionary = {}

	# Scan columns above each destroyed position
	for pos in destroyed_positions:
		_scan_above(grid, pos, terrain_defs, to_free)

	# Flood-fill laterally to find connected passable chunks
	var frontier: Array = to_free.keys()
	while frontier.size() > 0:
		var pos: Vector2i = frontier.pop_back()
		for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
			var n: Vector2i = pos + offset
			if to_free.has(n):
				continue
			if not grid.is_in_bounds(n):
				continue
			var chunk: Dictionary = grid.get_chunk(n)
			if chunk.terrain == 0:
				continue
			if not _is_passable(chunk, terrain_defs):
				continue
			to_free[n] = true
			frontier.append(n)

	# Spawn all freed chunks as bodies
	for pos in to_free:
		var chunk: Dictionary = grid.get_chunk(pos)
		if chunk.terrain == 0:
			continue
		grid.set_chunk(pos, 0, 0, 0)
		if chunk_spawner != null and parent != null:
			var world_pos := Vector2(pos.x * 4.0 + 2.0, pos.y * 4.0 + 2.0)
			var vel := Vector2(randf_range(-20, 20), randf_range(30, 80))
			chunk_spawner.spawn_chunk(parent, world_pos, chunk.terrain, chunk.color, vel)


func _scan_above(grid: ChunkGrid, pos: Vector2i, terrain_defs: Array[TerrainDef], to_free: Dictionary) -> void:
	for y in range(pos.y - 1, -1, -1):
		var check := Vector2i(pos.x, y)
		var chunk: Dictionary = grid.get_chunk(check)
		if chunk.terrain == 0:
			break
		if not _is_passable(chunk, terrain_defs):
			break
		to_free[check] = true


func _is_passable(chunk: Dictionary, terrain_defs: Array[TerrainDef]) -> bool:
	if chunk.terrain <= 0 or chunk.terrain >= terrain_defs.size():
		return false
	var tdef: TerrainDef = terrain_defs[chunk.terrain]
	return tdef != null and tdef.passable
