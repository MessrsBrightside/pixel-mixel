# tests/

Headless test scripts. Run via `tests/run_all_tests.sh` or individually with `godot --headless --script <file>`.

- `test_chunk_grid.gd` — ChunkGrid data structure
- `test_pipeline.gd` — Plugin pipeline runner
- `test_terrain_defs.gd` — Terrain resource loading
- `test_chunk_simulator.gd` — Physics simulation
- `test_chunk_renderer.gd` — Rendering correctness
- `test_generation_plugins.gd` — Individual plugin behavior
- `test_integration.gd` — End-to-end determinism and invariants
- `test_snapshot.gd` — Visual regression (baseline PNG comparison)
- `baselines/` — Committed snapshot baselines
- `output/` — Test run output (gitignored)
