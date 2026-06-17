extends SceneTree

## Headless tests for ChunkRenderer.

const ChunkGridClass = preload("res://scripts/chunk_grid.gd")
const TerrainDefClass = preload("res://scripts/terrain_def.gd")
const ChunkRendererClass = preload("res://scripts/render/chunk_renderer.gd")

const CHUNK_PX := 4


func _make_terrain_defs() -> Array[TerrainDef]:
	var empty := TerrainDefClass.new()
	empty.id = &"empty"
	empty.palette = [Color.TRANSPARENT] as Array[Color]

	var dirt := TerrainDefClass.new()
	dirt.id = &"dirt"
	dirt.palette = [Color(0.4, 0.26, 0.13, 1), Color(0.55, 0.35, 0.17, 1)] as Array[Color]

	var stone := TerrainDefClass.new()
	stone.id = &"stone"
	stone.palette = [Color(0.5, 0.5, 0.5, 1), Color(0.63, 0.63, 0.63, 1)] as Array[Color]

	var defs: Array[TerrainDef] = [empty, dirt, stone]
	return defs


func _make_renderer(grid: ChunkGrid, defs: Array[TerrainDef]) -> Node2D:
	var r := ChunkRendererClass.new()
	r.grid = grid
	r.terrain_defs = defs
	return r


