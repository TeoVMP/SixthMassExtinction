extends Control
class_name BiomeUI

@onready var temporal_client = $TemporalClient

func _ready():
	temporal_client.connect("biomes_loaded", self, "_on_biomes_loaded")
	temporal_client.connect("world_updated", self, "_on_world_updated")
	
	# Cargar biomas al inicio
	temporal_client.get_biomes()

func _on_biomes_loaded(biomes: Array):
	print("Biomes loaded, creating buttons...")
	
	# Crear botón por cada bioma
	for biome in biomes:
		var button = Button.new()
		button.text = "%s (%s)" % [biome["name"], biome["type"]]
		button.custom_minimum_size = Vector2(200, 40)
		button.connect("pressed", self, "_on_biome_selected.bind(biome['id'])")
		$VBoxContainer.add_child(button)

func _on_biome_selected(biome_id: String):
	print("Selected biome: ", biome_id)
	# Mostrar acciones disponibles para este bioma

func _on_world_updated(world: Dictionary):
	print("World updated to year: ", world.get("Year", 2025))