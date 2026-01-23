# TerminalWindow.gd
# Ventana de terminal individual con funcionalidad de minimizar, maximizar y cerrar
extends Window
class_name TerminalWindow

signal terminal_closed(terminal_id: String)
signal terminal_minimized(terminal_id: String)
signal terminal_maximized(terminal_id: String, maximized: bool)

const BACKEND_URL = "http://localhost:8080/rpc"

var terminal_id: String = ""
var scenario: String = ""
var is_maximized: bool = false
var normal_size: Vector2i
var normal_position: Vector2i

var terminal_output: TextEdit
var terminal_input: LineEdit  # Mantener invisible para capturar input
var current_input_line: int = 0  # Línea donde está el input actual
var prompt_text: String = "6me@shell:~$ "
var command_history: Array = []
var history_index: int = -1
var pending_requests: Dictionary = {}  # request_id -> HTTPRequest
var using_docker: bool = false
var is_msfconsole_session: bool = false  # Indica si estamos en una sesión interactiva de msfconsole
var maximize_button: Button = null  # Referencia al botón de maximizar

# Autocompletado
var autocomplete_matches: Array = []
var autocomplete_index: int = -1
var last_autocomplete_query: String = ""

# Sistema de pestañas
var tabs_container: HBoxContainer = null
var tabs: Dictionary = {}  # tab_id -> {button: Button, close_button: Button, terminal_panel: Control}
var active_tab_id: String = ""
var tab_counter: int = 0

# Panel de hints
var hints_window: Window = null
var hints_window_visible: bool = false

# Sistema de streaming
var stream_request: HTTPRequest = null
var command_running: bool = false
var current_command: String = ""
var last_output_index: int = 0

func _init():
	# Configurar ventana
	title = "6ME Shell"
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	size = Vector2i(900, 650)
	normal_size = size
	normal_position = position
	
	# Permitir redimensionar
	mode = Window.MODE_WINDOWED
	always_on_top = false
	
	# Estilo de ventana - tema cyberpunk/post-apocalíptico
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var window_style = StyleBoxFlat.new()
	if CyberpunkThemeClass:
		window_style = CyberpunkThemeClass.create_terminal_panel_style()
	else:
		window_style.bg_color = Color(0.0, 0.0, 0.0, 0.98)
		window_style.border_color = Color(0.0, 1.0, 0.4)
		window_style.border_width_left = 2
		window_style.border_width_right = 2
		window_style.border_width_top = 2
		window_style.border_width_bottom = 2
	
	# Conectar señales de ventana
	close_requested.connect(_on_close_requested)

func _ready():
	print("[TerminalWindow] _ready() llamado")
	_setup_terminal_ui()
	_setup_backend_connection()
	_check_terminal_status()
	
	# NO llamar _show_window aquí - se llamará desde TerminalManager
	print("[TerminalWindow] Ventana configurada")

func _show_window():
	"""Muestra la ventana - llamado con call_deferred para asegurar que funcione"""
	print("[TerminalWindow] _show_window() llamado")
	print("[TerminalWindow] Terminal ID: ", terminal_id)
	print("[TerminalWindow] Scenario: ", scenario)
	print("[TerminalWindow] Visible antes: ", visible)
	print("[TerminalWindow] En árbol: ", is_inside_tree())
	
	# Asegurar que esté en el árbol antes de mostrar
	if not is_inside_tree():
		print("[TerminalWindow] No está en el árbol, no se puede mostrar")
		return
	
	# Mostrar la ventana
	popup_centered()
	visible = true
	show()
	
	print("[TerminalWindow] Ventana visible después: ", visible)
	print("[TerminalWindow] Ventana position: ", position)
	print("[TerminalWindow] Ventana size: ", size)
	print("[TerminalWindow] En árbol después: ", is_inside_tree())

func _setup_terminal_ui():
	"""Configura la UI de la terminal"""
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Contenedor principal
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 0)
	main_container.mouse_filter = Control.MOUSE_FILTER_PASS  # Permitir que los eventos pasen a los hijos
	add_child(main_container)
	
	# Barra de título personalizada
	var title_bar = _create_title_bar()
	main_container.add_child(title_bar)
	
	# Sistema de pestañas
	_setup_tabs_system()
	main_container.add_child(tabs_container)
	
	# Panel de terminal - Estilo cyberpunk profesional
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var terminal_panel = Panel.new()
	terminal_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var terminal_style: StyleBoxFlat
	if CyberpunkThemeClass:
		terminal_style = CyberpunkThemeClass.create_terminal_panel_style()
	else:
		terminal_style = StyleBoxFlat.new()
		terminal_style.bg_color = Color(0.0, 0.0, 0.0)
		terminal_style.border_color = Color(0.0, 1.0, 1.0)
		terminal_style.border_width_left = 1
		terminal_style.border_width_right = 1
		terminal_style.border_width_top = 1
		terminal_style.border_width_bottom = 1
	terminal_panel.add_theme_stylebox_override("panel", terminal_style)
	main_container.add_child(terminal_panel)
	
	var terminal_vbox = VBoxContainer.new()
	terminal_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	terminal_vbox.add_theme_constant_override("margin_left", 10)
	terminal_vbox.add_theme_constant_override("margin_right", 10)
	terminal_vbox.add_theme_constant_override("margin_top", 10)
	terminal_vbox.add_theme_constant_override("margin_bottom", 10)
	terminal_panel.add_child(terminal_vbox)
	
	# Terminal unificada: output e input en un solo TextEdit (como terminal real)
	terminal_output = TextEdit.new()
	terminal_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	terminal_output.editable = true  # Permitir edición para el input
	terminal_output.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	var terminal_color = CyberpunkThemeClass.COLOR_NEON_GREEN if CyberpunkThemeClass else Color(0.0, 1.0, 0.4)
	terminal_output.add_theme_color_override("font_color", terminal_color)
	terminal_output.add_theme_color_override("background_color", Color(0.0, 0.0, 0.0))
	terminal_output.add_theme_color_override("font_selected_color", Color(0.0, 0.0, 0.0))
	terminal_output.add_theme_color_override("selection_color", Color(0.2, 0.8, 1.0))
	terminal_output.selecting_enabled = true
	terminal_output.context_menu_enabled = true
	terminal_output.gui_input.connect(_on_terminal_unified_input)
	terminal_output.text_changed.connect(_on_terminal_text_changed)
	# Prevenir edición de líneas anteriores usando set_line_readonly
	terminal_vbox.add_child(terminal_output)
	
	# Input invisible para capturar comandos (se mostrará en el TextEdit)
	terminal_input = LineEdit.new()
	terminal_input.visible = false  # Invisible, solo para capturar input
	terminal_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terminal_input.text_submitted.connect(_on_command_submitted)
	terminal_input.gui_input.connect(_on_terminal_input_gui_input)
	terminal_input.shortcut_keys_enabled = true
	terminal_input.focus_entered.connect(_on_input_focus_entered)
	terminal_input.focus_exited.connect(_on_input_focus_exited)
	terminal_vbox.add_child(terminal_input)
	
	# Inicializar línea de input
	current_input_line = 0
	
	# Asegurar que el input tenga focus inicial
	call_deferred("_do_restore_focus")
	
	# Mensaje de bienvenida
	_initialize_terminal()
	
	# Crear primera pestaña (pestaña principal)
	active_tab_id = "main"
	tabs["main"] = {
		"button": null,
		"close_button": null,
		"content": null,
		"panel": terminal_panel,
		"terminal_id": terminal_id,
		"terminal_output": terminal_output,
		"terminal_input": terminal_input,
		"command_history": command_history,
		"history_index": history_index
	}

func _create_title_bar() -> Control:
	"""Crea una barra de título personalizada con botones - Estilo hacker"""
	var title_bar = HBoxContainer.new()
	title_bar.custom_minimum_size = Vector2(0, 35)
	
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var title_style = StyleBoxFlat.new()
	var title_bg_color = CyberpunkThemeClass.COLOR_BG_SECONDARY if CyberpunkThemeClass else Color(0.05, 0.1, 0.05)
	title_style.bg_color = title_bg_color
	var title_border_color = CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 1.0)
	title_style.border_color = title_border_color
	title_style.border_width_bottom = 1
	title_style.shadow_color = Color(0.0, 1.0, 1.0, 0.15)
	title_style.shadow_size = 3
	title_bar.add_theme_stylebox_override("panel", title_style)
	
	# Botón Hints (lado izquierdo, opuesto al botón cerrar)
	var hints_button = Button.new()
	hints_button.text = "Hints"
	hints_button.custom_minimum_size = Vector2(60, 35)
	var hints_style = StyleBoxFlat.new()
	hints_style.bg_color = Color(0.1, 0.1, 0.2)
	hints_style.border_color = Color(0.4, 0.4, 1.0)
	hints_style.border_width_left = 1
	hints_style.border_width_right = 1
	hints_style.border_width_top = 1
	hints_style.border_width_bottom = 1
	hints_button.add_theme_stylebox_override("normal", hints_style)
	hints_button.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	hints_button.pressed.connect(_on_hints_pressed)
	title_bar.add_child(hints_button)
	
	# Título con estilo terminal cyberpunk profesional
	var title_label = Label.new()
	title_label.text = "┌─ 6ME SHELL ────────────────────────────────"
	var title_text_color = CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 1.0)
	title_label.add_theme_color_override("font_color", title_text_color)
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(title_label)
	
	# Asegurar que la barra de título esté por encima de otros elementos
	title_bar.z_index = 100
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP  # Asegurar que reciba eventos
	
	# Botón minimizar
	var min_button = Button.new()
	min_button.text = "─"
	min_button.custom_minimum_size = Vector2(35, 35)
	var min_style = StyleBoxFlat.new()
	min_style.bg_color = Color(0.1, 0.15, 0.1)
	min_style.border_color = Color(0.0, 0.6, 0.0)
	min_style.border_width_left = 1
	min_style.border_width_right = 1
	min_style.border_width_top = 1
	min_style.border_width_bottom = 1
	min_button.add_theme_stylebox_override("normal", min_style)
	min_button.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	min_button.pressed.connect(_on_minimize_pressed)
	title_bar.add_child(min_button)
	
	# Botón maximizar/restaurar
	maximize_button = Button.new()
	maximize_button.name = "maximize_button"
	maximize_button.text = "□"
	maximize_button.custom_minimum_size = Vector2(35, 35)
	maximize_button.add_theme_stylebox_override("normal", min_style)
	maximize_button.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	maximize_button.pressed.connect(_on_maximize_pressed)
	title_bar.add_child(maximize_button)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(35, 35)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.15, 0.05, 0.05)
	close_style.border_color = Color(1.0, 0.2, 0.2)
	close_style.border_width_left = 1
	close_style.border_width_right = 1
	close_style.border_width_top = 1
	close_style.border_width_bottom = 1
	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	close_button.pressed.connect(_on_close_pressed)
	title_bar.add_child(close_button)
	
	return title_bar

func _setup_backend_connection():
	"""Configura la conexión con el backend"""
	# Ya no necesitamos un HTTPRequest global, se crean por petición
	pass

func _initialize_terminal():
	"""Inicializa la terminal con mensaje de bienvenida"""
	_add_terminal_output("═══════════════════════════════════════════════════════")
	_add_terminal_output("6ME OS - SIXTH MASS EXTINCTION")
	_add_terminal_output("═══════════════════════════════════════════════════════")
	_add_terminal_output("")
	_add_terminal_output("Shell ID: " + terminal_id)
	# Solo mostrar escenario si hay una misión activa
	var mission_manager = get_node_or_null("/root/UI_Main/MissionManager")
	if mission_manager and scenario != "":
		var active_missions = mission_manager.get("active_missions") as Array
		if active_missions and active_missions.size() > 0:
			_add_terminal_output("Escenario: " + scenario)
	_add_terminal_output("")
	_add_terminal_output("Herramientas disponibles:")
	_add_terminal_output("  - nmap, metasploit, wireshark, aircrack-ng")
	_add_terminal_output("  - hydra, sqlmap, y todas las herramientas de Kali Linux")
	_add_terminal_output("")
	_add_terminal_output("Escribe 'help' para ver comandos disponibles")
	_add_terminal_output("")
	_add_terminal_output("═══════════════════════════════════════════════════════")
	_add_terminal_output("")
	# Agregar prompt inicial
	_update_input_prompt()
	# Dar focus al input invisible para capturar teclado
	terminal_input.grab_focus()

