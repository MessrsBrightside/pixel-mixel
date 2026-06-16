extends Node2D

## Main scene: press 1-5 for preset worlds, R for random.
## Shows world generating and settling in real-time.

var _renderer: ChunkRenderer
var _simulator: ChunkSimulator
var _grid: ChunkGrid
var _current_seed: int = 42
var _settling: bool = false
var _ticks_per_frame: int = 50
var _label: Label
var _total_ticks: int = 0

# Presets: each is [seed, params_dict]
var _presets: Array = [
	[42, {"amplitude": 20, "frequency": 0.02, "base_height": 80, "water_level": 78, "dirt_depth": 16, "loose_density": 0.08}],
	[99, {"amplitude": 35, "frequency": 0.015, "base_height": 70, "water_level": 85, "dirt_depth": 12, "loose_density": 0.1}],
	[256, {"amplitude": 15, "frequency": 0.06, "base_height": 90, "water_level": 88, "dirt_depth": 20, "loose_density": 0.05}],
	[1337, {"amplitude": 40, "frequency": 0.01, "base_height": 60, "water_level": 75, "dirt_depth": 10, "loose_density": 0.15}],
	[7777, {"amplitude": 25, "frequency": 0.03, "base_height": 75, "water_level": 80, "dirt_depth": 14, "loose_density": 0.12}],
]


func _ready() -> void:
	_renderer = ChunkRenderer.new()
	add_child(_renderer)
	_label = Label.new()
	_label.position = Vector2(4, 4)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_font_size_override("font_size", 12)
	add_child(_label)
	_generate_preset(0)


func _process(_delta: float) -> void:
	if not _settling:
		return
	var moved := false
	for i in range(_ticks_per_frame):
		if _simulator.tick(_grid):
			moved = true
			_total_ticks += 1
		else:
			break
	_renderer.render()
	if not moved:
		_settling = false
		_update_label("settled (seed %d, %d ticks)" % [_current_seed, _total_ticks])
	else:
		_update_label("settling seed %d... tick %d" % [_current_seed, _total_ticks])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _generate_preset(0)
			KEY_2: _generate_preset(1)
			KEY_3: _generate_preset(2)
			KEY_4: _generate_preset(3)
			KEY_5: _generate_preset(4)
			KEY_R: _generate(randi(), {"amplitude": 30, "frequency": 0.02, "base_height": 75, "water_level": 80, "dirt_depth": 14, "loose_density": 0.1})
			KEY_UP: _ticks_per_frame = mini(_ticks_per_frame * 2, 500)
			KEY_DOWN: _ticks_per_frame = maxi(_ticks_per_frame / 2, 1)


func _generate_preset(idx: int) -> void:
	var preset: Array = _presets[idx]
	_generate(preset[0], preset[1])


func _generate(seed_val: int, params: Dictionary = {}) -> void:
	_current_seed = seed_val
	params["water_terrain_index"] = 3
	if not params.has("loose_terrain_index"):
		params["loose_terrain_index"] = 1  # dirt
	_grid = ChunkGrid.new(256, 144)
	var runner := PipelineRunner.new()
	runner.add_plugin(SurfaceShapePlugin.new())
	runner.add_plugin(TerrainFillPlugin.new())
	runner.add_plugin(WaterPlacementPlugin.new())
	runner.add_plugin(LooseChunkPlugin.new())
	runner.add_plugin(PalettePlugin.new())
	runner.run(_grid, seed_val, params)

	_simulator = ChunkSimulator.new(seed_val)
	_renderer.grid = _grid
	_renderer.terrain_defs = _load_terrain_defs()
	_renderer.render()

	_settling = true
	_total_ticks = 0
	_update_label("settling... (seed %d)" % seed_val)


func _update_label(status: String) -> void:
	_label.text = "%s | ticks/frame: %d (UP/DOWN)" % [status, _ticks_per_frame]


func _load_terrain_defs() -> Array[TerrainDef]:
	var defs: Array[TerrainDef] = []
	defs.resize(4)
	defs[0] = null
	defs[1] = load("res://resources/dirt.tres")
	defs[2] = load("res://resources/stone.tres")
	defs[3] = load("res://resources/water.tres")
	return defs
