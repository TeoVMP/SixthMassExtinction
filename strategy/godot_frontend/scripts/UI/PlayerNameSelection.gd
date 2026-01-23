# PlayerNameSelection.gd
# Diálogo de selección de nombre del jugador al inicio del juego
extends Control

signal player_name_selected(name: String)

var player_name: String = ""

func _ready():
	_setup_dialog()

func _setup_dialog() -> void:
	"""Configura el diálogo de selección de nombre"""
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Contenedor principal centrado
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.custom_minimum_size = Vector2(500, 300)
	main_container.add_theme_constant_override("separation", 20)
	main_container.add_theme_constant_override("margin_left", 20)
	main_container.add_theme_constant_override("margin_right", 20)
	main_container.add_theme_constant_override("margin_top", 20)
	main_container.add_theme_constant_override("margin_bottom", 20)
	add_child(main_container)
	
	# Título
	var title = Label.new()
	title.text = "SIXTH MASS EXTINCTION"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "INSURGENCIA TEMPORAL"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(subtitle)
	
	# Separador
	var separator = HSeparator.new()
	main_container.add_child(separator)
	
	# Instrucciones
	var instructions = Label.new()
	instructions.text = "Ingresa tu nombre de hacktivista:"
	instructions.add_theme_font_size_override("font_size", 16)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(instructions)
	
	# Input de nombre
	var name_input = LineEdit.new()
	name_input.placeholder_text = "Ej: Alexei Volkov"
	name_input.custom_minimum_size = Vector2(0, 40)
	name_input.add_theme_font_size_override("font_size", 16)
	name_input.text_submitted.connect(_on_name_submitted)
	main_container.add_child(name_input)
	# Nombre por defecto
	name_input.text = "Alexei Volkov"
	# Defer grab_focus until the node is in the tree and after a frame
	call_deferred("_grab_focus_deferred", name_input)
	
	# Botón confirmar
	var confirm_button = Button.new()
	confirm_button.text = "Confirmar"
	confirm_button.custom_minimum_size = Vector2(0, 40)
	confirm_button.pressed.connect(func(): _on_name_submitted(name_input.text))
	main_container.add_child(confirm_button)

func _grab_focus_deferred(input: LineEdit):
	"""Helper function to grab focus after node is in tree"""
	if input and is_instance_valid(input) and input.is_inside_tree():
		input.grab_focus()

func _on_name_submitted(name: String):
	"""Procesa el nombre ingresado"""
	var trimmed_name = name.strip_edges()
	if trimmed_name.is_empty():
		trimmed_name = "Alexei Volkov"
	
	player_name = trimmed_name
	player_name_selected.emit(player_name)
	
	# Guardar nombre en GameClient si existe
	var game_client = get_tree().root.find_child("GameClient", true, false)
	if game_client and game_client.has_method("set_player_name"):
		game_client.set_player_name(player_name)
	
	# Ocultar diálogo
	visible = false
	queue_free()