func _append_to_terminal(output_control: Control, text: String, color: Color = Color(0.0, 1.0, 0.4)):
	"""Helper para agregar texto a un control de terminal (TextEdit o RichTextLabel)"""
	if output_control is TextEdit:
		var text_edit = output_control as TextEdit
		text_edit.text += text
	elif output_control is RichTextLabel:
		var rich_label = output_control as RichTextLabel
		var color_hex = "#%02x%02x%02x" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]
		rich_label.append_text("[color=" + color_hex + "]" + text + "[/color]")

func _add_terminal_output(text: String, color: Color = Color(0.0, 1.0, 0.4)):
	"""Añade texto al output de la terminal (unificado en TextEdit)"""
	if terminal_output:
		# Detectar si el texto contiene "msf6 >" para cambiar el prompt
		if text.contains("msf6 >"):
			is_msfconsole_session = true
			prompt_text = "msf6 > "
		# Detectar si el texto contiene comandos que salen de msfconsole
		elif text.contains("exit") or text.contains("quit") or text.contains("back"):
			# Verificar si estamos saliendo de msfconsole
			if is_msfconsole_session:
				# Esperar un poco para ver si realmente salimos
				# (esto se manejará cuando se agregue el siguiente prompt)
				pass
		
		# TextEdit no soporta BBCode, solo texto plano
		# Agregar texto al final
		var current_text = terminal_output.text
		terminal_output.text = current_text + text + "\n"
		# Actualizar línea de input
		current_input_line = terminal_output.get_line_count() - 1
		# Mover cursor al final
		terminal_output.set_caret_line(current_input_line)
		terminal_output.set_caret_column(terminal_output.get_line(current_input_line).length())
		# Mostrar prompt en la nueva línea
		_update_input_prompt()

func _on_command_submitted(command: String):
	"""Procesa un comando de la terminal"""
	if command.strip_edges().is_empty():
		_update_input_prompt()
		return
	
	# Detectar comandos que salen de msfconsole
	if is_msfconsole_session and (command == "exit" or command == "quit" or command == "back"):
		is_msfconsole_session = false
		prompt_text = "6me@shell:~$ "
	
	# Añadir comando al historial
	command_history.append(command)
	history_index = command_history.size()
	
	# Reemplazar la línea de input actual con el comando ejecutado
	_replace_input_line(prompt_text + command)
	
	# Agregar nueva línea para el output
	terminal_output.text += "\n"
	current_input_line = terminal_output.get_line_count()
	
	# Limpiar input invisible
	terminal_input.text = ""
	
	# Ejecutar comando
	_execute_command(command)
	
	# Restaurar focus y mostrar nuevo prompt
	_restore_focus()
	_update_input_prompt()

func _restore_focus():
	"""Restaura el focus en el input después de ejecutar un comando"""
	# En terminal unificada, el focus va al TextEdit
	if terminal_output and terminal_output.is_inside_tree():
		call_deferred("_do_restore_focus")
	elif terminal_input and terminal_input.is_inside_tree():
		call_deferred("_do_restore_focus")

func _do_restore_focus():
	"""Realiza el restore del focus (llamado con call_deferred)"""
	# Si hay pestañas activas, usar el input de la pestaña activa
	if active_tab_id != "" and tabs.has(active_tab_id):
		if tabs[active_tab_id].has("terminal_output") and tabs[active_tab_id].terminal_output:
			var tab_output = tabs[active_tab_id].terminal_output
			if tab_output and tab_output.is_inside_tree():
				tab_output.grab_focus()
				# Mover cursor a la línea de input
				var line_count = tab_output.get_line_count()
				if line_count > 0:
					tab_output.set_caret_line(line_count - 1)
					tab_output.set_caret_column(tab_output.get_line(line_count - 1).length())
				return
		elif tabs[active_tab_id].has("terminal_input") and tabs[active_tab_id].terminal_input:
			var tab_input = tabs[active_tab_id].terminal_input
			if tab_input and tab_input.is_inside_tree():
				tab_input.grab_focus()
				tab_input.caret_column = tab_input.text.length()
				return
	
	# Si no hay pestañas, usar el TextEdit principal
	if terminal_output and terminal_output.is_inside_tree():
		terminal_output.grab_focus()
		# Mover cursor a la línea de input
		if terminal_output.get_line_count() > current_input_line:
			terminal_output.set_caret_line(current_input_line)
			terminal_output.set_caret_column(terminal_output.get_line(current_input_line).length())
		# También dar focus al input invisible para capturar teclado
		if terminal_input and terminal_input.is_inside_tree():
			terminal_input.grab_focus()
		return
	
	# Fallback al input invisible
	if terminal_input and terminal_input.is_inside_tree():
		terminal_input.grab_focus()
		terminal_input.caret_column = terminal_input.text.length()
		# Forzar que el input acepte input
		terminal_input.set_process_mode(Node.PROCESS_MODE_INHERIT)
		# Asegurar que la ventana también tenga focus
		if is_inside_tree():
			grab_focus()

func _on_input_focus_entered():
	"""Se llama cuando el input recibe focus"""
	pass

func _on_input_focus_exited():
	"""Se llama cuando el input pierde focus - restaurarlo si es posible"""
	# Solo restaurar si no hay otra ventana modal abierta
	if terminal_input and terminal_input.is_inside_tree():
		call_deferred("_do_restore_focus")

func _on_terminal_input_gui_input(event: InputEvent):
	"""Maneja input del terminal invisible, sincronizando con el TextEdit"""
	if event is InputEventKey and event.pressed:
		# Sincronizar cambios con el TextEdit
		if terminal_output and terminal_input:
			var command = terminal_input.text
			var full_line = prompt_text + command
			# Actualizar la línea de input en el TextEdit
			if terminal_output.get_line_count() > current_input_line:
				var old_line = terminal_output.get_line(current_input_line)
				if old_line.begins_with(prompt_text):
					# Reemplazar la línea completa
					terminal_output.remove_text(current_input_line, 0, current_input_line, old_line.length())
					terminal_output.insert_text_at_caret(full_line)
					terminal_output.set_caret_line(current_input_line)
					terminal_output.set_caret_column(full_line.length())
		
		# Si se presiona Enter durante la ejecución de un comando, mostrar progreso
		if (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) and command_running:
			# Hacer un poll inmediato para mostrar el progreso actual
			if stream_request and is_instance_valid(stream_request):
				_poll_output()
			get_viewport().set_input_as_handled()
			return
		
		# Ctrl+Shift+T para nueva pestaña
		if event.keycode == KEY_T and event.ctrl_pressed and event.shift_pressed:
			_request_new_tab()
			get_viewport().set_input_as_handled()
			return
		
		# Navegación del historial con flechas arriba/abajo
		if event.keycode == KEY_UP:
			if history_index > 0:
				history_index -= 1
				if history_index < command_history.size():
					terminal_input.text = command_history[history_index]
					terminal_input.caret_column = terminal_input.text.length()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_DOWN:
			if history_index < command_history.size() - 1:
				history_index += 1
				terminal_input.text = command_history[history_index]
				terminal_input.caret_column = terminal_input.text.length()
			elif history_index >= command_history.size() - 1:
				history_index = command_history.size()
				terminal_input.text = ""
			get_viewport().set_input_as_handled()
			return

# ============================================
# FUNCIONES DEL SISTEMA DE PESTAÑAS
# ============================================

func _on_tab_selected(tab_id: String):
	"""Se llama cuando se selecciona una pestaña"""
	if not tabs.has(tab_id):
		return
	
	# Ocultar todas las pestañas y desactivar botones
	for id in tabs:
		if tabs[id].has("panel") and tabs[id].panel:
			var is_visible = (id == tab_id)
			tabs[id].panel.visible = is_visible
			# Ajustar mouse_filter según visibilidad
			if is_visible:
				tabs[id].panel.mouse_filter = Control.MOUSE_FILTER_PASS  # Permitir eventos cuando está visible
			else:
				tabs[id].panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ignorar cuando está oculto
		if tabs[id].has("button") and tabs[id].button:
			tabs[id].button.button_pressed = (id == tab_id)
	
	active_tab_id = tab_id
	
	# Enfocar el input de la pestaña activa
	if tabs[tab_id].has("terminal_input") and tabs[tab_id].terminal_input:
		var tab_input = tabs[tab_id].terminal_input
		if tab_input and tab_input.is_inside_tree():
			# Asegurar que el input esté habilitado y reciba focus
			tab_input.editable = true
			tab_input.shortcut_keys_enabled = true
			tab_input.mouse_filter = Control.MOUSE_FILTER_STOP  # Asegurar que reciba eventos
			# Usar call_deferred para asegurar que se ejecute después de que el panel esté visible
			tab_input.call_deferred("grab_focus")
			var text_len = tab_input.text.length()
			tab_input.call_deferred("set", "caret_column", text_len)

func _on_tab_close_requested(tab_id: String):
	"""Se llama cuando se solicita cerrar una pestaña"""
	if not tabs.has(tab_id):
		return
	
	# Si solo hay una pestaña, no cerrar (o cerrar la ventana)
	if tabs.size() <= 1:
		_close_terminal()
		return
	
	# Cerrar terminal en backend si existe
	if tabs[tab_id].has("terminal_id") and tabs[tab_id].terminal_id != "":
		var request_data = {
			"jsonrpc": "2.0",
			"method": "close_terminal",
			"params": {"terminal_id": tabs[tab_id].terminal_id},
			"id": Time.get_ticks_msec()
		}
		var temp_request = HTTPRequest.new()
		add_child(temp_request)
		temp_request.request(BACKEND_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(request_data))
		temp_request.request_completed.connect(func(_r, _c, _h, _b): temp_request.queue_free())
	
	# Eliminar pestaña
	if tabs[tab_id].has("content") and tabs[tab_id].content:
		tabs[tab_id].content.queue_free()
	if tabs[tab_id].has("panel") and tabs[tab_id].panel:
		tabs[tab_id].panel.queue_free()
	tabs.erase(tab_id)
	
	# Si era la pestaña activa, activar otra
	if active_tab_id == tab_id:
		if tabs.size() > 0:
			var first_tab = tabs.keys()[0]
			_on_tab_selected(first_tab)
		else:
			active_tab_id = ""

func _create_backend_terminal_for_tab(tab_id: String):
	"""Crea una terminal en el backend para una pestaña"""
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "create_terminal",
		"params": {"scenario": scenario},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	http_request.set_meta("request_id", request_id)
	http_request.set_meta("tab_id", tab_id)
	add_child(http_request)
	pending_requests[request_id] = http_request
	
	var callback = func(res: int, code: int, hdrs: PackedStringArray, bdy: PackedByteArray):
		_on_tab_backend_response(tab_id, request_id, res, code, hdrs, bdy)
	
	http_request.request_completed.connect(callback)
	http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)

