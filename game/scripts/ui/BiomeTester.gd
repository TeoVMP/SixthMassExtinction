extends Control
class_name BiomeTester

@onready var temporal_client = $TemporalClient
@onready var status_label = $Panel/VBoxContainer/StatusLabel
@onready var biomes_container = $Panel/VBoxContainer/BiomesContainer
@onready var action_buttons = $Panel/VBoxContainer/ActionsContainer

var current_biomes = []
var selected_biome_id = ""

func _ready():
	# Conectar señales
	temporal_client.connection_established.connect(_on_connection_established)
	temporal_client.biomes_loaded.connect(_on_biomes_loaded)
	temporal_client.simulation_completed.connect(_on_simulation_completed)
	temporal_client.error_occurred.connect(_on_error_occurred)
	
	status_label.text = "Connecting to server..."

func _on_connection_established(status):
	status_label.text = "Connected! Year: %d | Biomes: %d" % [status.current_year, status.total_biomes]
	
	# Cargar biomas automáticamente
	temporal_client.get_biomes()

func _on_biomes_loaded(biomes):
	current_biomes = biomes
	status_label.text = "Loaded %d biomes" % biomes.size()
	
	# Limpiar container
	for child in biomes_container.get_children():
		child.queue_free()
	
	# Crear botones para cada bioma
	for biome in biomes:
		var button = Button.new()
		button.text = "%s [%s]" % [biome.name, biome.type]
		button.custom_minimum_size = Vector2(250, 40)
		button.pressed.connect(_on_biome_selected.bind(biome.id))
		biomes_container.add_child(button)

func _on_biome_selected(biome_id):
	selected_biome_id = biome_id
	status_label.text = "Selected biome: %s" % biome_id
	
	# Mostrar acciones disponibles
	update_action_buttons()

func update_action_buttons():
	# Limpiar acciones
	for child in action_buttons.get_children():
		child.queue_free()
	
	if selected_biome_id == "":
		return
	
	# Crear botones de acción
	var actions = [
		{"name": "Protect", "action": "protect", "color": Color.GREEN},
		{"name": "Deforest", "action": "deforest", "color": Color.RED},
		{"name": "Pollute", "action": "pollute", "color": Color.ORANGE},
		{"name": "Clean Up", "action": "cleanup", "color": Color.CYAN},
	]
	
	for action_data in actions:
		var button = Button.new()
		button.text = action_data.name
		button.custom_minimum_size = Vector2(120, 40)
		button.add_theme_color_override("font_color", action_data.color)
		button.pressed.connect(_on_action_selected.bind(action_data.action))
		action_buttons.add_child(button)

func _on_action_selected(action):
	if selected_biome_id == "":
		return
	
	status_label.text = "Simulating %s on %s..." % [action, selected_biome_id]
	temporal_client.simulate_decision(selected_biome_id, action, 0.5, 2)

func _on_simulation_completed(result):
	status_label.text = "✅ " + result.message
	
	# Actualizar lista de biomas
	temporal_client.get_biomes()

func _on_error_occurred(error_message):
	status_label.text = "❌ Error: " + error_message