class_name ChunkRenderer
extends Node2D

const CHUNK_PX := 4
const BORDER_COLOR := Color.BLACK

var grid: ChunkGrid
var terrain_defs: Array[TerrainDef]

var _sprite: Sprite2D
var _fg_sprite: Sprite2D
var _bg_img: Image
var _fg_img: Image
var _bg_tex: ImageTexture
var _fg_tex: ImageTexture


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)
	_fg_sprite = Sprite2D.new()
	_fg_sprite.centered = false
	_fg_sprite.z_index = 2
	add_child(_fg_sprite)


func render() -> void:
	var size := grid.get_size()
	_bg_img = Image.create(size.x * CHUNK_PX, size.y * CHUNK_PX, false, Image.FORMAT_RGBA8)
	_fg_img = Image.create(size.x * CHUNK_PX, size.y * CHUNK_PX, false, Image.FORMAT_RGBA8)
	_bg_img.fill(Color(0, 0, 0, 0))
	_fg_img.fill(Color(0, 0, 0, 0))

	for y in range(size.y):
		for x in range(size.x):
			_render_chunk(x, y)

	_bg_tex = ImageTexture.create_from_image(_bg_img)
	_fg_tex = ImageTexture.create_from_image(_fg_img)
	_sprite.texture = _bg_tex
	_fg_sprite.texture = _fg_tex


func render_dirty() -> void:
	## Fast update: re-render only chunks that the simulator moved.
	## Call this instead of render() after small changes.
	if _bg_img == null:
		render()
		return
	_bg_tex.update(_bg_img)
	_fg_tex.update(_fg_img)


func mark_dirty_region(rect: Rect2i) -> void:
	## Re-render a rectangular region of chunks (after sim tick or attack).
	var x0 := maxi(rect.position.x - 1, 0)
	var y0 := maxi(rect.position.y - 1, 0)
	var x1 := mini(rect.end.x + 1, grid.get_size().x)
	var y1 := mini(rect.end.y + 1, grid.get_size().y)
	for y in range(y0, y1):
		for x in range(x0, x1):
			_clear_chunk(x, y)
			_render_chunk(x, y)
	_bg_tex.update(_bg_img)
	_fg_tex.update(_fg_img)


func render_to_image() -> Image:
	if _bg_img == null:
		render()
	return _bg_img


func render_to_images() -> Array[Image]:
	if _bg_img == null:
		render()
	return [_bg_img, _fg_img]


func _clear_chunk(x: int, y: int) -> void:
	var px := x * CHUNK_PX
	var py := y * CHUNK_PX
	var clear := Color(0, 0, 0, 0)
	_bg_img.fill_rect(Rect2i(px, py, CHUNK_PX, CHUNK_PX), clear)
	_fg_img.fill_rect(Rect2i(px, py, CHUNK_PX, CHUNK_PX), clear)


func _render_chunk(x: int, y: int) -> void:
	var chunk: Dictionary = grid.get_chunk(Vector2i(x, y))
	var terrain: int = chunk.terrain
	if terrain == 0:
		return

	if terrain >= terrain_defs.size() or terrain_defs[terrain] == null:
		return

	var tdef: TerrainDef = terrain_defs[terrain]
	var color: Color = tdef.palette[chunk.color]
	var state: int = chunk.state

	if state == ChunkGrid.State.LIQUID and tdef is LiquidDef:
		color.a = (tdef as LiquidDef).transparency

	var px := x * CHUNK_PX
	var py := y * CHUNK_PX
	var img: Image = _fg_img if tdef.foreground else _bg_img
	img.fill_rect(Rect2i(px, py, CHUNK_PX, CHUNK_PX), color)

	if state == ChunkGrid.State.STATIC:
		_draw_borders(img, Vector2i(x, y), px, py, terrain)


func _draw_borders(img: Image, pos: Vector2i, px: int, py: int, terrain: int) -> void:
	var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for dir_idx in range(4):
		var npos := pos + offsets[dir_idx]
		var needs_border := true
		if grid.is_in_bounds(npos):
			var n: Dictionary = grid.get_chunk(npos)
			if n.terrain == terrain:
				needs_border = false
		if needs_border:
			match dir_idx:
				0:
					for i in range(CHUNK_PX):
						img.set_pixel(px + i, py, BORDER_COLOR)
				1:
					for i in range(CHUNK_PX):
						img.set_pixel(px + i, py + CHUNK_PX - 1, BORDER_COLOR)
				2:
					for i in range(CHUNK_PX):
						img.set_pixel(px, py + i, BORDER_COLOR)
				3:
					for i in range(CHUNK_PX):
						img.set_pixel(px + CHUNK_PX - 1, py + i, BORDER_COLOR)
