extends Node2D

## Main scene: press 1-5 for preset seeds, R for random.
## Shows world generating and settling in real-time.

var _renderer: ChunkRenderer
var _simulator: ChunkSimulator
var _grid: ChunkGrid
var _seeds: Array[int] = [42, 99, 256, 1337, 7777]
var _settling: bool = false
var _ticks_per_frame: int = 20
var _label: Label
var _total_ticks: int = 0


func _ready() -> void:
	_renderer = ChunkRenderer.new()
	add_child(_renderer)
	_label = Label.new()
	_label.position = Vector2(4, 4)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_font_size_override("font_size", 12)
	add_child(_label)
	_generate(_seeds[0])


func _process(_delta: float) -> void:
	if not _settling:
		return
	# Run several ticks per frame for speed, re-render after
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
			KEY_1: _generate(_seeds[0])
			KEY_2: _generate(_seeds[1])
			KEY_3: _generate(_seeds[2])
			KEY_4: _generate(_seeds[3])
			KEY_5: _generate(_seeds[4])
			KEY_R: _generate(randi())
			KEY_UP: _ticks_per_frame = mini(_ticks_per_frame * 2, 500)
			KEY_DOWN: _ticks_per_frame = maxi(_ticks_per_frame / 2, 1)


func _generate(seed_val: int) -> void:
	# Run pipeline only (no simulation yet)
	_grid = ChunkGrid.new(256, 144)
	var runner := PipelineRunner.new()
	runner.add_plugin(SurfaceShapePlugin.new())
	runner.add_plugin(TerrainFillPlugin.new())
	runner.add_plugin(WaterPlacementPlugin.new())
	runner.add_plugin(LooseChunkPlugin.new())
	runner.add_plugin(PalettePlugin.new())
	runner.run(_grid, seed_val)

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
	defs.resize(3)
	defs[0] = null
	defs[1] = load("res://resources/dirt.tres")
	defs[2] = load("res://resources/stone.tres")
	return defs
