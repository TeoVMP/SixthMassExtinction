extends Control

@onready var temporal_client = $"../TemporalClient"
@onready var label = $Label

func _ready():
	# Conectar señales del TemporalClient
	temporal_client.connection_established.connect(_on_connected)
	temporal_client.biomes_loaded.connect(_on_biomes_loaded)
	temporal_client.simulation_completed.connect(_on_simulation_completed)
	temporal_client.error_occurred.connect(_on_error)
	
	# Esperar un momento antes de conectar
	await get_tree().create_timer(1.0).timeout
	label.text = "🔄 Connecting to Temporal Server..."
	temporal_client.test_connection()

func _on_connected(status_data: Dictionary):
	label.text = "✅ CONNECTED TO TEMPORAL SERVER!\n\n"
	label.text += "Version: %s\n" % status_data.get("version", "unknown")
	label.text += "Current Year: %d\n" % status_data.get("current_year", 2025)
	label.text += "Total Biomes: %d\n" % status_data.get("total_biomes", 0)
	label.text += "Total Species: %d\n\n" % status_data.get("total_species", 0)
	label.text += "🔄 Loading biomes..."
	
	# Cargar biomas después de 1 segundo
	await get_tree().create_timer(1.0).timeout
	temporal_client.get_biomes()

func _on_biomes_loaded(biomes: Array):
	label.text += " DONE!\n\n"
	label.text += "📋 AVAILABLE BIOMES (%d):\n" % biomes.size()
	
	# Mostrar primeros 4 biomas
	for i in range(min(4, biomes.size())):
		var biome = biomes[i]
		label.text += "  • %s\n" % biome.name
		label.text += "    Type: %s | Temp: %.1f°C\n" % [biome.type, biome.temperature]
		label.text += "    Biodiversity: %.2f | Species: %d\n\n" % [biome.biodiversity, biome.species_count]
	
	label.text += "\n🎮 Testing simulation in 3 seconds..."
	
	# Probar simulación después de 3 segundos
	await get_tree().create_timer(3.0).timeout
	label.text += "\n\n🔮 Simulating: PROTECT Amazon Rainforest..."
	temporal_client.simulate_decision("amazon", "protect", 0.7, 2)

func _on_simulation_completed(result: Dictionary):
	label.text += " SUCCESS!\n\n"
	label.text += "📊 SIMULATION RESULTS:\n"
	label.text += "  Message: %s\n" % result.get("message", "")
	label.text += "  Final Year: %d\n" % result.get("final_year", 0)
	label.text += "  Effects: %s\n\n" % str(result.get("effects", []))
	
	# Mostrar estado del bioma
	var biome_state = result.get("biome_state", {})
	if not biome_state.is_empty():
		label.text += "🌳 AMAZON STATE AFTER SIMULATION:\n"
		label.text += "  Biodiversity: %.3f\n" % biome_state.get("biodiversity", 0)
		label.text += "  Temperature: %.1f°C\n" % biome_state.get("temperature", 0)
		label.text += "  Air Quality: %.1f\n" % biome_state.get("air_quality", 0)
		label.text += "  Species Count: %d\n" % biome_state.get("species_count", 0)
	
	label.text += "\n\n✅ INTEGRATION TEST COMPLETE!"
	label.text += "\n🎮 Temporal Server + Godot = ✅ WORKING"

func _on_error(error_msg: String):
	label.text = "❌ ERROR: %s\n\n" % error_msg
	label.text += "Make sure:\n"
	label.text += "1. Go server is running: go run cmd/temporal_server_v2/main.go\n"
	label.text += "2. Server is on port 8081\n"
	label.text += "3. No firewall blocking the connection"
