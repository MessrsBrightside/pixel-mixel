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
echo 'ALL TESTS PASSED'