func _init() -> void:
	var passed := 0
	var failed := 0
	var defs := _make_terrain_defs()

	# Test: empty grid produces fully transparent image
	var grid := ChunkGridClass.new(4, 4)
	var r = _make_renderer(grid, defs)
	var img: Image = r.render_to_image()
	var all_transparent := true
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.0:
				all_transparent = false
				break
	if all_transparent:
		passed += 1
		print("PASS: empty grid produces fully transparent image")
	else:
		failed += 1
		print("FAIL: empty grid has non-transparent pixels")

	# Test: rendered image dimensions match grid size * 4
	if img.get_width() == 16 and img.get_height() == 16:
		passed += 1
		print("PASS: rendered image dimensions match grid size * 4")
	else:
		failed += 1
		print("FAIL: image dimensions %dx%d (expected 16x16)" % [img.get_width(), img.get_height()])

	# Test: single static chunk produces 4x4 colored block with black border on all sides
	grid = ChunkGridClass.new(4, 4)
	grid.set_chunk(Vector2i(1, 1), 1, 0, ChunkGridClass.State.STATIC)
	r = _make_renderer(grid, defs)
	img = r.render_to_image()
	var px := 1 * CHUNK_PX
	var py := 1 * CHUNK_PX
	var border_ok := true
	# Top and bottom borders
	for i in range(CHUNK_PX):
		if img.get_pixel(px + i, py) != Color.BLACK:
			border_ok = false
		if img.get_pixel(px + i, py + CHUNK_PX - 1) != Color.BLACK:
			border_ok = false
	# Left and right borders
	for i in range(CHUNK_PX):
		if img.get_pixel(px, py + i) != Color.BLACK:
			border_ok = false
		if img.get_pixel(px + CHUNK_PX - 1, py + i) != Color.BLACK:
			border_ok = false
	# Interior should be terrain color (not black, not transparent)
	var interior_ok := true
	for iy in range(1, CHUNK_PX - 1):
		for ix in range(1, CHUNK_PX - 1):
			var p := img.get_pixel(px + ix, py + iy)
			if p == Color.BLACK or p.a == 0.0:
				interior_ok = false
	if border_ok and interior_ok:
		passed += 1
		print("PASS: single static chunk has black border and correct fill")
	else:
		failed += 1
		print("FAIL: single static chunk border=%s interior=%s" % [border_ok, interior_ok])

	# Test: two adjacent same-terrain static chunks have no border between them
	grid = ChunkGridClass.new(4, 4)
	grid.set_chunk(Vector2i(1, 1), 1, 0, ChunkGridClass.State.STATIC)
	grid.set_chunk(Vector2i(2, 1), 1, 0, ChunkGridClass.State.STATIC)
	r = _make_renderer(grid, defs)
	img = r.render_to_image()
	# Right edge of chunk (1,1) should NOT be black (same terrain neighbor)
	var no_border := true
	var right_edge_x := 1 * CHUNK_PX + CHUNK_PX - 1
	for i in range(1, CHUNK_PX - 1):
		if img.get_pixel(right_edge_x, 1 * CHUNK_PX + i) == Color.BLACK:
			no_border = false
	# Left edge of chunk (2,1) should NOT be black
	var left_edge_x := 2 * CHUNK_PX
	for i in range(1, CHUNK_PX - 1):
		if img.get_pixel(left_edge_x, 1 * CHUNK_PX + i) == Color.BLACK:
			no_border = false
	if no_border:
		passed += 1
		print("PASS: adjacent same-terrain static chunks have no border between them")
	else:
		failed += 1
		print("FAIL: adjacent same-terrain chunks have border between them")

	# Test: two adjacent different-terrain static chunks have border between them
	grid = ChunkGridClass.new(4, 4)
	grid.set_chunk(Vector2i(1, 1), 1, 0, ChunkGridClass.State.STATIC)
	grid.set_chunk(Vector2i(2, 1), 2, 0, ChunkGridClass.State.STATIC)
	r = _make_renderer(grid, defs)
	img = r.render_to_image()
	var has_border := true
	right_edge_x = 1 * CHUNK_PX + CHUNK_PX - 1
	for i in range(CHUNK_PX):
		if img.get_pixel(right_edge_x, 1 * CHUNK_PX + i) != Color.BLACK:
			has_border = false
	left_edge_x = 2 * CHUNK_PX
	for i in range(CHUNK_PX):
		if img.get_pixel(left_edge_x, 1 * CHUNK_PX + i) != Color.BLACK:
			has_border = false
	if has_border:
		passed += 1
		print("PASS: adjacent different-terrain static chunks have border between them")
	else:
		failed += 1
		print("FAIL: adjacent different-terrain chunks missing border")

	# Test: LOOSE chunk has border on all 4 sides
	grid = ChunkGridClass.new(4, 4)
	grid.set_chunk(Vector2i(1, 1), 1, 0, ChunkGridClass.State.LOOSE)
	r = _make_renderer(grid, defs)
	img = r.render_to_image()
	px = 1 * CHUNK_PX
	py = 1 * CHUNK_PX
	var loose_border_ok := true
	for i in range(CHUNK_PX):
		if img.get_pixel(px + i, py) != Color.BLACK:
			loose_border_ok = false
		if img.get_pixel(px + i, py + CHUNK_PX - 1) != Color.BLACK:
			loose_border_ok = false
		if img.get_pixel(px, py + i) != Color.BLACK:
			loose_border_ok = false
		if img.get_pixel(px + CHUNK_PX - 1, py + i) != Color.BLACK:
			loose_border_ok = false
	if loose_border_ok:
		passed += 1
		print("PASS: LOOSE chunk has border on all 4 sides")
	else:
		failed += 1
		print("FAIL: LOOSE chunk missing border pixels")

	# Test: two adjacent same-terrain LOOSE chunks have border between them
	grid = ChunkGridClass.new(4, 4)
	grid.set_chunk(Vector2i(1, 1), 1, 0, ChunkGridClass.State.LOOSE)
	grid.set_chunk(Vector2i(2, 1), 1, 0, ChunkGridClass.State.LOOSE)
	r = _make_renderer(grid, defs)
	img = r.render_to_image()
	var loose_border_between := true
	right_edge_x = 1 * CHUNK_PX + CHUNK_PX - 1
	for i in range(CHUNK_PX):
		if img.get_pixel(right_edge_x, 1 * CHUNK_PX + i) != Color.BLACK:
			loose_border_between = false
	left_edge_x = 2 * CHUNK_PX
	for i in range(CHUNK_PX):
		if img.get_pixel(left_edge_x, 1 * CHUNK_PX + i) != Color.BLACK:
			loose_border_between = false
	if loose_border_between:
		passed += 1
		print("PASS: two adjacent same-terrain LOOSE chunks have border between them")
	else:
		failed += 1
		print("FAIL: adjacent same-terrain LOOSE chunks missing border between them")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
