extends SceneTree

## Headless tests for ChunkSimulator physics simulation.

const ChunkGridClass = preload("res://scripts/chunk_grid.gd")
const ChunkSimulatorClass = preload("res://scripts/sim/chunk_simulator.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	# Test: loose chunk mid-air falls to bottom
	var grid = ChunkGridClass.new(5, 5)
	grid.set_chunk(Vector2i(2, 1), 1, 1, ChunkGridClass.State.LOOSE)
	var sim = ChunkSimulatorClass.new(42)
	sim.simulate_until_settled(grid)
	var fell = grid.get_chunk(Vector2i(2, 4))
	var origin = grid.get_chunk(Vector2i(2, 1))
	if fell.terrain == 1 and fell.state == ChunkGridClass.State.LOOSE and origin.terrain == 0:
		passed += 1
		print("PASS: loose chunk falls to bottom")
	else:
		failed += 1
		print("FAIL: loose chunk did not fall to bottom")

	# Test: loose chunk stacks on other loose chunks
	grid = ChunkGridClass.new(5, 5)
	grid.set_chunk(Vector2i(2, 0), 1, 1, ChunkGridClass.State.LOOSE)
	grid.set_chunk(Vector2i(2, 2), 2, 2, ChunkGridClass.State.LOOSE)
	sim = ChunkSimulatorClass.new(42)
	sim.simulate_until_settled(grid)
	var bottom = grid.get_chunk(Vector2i(2, 4))
	var stacked = grid.get_chunk(Vector2i(2, 3))
	if bottom.terrain == 2 and stacked.terrain == 1:
		passed += 1
		print("PASS: loose chunk stacks on other loose chunks")
	else:
		failed += 1
		print("FAIL: loose stacking — bottom=%s stacked=%s" % [str(bottom), str(stacked)])

	# Test: loose chunk stops at obstacle (static chunk below)
	grid = ChunkGridClass.new(5, 5)
	grid.set_chunk(Vector2i(2, 1), 1, 1, ChunkGridClass.State.LOOSE)
	grid.set_chunk(Vector2i(2, 3), 3, 3, ChunkGridClass.State.STATIC)
	sim = ChunkSimulatorClass.new(42)
	sim.simulate_until_settled(grid)
	var stopped = grid.get_chunk(Vector2i(2, 2))
	if stopped.terrain == 1 and stopped.state == ChunkGridClass.State.LOOSE:
		passed += 1
		print("PASS: loose chunk stops at obstacle")
	else:
		failed += 1
		print("FAIL: loose chunk did not stop at obstacle")

	# Test: liquid chunk falls then spreads
	grid = ChunkGridClass.new(5, 5)
	grid.set_chunk(Vector2i(2, 0), 4, 1, ChunkGridClass.State.LIQUID)
	grid.set_chunk(Vector2i(0, 4), 3, 3, ChunkGridClass.State.STATIC)
	grid.set_chunk(Vector2i(1, 4), 3, 3, ChunkGridClass.State.STATIC)
	grid.set_chunk(Vector2i(2, 4), 3, 3, ChunkGridClass.State.STATIC)
	grid.set_chunk(Vector2i(3, 4), 3, 3, ChunkGridClass.State.STATIC)
	grid.set_chunk(Vector2i(4, 4), 3, 3, ChunkGridClass.State.STATIC)
	sim = ChunkSimulatorClass.new(42)
	sim.simulate_until_settled(grid)
	# Liquid should have fallen to row 3 then potentially spread laterally
	var found_liquid := false
	for x in range(5):
		var c = grid.get_chunk(Vector2i(x, 3))
		if c.terrain == 4 and c.state == ChunkGridClass.State.LIQUID:
			found_liquid = true
			break
	if found_liquid:
		passed += 1
		print("PASS: liquid chunk falls then settles on row above floor")
	else:
		failed += 1
		print("FAIL: liquid not found on row 3")

	# Test: already settled grid returns 0 movement on first tick
	grid = ChunkGridClass.new(5, 5)
	grid.set_chunk(Vector2i(2, 4), 1, 1, ChunkGridClass.State.LOOSE)
	sim = ChunkSimulatorClass.new(42)
	var moved = sim.tick(grid)
	if not moved:
		passed += 1
		print("PASS: settled grid returns false on tick")
	else:
		failed += 1
		print("FAIL: settled grid reported movement")

	# Test: simulation terminates (doesn't infinite loop)
	grid = ChunkGridClass.new(10, 10)
	for x in range(10):
		grid.set_chunk(Vector2i(x, 0), 4, 1, ChunkGridClass.State.LIQUID)
	sim = ChunkSimulatorClass.new(42)
	var ticks = sim.simulate_until_settled(grid)
	if ticks < 10000:
		passed += 1
		print("PASS: simulation terminates in %d ticks" % ticks)
	else:
		failed += 1
		print("FAIL: simulation hit max_ticks")

	# Test: deterministic (same input = same output)
	var grid_a = ChunkGridClass.new(8, 8)
	var grid_b = ChunkGridClass.new(8, 8)
	for x in range(8):
		grid_a.set_chunk(Vector2i(x, 0), 4, 1, ChunkGridClass.State.LIQUID)
		grid_b.set_chunk(Vector2i(x, 0), 4, 1, ChunkGridClass.State.LIQUID)
	# Static floor
	for x in range(8):
		grid_a.set_chunk(Vector2i(x, 7), 3, 3, ChunkGridClass.State.STATIC)
		grid_b.set_chunk(Vector2i(x, 7), 3, 3, ChunkGridClass.State.STATIC)
	var sim_a = ChunkSimulatorClass.new(99)
	var sim_b = ChunkSimulatorClass.new(99)
	sim_a.simulate_until_settled(grid_a)
	sim_b.simulate_until_settled(grid_b)
	var identical := true
	for y in range(8):
		for x in range(8):
			var ca = grid_a.get_chunk(Vector2i(x, y))
			var cb = grid_b.get_chunk(Vector2i(x, y))
			if ca.terrain != cb.terrain or ca.state != cb.state:
				identical = false
				break
	if identical:
		passed += 1
		print("PASS: deterministic — same seed produces same result")
	else:
		failed += 1
		print("FAIL: non-deterministic output")

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()
