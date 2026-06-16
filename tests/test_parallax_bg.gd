extends SceneTree

## Functional tests for ParallaxBG: setup per biome, fallback, layer count.

const ParallaxBGClass = preload("res://scripts/render/parallax_bg.gd")


func _init() -> void:
	var passed := 0
	var failed := 0
	var biomes := ["ocean_shore", "forest_surface", "forest_lake", "cave", "desert"]

	# --- Test: setup doesn't crash for each biome ---
	var all_ok := true
	for biome_name in biomes:
		var bg := ParallaxBGClass.new()
		bg.setup(biome_name)
		if bg.get_child_count() == 0:
			all_ok = false
			print("FAIL: setup produced no layers for %s" % biome_name)
		bg.free()
	if all_ok:
		passed += 1
		print("PASS: setup doesn't crash for each biome")
	else:
		failed += 1

	# --- Test: unknown biome falls back to default without crash ---
	var bg_unknown := ParallaxBGClass.new()
	bg_unknown.setup("nonexistent_biome")
	if bg_unknown.get_child_count() > 0:
		passed += 1
		print("PASS: unknown biome falls back to default without crash")
	else:
		failed += 1
		print("FAIL: unknown biome produced no layers")
	bg_unknown.free()

	# --- Test: parallax node has at least one layer after setup ---
	var bg_layers := ParallaxBGClass.new()
	bg_layers.setup("ocean_shore")
	var has_layer := false
	for child in bg_layers.get_children():
		if child is ParallaxLayer:
			has_layer = true
			break
	if has_layer:
		passed += 1
		print("PASS: parallax node has at least one ParallaxLayer after setup")
	else:
		failed += 1
		print("FAIL: no ParallaxLayer found after setup")
	bg_layers.free()

	# --- Test: cave has only 1 layer (no silhouette) ---
	var bg_cave := ParallaxBGClass.new()
	bg_cave.setup("cave")
	var cave_layers := 0
	for child in bg_cave.get_children():
		if child is ParallaxLayer:
			cave_layers += 1
	if cave_layers == 1:
		passed += 1
		print("PASS: cave has 1 layer (no silhouette)")
	else:
		failed += 1
		print("FAIL: cave has %d layers, expected 1" % cave_layers)
	bg_cave.free()

	# --- Test: non-cave biomes have 2 layers ---
	var bg_ocean := ParallaxBGClass.new()
	bg_ocean.setup("ocean_shore")
	var ocean_layers := 0
	for child in bg_ocean.get_children():
		if child is ParallaxLayer:
			ocean_layers += 1
	if ocean_layers == 2:
		passed += 1
		print("PASS: ocean_shore has 2 layers (gradient + silhouette)")
	else:
		failed += 1
		print("FAIL: ocean_shore has %d layers, expected 2" % ocean_layers)
	bg_ocean.free()

	# --- Summary ---
	print("")
	print("%d passed, %d failed" % [passed, failed])
	if failed > 0:
		print("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	quit()
