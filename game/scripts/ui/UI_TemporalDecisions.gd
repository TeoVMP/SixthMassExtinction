extends Control
class_name UI_TemporalDecisions

# Referencia al GameManager (se asignará después)
var game_manager = null
var current_biome = null

# Acciones disponibles (mismo que antes)
var available_actions = [
	{
		"id": "protect",
		"name": "🛡️ Protect Ecosystem",
		"description": "Establish protected area, increase biodiversity",
		"sanity_cost": -5,
		"reputation_effects": {"scientists": 15, "activists": 10}
	},
	{
		"id": "deforest",
		"name": "🪓 Clear Forest",
		"description": "Clear land for agriculture/development",
		"sanity_cost": -15,
		"reputation_effects": {"oligarchs": 20, "activists": -25}
	},
	{
		"id": "pollute",
		"name": "☢️ Industrial Pollution",
		"description": "Allow industrial waste dumping",
		"sanity_cost": -25,
		"reputation_effects": {"oligarchs": 30, "scientists": -20, "global_south": -15}
	},
	{
		"id": "cleanup",
		"name": "🧹 Environmental Cleanup",
		"description": "Fund cleanup operations",
		"sanity_cost": 10,
		"reputation_effects": {"scientists": 10, "activists": 15, "global_south": 5}
	},
]

# Referencias a nodos que crearemos
var biome_name_label: Label
var biome_type_label: Label
var biome_temp_label: Label
var biome_bio_label: Label
var actions_container: VBoxContainer
var error_label: Label
var close_button: Button

func _ready():
	# Ocultar por defecto
	visible = false
	
	# Construir toda la UI por código
	_build_ui()
	
	# Conectar señal del botón close
	close_button.pressed.connect(_on_close_pressed)

# Construir toda la UI programáticamente
func _build_ui():
	# Configurar tamaño de este Control
	custom_minimum_size = Vector2(400, 600)
	
	# ===== CREAR PANEL PRINCIPAL =====
	var panel = Panel.new()
	panel.name = "Panel"
	add_child(panel)
	
	# Estilo del panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#1e1e2e")  # Gris oscuro
	panel_style.border_color = Color("#5e81ac")  # Azul
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# ===== CREAR CONTENEDOR PRINCIPAL =====
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	panel.add_child(main_container)
	
	# Configurar contenedor
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_theme_constant_override("separation", 15)
	
	# ===== CREAR LABELS DE INFORMACIÓN =====
	
	# 1. Nombre del bioma
	biome_name_label = Label.new()
	biome_name_label.name = "BiomeName"
	biome_name_label.text = "BIOME NAME"
	biome_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	biome_name_label.add_theme_font_size_override("font_size", 24)
	biome_name_label.add_theme_color_override("font_color", Color("#88c0d0"))
	main_container.add_child(biome_name_label)
	
	# 2. Tipo de bioma
	biome_type_label = Label.new()
	biome_type_label.name = "BiomeType"
	biome_type_label.text = "Type: Unknown"
	biome_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_type_label.add_theme_font_size_override("font_size", 18)
	biome_type_label.add_theme_color_override("font_color", Color("#a3be8c"))
	main_container.add_child(biome_type_label)
	
	# 3. Temperatura
	biome_temp_label = Label.new()
	biome_temp_label.name = "BiomeTemp"
	biome_temp_label.text = "Temperature: 0.0°C"
	biome_temp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_temp_label.add_theme_font_size_override("font_size", 18)
	biome_temp_label.add_theme_color_override("font_color", Color("#ebcb8b"))
	main_container.add_child(biome_temp_label)
	
	# 4. Biodiversidad
	biome_bio_label = Label.new()
	biome_bio_label.name = "BiomeBiodiversity"
	biome_bio_label.text = "Biodiversity: 0.00"
	biome_bio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_bio_label.add_theme_font_size_override("font_size", 18)
	biome_bio_label.add_theme_color_override("font_color", Color("#b48ead"))
	main_container.add_child(biome_bio_label)
	
	# ===== CREAR CONTENEDOR DE ACCIONES =====
	actions_container = VBoxContainer.new()
	actions_container.name = "ActionsContainer"
	actions_container.add_theme_constant_override("separation", 8)
	actions_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(actions_container)
	
	# ===== CREAR LABEL DE ERROR =====
	error_label = Label.new()
	error_label.name = "ErrorLabel"
	error_label.text = ""
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.add_theme_font_size_override("font_size", 14)
	error_label.add_theme_color_override("font_color", Color("#bf616a"))
	main_container.add_child(error_label)
	
	# ===== CREAR BOTÓN CERRAR =====
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "CLOSE"
	close_button.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Estilo del botón
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("#4c566a")
	button_style.corner_radius_top_left = 5
	button_style.corner_radius_top_right = 5
	button_style.corner_radius_bottom_left = 5
	button_style.corner_radius_bottom_right = 5
	close_button.add_theme_stylebox_override("normal", button_style)
	
	var button_hover = button_style.duplicate()
	button_hover.bg_color = Color("#5e81ac")
	close_button.add_theme_stylebox_override("hover", button_hover)
	
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.add_theme_color_override("font_color", Color("#d08770"))
	main_container.add_child(close_button)