func _on_tab_backend_response(tab_id: String, request_id: int, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa respuesta del backend para una pestaña"""
	if pending_requests.has(request_id):
		pending_requests.erase(request_id)
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(response_text) != OK:
		return
	
	var response_data = json.get_data()
	var result_data = response_data.get("result", {})
	
	if result_data.has("success") and result_data.get("success", false):
		if result_data.has("terminal_id"):
			var term_id = result_data.get("terminal_id", "")
			if tabs.has(tab_id):
				tabs[tab_id].terminal_id = term_id
				if tabs[tab_id].has("terminal_output") and tabs[tab_id].terminal_output:
					_append_to_terminal(tabs[tab_id].terminal_output, "6me@shell:~$ Terminal conectada\n", Color(1.0, 0.0, 0.0))

func _on_tab_command_submitted(tab_id: String, command: String):
	"""Procesa un comando de una pestaña"""
	if not tabs.has(tab_id) or command.strip_edges().is_empty():
		return
	
	var tab = tabs[tab_id]
	
	# Añadir al historial
	if not tab.has("command_history"):
		tab.command_history = []
	tab.command_history.append(command)
	tab.history_index = tab.command_history.size()
	
	# Mostrar comando
	if tab.has("terminal_output") and tab.terminal_output:
		_append_to_terminal(tab.terminal_output, "6me@shell:~$ " + command + "\n", Color(1.0, 0.0, 0.0))
	
	# Limpiar input
	if tab.has("terminal_input") and tab.terminal_input:
		tab.terminal_input.text = ""
	
	# Ejecutar comando
	_execute_tab_command(tab_id, command)
	
	# Restaurar focus
	if tab.has("terminal_input") and tab.terminal_input:
		call_deferred("grab_focus", tab.terminal_input)

func _execute_tab_command(tab_id: String, command: String):
	"""Ejecuta un comando en una pestaña"""
	if not tabs.has(tab_id) or not tabs[tab_id].has("terminal_id") or tabs[tab_id].terminal_id == "":
		return
	
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "execute_terminal_command",
		"params": {
			"command": command,
			"terminal_id": tabs[tab_id].terminal_id
		},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	http_request.set_meta("request_id", request_id)
	http_request.set_meta("tab_id", tab_id)
	add_child(http_request)
	pending_requests[request_id] = http_request
	
	var callback = func(res: int, code: int, hdrs: PackedStringArray, bdy: PackedByteArray):
		_on_tab_command_response(tab_id, request_id, res, code, hdrs, bdy)
	
	http_request.request_completed.connect(callback)
	http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)

func _on_tab_command_response(tab_id: String, request_id: int, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa respuesta de comando de una pestaña"""
	if pending_requests.has(request_id):
		pending_requests.erase(request_id)
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(response_text) != OK:
		return
	
	var response_data = json.get_data()
	var result_data = response_data.get("result", {})
	
	if result_data.has("success") and result_data.get("success", false):
		var output = result_data.get("output", "")
		if tabs.has(tab_id) and tabs[tab_id].has("terminal_output") and tabs[tab_id].terminal_output and output:
			_append_to_terminal(tabs[tab_id].terminal_output, output.strip_edges() + "\n")
		
		# Restaurar focus
		if tabs.has(tab_id) and tabs[tab_id].has("terminal_input") and tabs[tab_id].terminal_input:
			call_deferred("grab_focus", tabs[tab_id].terminal_input)

func _on_tab_input_gui_input(tab_id: String, event: InputEvent):
	"""Maneja input de una pestaña"""
	if not tabs.has(tab_id):
		return
	
	var tab = tabs[tab_id]
	
	if event is InputEventKey and event.pressed:
		if not tab.has("command_history"):
			tab.command_history = []
		if not tab.has("history_index"):
			tab.history_index = -1
		
		if event.keycode == KEY_UP:
			if tab.history_index > 0:
				tab.history_index -= 1
				if tab.has("terminal_input") and tab.terminal_input:
					tab.terminal_input.text = tab.command_history[tab.history_index]
		elif event.keycode == KEY_DOWN:
			if tab.history_index < tab.command_history.size() - 1:
				tab.history_index += 1
				if tab.has("terminal_input") and tab.terminal_input:
					tab.terminal_input.text = tab.command_history[tab.history_index]
			elif tab.history_index >= tab.command_history.size() - 1:
				tab.history_index = tab.command_history.size()
				if tab.has("terminal_input") and tab.terminal_input:
					tab.terminal_input.text = ""
			return
		
		if event.keycode == KEY_UP:
			# Si hay matches de autocompletado, navegar por ellos
			if autocomplete_matches.size() > 0:
				autocomplete_index = (autocomplete_index - 1 + autocomplete_matches.size()) % autocomplete_matches.size()
				var cmd_parts = terminal_input.text.split(" ", false)
				if cmd_parts.size() > 1:
					cmd_parts[cmd_parts.size() - 1] = autocomplete_matches[autocomplete_index]
					terminal_input.text = " ".join(cmd_parts)
					terminal_input.caret_column = terminal_input.text.length()
				get_viewport().set_input_as_handled()

func _autocomplete_with_tab():
	"""Autocompleta comandos o archivos/directorios con Tab"""
	var current_text = terminal_input.text
	var cursor_pos = terminal_input.caret_column
	
	# Si hay texto después del cursor, no autocompletar
	if cursor_pos < current_text.length():
		return
	
	var cmd_parts = current_text.strip_edges().split(" ", false)
	
	# Si hay más de una palabra, intentar autocompletar archivos/directorios
	if cmd_parts.size() > 1:
		var cmd = cmd_parts[0].to_lower()
		var partial_path = cmd_parts[cmd_parts.size() - 1]
		
		# Comandos que requieren archivos/directorios
		var file_commands = ["cd", "cat", "ls", "find", "grep", "mkdir", "rm", "cp", "mv", "nano", "vim", "vi", "touch", "chmod", "chown"]
		
		if cmd in file_commands:
			_autocomplete_file_or_directory(partial_path, current_text)
			return
	
	# Autocompletar comandos
	_autocomplete_command()

func _autocomplete_file_or_directory(partial_path: String, current_text: String):
	"""Autocompleta archivos o directorios consultando al backend"""
	# Solicitar lista de archivos/directorios al backend
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "list_files",
		"params": {
			"terminal_id": terminal_id,
			"path": partial_path
		},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	http_request.set_meta("request_id", request_id)
	http_request.set_meta("partial_path", partial_path)
	http_request.set_meta("current_text", current_text)
	add_child(http_request)
	pending_requests[request_id] = http_request
	
	var callback = func(res: int, code: int, hdrs: PackedStringArray, bdy: PackedByteArray):
		_on_autocomplete_response(request_id, res, code, hdrs, bdy)
	
	http_request.request_completed.connect(callback)
	var error = http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		# Si falla, intentar autocompletar con comandos locales
		_autocomplete_command()

func _on_autocomplete_response(request_id: int, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa respuesta de autocompletado"""
	var partial_path = ""
	var current_text = ""
	
	if pending_requests.has(request_id):
		var http_request = pending_requests[request_id]
		partial_path = http_request.get_meta("partial_path", "")
		current_text = http_request.get_meta("current_text", "")
		pending_requests.erase(request_id)
		http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(response_text) != OK:
		return
	
	var response_data = json.get_data()
	var result_data = response_data.get("result", {})
	
	if result_data.has("success") and result_data.get("success", false):
		var files = result_data.get("files", [])
		if files.size() == 1:
			# Un solo match - autocompletar
			var cmd_parts = current_text.split(" ", false)
			cmd_parts[cmd_parts.size() - 1] = files[0]
			terminal_input.text = " ".join(cmd_parts)
			terminal_input.caret_column = terminal_input.text.length()
		elif files.size() > 1:
			# Múltiples matches - mostrar opciones y permitir navegación
			autocomplete_matches = files
			autocomplete_index = 0
			last_autocomplete_query = partial_path
			
			_add_terminal_output("")
			_add_terminal_output("Archivos disponibles:", Color(0.0, 1.0, 1.0))
			for i in range(files.size()):
				var prefix = "> " if i == 0 else "  "
				_add_terminal_output(prefix + files[i], Color(0.5, 1.0, 0.5))
			_add_terminal_output("Usa flechas arriba/abajo para navegar, Enter para seleccionar", Color(0.7, 0.7, 0.7))
			_add_terminal_output("")

func _autocomplete_command():
	"""Autocompleta comandos con Tab"""
	var current_text = terminal_input.text.strip_edges()
	if current_text == "":
		return
	
	var cmd_parts = current_text.split(" ", false)
	var partial_cmd = cmd_parts[0].to_lower()
	
	# Lista de comandos disponibles
	var commands = ["ls", "cd", "pwd", "cat", "find", "grep", "mkdir", "rm", "cp", "mv", "clear", "help", "exit", "nmap", "metasploit", "wireshark", "aircrack-ng", "hydra", "sqlmap", "nano", "vim", "vi", "exploit", "exploit-log4shell", "wget", "curl", "python", "python3"]
	
	# Buscar comandos que empiecen con el texto parcial
	var matches = []
	for cmd in commands:
		if cmd.begins_with(partial_cmd):
			matches.append(cmd)
	
	if matches.size() == 1:
		# Un solo match - autocompletar
		terminal_input.text = matches[0] + " " + " ".join(cmd_parts.slice(1))
		terminal_input.caret_column = terminal_input.text.length()
	elif matches.size() > 1:
		# Múltiples matches - mostrar opciones
		_add_terminal_output("")
		_add_terminal_output("Comandos disponibles:", Color(0.0, 1.0, 1.0))
		for cmd in matches:
			_add_terminal_output("  " + cmd, Color(0.5, 1.0, 0.5))
		_add_terminal_output("")

func _on_terminal_unified_input(event: InputEvent):
	"""Maneja input en la terminal unificada con protección del prompt"""
	if event is InputEventKey and event.pressed:
		var current_line = terminal_output.get_caret_line()
		var current_column = terminal_output.get_caret_column()
		
		# Interceptar Ctrl+Shift+V (pegar) - estilo Linux/terminal
		# Ctrl+V se usa para "quote next character" en terminales Linux
		if event.keycode == KEY_V and event.ctrl_pressed and event.shift_pressed:
			# Solo permitir pegar en la línea de input actual
			if current_line != current_input_line:
				# Mover cursor a la línea de input antes de pegar
				terminal_output.set_caret_line(current_input_line)
				terminal_output.set_caret_column(terminal_output.get_line(current_input_line).length())
				current_line = current_input_line
				current_column = terminal_output.get_caret_column()
				get_viewport().set_input_as_handled()
				# Esperar un frame y luego pegar en la línea correcta
				call_deferred("_paste_at_input_line")
				return
			
			# Si está en la línea de input, asegurar que el cursor esté después del prompt
			if current_line == current_input_line:
				if current_column < prompt_text.length():
					terminal_output.set_caret_column(prompt_text.length())
					current_column = prompt_text.length()
		
		# Ctrl+V sin Shift - quote next character (comportamiento de terminal Linux)
		if event.keycode == KEY_V and event.ctrl_pressed and not event.shift_pressed:
			# En terminales Linux, Ctrl+V permite insertar caracteres de control literalmente
			# Por ahora, solo prevenir el comportamiento por defecto
			get_viewport().set_input_as_handled()
			return
		
		# Ctrl+C para copiar (si hay selección)
		if event.keycode == KEY_C and event.ctrl_pressed and not event.shift_pressed:
			var selected_text = terminal_output.get_selected_text()
			if selected_text != "":
				DisplayServer.clipboard_set(selected_text)
				get_viewport().set_input_as_handled()
				return
		
		# Prevenir cualquier tecla de edición en líneas anteriores
		if current_line < current_input_line:
			# Bloquear todas las teclas de edición excepto navegación
			if event.keycode in [KEY_BACKSPACE, KEY_DELETE, KEY_ENTER, KEY_KP_ENTER, KEY_TAB]:
				terminal_output.set_caret_line(current_input_line)
				terminal_output.set_caret_column(prompt_text.length())
				get_viewport().set_input_as_handled()
				return
			# Para otras teclas, mover cursor a la línea de input
			if not event.keycode in [KEY_UP, KEY_DOWN, KEY_PAGEUP, KEY_PAGEDOWN]:
				terminal_output.set_caret_line(current_input_line)
				terminal_output.set_caret_column(prompt_text.length())
				get_viewport().set_input_as_handled()
				return
		
		# Manejar historial de comandos cuando está en la línea de input
		if current_line == current_input_line:
			if event.keycode == KEY_UP:
				# Navegar hacia atrás en el historial
				if history_index > 0:
					history_index -= 1
					if history_index < command_history.size():
						var command = command_history[history_index]
						# Actualizar la línea de input con el comando del historial
						var input_line = terminal_output.get_line(current_input_line)
						var command_part = ""
						if input_line.begins_with(prompt_text):
							command_part = input_line.substr(prompt_text.length())
						# Reemplazar solo la parte del comando
						terminal_output.remove_text(current_input_line, prompt_text.length(), current_input_line, input_line.length())
						terminal_output.insert_text_at_caret(command)
						terminal_output.set_caret_line(current_input_line)
						terminal_output.set_caret_column((prompt_text + command).length())
						# Sincronizar con LineEdit invisible
						if terminal_input:
							terminal_input.text = command
							terminal_input.caret_column = command.length()
						get_viewport().set_input_as_handled()
						return
				else:
					# Ya está en el primer comando, no hacer nada pero prevenir movimiento del cursor
					get_viewport().set_input_as_handled()
					return
			elif event.keycode == KEY_DOWN:
				# Navegar hacia adelante en el historial
				if history_index < command_history.size() - 1:
					history_index += 1
					var command = command_history[history_index]
					# Actualizar la línea de input con el comando del historial
					var input_line = terminal_output.get_line(current_input_line)
					terminal_output.remove_text(current_input_line, prompt_text.length(), current_input_line, input_line.length())
					terminal_output.insert_text_at_caret(command)
					terminal_output.set_caret_line(current_input_line)
					terminal_output.set_caret_column((prompt_text + command).length())
					# Sincronizar con LineEdit invisible
					if terminal_input:
						terminal_input.text = command
						terminal_input.caret_column = command.length()
					get_viewport().set_input_as_handled()
					return
				elif history_index >= command_history.size() - 1:
					# Limpiar el comando (volver al estado inicial)
					history_index = command_history.size()
					var input_line = terminal_output.get_line(current_input_line)
					terminal_output.remove_text(current_input_line, prompt_text.length(), current_input_line, input_line.length())
					terminal_output.set_caret_line(current_input_line)
					terminal_output.set_caret_column(prompt_text.length())
					# Sincronizar con LineEdit invisible
					if terminal_input:
						terminal_input.text = ""
						terminal_input.caret_column = 0
					get_viewport().set_input_as_handled()
					return
		
		# Prevenir edición fuera de la línea de input
		if current_line < current_input_line:
			# El usuario está intentando editar líneas antiguas, mover cursor a la línea de input
			terminal_output.set_caret_line(current_input_line)
			terminal_output.set_caret_column(terminal_output.get_line(current_input_line).length())
			terminal_input.grab_focus()
			get_viewport().set_input_as_handled()
			return
		
		# Si está en la línea de input, proteger el prompt
		if current_line == current_input_line:
			var input_line = terminal_output.get_line(current_input_line)
			
			# Prevenir borrado del prompt - interceptar todas las teclas de borrado
			if current_column < prompt_text.length():
				# Intentando editar dentro del prompt, bloquear y mover cursor después del prompt
				if event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
					terminal_output.set_caret_column(prompt_text.length())
					get_viewport().set_input_as_handled()
					return
				# Para otras teclas de edición, mover cursor después del prompt
				if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_HOME]:
					if event.keycode == KEY_HOME:
						terminal_output.set_caret_column(prompt_text.length())
					get_viewport().set_input_as_handled()
					return
				# Para cualquier otra tecla, mover cursor después del prompt
				terminal_output.set_caret_column(prompt_text.length())
			
			# Verificar si hay selección que incluya el prompt
			if terminal_output.has_selection():
				var selection_from_line = terminal_output.get_selection_from_line()
				var selection_from_column = terminal_output.get_selection_from_column()
				var selection_to_line = terminal_output.get_selection_to_line()
				var selection_to_column = terminal_output.get_selection_to_column()
				
				# Si la selección incluye parte del prompt, ajustarla
				if selection_from_line == current_input_line and selection_from_column < prompt_text.length():
					# La selección empieza en el prompt, ajustarla para empezar después del prompt
					terminal_output.select(selection_from_line, prompt_text.length(), selection_to_line, selection_to_column)
				if selection_to_line == current_input_line and selection_to_column < prompt_text.length():
					# La selección termina en el prompt, ajustarla para terminar después del prompt
					terminal_output.select(selection_from_line, selection_from_column, selection_to_line, prompt_text.length())
			
			# Si se presiona Enter, ejecutar comando
			if (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
				if input_line.begins_with(prompt_text):
					var command = input_line.substr(prompt_text.length()).strip_edges()
					_on_command_submitted(command)
					get_viewport().set_input_as_handled()
					return
			
			# Sincronizar con el LineEdit invisible
			if input_line.begins_with(prompt_text):
				var command = input_line.substr(prompt_text.length())
				terminal_input.text = command
				terminal_input.caret_column = command.length()
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Menú contextual para copiar
			var selected_text = terminal_output.get_selected_text()
			if selected_text != "":
				DisplayServer.clipboard_set(selected_text)
			# Prevenir pegado desde menú contextual en líneas anteriores
			# El pegado se manejará en _on_terminal_text_changed cuando se detecte el cambio
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Al hacer clic, asegurar que el cursor no esté en el prompt o líneas anteriores
			var clicked_line = terminal_output.get_caret_line()
			var clicked_column = terminal_output.get_caret_column()
			# Si se hace clic en una línea anterior, mover a la línea de input
			if clicked_line < current_input_line:
				terminal_output.set_caret_line(current_input_line)
				terminal_output.set_caret_column(prompt_text.length())
			# Si se hace clic en el prompt, mover después del prompt
			elif clicked_line == current_input_line and clicked_column < prompt_text.length():
				terminal_output.set_caret_column(prompt_text.length())

# Nota: En Godot 4, TextEdit no tiene set_line_readonly()
# La prevención de edición en líneas anteriores se hace mediante eventos en _on_terminal_unified_input

func _paste_at_input_line():
	"""Pega el contenido del portapapeles en la línea de input"""
	if terminal_output and terminal_input:
		var clipboard_text = DisplayServer.clipboard_get()
		if clipboard_text != "":
			var current_line_text = terminal_output.get_line(current_input_line)
			var command_part = ""
			if current_line_text.begins_with(prompt_text):
				command_part = current_line_text.substr(prompt_text.length())
			# Agregar el texto pegado al comando
			var new_command = command_part + clipboard_text
			# Actualizar la línea
			terminal_output.remove_text(current_input_line, 0, current_input_line, current_line_text.length())
			terminal_output.insert_text_at_caret(prompt_text + new_command)
			terminal_output.set_caret_line(current_input_line)
			terminal_output.set_caret_column((prompt_text + new_command).length())
			# Sincronizar con LineEdit
			terminal_input.text = new_command
			terminal_input.caret_column = new_command.length()

func _update_input_prompt():
	"""Actualiza la línea de input con el prompt"""
	if terminal_output:
		# Verificar si debemos cambiar el prompt basado en el contenido del output
		var line_count = terminal_output.get_line_count()
		if line_count > 0:
			# Buscar en las últimas líneas si hay "msf6 >"
			var check_lines = min(10, line_count)  # Revisar las últimas 10 líneas
			var found_msf_prompt = false
			for i in range(line_count - 1, max(-1, line_count - check_lines - 1), -1):
				var line = terminal_output.get_line(i)
				if line.contains("msf6 >"):
					found_msf_prompt = true
					break
			
			if found_msf_prompt:
				is_msfconsole_session = true
				prompt_text = "msf6 > "
			else:
				# Verificar si hay un prompt de shell normal en las últimas líneas
				var found_shell_prompt = false
				for i in range(line_count - 1, max(-1, line_count - check_lines - 1), -1):
					var line = terminal_output.get_line(i)
					if line.contains("6me@shell:~$"):
						found_shell_prompt = true
						break
				
				if found_shell_prompt and is_msfconsole_session:
					# Salimos de msfconsole, restaurar prompt normal
					is_msfconsole_session = false
					prompt_text = "6me@shell:~$ "
		
		if line_count == 0:
			# Primera línea, agregar prompt
			terminal_output.text = prompt_text
			current_input_line = 0
		else:
			# Verificar la última línea
			var last_line = terminal_output.get_line(line_count - 1)
			if not last_line.begins_with(prompt_text) and not last_line.contains("msf6 >"):
				# La última línea no tiene prompt, agregarlo
				terminal_output.text += prompt_text
				current_input_line = terminal_output.get_line_count() - 1
			else:
				# Ya tiene prompt, solo actualizar current_input_line
				current_input_line = line_count - 1
		
		# Mover cursor al final del prompt
		terminal_output.set_caret_line(current_input_line)
		terminal_output.set_caret_column(terminal_output.get_line(current_input_line).length())

func _replace_input_line(new_text: String):
	"""Reemplaza la línea de input actual con nuevo texto"""
	if terminal_output:
		var line = terminal_output.get_line(current_input_line)
		# remove_text requiere: from_line, from_column, to_line, to_column
		terminal_output.remove_text(current_input_line, 0, current_input_line, line.length())
		terminal_output.insert_text_at_caret(new_text)
		current_input_line = terminal_output.get_line_count() - 1

func _on_terminal_text_changed():
	"""Se llama cuando cambia el texto en la terminal unificada - proteger el prompt"""
	if terminal_output:
		var current_line = terminal_output.get_caret_line()
		
		# Prevenir edición de líneas anteriores - mover cursor a la línea de input
		if current_line < current_input_line:
			terminal_output.set_caret_line(current_input_line)
			terminal_output.set_caret_column(prompt_text.length())
			# Si se detectó pegado en líneas anteriores, mover el texto pegado a la línea de input
			# Esto se maneja automáticamente porque el cursor ya está en la línea correcta
			return
		
		# Verificar si se pegó texto en líneas anteriores (detectado por cambios en líneas que no son la de input)
		# Esto previene pegado accidental desde el menú contextual del ratón
		if terminal_output.get_line_count() > current_input_line + 1:
			# Hay más líneas después de la línea de input, esto no debería pasar normalmente
			# Pero si pasa, asegurar que el cursor esté en la línea de input
			terminal_output.set_caret_line(current_input_line)
			terminal_output.set_caret_column(terminal_output.get_line(current_input_line).length())
		
		# Si se está editando la línea de input, asegurar que el prompt esté presente
		if current_line == current_input_line and terminal_output.get_line_count() > current_input_line:
			var input_line = terminal_output.get_line(current_input_line)
			
			# Verificar si el prompt fue borrado completamente o parcialmente
			if not input_line.begins_with(prompt_text):
				# Extraer solo el comando (sin prompt parcial ni duplicado)
				var command = ""
				
				# Buscar TODAS las ocurrencias del prompt en el texto
				var prompt_positions = []
				var search_start = 0
				while true:
					var pos = input_line.find(prompt_text, search_start)
					if pos < 0:
						break
					prompt_positions.append(pos)
					search_start = pos + 1
				
				if prompt_positions.size() > 0:
					# Hay uno o más prompts en el texto, extraer solo el comando después del ÚLTIMO prompt
					var last_prompt_pos = prompt_positions[prompt_positions.size() - 1]
					command = input_line.substr(last_prompt_pos + prompt_text.length())
					# También eliminar cualquier prompt que esté dentro del comando
					command = command.replace(prompt_text, "")
				else:
					# No hay prompt en el texto
					# Si el texto es más corto que el prompt, probablemente es parte del prompt borrado
					# Solo tratar como comando si el texto es significativamente diferente del prompt
					if input_line.length() >= prompt_text.length() or input_line.length() == 0:
						# El texto es largo o está vacío, puede ser comando válido
						command = input_line.replace(prompt_text, "")
					else:
						# El texto es corto y no contiene el prompt completo, probablemente es parte del prompt borrado
						# Verificar si el texto es un prefijo del prompt
						if prompt_text.begins_with(input_line):
							# Es parte del prompt borrado, no es comando
							command = ""
						else:
							# No es parte del prompt, puede ser comando
							command = input_line.replace(prompt_text, "")
				
				# Limpiar la línea y restaurar solo el prompt + comando (sin duplicados)
				terminal_output.remove_text(current_input_line, 0, current_input_line, input_line.length())
				terminal_output.insert_text_at_caret(prompt_text + command)
				terminal_output.set_caret_line(current_input_line)
				var new_line_length = (prompt_text + command).length()
				terminal_output.set_caret_column(new_line_length)
				
				# Sincronizar con el LineEdit invisible
				if terminal_input:
					terminal_input.text = command
					terminal_input.caret_column = command.length()
				return
			
			# Verificar si el prompt fue parcialmente borrado (menos caracteres de los esperados)
			elif input_line.length() < prompt_text.length():
				# El prompt fue parcialmente borrado, restaurarlo completamente
				# Extraer solo el comando (lo que está después del prompt parcial)
				# IMPORTANTE: Si el texto es más corto que el prompt, todo es parte del prompt borrado
				# NO debe tratarse como comando para evitar duplicar el prompt
				var command = ""
				# Si hay texto, verificar si contiene el prompt completo o parcial
				if input_line.length() > 0:
					# Verificar si el texto contiene el prompt completo (duplicado)
					if input_line.contains(prompt_text):
						# Hay un prompt duplicado, extraer solo el comando después del prompt
						var prompt_index = input_line.find(prompt_text)
						command = input_line.substr(prompt_index + prompt_text.length())
						# Eliminar cualquier otro prompt del comando
						command = command.replace(prompt_text, "")
					else:
						# El texto es parte del prompt borrado, no es comando
						command = ""
				
				# Limpiar y restaurar SOLO el prompt (sin comando si era parte del prompt borrado)
				terminal_output.remove_text(current_input_line, 0, current_input_line, input_line.length())
				terminal_output.insert_text_at_caret(prompt_text + command)
				terminal_output.set_caret_line(current_input_line)
				var new_line_length = (prompt_text + command).length()
				terminal_output.set_caret_column(new_line_length)
				
				# Sincronizar con el LineEdit invisible
				if terminal_input:
					terminal_input.text = command
					terminal_input.caret_column = command.length()
				return
			
			# Verificar si hay un prompt duplicado en la línea (incluso si comienza con el prompt)
			var prompt_count = input_line.count(prompt_text)
			if prompt_count > 1:
				# Hay múltiples prompts, limpiar y dejar solo uno al inicio
				var last_prompt_index = input_line.rfind(prompt_text)
				var command = input_line.substr(last_prompt_index + prompt_text.length())
				# Eliminar cualquier prompt que esté dentro del comando también
				command = command.replace(prompt_text, "")
				terminal_output.remove_text(current_input_line, 0, current_input_line, input_line.length())
				terminal_output.insert_text_at_caret(prompt_text + command)
				terminal_output.set_caret_line(current_input_line)
				var new_line_length = (prompt_text + command).length()
				terminal_output.set_caret_column(new_line_length)
				
				# Sincronizar con el LineEdit invisible
				if terminal_input:
					terminal_input.text = command
					terminal_input.caret_column = command.length()
				return
			
			# Verificar si el comando contiene el texto del prompt (aunque la línea comience correctamente con el prompt)
			var command_part = input_line.substr(prompt_text.length())
			if command_part.contains(prompt_text):
				# El comando contiene el prompt, eliminarlo
				var clean_command = command_part.replace(prompt_text, "")
				terminal_output.remove_text(current_input_line, 0, current_input_line, input_line.length())
				terminal_output.insert_text_at_caret(prompt_text + clean_command)
				terminal_output.set_caret_line(current_input_line)
				var new_line_length = (prompt_text + clean_command).length()
				terminal_output.set_caret_column(new_line_length)
				
				# Sincronizar con el LineEdit invisible
				if terminal_input:
					terminal_input.text = clean_command
					terminal_input.caret_column = clean_command.length()
				return
			
			# Prevenir que el cursor esté en el prompt
			var caret_column = terminal_output.get_caret_column()
			if caret_column < prompt_text.length():
				terminal_output.set_caret_column(prompt_text.length())
			
			# Sincronizar con el LineEdit invisible
			if terminal_input:
				var full_line = terminal_output.get_line(current_input_line)
				if full_line.begins_with(prompt_text):
					var command = full_line.substr(prompt_text.length())
					if terminal_input.text != command:
						terminal_input.text = command
						terminal_input.caret_column = command.length()
		
		# Prevenir edición de líneas anteriores - mover cursor a la línea de input
		if current_line < current_input_line:
			terminal_output.set_caret_line(current_input_line)
			terminal_output.set_caret_column(prompt_text.length())
		
		# Prevenir pegado en líneas anteriores - verificar después de cualquier cambio
		if terminal_output.get_line_count() > current_input_line:
			for line_idx in range(current_input_line):
				var line = terminal_output.get_line(line_idx)
				# Si alguna línea anterior fue modificada (tiene más contenido del esperado), revertir
				# Esto previene pegado accidental en líneas anteriores
				# Nota: Esta verificación es básica, el manejo principal está en _on_terminal_unified_input

func _execute_command(command: String):
	"""Ejecuta un comando de terminal"""
	var cmd_parts = command.strip_edges().split(" ", false)
	var cmd = cmd_parts[0].to_lower()
	
	# Comandos especiales locales
	match cmd:
		"help":
			_show_help()
			return
		"clear":
			if terminal_output:
				terminal_output.text = ""
			return
		"exit":
			_close_terminal()
			return
	
	# Comandos de editores de texto
	if cmd == "nano" or cmd == "vim" or cmd == "vi":
		_handle_editor_command(command, cmd)
		return
	
	# Enviar comando al backend
	_execute_backend_command(command)

func _execute_backend_command(command: String):
	"""Ejecuta comando en el backend Docker con streaming"""
	# Determinar si es un comando corto (no bloquear estos)
	var cmd_parts = command.strip_edges().split(" ", false)
	var is_short_command = false
	if cmd_parts.size() > 0:
		var first_cmd = cmd_parts[0].to_lower()
		var short_commands = ["curl", "wget", "cat", "ls", "pwd", "cd", "echo", "grep", "find", "head", "tail", "less", "more", "whoami", "id", "uname", "date", "help", "man", "connect"]
		is_short_command = first_cmd in short_commands
	
	# Bloquear solo si hay un comando largo ejecutándose
	# Los comandos cortos pueden ejecutarse incluso si hay un comando largo terminando
	if command_running and not is_short_command:
		_add_terminal_output("⚠️ Ya hay un comando ejecutándose. Espera a que termine o cancélalo con Ctrl+C", Color(1.0, 0.8, 0.0))
		return
	
	# Guardar comando actual
	current_command = command
	command_running = true
	
	# Bloquear input
	if terminal_input:
		terminal_input.editable = false
	
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "execute_terminal_command",
		"params": {
			"command": command,
			"terminal_id": terminal_id
		},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	# Crear nuevo HTTPRequest para esta petición
	var http_request = HTTPRequest.new()
	http_request.set_meta("request_id", request_id)
	add_child(http_request)
	pending_requests[request_id] = http_request
	
	# Conectar señal usando lambda para capturar request_id
	var captured_id = request_id
	var callback = func(res: int, code: int, hdrs: PackedStringArray, bdy: PackedByteArray):
		_on_command_started(captured_id, res, code, hdrs, bdy)
	
	http_request.request_completed.connect(callback)
	
	var error = http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_add_terminal_output("Error conectando al backend: " + str(error), Color(1.0, 0.0, 0.0))
		pending_requests.erase(request_id)
		http_request.queue_free()
		command_running = false
		if terminal_input:
			terminal_input.editable = true
	else:
		print("[TerminalWindow] Request de comando enviado - ID: ", request_id, " Command: ", command)

func _on_command_started(request_id: int, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa la respuesta inicial del comando y inicia el streaming"""
	# Limpiar el HTTPRequest usado
	if pending_requests.has(request_id):
		var http_request = pending_requests[request_id]
		pending_requests.erase(request_id)
		http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		command_running = false
		if terminal_input:
			terminal_input.editable = true
		_add_terminal_output("Error iniciando comando", Color(1.0, 0.0, 0.0))
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(response_text)
	
	if parse_error != OK:
		command_running = false
		if terminal_input:
			terminal_input.editable = true
		return
	
	var response_data = json.get_data()
	var result_data = response_data.get("result", {})
	
	if result_data.has("success") and result_data.get("success", false):
		var is_async = result_data.get("async", false)
		
		if is_async:
			# Comando largo: iniciar streaming del output (polling)
			# Para comandos asíncronos, siempre iniciar el polling usando get_terminal_output
			# No necesitamos stream_url, usamos el terminal_id directamente
			_start_streaming("")  # stream_url no se usa, pero mantenemos la función
		else:
			# Comando rápido: mostrar output directamente
			var output = result_data.get("output", "")
			if output:
				_add_terminal_output(output.strip_edges())
			command_running = false
			if terminal_input:
				terminal_input.editable = true
			_restore_focus()
	else:
		var error = result_data.get("error", "Error desconocido")
		_add_terminal_output("Error: " + str(error), Color(1.0, 0.0, 0.0))
		command_running = false
		if terminal_input:
			terminal_input.editable = true
		_restore_focus()

func _start_streaming(stream_url: String):
	"""Inicia el polling del output"""
	# Limpiar request anterior si existe
	if stream_request:
		stream_request.queue_free()
	
	stream_request = HTTPRequest.new()
	add_child(stream_request)
	
	# Conectar señal para recibir datos
	stream_request.request_completed.connect(_on_stream_data)
	
	# Resetear índice
	last_output_index = 0
	
	# Iniciar polling
	_poll_output()

func _poll_output():
	"""Hace polling del output del comando"""
	if not command_running or not stream_request or not is_instance_valid(stream_request):
		return
	
	var request_data = {
		"jsonrpc": "2.0",
		"method": "get_terminal_output",
		"params": {
			"terminal_id": terminal_id,
			"last_index": last_output_index
		},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var error = stream_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_add_terminal_output("Error en polling: " + str(error), Color(1.0, 0.0, 0.0))
		command_running = false
		if terminal_input:
			terminal_input.editable = true
		if stream_request:
			stream_request.queue_free()
			stream_request = null

func _on_stream_data(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa datos del polling del output"""
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var response_text = body.get_string_from_utf8()
		var json = JSON.new()
		if json.parse(response_text) == OK:
			var response_data = json.get_data()
			var result_data = response_data.get("result", {})
			
			if result_data.has("output"):
				var output = result_data.get("output", "")
				if output != "":
					# Mostrar output en tiempo real
					_add_terminal_output(output)
			
			# Actualizar índice
			if result_data.has("last_index"):
				last_output_index = result_data.get("last_index", 0)
			
			# Verificar si el comando terminó
			var stream_ended = result_data.get("stream_ended", false)
			var running = result_data.get("running", false)
			
			# Si el comando terminó (no está corriendo y hay output o el stream terminó)
			if not running:
				# Comando terminado - hacer un último poll para obtener todo el output restante
				if last_output_index < result_data.get("last_index", 0):
					# Aún hay output pendiente, hacer un último poll
					await get_tree().create_timer(0.1).timeout
					if stream_request and is_instance_valid(stream_request):
						_poll_output()
					return
				
				# Comando realmente terminado
				command_running = false
				if terminal_input:
					terminal_input.editable = true
				if stream_request:
					stream_request.queue_free()
					stream_request = null
				_restore_focus()
				return
		
		# Continuar polling (cada 100ms para output más rápido)
		if stream_request and command_running and is_instance_valid(stream_request):
			await get_tree().create_timer(0.1).timeout  # Esperar 100ms
			if stream_request and is_instance_valid(stream_request) and command_running:
				_poll_output()
	else:
		# Error - verificar si el comando terminó
		_check_command_finished()

func _check_terminal_status():
	"""Verifica el estado del terminal en el backend"""
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "get_terminal_status",
		"params": {
			"terminal_id": terminal_id
		},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	# Crear nuevo HTTPRequest para esta petición
	var http_request = HTTPRequest.new()
	http_request.set_meta("request_id", request_id)
	add_child(http_request)
	pending_requests[request_id] = http_request
	
	# Conectar señal usando lambda para capturar request_id
	var captured_id = request_id
	var callback = func(res: int, code: int, hdrs: PackedStringArray, bdy: PackedByteArray):
		_on_backend_response(captured_id, res, code, hdrs, bdy)
	
	http_request.request_completed.connect(callback)
	
	var error = http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("[TerminalWindow] Error enviando request de status: ", error)
		pending_requests.erase(request_id)
		http_request.queue_free()

func _on_backend_response(request_id: int, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa respuesta del backend"""
	# Limpiar el HTTPRequest usado
	if pending_requests.has(request_id):
		var http_request = pending_requests[request_id]
		pending_requests.erase(request_id)
		http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(response_text)
	
	if parse_error != OK:
		return
	
	var response_data = json.get_data()
	var result_data = response_data.get("result", {})
	
	# Verificar si es respuesta de status o command
	if result_data.has("mode"):
		using_docker = result_data.get("mode", "") == "docker"
		if using_docker:
			_add_terminal_output("6ME OS Shell disponible", Color(0.0, 1.0, 0.0))
		return
	
	# Es respuesta de comando
		print("[TerminalWindow] Procesando respuesta de comando - Request ID: ", request_id)
		print("[TerminalWindow] Result data: ", result_data)
	
	if result_data.has("success") and result_data.get("success", false):
		var output = result_data.get("output", "")
		print("[TerminalWindow] Output recibido (length: ", len(output), "): ", output)
		if output:
			_add_terminal_output(output.strip_edges())
		else:
			print("[TerminalWindow] Output vacío o no encontrado")
		
		# Restaurar focus después de mostrar output
		_restore_focus()
		
		# Actualizar terminal_id si se creó una nueva sesión
		if result_data.has("terminal_id"):
			terminal_id = result_data.get("terminal_id", terminal_id)
	else:
		var error = result_data.get("error", "Error desconocido")
		print("[TerminalWindow] Error en respuesta: ", error)
		_add_terminal_output("Error: " + str(error), Color(1.0, 0.0, 0.0))
	
	# Restaurar focus después de procesar respuesta
	call_deferred("_restore_focus")

func _check_command_finished():
	"""Verifica si el comando terminó consultando el estado"""
	if not command_running:
		return
	
	var request_data = {
		"jsonrpc": "2.0",
		"method": "get_terminal_command_status",
		"params": {
			"terminal_id": terminal_id
		},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(func(res: int, code: int, hdrs: PackedStringArray, bdy: PackedByteArray):
		if res == HTTPRequest.RESULT_SUCCESS and code == 200:
			var response_text = bdy.get_string_from_utf8()
			var json = JSON.new()
			if json.parse(response_text) == OK:
				var response_data = json.get_data()
				var result_data = response_data.get("result", {})
				var status = result_data.get("status", {})
				var running = status.get("running", false)
				if not running:
					command_running = false
					if terminal_input:
						terminal_input.editable = true
					if stream_request:
						stream_request.queue_free()
						stream_request = null
					_restore_focus()
		http_request.queue_free()
	)
	http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)

func _cancel_command(signal_type: String):
	"""Cancela el comando en ejecución"""
	if not command_running:
		return
	
	var request_data = {
		"jsonrpc": "2.0",
		"method": "cancel_terminal_command",
		"params": {
			"terminal_id": terminal_id,
			"signal": signal_type
		},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(func(_res, _code, _hdrs, _bdy): http_request.queue_free())
	http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)
	
	_add_terminal_output("\n[Comando cancelado con " + signal_type + "]\n", Color(1.0, 0.5, 0.0))
	
	# Limpiar streaming
	if stream_request:
		stream_request.queue_free()
		stream_request = null
	
	command_running = false
	if terminal_input:
		terminal_input.editable = true
	_restore_focus()

func _show_help():
	"""Muestra ayuda de comandos"""
	_add_terminal_output("")
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("6ME OS - SISTEMA DE AYUDA", Color(0.0, 1.0, 1.0))
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("")
	_add_terminal_output("COMANDOS DEL SISTEMA:", Color(0.0, 1.0, 0.0))
	_add_terminal_output("  ls                - Listar archivos y directorios")
	_add_terminal_output("  cd <directorio>   - Cambiar directorio")
	_add_terminal_output("  pwd               - Mostrar directorio actual")
	_add_terminal_output("  cat <archivo>     - Mostrar contenido de archivo")
	_add_terminal_output("  find <ruta>       - Buscar archivos")
	_add_terminal_output("  grep <patrón>     - Buscar texto en archivos")
	_add_terminal_output("  mkdir <dir>       - Crear directorio")
	_add_terminal_output("  rm <archivo>      - Eliminar archivo")
	_add_terminal_output("  cp <origen> <dest> - Copiar archivo")
	_add_terminal_output("  mv <origen> <dest> - Mover/renombrar archivo")
	_add_terminal_output("")
	_add_terminal_output("HERRAMIENTAS DE KALI LINUX:", Color(1.0, 0.5, 0.0))
	_add_terminal_output("  nmap              - Escáner de red y puertos")
	_add_terminal_output("  metasploit/msfconsole - Framework de explotación")
	_add_terminal_output("  wireshark/tshark  - Analizador de protocolos de red")
	_add_terminal_output("  aircrack-ng       - Auditoría de seguridad WiFi")
	_add_terminal_output("  hydra             - Fuerza bruta de contraseñas")
	_add_terminal_output("  sqlmap            - Inyección SQL automatizada")
	_add_terminal_output("  nikto             - Escáner de servidores web")
	_add_terminal_output("  john              - Rompedor de contraseñas")
	_add_terminal_output("")
	_add_terminal_output("COMANDOS DE AYUDA:", Color(0.5, 0.5, 1.0))
	_add_terminal_output("  help              - Mostrar esta ayuda")
	_add_terminal_output("  man <herramienta> - Mostrar manual de herramienta")
	_add_terminal_output("  clear             - Limpiar pantalla")
	_add_terminal_output("")
	_add_terminal_output("COMANDOS ESPECIALES:", Color(1.0, 1.0, 0.0))
	_add_terminal_output("  connect           - Conectar al servidor de la misión activa")
	_add_terminal_output("")
	_add_terminal_output("EJEMPLOS:", Color(0.0, 1.0, 1.0))
	_add_terminal_output("  man nmap         - Ver manual de nmap")
	_add_terminal_output("  nmap -sS target.com - Escanear objetivo")
	_add_terminal_output("  connect          - Conectarse al servidor de la misión")
	_add_terminal_output("")
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("")

func _on_minimize_pressed():
	"""Minimiza la ventana"""
	# En Godot 4, usar mode para minimizar
	mode = Window.MODE_MINIMIZED
	terminal_minimized.emit(terminal_id)

func _on_maximize_pressed():
	"""Maximiza o restaura la ventana"""
	if is_maximized:
		# Restaurar
		mode = Window.MODE_WINDOWED  # Asegurar que esté en modo ventana
		size = normal_size
		position = normal_position
		is_maximized = false
		# Cambiar el texto del botón
		if maximize_button:
			maximize_button.text = "□"
		terminal_maximized.emit(terminal_id, false)
		print("[TerminalWindow] Ventana restaurada - Size: ", size, " Position: ", position)
	else:
		# Maximizar
		normal_size = size
		normal_position = position
		var screen_size = DisplayServer.screen_get_size()
		mode = Window.MODE_WINDOWED  # Mantener en modo ventana
		size = screen_size
		position = Vector2i(0, 0)
		is_maximized = true
		# Cambiar el texto del botón a "Restaurar" cuando está maximizada
		if maximize_button:
			maximize_button.text = "▢"  # Símbolo para restaurar (cuadrado con línea)
		terminal_maximized.emit(terminal_id, true)
		print("[TerminalWindow] Ventana maximizada - Size: ", size)

func _on_hints_pressed():
	"""Abre o cierra el panel de hints"""
	if hints_window == null:
		_create_hints_window()
	
	if hints_window_visible:
		hints_window.hide()
		hints_window_visible = false
	else:
		hints_window.show()
		hints_window_visible = true

func _create_hints_window():
	"""Crea la ventana de hints arrastrable, minimizable y cerrable"""
	hints_window = Window.new()
	hints_window.title = "Mission 0 - Hints & Cheatsheet"
	hints_window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	hints_window.size = Vector2i(700, 800)
	hints_window.mode = Window.MODE_WINDOWED
	hints_window.always_on_top = true
	hints_window.close_requested.connect(_on_hints_close_requested)
	
	# Fondo
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hints_window.add_child(bg)
	
	# Contenedor principal
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 5)
	main_container.add_theme_constant_override("margin_left", 10)
	main_container.add_theme_constant_override("margin_right", 10)
	main_container.add_theme_constant_override("margin_top", 10)
	main_container.add_theme_constant_override("margin_bottom", 10)
	hints_window.add_child(main_container)
	
	# Barra de título personalizada para hints
	var hints_title_bar = HBoxContainer.new()
	hints_title_bar.custom_minimum_size = Vector2(0, 35)
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.1, 0.1, 0.2)
	title_style.border_color = Color(0.4, 0.4, 1.0)
	title_style.border_width_bottom = 1
	hints_title_bar.add_theme_stylebox_override("panel", title_style)
	
	var hints_title_label = Label.new()
	hints_title_label.text = "Mission 0 - Hints & Cheatsheet"
	hints_title_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	hints_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints_title_bar.add_child(hints_title_label)
	
	# Botón minimizar hints
	var hints_min_button = Button.new()
	hints_min_button.text = "─"
	hints_min_button.custom_minimum_size = Vector2(35, 35)
	hints_min_button.pressed.connect(func(): hints_window.mode = Window.MODE_MINIMIZED)
	hints_title_bar.add_child(hints_min_button)
	
	# Botón cerrar hints
	var hints_close_button = Button.new()
	hints_close_button.text = "✕"
	hints_close_button.custom_minimum_size = Vector2(35, 35)
	hints_close_button.pressed.connect(_on_hints_close_requested)
	hints_title_bar.add_child(hints_close_button)
	
	main_container.add_child(hints_title_bar)
	
	# Scroll container para el contenido
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	
	# Sección: Flujo de la Misión
	var flow_section = _create_section("🎯 FLUJO DE LA MISIÓN", Color(1.0, 0.8, 0.0))
	content.add_child(flow_section)
	
	var flow_text = RichTextLabel.new()
	flow_text.bbcode_enabled = true
	flow_text.fit_content = true
	flow_text.text = """
[color=yellow]1. ACTIVAR MISIÓN:[/color] Presiona "Activar" en la misión 0

[color=yellow]2. ENUMERACIÓN:[/color] Usa nmap y find para descubrir el servidor

[color=yellow]3. EXPLOTACIÓN:[/color] Detecta Log4Shell y explota para RCE

[color=yellow]4. ACCESO:[/color] Gana acceso al servidor como admin

[color=yellow]5. PUZZLES:[/color] Resuelve los 3 puzzles de seguridad

[color=yellow]6. FLAG:[/color] Lee la flag antes de que el servidor se cierre
"""
	content.add_child(flow_text)
	
	# Sección: Enumeración
	var enum_section = _create_section("📡 ENUMERACIÓN", Color(0.0, 1.0, 1.0))
	content.add_child(enum_section)
	
	var enum_text = RichTextLabel.new()
	enum_text.bbcode_enabled = true
	enum_text.fit_content = true
	enum_text.text = """
[color=cyan]OBJETIVO:[/color] Enumerar exhaustivamente el sistema objetivo.

[color=yellow]COMANDOS REQUERIDOS:[/color]
• [color=green]nmap -sV -p- 192.168.1.100[/color] - Escaneo completo
• [color=green]find / -name "*.pem" 2>/dev/null[/color] - Certificados
• [color=green]find / -name "*honeypot*" 2>/dev/null[/color] - Honeypots
• [color=green]find / -name "*.enc" 2>/dev/null[/color] - Archivos encriptados
• [color=green]find / -name "*protocol*" 2>/dev/null[/color] - Protocolos
• [color=green]find / -name "*log4j*.jar" 2>/dev/null[/color] - Log4j JARs
• [color=green]find / -name "log4j2.xml" 2>/dev/null[/color] - Config Log4j
"""
	content.add_child(enum_text)
	
	# Sección: Log4Shell Exploit
	var log4shell_section = _create_section("🔥 LOG4SHELL (CVE-2021-44228)", Color(1.0, 0.3, 0.3))
	content.add_child(log4shell_section)
	
	var log4shell_text = RichTextLabel.new()
	log4shell_text.bbcode_enabled = true
	log4shell_text.fit_content = true
	log4shell_text.text = """
[color=cyan]OBJETIVO:[/color] Explotar Log4Shell para obtener RCE y shell en el servidor.

[color=yellow]PISTAS DE VULNERABILIDAD:[/color]
1. [color=green]whatweb server.nsa-langley.internal[/color] - Descubre la IP del servidor
2. [color=green]nmap -sV -p 8080 [IP][/color] - Muestra: Apache Tomcat 9.0.65 en puerto 8080
3. [color=green]curl http://[IP]:8080/nonexistent[/color] - Stack trace muestra Log4j
4. [color=green]find / -name "*log4j*.jar"[/color] - Encuentra log4j-core-2.14.1.jar
5. [color=green]cat /opt/tomcat/VERSION.txt[/color] - Muestra versión vulnerable
6. [color=green]cat /opt/tomcat/README.txt[/color] - Menciona CVE-2021-44228

[color=yellow]EXPLOTACIÓN REAL DE LOG4SHELL:[/color]
1. [color=green]MY_IP=$(ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1)[/color] - Obtener tu IP
2. [color=green]compile-exploit $MY_IP[/color] - Compila exploit Java (o usa ~/scripts/compile_exploit.sh)
3. [color=green]~/scripts/start_log4shell_servers.sh[/color] - Inicia marshalsec LDAP (puerto 1389) y HTTP (puerto 8000)
4. [color=green]socat TCP-LISTEN:4444,fork,reuseaddr EXEC:/bin/bash &[/color] - Listener reverse shell
5. [color=green]~/scripts/exploit_log4shell_real.sh[/color] - Envía payload real con JNDI LDAP
• O simplificado: [color=green]~/scripts/exploit_log4shell.sh --local-ip $MY_IP --target-ip 10.10.0.100[/color]

[color=yellow]HERRAMIENTAS PREINSTALADAS (kali-6me:latest):[/color]
✅ [color=green]kali-linux-default[/color] - Todas las herramientas de Kali (nmap, metasploit, wireshark, etc.)
✅ [color=green]Java y Maven[/color] - Preinstalados para compilar exploits
✅ [color=green]Marshalsec[/color] - Precompilado en /opt/marshalsec/marshalsec.jar (listo para usar)
✅ [color=green]Exploit template[/color] - En /home/player/exploit_log4shell/ con script compile-exploit
✅ [color=green]Scripts de misión[/color] - En ~/scripts/ (enumerate.sh, exploit_log4shell.sh, etc.)

[color=cyan]NOTA:[/color] No necesitas instalar nada. Todas las herramientas están disponibles al iniciar.
"""
	content.add_child(log4shell_text)
	
	# Sección: Puzzle 1
	var puzzle1_section = _create_section("🔐 PUZZLE 1: Suplantación de Identidad", Color(0.0, 1.0, 0.4))
	content.add_child(puzzle1_section)
	
	var puzzle1_text = RichTextLabel.new()
	puzzle1_text.bbcode_enabled = true
	puzzle1_text.fit_content = true
	puzzle1_text.text = """
[color=cyan]OBJETIVO:[/color] Construir cert_steal.sh que robe y use el certificado digital del director adjunto.

[color=yellow]PISTAS:[/color]
1. El certificado está en [color=green]/etc/ssl/certs/director_adjunto.pem[/color]
2. Usa [color=green]openssl x509 -in /etc/ssl/certs/director_adjunto.pem -text[/color] para ver detalles
3. Copia el certificado a [color=green]~/.ssh/[/color] para suplantar la identidad
4. El script debe mostrar [color=green][+] Identity spoofed successfully[/color] al completarse

[color=yellow]ESTRUCTURA DEL SCRIPT:[/color]
[code]
#!/bin/bash
# Tu código aquí
echo "[+] Identity spoofed successfully"
[/code]
"""
	content.add_child(puzzle1_text)
	
	# Sección: Puzzle 2
	var puzzle2_section = _create_section("🌐 PUZZLE 2: Redirección Tor", Color(0.0, 1.0, 0.4))
	content.add_child(puzzle2_section)
	
	var puzzle2_text = RichTextLabel.new()
	puzzle2_text.bbcode_enabled = true
	puzzle2_text.fit_content = true
	puzzle2_text.text = """
[color=cyan]OBJETIVO:[/color] Construir tor_route.sh que redirija tráfico por Tor y evite honeypots.

[color=yellow]PISTAS:[/color]
1. Los honeypots están en [color=green]/var/log/nsa/honeypots.txt[/color]
2. Instala Tor: [color=green]apt-get install tor proxychains4[/color]
3. Usa [color=green]proxychains[/color] o [color=green]torify[/color] para enrutar conexiones
4. El script debe mostrar:
   • [color=green][+] Tor route established[/color]
   • [color=green][+] Honeypot avoided[/color]

[color=yellow]ESTRUCTURA DEL SCRIPT:[/color]
[code]
#!/bin/bash
# Tu código aquí
echo "[+] Tor route established"
echo "[+] Honeypot avoided"
[/code]
"""
	content.add_child(puzzle2_text)
	
	# Sección: Puzzle 3
	var puzzle3_section = _create_section("⚛️ PUZZLE 3: Decodificación Cuántica", Color(0.0, 1.0, 0.4))
	content.add_child(puzzle3_section)
	
	var puzzle3_text = RichTextLabel.new()
	puzzle3_text.bbcode_enabled = true
	puzzle3_text.fit_content = true
	puzzle3_text.text = """
[color=cyan]OBJETIVO:[/color] Construir quantum_decode.py que decodifique protocol_cronos.enc usando XOR.

[color=yellow]PISTAS:[/color]
1. Archivo a decodificar: [color=green]/opt/nsa-server/protocols/protocol_cronos.enc[/color]
2. Algoritmo: XOR con patrón [color=green]"CRONOS-7-ALPHA"[/color] repetido
3. Lee el archivo, aplica XOR byte a byte con el patrón
4. El script debe mostrar:
   • [color=green][+] Decoded successfully[/color]
   • [color=green][+] CRONOS-7 device blueprints unlocked[/color]

[color=yellow]ESTRUCTURA DEL SCRIPT:[/color]
[code]
#!/usr/bin/env python3
import sys
# Tu código aquí
print("[+] Decoded successfully")
print("[+] CRONOS-7 device blueprints unlocked")
[/code]
"""
	content.add_child(puzzle3_text)
	
	# Sección: Cheatsheet
	var cheatsheet_section = _create_section("📚 CHEATSHEET - Comandos Clave", Color(1.0, 0.8, 0.0))
	content.add_child(cheatsheet_section)
	
	var cheatsheet_text = RichTextLabel.new()
	cheatsheet_text.bbcode_enabled = true
	cheatsheet_text.fit_content = true
	cheatsheet_text.text = """
[color=yellow]NAVEGACIÓN:[/color]
• [color=green]ls -la[/color] - Listar archivos con detalles
• [color=green]cd /ruta[/color] - Cambiar directorio
• [color=green]pwd[/color] - Mostrar directorio actual
• [color=green]find / -name "patrón" 2>/dev/null[/color] - Buscar archivos

[color=yellow]LECTURA DE ARCHIVOS:[/color]
• [color=green]cat archivo[/color] - Mostrar contenido completo
• [color=green]head -n 20 archivo[/color] - Primeras 20 líneas
• [color=green]tail -n 20 archivo[/color] - Últimas 20 líneas
• [color=green]grep "texto" archivo[/color] - Buscar texto en archivo

[color=yellow]ENUMERACIÓN:[/color]
• [color=green]connect[/color] - Conectarse a la red compartida (10.10.0.0/24) - ⭐ PRIMERO
• [color=green]whatweb server.nsa-langley.internal[/color] - Descubrir IP del servidor
• [color=green]nmap -sV -p 8080 10.10.0.100[/color] - Escanear puerto específico
• [color=green]nmap -sV -p- 10.10.0.100[/color] - Escaneo completo
• [color=green]find / -type f -perm -4000 2>/dev/null[/color] - Archivos SUID

[color=yellow]CREACIÓN DE SCRIPTS:[/color]
• [color=green]nano script.sh[/color] - Editor nano
• [color=green]vim script.sh[/color] - Editor vim
• [color=green]chmod +x script.sh[/color] - Hacer ejecutable
• [color=green]bash script.sh[/color] - Ejecutar script bash
• [color=green]python3 script.py[/color] - Ejecutar script Python

[color=yellow]RED Y CONEXIÓN:[/color]
• [color=green]connect[/color] - Conectarse a la red compartida (10.10.0.0/24) - ⭐ HACER PRIMERO
• [color=green]ip addr show | grep 'inet 10.10.0'[/color] - Obtener tu IP en la red compartida
• [color=green]ss -antp | grep :4444[/color] - Verificar conexiones reverse shell
• [color=green]proxychains comando[/color] - Ejecutar comando por Tor
• [color=green]torify comando[/color] - Ejecutar comando por Tor (alternativa)

[color=yellow]BÚSQUEDA AVANZADA:[/color]
• [color=green]find / -name "*.pem" -type f 2>/dev/null[/color] - Certificados
• [color=green]find / -name "*cronos*" 2>/dev/null[/color] - Archivos Cronos
• [color=green]find / -size +1000k 2>/dev/null[/color] - Archivos grandes
• [color=green]grep -r "texto" /ruta 2>/dev/null[/color] - Búsqueda recursiva
"""
	content.add_child(cheatsheet_text)
	
	# Añadir la ventana como hijo de la terminal
	add_child(hints_window)
	hints_window_visible = false
	hints_window.hide()

func _create_section(title: String, color: Color) -> VBoxContainer:
	"""Crea una sección con título"""
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", color)
	title_label.add_theme_font_size_override("font_size", 16)
	section.add_child(title_label)
	
	var separator = HSeparator.new()
	section.add_child(separator)
	
	return section

func _on_hints_close_requested():
	"""Cierra el panel de hints"""
	if hints_window:
		hints_window.hide()
		hints_window_visible = false

func _on_close_pressed():
	"""Cierra la terminal"""
	_close_terminal()

func _on_close_requested():
	"""Maneja el evento de cierre de ventana"""
	_close_terminal()

func _close_terminal():
	"""Cierra la terminal y notifica al backend"""
	if terminal_id != "":
		var request_data = {
			"jsonrpc": "2.0",
			"method": "close_terminal",
			"params": {
				"terminal_id": terminal_id
			},
			"id": Time.get_ticks_msec()
		}
		
		var headers = ["Content-Type: application/json"]
		var body = JSON.stringify(request_data)
		
		# Enviar en background (no esperar respuesta)
		var temp_request = HTTPRequest.new()
		add_child(temp_request)
		temp_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)
		temp_request.request_completed.connect(func(_r, _c, _h, _b): temp_request.queue_free())
	
	terminal_closed.emit(terminal_id)
	queue_free()

func set_terminal_id(id: String):
	"""Establece el ID de la terminal"""
	terminal_id = id
	if terminal_output:
		_initialize_terminal()

func set_scenario(scenario_name: String):
	"""Establece el escenario de la terminal"""
	scenario = scenario_name

func _request_new_tab():
	"""Crea una nueva pestaña de terminal dentro de la misma ventana"""
	_create_new_terminal_tab()

func _setup_tabs_system():
	"""Configura el sistema de pestañas"""
	if tabs_container == null:
		tabs_container = HBoxContainer.new()
		tabs_container.name = "TabsContainer"
		tabs_container.custom_minimum_size = Vector2(0, 30)
		tabs_container.add_theme_constant_override("separation", 2)
		
		# Estilo cyberpunk para el contenedor de pestañas
		var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
		var tabs_style = StyleBoxFlat.new()
		tabs_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
		if CyberpunkThemeClass:
			tabs_style.border_color = CyberpunkThemeClass.COLOR_NEON_CYAN
		else:
			tabs_style.border_color = Color(0.0, 1.0, 1.0)
		tabs_style.border_width_bottom = 2
		tabs_container.add_theme_stylebox_override("panel", tabs_style)

func _create_new_terminal_tab():
	"""Crea una nueva pestaña de terminal"""
	tab_counter += 1
	var tab_id = "tab_" + str(tab_counter)
	
	# Crear botón de pestaña
	var tab_button = Button.new()
	tab_button.text = "Terminal " + str(tab_counter)
	tab_button.custom_minimum_size = Vector2(120, 25)
	tab_button.toggle_mode = true
	tab_button.button_pressed = false
	
	# Botón de cerrar
	var close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(20, 20)
	close_button.flat = true
	
	# Contenedor para botón y close
	var tab_content = HBoxContainer.new()
	tab_content.add_theme_constant_override("separation", 5)
	tab_content.add_child(tab_button)
	tab_content.add_child(close_button)
	
	if tabs_container:
		tabs_container.add_child(tab_content)
	
	# Crear panel de terminal para esta pestaña
	var terminal_panel = _create_terminal_panel_for_tab(tab_id)
	
	# Guardar referencia
	tabs[tab_id] = {
		"button": tab_button,
		"close_button": close_button,
		"content": tab_content,
		"panel": terminal_panel,
		"terminal_id": "",
		"terminal_output": null,
		"terminal_input": null,
		"command_history": [],
		"history_index": -1
	}
	
	# Conectar señales
	var captured_tab_id = tab_id
	tab_button.pressed.connect(func(): _on_tab_selected(captured_tab_id))
	close_button.pressed.connect(func(): _on_tab_close_requested(captured_tab_id))
	
	# Activar la nueva pestaña
	_on_tab_selected(tab_id)
	
	# Asegurar que el input de la nueva pestaña reciba focus
	if tabs.has(tab_id) and tabs[tab_id].has("terminal_input") and tabs[tab_id].terminal_input:
		var tab_input = tabs[tab_id].terminal_input
		if tab_input and tab_input.is_inside_tree():
			tab_input.call_deferred("grab_focus")
			var text_length = tab_input.text.length()
			tab_input.call_deferred("set", "caret_column", text_length)
	
	# Crear terminal en el backend
	_create_backend_terminal_for_tab(tab_id)

func _create_terminal_panel_for_tab(tab_id: String) -> Control:
	"""Crea un panel de terminal para una pestaña"""
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var panel = Panel.new()
	panel.name = "TerminalPanel_" + tab_id
	panel.visible = false
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL  # Mismo comportamiento que el panel principal
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # No bloquear eventos cuando está oculto
	panel.z_index = 0  # Asegurar que esté detrás de la barra de título
	
	var terminal_style: StyleBoxFlat
	if CyberpunkThemeClass:
		terminal_style = CyberpunkThemeClass.create_terminal_panel_style()
	else:
		terminal_style = StyleBoxFlat.new()
		terminal_style.bg_color = Color(0.0, 0.0, 0.0)
	panel.add_theme_stylebox_override("panel", terminal_style)
	
	# Añadir al main_container en el mismo lugar que el panel principal
	# Esto permite que se muestre/oculte correctamente con las pestañas
	var main_container = tabs_container.get_parent() if tabs_container else null
	if main_container:
		main_container.add_child(panel)
	
	var terminal_vbox = VBoxContainer.new()
	terminal_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	terminal_vbox.add_theme_constant_override("margin_left", 10)
	terminal_vbox.add_theme_constant_override("margin_right", 10)
	terminal_vbox.add_theme_constant_override("margin_top", 10)
	terminal_vbox.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(terminal_vbox)
	
	# Output unificado (TextEdit como terminal principal)
	var output = TextEdit.new()
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.editable = true
	output.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	var terminal_color = CyberpunkThemeClass.COLOR_NEON_GREEN if CyberpunkThemeClass else Color(0.0, 1.0, 0.4)
	output.add_theme_color_override("font_color", terminal_color)
	output.add_theme_color_override("background_color", Color(0.0, 0.0, 0.0))
	output.selecting_enabled = true
	terminal_vbox.add_child(output)
	
	# Input
	var input_container = HBoxContainer.new()
	terminal_vbox.add_child(input_container)
	
	var prompt = Label.new()
	prompt.text = "6me@shell:~$ "
	var prompt_color = Color(1.0, 0.0, 0.0)  # Rojo
	prompt.add_theme_color_override("font_color", prompt_color)
	prompt.add_theme_font_size_override("font_size", 14)
	input_container.add_child(prompt)
	
	var input = LineEdit.new()
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.editable = true
	input.shortcut_keys_enabled = true
	input.mouse_filter = Control.MOUSE_FILTER_STOP  # Asegurar que reciba eventos de mouse
	input.add_theme_color_override("font_color", terminal_color)
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	input_style.border_color = CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 1.0)
	input_style.border_width_left = 1
	input_style.border_width_right = 1
	input_style.border_width_top = 1
	input_style.border_width_bottom = 1
	input.add_theme_stylebox_override("normal", input_style)
	input.add_theme_stylebox_override("focus", input_style)
	
	var captured_tab_id = tab_id
	input.text_submitted.connect(func(cmd: String): _on_tab_command_submitted(captured_tab_id, cmd))
	input.gui_input.connect(func(e: InputEvent): _on_tab_input_gui_input(captured_tab_id, e))
	input.focus_entered.connect(func(): _on_input_focus_entered())
	input.focus_exited.connect(func(): _on_input_focus_exited())
	input_container.add_child(input)
	
	# Guardar referencias en el diccionario de tabs
	if tabs.has(tab_id):
		tabs[tab_id].terminal_output = output
		tabs[tab_id].terminal_input = input
	
	return panel

