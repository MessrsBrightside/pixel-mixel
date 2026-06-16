extends SceneTree

## Headless tool: generates forest_surface, captures before/after blade attack screenshots.
## Usage: godot --headless --script tools/capture_destruction_screenshot.gd

const BladeAttackClass = preload("res://scripts/blade_attack.gd")


func _init() -> void:
	var gen := BiomeGenerator.new()
	var grid := gen.generate("forest_surface", 42)
	var terrain_defs := _load_terrain_defs()

	var renderer := ChunkRenderer.new()
	renderer.grid = grid
	renderer.terrain_defs = terrain_defs

	var dir := DirAccess.open("res://")
	if not dir.dir_exists("screenshots/phase1"):
		dir.make_dir_recursive("screenshots/phase1")

	# Before
	var img_before := renderer.render_to_image()
	img_before.save_png("res://screenshots/phase1/destruction_before.png")
	print("Saved: destruction_before.png")

	# Attack at surface level (trees area), pointing right
	var size := grid.get_size()
	var origin := Vector2(size.x / 2 * 4, size.y * 0.3 * 4)
	var blade := BladeAttackClass.new()
	var freed := blade.execute(grid, origin, Vector2.RIGHT, 3.0, terrain_defs)
	print("Freed %d chunks" % freed)

	# After
	var img_after := renderer.render_to_image()
	img_after.save_png("res://screenshots/phase1/destruction_after.png")
	print("Saved: destruction_after.png")
	quit()


func _load_terrain_defs() -> Array[TerrainDef]:
	var defs: Array[TerrainDef] = []
	defs.resize(10)
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
	return defs
