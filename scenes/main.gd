extends Node2D

## Main scene: press 1-5 to generate worlds with different seeds.
## Press R for a random seed.

var _renderer: ChunkRenderer
var _seeds: Array[int] = [42, 99, 256, 1337, 7777]
var _current_seed: int = 42


func _ready() -> void:
	_renderer = ChunkRenderer.new()
	add_child(_renderer)
	_generate(_current_seed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _generate(_seeds[0])
			KEY_2: _generate(_seeds[1])
			KEY_3: _generate(_seeds[2])
			KEY_4: _generate(_seeds[3])
			KEY_5: _generate(_seeds[4])
			KEY_R: _generate(randi())


func _generate(seed_val: int) -> void:
	_current_seed = seed_val
	var gen := WorldGenerator.new()
	var grid := gen.generate(seed_val)
	_renderer.grid = grid
	_renderer.terrain_defs = _load_terrain_defs()
	_renderer.render()
	print("Generated world with seed: %d" % seed_val)


func _load_terrain_defs() -> Array[TerrainDef]:
	var defs: Array[TerrainDef] = []
	defs.resize(3)
	defs[0] = null  # empty
	defs[1] = load("res://resources/dirt.tres")
	defs[2] = load("res://resources/stone.tres")
	return defs