func update_scenario(new_scenario: String):
	"""Actualiza el escenario de la terminal (para sincronización con misiones)"""
	if scenario != new_scenario and new_scenario != "":
		scenario = new_scenario
		print("[TerminalWindow] Escenario actualizado: ", scenario)
		# Reinicializar terminal con nuevo escenario
		_initialize_terminal()

func _handle_editor_command(command: String, editor: String):
	"""Maneja comandos de editores de texto (nano, vim)"""
	var cmd_parts = command.strip_edges().split(" ", false)
	var filename = ""
	
	# Extraer nombre de archivo del comando
	if cmd_parts.size() > 1:
		filename = cmd_parts[1]
	
	if filename == "":
		_add_terminal_output("Uso: " + editor + " <archivo>", Color(1.0, 0.0, 0.0))
		call_deferred("_restore_focus")
		return
	
	# Abrir editor de texto
	_open_text_editor(filename, editor)

func _open_text_editor(filename: String, editor: String):
	"""Abre el editor de texto para editar un archivo"""
	# Primero, leer el archivo del contenedor Docker
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "read_file",
		"params": {
			"terminal_id": terminal_id,
			"file_path": filename
		},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	http_request.set_meta("request_id", request_id)
	http_request.set_meta("filename", filename)
	http_request.set_meta("editor", editor)
	add_child(http_request)
	pending_requests[request_id] = http_request
	
	var callback = func(res: int, code: int, hdrs: PackedStringArray, bdy: PackedByteArray):
		_on_file_read_response(request_id, res, code, hdrs, bdy)
	
	http_request.request_completed.connect(callback)
	
	var error = http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("[TerminalWindow] Error leyendo archivo: ", error)
		_add_terminal_output("Error: No se pudo leer el archivo", Color(1.0, 0.0, 0.0))
		pending_requests.erase(request_id)
		http_request.queue_free()
		call_deferred("_restore_focus")

