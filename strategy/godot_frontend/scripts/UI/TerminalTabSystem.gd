# TerminalTabSystem.gd
# Sistema de pestañas para terminales múltiples
extends Control
class_name TerminalTabSystem

signal tab_closed(tab_id: String)
signal tab_selected(tab_id: String)
signal new_tab_requested()

var tabs: Dictionary = {}  # tab_id -> {button: Button, terminal: TerminalWindow}
var active_tab_id: String = ""
var tab_container: HBoxContainer = null
var tab_counter: int = 0

func _ready():
	_setup_tab_ui()

func _setup_tab_ui():
	"""Configura la UI de las pestañas"""
	tab_container = HBoxContainer.new()
	tab_container.name = "TabContainer"
	tab_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tab_container.set_offsets_preset(Control.PRESET_TOP_LEFT)
	tab_container.offset_left = 5
	tab_container.offset_top = 5
	tab_container.offset_right = -5
	tab_container.custom_minimum_size = Vector2(0, 30)
	tab_container.add_theme_constant_override("separation", 2)
	add_child(tab_container)

func create_tab(terminal_window: TerminalWindow, tab_id: String = "") -> String:
	"""Crea una nueva pestaña"""
	if tab_id == "":
		tab_counter += 1
		tab_id = "tab_" + str(tab_counter)
	
	# Crear botón de pestaña
	var tab_button = Button.new()
	tab_button.text = "Terminal " + str(tab_counter)
	tab_button.custom_minimum_size = Vector2(120, 25)
	tab_button.toggle_mode = true
	tab_button.button_pressed = true
	
	# Botón de cerrar
	var close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(20, 20)
	close_button.flat = true
	
	# Contenedor para botón y close
	var tab_content = HBoxContainer.new()
	tab_content.add_theme_constant_override("separation", 5)
	tab_content.add_child(tab_button)
	tab_content.add_child(close_button)
	
	tab_container.add_child(tab_content)
	
	# Conectar señales
	var captured_tab_id = tab_id
	tab_button.pressed.connect(func(): _on_tab_selected(captured_tab_id))
	close_button.pressed.connect(func(): _on_tab_close_requested(captured_tab_id))
	
	# Guardar referencia
	tabs[tab_id] = {
		"button": tab_button,
		"close_button": close_button,
		"content": tab_content,
		"terminal": terminal_window
	}
	
	# Si es la primera pestaña, activarla
	if tabs.size() == 1:
		active_tab_id = tab_id
		tab_button.button_pressed = true
	
	return tab_id

func _on_tab_selected(tab_id: String):
	"""Se llama cuando se selecciona una pestaña"""
	if not tabs.has(tab_id):
		return
	
	# Desactivar todas las pestañas
	for id in tabs:
		tabs[id].button.button_pressed = (id == tab_id)
		if tabs[id].terminal:
			tabs[id].terminal.visible = (id == tab_id)
	
	active_tab_id = tab_id
	tab_selected.emit(tab_id)
	
	# Enfocar la terminal activa
	if tabs[tab_id].terminal:
		tabs[tab_id].terminal.grab_focus()
		if tabs[tab_id].terminal.terminal_input:
			tabs[tab_id].terminal.terminal_input.grab_focus()

func _on_tab_close_requested(tab_id: String):
	"""Se llama cuando se solicita cerrar una pestaña"""
	if not tabs.has(tab_id):
		return
	
	# Si solo hay una pestaña, no cerrar
	if tabs.size() <= 1:
		return
	
	# Cerrar la terminal
	if tabs[tab_id].terminal:
		tabs[tab_id].terminal._close_terminal()
	
	# Eliminar pestaña
	tabs[tab_id].content.queue_free()
	tabs.erase(tab_id)
	
	# Si era la pestaña activa, activar otra
	if active_tab_id == tab_id:
		if tabs.size() > 0:
			var first_tab = tabs.keys()[0]
			_on_tab_selected(first_tab)
		else:
			active_tab_id = ""
	
	tab_closed.emit(tab_id)

func get_active_terminal() -> TerminalWindow:
	"""Obtiene la terminal activa"""
	if active_tab_id != "" and tabs.has(active_tab_id):
		return tabs[active_tab_id].terminal
	return null

func create_new_tab():
	"""Crea una nueva pestaña de terminal"""
	new_tab_requested.emit()







