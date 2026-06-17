#!/bin/bash
set -e
godot --headless --script tests/test_chunk_grid.gd
godot --headless --script tests/test_pipeline.gd
godot --headless --script tests/test_terrain_defs.gd
godot --headless --script tests/test_terrain_types_phase1.gd
godot --headless --script tests/test_chunk_simulator.gd
godot --headless --script tests/test_chunk_renderer.gd
godot --headless --script tests/test_generation_plugins.gd
godot --headless --script tests/test_integration.gd
godot --headless --script tests/test_player.gd
godot --headless --script tests/test_snapshot.gd
godot --headless --script tests/test_parallax_bg.gd
godot --headless --script tests/test_ocean_shore_biome.gd
godot --headless --script tests/test_forest_surface_biome.gd
godot --headless --script tests/test_forest_lake_biome.gd
godot --headless --script tests/test_cave_biome.gd
godot --headless --script tests/test_desert_biome.gd
godot --headless --script tests/test_safe_spawn.gd
godot --headless --script tests/test_grass_layers.gd
godot --headless --script tests/test_loose_chunk_body.gd
echo 'ALL TESTS PASSED'
