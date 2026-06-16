extends SceneTree

## Snapshot test: renders seed 42 world and compares to baseline PNG.

const WorldGeneratorClass = preload("res://scripts/world_generator.gd")
const ChunkRendererClass = preload("res://scripts/render/chunk_renderer.gd")
const BASELINE_PATH := "res://tests/baselines/snapshot_seed42.png"
const OUTPUT_PATH := "res://tests/output/snapshot_seed42.png"


func _init() -> void:
	var passed := 0
	var failed := 0

	# Generate world
	var gen := WorldGeneratorClass.new()
	var grid := gen.generate(42)

	# Render to image
	var renderer := ChunkRendererClass.new()
	renderer.grid = grid
	renderer.terrain_defs = _load_terrain_defs()
	var img := renderer.render_to_image()

	# Save output
	DirAccess.make_dir_recursive_absolute("res://tests/output")
	img.save_png(OUTPUT_PATH)
	print("Saved snapshot to %s" % OUTPUT_PATH)

	# Compare to baseline
	if FileAccess.file_exists(BASELINE_PATH):
		var baseline := Image.load_from_file(BASELINE_PATH)
		if baseline == null:
			failed += 1
			print("FAIL: could not load baseline image")
		elif baseline.get_size() != img.get_size():
			failed += 1
			print("FAIL: snapshot size differs from baseline")
		else:
			var differs := false
			for y in range(img.get_height()):
				for x in range(img.get_width()):
					if img.get_pixel(x, y) != baseline.get_pixel(x, y):
						differs = true
						break
				if differs:
					break
			if differs:
				failed += 1
				print("FAIL: snapshot differs from baseline")
			else:
				passed += 1
				print("PASS: snapshot matches baseline")
	else:
		# First run — save as baseline
		DirAccess.make_dir_recursive_absolute("res://tests/baselines")
		img.save_png(BASELINE_PATH)
		passed += 1
		print("PASS: baseline created (first run) at %s" % BASELINE_PATH)

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
	quit()


func _load_terrain_defs() -> Array[TerrainDef]:
	var defs: Array[TerrainDef] = []
	# Index 0 = null placeholder (empty terrain)
	defs.append(null)
	# Index 1 = dirt (TerrainFillPlugin layer 1)
	defs.append(load("res://resources/dirt.tres"))
	# Index 2 = water/stone (shared index in phase 0: fill uses 2 for stone, water uses 2 for liquid)
	defs.append(load("res://resources/water.tres"))
	return defs