# Inicializar con GameManager
func initialize(gm):
	game_manager = gm

# Mostrar UI para un bioma
func show_for_biome(biome_data: Dictionary):
	if not game_manager:
		push_error("GameManager not set")
		return
	
	current_biome = biome_data
	
	# Actualizar labels
	biome_name_label.text = biome_data.get("name", "Unknown").to_upper()
	biome_type_label.text = "Type: " + biome_data.get("type", "unknown")
	biome_temp_label.text = "Temperature: %.1f°C" % biome_data.get("temperature", 0.0)
	biome_bio_label.text = "Biodiversity: %.2f" % biome_data.get("biodiversity", 0.0)
	
	# Limpiar y crear botones de acción
	_clear_action_buttons()
	_create_action_buttons()
	
	# Limpiar mensaje de error
	error_label.text = ""
	error_label.add_theme_color_override("font_color", Color("#bf616a"))
	
	# Mostrar
	visible = true

# Crear botones de acción
func _create_action_buttons():
	for action in available_actions:
		var button = Button.new()
		button.text = "%s\n%s" % [action.name, action.description]
		button.custom_minimum_size = Vector2(350, 70)
		button.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.clip_text = true
		
		# Estilo basado en tipo de acción
		var action_style = StyleBoxFlat.new()
		action_style.corner_radius_top_left = 5
		action_style.corner_radius_top_right = 5
		action_style.corner_radius_bottom_left = 5
		action_style.corner_radius_bottom_right = 5
		
		match action.id:
			"protect", "cleanup":
				action_style.bg_color = Color("#2e3440")
				button.add_theme_color_override("font_color", Color("#a3be8c"))
			"deforest", "pollute":
				action_style.bg_color = Color("#2e3440")
				button.add_theme_color_override("font_color", Color("#bf616a"))
			_:
				action_style.bg_color = Color("#3b4252")
				button.add_theme_color_override("font_color", Color("#d8dee9"))
		
		button.add_theme_stylebox_override("normal", action_style)
		
		# Estilo hover
		var hover_style = action_style.duplicate()
		hover_style.bg_color = Color("#434c5e")
		button.add_theme_stylebox_override("hover", hover_style)
		
		# Conectar señal
		button.pressed.connect(_on_action_selected.bind(action))
		
		actions_container.add_child(button)

# Limpiar botones
func _clear_action_buttons():
	for child in actions_container.get_children():
		child.queue_free()

# Cuando se selecciona una acción
func _on_action_selected(action: Dictionary):
	if not game_manager or not current_biome:
		return
	
	# Verificar sanidad
	if game_manager.sanity + action.sanity_cost < 10:
		error_label.text = "❌ Insufficient sanity for this action"
		return
	
	# Aplicar costo de sanidad
	game_manager.apply_sanity_effect("temporal_decision", action.sanity_cost)
	
	# Aplicar reputación
	for faction in action.reputation_effects:
		var effect = action.reputation_effects[faction]
		if game_manager.global_reputation.has(faction):
			game_manager.global_reputation[faction] += effect
	
	# Ejecutar simulación
	print("Executing: %s on %s" % [action.name, current_biome.name])
	
	if game_manager.temporal_client:
		var magnitude = clamp(game_manager.sanity / 100.0, 0.3, 0.9)
		game_manager.temporal_client.simulate_decision(
			current_biome.id,
			action.id,
			magnitude,
			3  # 3 años
		)
	else:
		error_label.text = "❌ Temporal system offline"
	
	# Cerrar después de un momento
	await get_tree().create_timer(0.3).timeout
	visible = false
	_clear_action_buttons()

# Mostrar resultados
func show_simulation_result(result: Dictionary):
	# Si la UI no está visible, mostrarla primero
	if not visible:
		show_for_biome(current_biome if current_biome else {"name": "Results"})
	
	var result_text = "✅ Temporal Simulation Complete!\n\n"
	result_text += "Action: %s\n" % result.get("action", "unknown")
	result_text += "%s\n" % result.get("message", "")
	result_text += "New Timeline Year: %d\n\n" % result.get("final_year", 0)
	
	var effects = result.get("effects", [])
	if effects.size() > 0:
		result_text += "Effects:\n"
		for effect in effects:
			result_text += "• %s\n" % effect
	
	error_label.text = result_text
	error_label.add_theme_color_override("font_color", Color("#88c0d0"))

# Cerrar UI
func _on_close_pressed():
	visible = false
	_clear_action_buttons()
	current_biome = null

# Ajustar tamaño cuando cambia la ventana
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if has_node("Panel"):
			$Panel.size = size - Vector2(20, 20)
			$Panel.position = Vector2(10, 10)