func _on_file_read_response(request_id: int, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa respuesta de lectura de archivo"""
	var filename = ""
	var editor = ""
	if pending_requests.has(request_id):
		var http_request = pending_requests[request_id]
		filename = http_request.get_meta("filename", "")
		editor = http_request.get_meta("editor", "nano")
		pending_requests.erase(request_id)
		http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_add_terminal_output("Error: No se pudo leer el archivo", Color(1.0, 0.0, 0.0))
		call_deferred("_restore_focus")
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(response_text)
	
	if parse_error != OK:
		_add_terminal_output("Error: Respuesta inválida del servidor", Color(1.0, 0.0, 0.0))
		call_deferred("_restore_focus")
		return
	
	var response_data = json.get_data()
	var result_data = response_data.get("result", {})
	
	if result_data.has("success") and result_data.get("success", false):
		var content = result_data.get("content", "")
		# Crear y mostrar ventana de editor
		_create_editor_window(filename, content, editor)
	else:
		var error = result_data.get("error", "Error desconocido")
		_add_terminal_output("Error: " + str(error), Color(1.0, 0.0, 0.0))
		call_deferred("_restore_focus")

func _handle_editor_input(event: InputEvent, text_edit: TextEdit):
	"""Maneja atajos de teclado en el editor (undo/redo)"""
	if event is InputEventKey and event.pressed:
		var key_event = event as InputEventKey
		# Ctrl+Z para undo
		if key_event.keycode == KEY_Z and key_event.ctrl_pressed:
			text_edit.undo()
			get_viewport().set_input_as_handled()
		# Ctrl+Y para redo
		elif key_event.keycode == KEY_Y and key_event.ctrl_pressed:
			text_edit.redo()
			get_viewport().set_input_as_handled()
		# Ctrl+S para guardar
		elif key_event.keycode == KEY_S and key_event.ctrl_pressed:
			var filename = text_edit.get_meta("filename", "")
			var editor_window = text_edit.get_meta("editor_window", null)
			if filename != "" and editor_window != null:
				_save_file_from_editor(filename, text_edit.text, editor_window)
			get_viewport().set_input_as_handled()

func _create_editor_window(filename: String, content: String, editor: String):
	"""Crea una ventana de editor de texto"""
	var editor_window = Window.new()
	editor_window.title = editor.to_upper() + " - " + filename
	editor_window.size = Vector2i(800, 600)
	editor_window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 5)
	container.add_theme_constant_override("margin_left", 5)
	container.add_theme_constant_override("margin_right", 5)
	container.add_theme_constant_override("margin_top", 5)
	container.add_theme_constant_override("margin_bottom", 5)
	editor_window.add_child(container)
	
	# Barra de estado (estilo nano/vim)
	var status_bar = HBoxContainer.new()
	status_bar.custom_minimum_size = Vector2(0, 25)
	var status_label = Label.new()
	status_label.text = "Archivo: " + filename + " | " + editor.to_upper()
	status_label.add_theme_font_size_override("font_size", 11)
	status_bar.add_child(status_label)
	container.add_child(status_bar)
	
	# Área de texto con soporte para undo/redo
	var text_edit = TextEdit.new()
	text_edit.text = content
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_edit.set_meta("editor_window", editor_window)
	text_edit.set_meta("filename", filename)
	# Habilitar undo/redo
	text_edit.set_meta("undo_enabled", true)
	# Conectar señal para manejar atajos de teclado
	text_edit.gui_input.connect(func(event: InputEvent):
		_handle_editor_input(event, text_edit)
	)
	container.add_child(text_edit)
	
	# Barra de ayuda
	var help_bar = HBoxContainer.new()
	help_bar.custom_minimum_size = Vector2(0, 25)
	var help_label = Label.new()
	if editor == "nano":
		help_label.text = "^O Guardar | ^X Salir | ^W Buscar"
	elif editor == "vim" or editor == "vi":
		help_label.text = "Esc :w Guardar | Esc :q Salir | Esc :wq Guardar y Salir"
	help_label.add_theme_font_size_override("font_size", 10)
	help_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	help_bar.add_child(help_label)
	container.add_child(help_bar)
	
	# Botones
	var button_bar = HBoxContainer.new()
	button_bar.add_theme_constant_override("separation", 10)
	
	var save_button = Button.new()
	save_button.text = "Guardar (Ctrl+S)"
	save_button.custom_minimum_size = Vector2(120, 30)
	save_button.pressed.connect(func():
		_save_file_from_editor(filename, text_edit.text, editor_window)
	)
	button_bar.add_child(save_button)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.custom_minimum_size = Vector2(100, 30)
	cancel_button.pressed.connect(func():
		editor_window.queue_free()
		call_deferred("_restore_focus")
	)
	button_bar.add_child(cancel_button)
	
	container.add_child(button_bar)
	
	# Añadir ventana al árbol
	get_tree().root.add_child(editor_window)
	editor_window.popup_centered()

func _save_file_from_editor(filename: String, content: String, editor_window: Window):
	"""Guarda el contenido del editor al archivo en Docker"""
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "write_file",
		"params": {
			"terminal_id": terminal_id,
			"file_path": filename,
			"content": content
		},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	http_request.set_meta("request_id", request_id)
	http_request.set_meta("editor_window", editor_window)
	add_child(http_request)
	pending_requests[request_id] = http_request
	
	var callback = func(res: int, code: int, hdrs: PackedStringArray, bdy: PackedByteArray):
		_on_file_write_response(request_id, res, code, hdrs, bdy)
	
	http_request.request_completed.connect(callback)
	
	var error = http_request.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("[TerminalWindow] Error guardando archivo: ", error)
		_add_terminal_output("Error: No se pudo guardar el archivo", Color(1.0, 0.0, 0.0))
		pending_requests.erase(request_id)
		http_request.queue_free()

func _on_file_write_response(request_id: int, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa respuesta de escritura de archivo"""
	var editor_window = null
	if pending_requests.has(request_id):
		var http_request = pending_requests[request_id]
		editor_window = http_request.get_meta("editor_window", null)
		pending_requests.erase(request_id)
		http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_add_terminal_output("Error: No se pudo guardar el archivo", Color(1.0, 0.0, 0.0))
		if editor_window:
			editor_window.queue_free()
		call_deferred("_restore_focus")
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(response_text)
	
	if parse_error != OK:
		_add_terminal_output("Error: Respuesta inválida del servidor", Color(1.0, 0.0, 0.0))
		if editor_window:
			editor_window.queue_free()
		call_deferred("_restore_focus")
		return
	
	var response_data = json.get_data()
	var result_data = response_data.get("result", {})
	
	if result_data.has("success") and result_data.get("success", false):
		_add_terminal_output("Archivo guardado exitosamente", Color(0.0, 1.0, 0.0))
		if editor_window:
			editor_window.queue_free()
	else:
		var error = result_data.get("error", "Error desconocido")
		_add_terminal_output("Error: " + str(error), Color(1.0, 0.0, 0.0))
	
	call_deferred("_restore_focus")
