class_name BiomeRegistry
extends RefCounted

## Maps biome names to their generation plugin.

var _biomes: Dictionary = {}


func _init() -> void:
	_biomes["ocean_shore"] = OceanShoreBiome.new()
	_biomes["forest_surface"] = ForestSurfaceBiome.new()
	_biomes["forest_lake"] = ForestLakeBiome.new()
	_biomes["cave"] = CaveBiome.new()


func get_biome(biome_name: String) -> GenerationPlugin:
	return _biomes.get(biome_name)
