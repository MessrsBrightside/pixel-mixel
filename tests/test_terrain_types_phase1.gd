extends SceneTree

## Headless tests for phase 1 terrain types: toughness, passable, new resources.

const TerrainDefClass = preload("res://scripts/terrain_def.gd")
const LiquidDefClass = preload("res://scripts/liquid_def.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	var new_terrains := ["grass", "leaves", "wood", "sand", "mushroom", "cactus"]
	var expected_toughness := {
		"grass": 0.2, "leaves": 0.1, "wood": 0.6,
		"sand": 0.3, "mushroom": 0.1, "cactus": 0.5
	}
	var expected_passable := {
		"grass": true, "leaves": true, "wood": true,
		"sand": false, "mushroom": true, "cactus": true
	}

	# Test: all new resources load
	var all_load := true
	var loaded := {}
	for t in new_terrains:
		var res: Resource = load("res://resources/%s.tres" % t)
		if res == null or not (res is TerrainDefClass):
			all_load = false
			print("FAIL: %s.tres failed to load or wrong type" % t)
		else:
			loaded[t] = res
	if all_load:
		passed += 1
		print("PASS: all new terrain resources load")
	else:
		failed += 1

	# Test: toughness accessible and correct values
	var toughness_ok := true
	for t in new_terrains:
		if loaded.has(t):
			if not is_equal_approx(loaded[t].toughness, expected_toughness[t]):
				toughness_ok = false
				print("FAIL: %s toughness expected %s got %s" % [t, str(expected_toughness[t]), str(loaded[t].toughness)])
	if toughness_ok and loaded.size() == new_terrains.size():
		passed += 1
		print("PASS: toughness values correct for all new terrains")
	else:
		failed += 1

	# Test: passable property accessible and correct
	var passable_ok := true
	for t in new_terrains:
		if loaded.has(t):
			if loaded[t].passable != expected_passable[t]:
				passable_ok = false
				print("FAIL: %s passable expected %s got %s" % [t, str(expected_passable[t]), str(loaded[t].passable)])
	if passable_ok and loaded.size() == new_terrains.size():
		passed += 1
		print("PASS: passable values correct for all new terrains")
	else:
		failed += 1

	# Test: palettes have 4 colors each
	var palettes_ok := true
	for t in new_terrains:
		if loaded.has(t):
			if loaded[t].palette.size() != 4:
				palettes_ok = false
				print("FAIL: %s palette has %d colors (expected 4)" % [t, loaded[t].palette.size()])
	if palettes_ok and loaded.size() == new_terrains.size():
		passed += 1
		print("PASS: all new terrains have 4-color palettes")
	else:
		failed += 1

	# Test: existing resources still load with new properties
	var dirt: Resource = load("res://resources/dirt.tres")
	var stone: Resource = load("res://resources/stone.tres")
	var water: Resource = load("res://resources/water.tres")
	var existing_ok := true
	if dirt == null or not (dirt is TerrainDefClass):
		existing_ok = false
		print("FAIL: dirt.tres failed to load")
	elif not is_equal_approx(dirt.toughness, 0.5) or dirt.passable != false:
		existing_ok = false
		print("FAIL: dirt.tres toughness/passable incorrect")
	if stone == null or not (stone is TerrainDefClass):
		existing_ok = false
		print("FAIL: stone.tres failed to load")
	elif not is_equal_approx(stone.toughness, 1.0) or stone.passable != false:
		existing_ok = false
		print("FAIL: stone.tres toughness/passable incorrect")
	if water == null or not (water is LiquidDefClass):
		existing_ok = false
		print("FAIL: water.tres failed to load")
	elif not is_equal_approx(water.toughness, 0.0) or water.passable != true:
		existing_ok = false
		print("FAIL: water.tres toughness/passable incorrect")
	if existing_ok:
		passed += 1
		print("PASS: existing resources (dirt/stone/water) load with correct toughness/passable")
	else:
		failed += 1

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
