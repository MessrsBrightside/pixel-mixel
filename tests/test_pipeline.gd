extends SceneTree

## Headless tests for GenerationPlugin and PipelineRunner.


func _init() -> void:
	var passed := 0
	var failed := 0

	# Test: empty pipeline produces unchanged grid
	var grid := ChunkGrid.new(8, 8)
	var runner := PipelineRunner.new()
	runner.run(grid, 42)
	var chunk = grid.get_chunk(Vector2i(0, 0))
	if chunk.terrain == 0 and chunk.color == 0 and chunk.state == 0:
		passed += 1
		print("PASS: empty pipeline produces unchanged grid")
	else:
		failed += 1
		print("FAIL: empty pipeline modified grid: %s" % str(chunk))

	# Test: no-op plugin doesn't modify grid
	grid = ChunkGrid.new(8, 8)
	runner = PipelineRunner.new()
	runner.add_plugin(GenerationPlugin.new())
	runner.run(grid, 42)
	chunk = grid.get_chunk(Vector2i(0, 0))
	if chunk.terrain == 0 and chunk.color == 0 and chunk.state == 0:
		passed += 1
		print("PASS: no-op plugin doesn't modify grid")
	else:
		failed += 1
		print("FAIL: no-op plugin modified grid: %s" % str(chunk))

	# Test: plugins execute in order (last wins)
	grid = ChunkGrid.new(8, 8)
	runner = PipelineRunner.new()
	var plugin_a := _make_writer_plugin(1)
	var plugin_b := _make_writer_plugin(2)
	runner.add_plugin(plugin_a)
	runner.add_plugin(plugin_b)
	runner.run(grid, 42)
	chunk = grid.get_chunk(Vector2i(0, 0))
	if chunk.terrain == 2:
		passed += 1
		print("PASS: plugins execute in order (last wins)")
	else:
		failed += 1
		print("FAIL: expected terrain=2, got %d" % chunk.terrain)

	# Test: same seed = same result (determinism)
	grid = ChunkGrid.new(8, 8)
	runner = PipelineRunner.new()
	runner.add_plugin(_make_rng_plugin())
	runner.run(grid, 99)
	var first_result: int = grid.get_chunk(Vector2i(0, 0)).terrain

	grid = ChunkGrid.new(8, 8)
	runner = PipelineRunner.new()
	runner.add_plugin(_make_rng_plugin())
	runner.run(grid, 99)
	var second_result: int = grid.get_chunk(Vector2i(0, 0)).terrain

	if first_result == second_result:
		passed += 1
		print("PASS: same seed = same result (%d)" % first_result)
	else:
		failed += 1
		print("FAIL: same seed gave %d vs %d" % [first_result, second_result])

	# Test: different seed = different result
	grid = ChunkGrid.new(8, 8)
	runner = PipelineRunner.new()
	runner.add_plugin(_make_rng_plugin())
	runner.run(grid, 1)
	var result_a: int = grid.get_chunk(Vector2i(0, 0)).terrain

	grid = ChunkGrid.new(8, 8)
	runner = PipelineRunner.new()
	runner.add_plugin(_make_rng_plugin())
	runner.run(grid, 2)
	var result_b: int = grid.get_chunk(Vector2i(0, 0)).terrain

	if result_a != result_b:
		passed += 1
		print("PASS: different seed = different result (%d vs %d)" % [result_a, result_b])
	else:
		failed += 1
		print("FAIL: different seeds gave same result (%d)" % result_a)

	# Summary
	print("")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")

	quit()


func _make_writer_plugin(value: int) -> GenerationPlugin:
	var script := GDScript.new()
	script.source_code = """extends GenerationPlugin
var terrain_value: int
func execute(grid: ChunkGrid, params: Dictionary) -> void:
	grid.set_chunk(Vector2i(0, 0), terrain_value, 0, 0)
"""
	script.reload()
	var plugin = script.new()
	plugin.terrain_value = value
	return plugin


func _make_rng_plugin() -> GenerationPlugin:
	var script := GDScript.new()
	script.source_code = """extends GenerationPlugin
func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var rng: RandomNumberGenerator = params["rng"]
	grid.set_chunk(Vector2i(0, 0), rng.randi_range(1, 255), 0, 0)
"""
	script.reload()
	return script.new()
