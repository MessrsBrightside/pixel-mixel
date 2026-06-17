class_name DesertBiome
extends GenerationPlugin

## Generates desert biome: sand dunes, stone underground, cactus, sparse dead grass.

const STONE := 2
const GRASS := 4
const SAND := 7
const CACTUS := 9


func execute(grid: ChunkGrid, params: Dictionary) -> void:
	var size := grid.get_size()
	var rng: RandomNumberGenerator = params["rng"]

	# Compute dune surface using layered sine (noise-like rolling hills)
	var base_y := int(size.y * 0.55)
	var surface: Array[int] = []
	surface.resize(size.x)
	for x in range(size.x):
		var n := sin(x * 0.02) * 8.0 + sin(x * 0.05) * 4.0 + sin(x * 0.007) * 12.0
		surface[x] = base_y + int(n)

	# Fill terrain: sand from surface down 15-20, then stone to bottom
	var sand_depth := 17
	for x in range(size.x):
		var sy := surface[x]
		for y in range(sy, mini(sy + sand_depth, size.y)):
			grid.set_chunk(Vector2i(x, y), SAND, 0, ChunkGrid.State.LOOSE)
		for y in range(sy + sand_depth, size.y):
			grid.set_chunk(Vector2i(x, y), STONE, 0, ChunkGrid.State.STATIC)

	# Cactus: every 40-70 chunks, 3 wide body 6-10 tall with arms
	var next_cactus := rng.randi_range(40, 70)
	while next_cactus < size.x:
		var height := rng.randi_range(6, 10)
		var sy := surface[next_cactus]
		var body_w := 3
		var half_body := body_w / 2
		# Main body: 3 wide
		for i in range(height):
			var cy := sy - 1 - i
			if cy >= 0:
				for bx in range(next_cactus - half_body, next_cactus + half_body + 1):
					if bx >= 0 and bx < size.x:
						grid.set_chunk(Vector2i(bx, cy), CACTUS, 0, ChunkGrid.State.STATIC)
		# Arms: 2 wide, extend 3-4 out from body at varied heights
		var num_arms := rng.randi_range(1, 3)
		for _a in range(num_arms):
			var arm_y := sy - 1 - rng.randi_range(2, height - 2)
			var arm_dir := -1 if rng.randf() < 0.5 else 1
			var arm_len := rng.randi_range(3, 4)
			for ai in range(1, arm_len + 1):
				var ax := next_cactus + arm_dir * (half_body + ai)
				if ax >= 0 and ax < size.x:
					grid.set_chunk(Vector2i(ax, arm_y), CACTUS, 0, ChunkGrid.State.STATIC)
					if arm_y - 1 >= 0:
						grid.set_chunk(Vector2i(ax, arm_y - 1), CACTUS, 0, ChunkGrid.State.STATIC)
		next_cactus += rng.randi_range(40, 70)

	# Sparse dead grass on surface
	for x in range(size.x):
		if rng.randf() < 0.03:
			var gy := surface[x] - 1
			if gy >= 0:
				grid.set_chunk(Vector2i(x, gy), GRASS, 0, ChunkGrid.State.STATIC)
