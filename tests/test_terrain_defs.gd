extends SceneTree

## Headless tests for TerrainDef and LiquidDef resource definitions.

const TerrainDefClass = preload("res://scripts/terrain_def.gd")
const LiquidDefClass = preload("res://scripts/liquid_def.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# Test: dirt.tres loads with correct properties
	var dirt: Resource = load("res://resources/dirt.tres")
	if dirt != null and dirt is TerrainDefClass:
		if dirt.id == &"dirt" and dirt.display_name == "Dirt" and dirt.palette.size() >= 3 and dirt.density == 1.0:
			passed += 1
			print("PASS: dirt.tres loads with correct properties")
		else:
			failed += 1
			print("FAIL: dirt.tres properties incorrect — id:%s name:%s palette:%d density:%s" % [dirt.id, dirt.display_name, dirt.palette.size(), str(dirt.density)])
	else:
		failed += 1
		print("FAIL: dirt.tres failed to load or wrong type")

	# Test: stone.tres loads with correct properties
	var stone: Resource = load("res://resources/stone.tres")
	if stone != null and stone is TerrainDefClass:
		if stone.id == &"stone" and stone.display_name == "Stone" and stone.palette.size() >= 3 and stone.density == 2.5:
			passed += 1
			print("PASS: stone.tres loads with correct properties")
		else:
			failed += 1
			print("FAIL: stone.tres properties incorrect — id:%s name:%s palette:%d density:%s" % [stone.id, stone.display_name, stone.palette.size(), str(stone.density)])
	else:
		failed += 1
		print("FAIL: stone.tres failed to load or wrong type")

	# Test: water.tres loads as LiquidDef with correct properties
	var water: Resource = load("res://resources/water.tres")
	if water != null and water is LiquidDefClass:
		if water.id == &"water" and water.display_name == "Water" and water.palette.size() >= 3 and water.density == 1.0 and water.viscosity == 1.0 and water.transparency == 0.5:
			passed += 1
			print("PASS: water.tres loads as LiquidDef with correct properties")
		else:
			failed += 1
			print("FAIL: water.tres properties incorrect — id:%s viscosity:%s transparency:%s" % [water.id, str(water.viscosity), str(water.transparency)])
	else:
		failed += 1
		print("FAIL: water.tres failed to load or not LiquidDef")

	# Test: LiquidDef is a TerrainDef (Liskov substitution)
	if water != null and water is TerrainDefClass:
		passed += 1
		print("PASS: LiquidDef is-a TerrainDef (LSP)")
	else:
		failed += 1
		print("FAIL: LiquidDef is not a TerrainDef")

	# Test: palette colors are valid (non-black, non-white for terrain palettes)
	var all_palettes_valid := true
	for def in [dirt, stone, water]:
		if def != null:
			for color in def.palette:
				if color == Color.BLACK or color == Color.WHITE:
					all_palettes_valid = false
	if all_palettes_valid:
		passed += 1
		print("PASS: all palette colors are non-trivial")
	else:
		failed += 1
		print("FAIL: found BLACK or WHITE in terrain palettes")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
