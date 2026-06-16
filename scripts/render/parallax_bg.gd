class_name ParallaxBG
extends ParallaxBackground

## Procedural parallax backgrounds per biome. Uses Image gradients — no external assets.

const WIDTH := 512
const HEIGHT := 288

var _color_schemes: Dictionary = {
	"ocean_shore": [Color(0.6, 0.85, 1.0), Color(0.3, 0.6, 0.9)],
	"forest_surface": [Color(0.2, 0.4, 0.2), Color(0.5, 0.75, 0.5)],
	"forest_lake": [Color(0.2, 0.4, 0.2), Color(0.5, 0.75, 0.5)],
	"cave": [Color(0.1, 0.08, 0.06), Color(0.25, 0.2, 0.15)],
	"desert": [Color(0.95, 0.6, 0.2), Color(1.0, 0.9, 0.6)],
}

var _default_scheme: Array = [Color(0.4, 0.5, 0.7), Color(0.7, 0.8, 0.9)]


func setup(biome_name: String) -> void:
	_clear_layers()
	var scheme: Array = _color_schemes.get(biome_name, _default_scheme)
	_add_layer(_make_gradient_texture(scheme[0], scheme[1]), 0.3)
	if biome_name != "cave":
		_add_layer(_make_silhouette_texture(scheme[0]), 0.6)


func _clear_layers() -> void:
	for child in get_children():
		child.queue_free()


func _add_layer(texture: ImageTexture, motion_scale_val: float) -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(motion_scale_val, motion_scale_val)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	layer.add_child(sprite)
	add_child(layer)


func _make_gradient_texture(top_color: Color, bottom_color: Color) -> ImageTexture:
	var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	for y in range(HEIGHT):
		var t := float(y) / float(HEIGHT)
		var color := top_color.lerp(bottom_color, t)
		for x in range(WIDTH):
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


func _make_silhouette_texture(base_color: Color) -> ImageTexture:
	var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := base_color.darkened(0.6)
	dark.a = 0.4
	# Simple hills silhouette at bottom
	for x in range(WIDTH):
		var hill_h := int(20.0 + 15.0 * sin(x * 0.02) + 8.0 * sin(x * 0.05))
		for y in range(HEIGHT - hill_h, HEIGHT):
			img.set_pixel(x, y, dark)
	return ImageTexture.create_from_image(img)
