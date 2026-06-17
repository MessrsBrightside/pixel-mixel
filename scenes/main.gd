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
var _render_frame_count: int = 0
var _player: Player
var _camera: Camera2D
var _parallax_bg: ParallaxBG

# Presets: each is [seed, params_dict]
var _presets: Array = [
	[42, {"amplitude": 20, "frequency": 0.02, "base_height": 80, "water_level": 78, "dirt_depth": 16, "loose_density": 0.08}],
	[99, {"amplitude": 35, "frequency": 0.015, "base_height": 70, "water_level": 85, "dirt_depth": 12, "loose_density": 0.1}],
	[256, {"amplitude": 15, "frequency": 0.06, "base_height": 90, "water_level": 88, "dirt_depth": 20, "loose_density": 0.05}],
	[1337, {"amplitude": 40, "frequency": 0.01, "base_height": 60, "water_level": 75, "dirt_depth": 10, "loose_density": 0.15}],
	[7777, {"amplitude": 25, "frequency": 0.03, "base_height": 75, "water_level": 80, "dirt_depth": 14, "loose_density": 0.12}],
]


func _ready() -> void:
	_parallax_bg = ParallaxBG.new()
	add_child(_parallax_bg)
	_renderer = ChunkRenderer.new()
	add_child(_renderer)
	_player = Player.new()
	_player.z_index = 1
	_player.attacked.connect(_on_player_attacked)
	add_child(_player)
	_camera = Camera2D.new()
	_camera.zoom = Vector2(2, 2)
	_player.add_child(_camera)
	_label = Label.new()
	_label.position = Vector2(4, 4)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_font_size_override("font_size", 12)
	_label.z_index = 2
	add_child(_label)
	_generate_preset(0)


func _process(_delta: float) -> void:
	if _player._settling_needed:
		_player._settling_needed = false
		_settling = true
	if not _settling:
		return
	var moved := false
	for i in range(_ticks_per_frame):
		if _simulator.tick(_grid):
			moved = true
			_total_ticks += 1
		else:
			break
	if moved:
		# Only re-render every 6th frame to stay responsive
		_render_frame_count += 1
		if _render_frame_count % 6 == 0:
			var dirty := _simulator.get_dirty_rect()
			if dirty.size.x > 0 and dirty.size.x < 200:
				_renderer.mark_dirty_region(dirty)
			else:
				_renderer.render_dirty()
	if not moved:
		_settling = false
		_renderer.render()
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
			KEY_6: _generate_biome("ocean_shore", 42)
			KEY_7: _generate_biome("forest_surface", 42)
			KEY_8: _generate_biome("forest_lake", 42)
			KEY_9: _generate_biome("cave", 42)
			KEY_0: _generate_biome("desert", 42)
			KEY_R: _generate(randi(), {"amplitude": 30, "frequency": 0.02, "base_height": 75, "water_level": 80, "dirt_depth": 14, "loose_density": 0.1})
			KEY_UP: _ticks_per_frame = mini(_ticks_per_frame * 2, 500)
			KEY_DOWN: _ticks_per_frame = maxi(_ticks_per_frame / 2, 1)


func _generate_preset(idx: int) -> void:
	var preset: Array = _presets[idx]
	_generate(preset[0], preset[1])


func _generate_biome(biome_name: String, seed_val: int) -> void:
	_current_seed = seed_val
	var gen := BiomeGenerator.new()
	_grid = gen.generate(biome_name, seed_val)
	_simulator = ChunkSimulator.new(seed_val)
	_renderer.grid = _grid
	_renderer.terrain_defs = _load_terrain_defs()
	_renderer.render()
	_settling = false
	_total_ticks = 0
	_update_label("biome: %s (seed %d)" % [biome_name, seed_val])
	_place_player()
	_parallax_bg.setup(biome_name)


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
	_place_player()
	_parallax_bg.setup("default")


func _update_label(status: String) -> void:
	_label.text = "%s | ticks/frame: %d (UP/DOWN)" % [status, _ticks_per_frame]


func _place_player() -> void:
	_player.chunk_grid = _grid
	_player.terrain_defs = _load_terrain_defs()
	_player.position = _player.find_spawn_position()
	_player.velocity = Vector2.ZERO
	_player.on_ground = false


func _load_terrain_defs() -> Array[TerrainDef]:
	var defs: Array[TerrainDef] = []
	defs.resize(11)
	defs[0] = null
	defs[1] = load("res://resources/dirt.tres")
	defs[2] = load("res://resources/stone.tres")
	defs[3] = load("res://resources/water.tres")
	defs[4] = load("res://resources/grass.tres")
	defs[5] = load("res://resources/leaves.tres")
	defs[6] = load("res://resources/wood.tres")
	defs[7] = load("res://resources/sand.tres")
	defs[8] = load("res://resources/mushroom.tres")
	defs[9] = load("res://resources/cactus.tres")
	defs[10] = load("res://resources/grass_solid.tres")
	return defs


func _on_player_attacked() -> void:
	_settling = true
	_ticks_per_frame = 2
	_renderer.render()
