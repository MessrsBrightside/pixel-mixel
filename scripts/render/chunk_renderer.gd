class_name ChunkRenderer
extends Node2D

const CHUNK_PX := 4
const BORDER_COLOR := Color.BLACK

var grid: ChunkGrid
var terrain_defs: Array[TerrainDef]

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)


func render() -> void:
	var tex := ImageTexture.create_from_image(render_to_image())
	_sprite.texture = tex


func render_to_image() -> Image:
	var size := grid.get_size()
	var img := Image.create(size.x * CHUNK_PX, size.y * CHUNK_PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in range(size.y):
		for x in range(size.x):
			var chunk: Dictionary = grid.get_chunk(Vector2i(x, y))
			var terrain: int = chunk.terrain
			if terrain == 0:
				continue

			var tdef: TerrainDef = terrain_defs[terrain]
			var color: Color = tdef.palette[chunk.color]
			var state: int = chunk.state

			if state == ChunkGrid.State.LIQUID and tdef is LiquidDef:
				color.a = (tdef as LiquidDef).transparency

			var px := x * CHUNK_PX
			var py := y * CHUNK_PX
			img.fill_rect(Rect2i(px, py, CHUNK_PX, CHUNK_PX), color)

			if state == ChunkGrid.State.STATIC:
				_draw_borders(img, Vector2i(x, y), px, py, terrain)

	return img


func update_region(_rect: Rect2i) -> void:
	pass  # Placeholder for partial re-render


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
				0:  # Top
					for i in range(CHUNK_PX):
						img.set_pixel(px + i, py, BORDER_COLOR)
				1:  # Bottom
					for i in range(CHUNK_PX):
						img.set_pixel(px + i, py + CHUNK_PX - 1, BORDER_COLOR)
				2:  # Left
					for i in range(CHUNK_PX):
						img.set_pixel(px, py + i, BORDER_COLOR)
				3:  # Right
					for i in range(CHUNK_PX):
						img.set_pixel(px + CHUNK_PX - 1, py + i, BORDER_COLOR)
