extends SceneTree

## Headless tool: generates a biome and saves a PNG screenshot.
## Usage: godot --headless --script tools/capture_biome_screenshot.gd -- ocean_shore 42


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --headless --script tools/capture_biome_screenshot.gd -- <biome_name> <seed>")
		quit()
		return

	var biome_name: String = args[0]
	var seed_val: int = int(args[1])

	var gen := BiomeGenerator.new()
	var grid := gen.generate(biome_name, seed_val)

	var renderer := ChunkRenderer.new()
	renderer.grid = grid
	renderer.terrain_defs = _load_terrain_defs()
	var img := renderer.render_to_image()

	var dir := DirAccess.open("res://")
	if not dir.dir_exists("screenshots/phase1"):
		dir.make_dir_recursive("screenshots/phase1")

	var path := "res://screenshots/phase1/%s_seed%d.png" % [biome_name, seed_val]
	img.save_png(path)
	print("Saved: %s" % path)
	quit()


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
