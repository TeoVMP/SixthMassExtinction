# Mission0Scene.gd
# Escena de la Misión 0: La Brecha de la NSA
# BONUS HACKER - Siempre disponible hasta completarse
extends Control
class_name Mission0Scene

signal mission_completed(result: Dictionary)
signal mission_failed(reason: String)

var mission_completed_flag: bool = false
var terminal_output: RichTextLabel = null
var terminal_input: LineEdit = null
var command_history: Array = []
var history_index: int = -1

# Estado de la misión
var connected: bool = false
var files_found: Array = []
var protocol_found: bool = false

# Backend connection
var backend_url: String = "http://localhost:8080/rpc"
var http_request: HTTPRequest = null
var using_docker: bool = false

# Sistema de quests
var quest_system: Mission0QuestSystem = null

# Sistema de puzzles
var puzzle_system: Mission0PuzzleSystem = null

# Estado de la misión
var mission_domain: String = "server.nsa-langley.internal"  # Domain name del servidor NSA (el jugador debe descubrir la IP con whatweb)
var mission_ip: String = "10.10.0.100"  # IP del servidor NSA (se descubre con whatweb)
var puzzles_completed: int = 0
var cronos_device_found: bool = false
var elara_message_found: bool = false

func _ready():
	print("Mision 0: La Brecha de la NSA iniciada")
	_setup_mission_ui()
	_setup_backend_connection()
	_initialize_terminal()
	_setup_quest_system()
	_setup_puzzle_system()
	_show_mission_intro()

func _setup_backend_connection():
	"""Configura la conexión con el backend"""
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_backend_response)
	
	# Verificar estado del terminal
	_check_terminal_status()

func _setup_mission_ui():
	"""Configura la UI de la misión"""
	# Fondo oscuro (terminal style)
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0)  # Negro puro
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Contenedor principal
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 10)
	main_container.add_theme_constant_override("margin_left", 20)
	main_container.add_theme_constant_override("margin_right", 20)
	main_container.add_theme_constant_override("margin_top", 20)
	main_container.add_theme_constant_override("margin_bottom", 20)
	add_child(main_container)
	
	# Título
	var title = Label.new()
	title.text = "MISIÓN 0: LA BRECHA DE LA NSA"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))  # Verde terminal
	main_container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Maryland, EE.UU. - 15 de marzo de 2055 | Terminal de Hacking"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	main_container.add_child(subtitle)
	
	# Terminal output (área de texto)
	var terminal_panel = Panel.new()
	terminal_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var terminal_style = StyleBoxFlat.new()
	terminal_style.bg_color = Color(0.0, 0.0, 0.0)
	terminal_style.border_color = Color(0.0, 1.0, 0.0)
	terminal_style.border_width_left = 2
	terminal_style.border_width_right = 2
	terminal_style.border_width_top = 2
	terminal_style.border_width_bottom = 2
	terminal_panel.add_theme_stylebox_override("panel", terminal_style)
	main_container.add_child(terminal_panel)
	
	var terminal_vbox = VBoxContainer.new()
	terminal_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	terminal_vbox.add_theme_constant_override("margin_left", 10)
	terminal_vbox.add_theme_constant_override("margin_right", 10)
	terminal_vbox.add_theme_constant_override("margin_top", 10)
	terminal_vbox.add_theme_constant_override("margin_bottom", 10)
	terminal_panel.add_child(terminal_vbox)
	
	# Output de terminal
	terminal_output = RichTextLabel.new()
	terminal_output.bbcode_enabled = true
	terminal_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	terminal_output.scroll_following = true
	terminal_output.add_theme_color_override("default_color", Color(0.0, 1.0, 0.0))  # Verde
	terminal_vbox.add_child(terminal_output)
	
	# Input de terminal
	var input_container = HBoxContainer.new()
	terminal_vbox.add_child(input_container)
	
	var prompt = Label.new()
	prompt.text = "hacker@nsa-breach:~$ "
	prompt.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	prompt.add_theme_font_size_override("font_size", 14)
	input_container.add_child(prompt)
	
	terminal_input = LineEdit.new()
	terminal_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terminal_input.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	terminal_input.add_theme_color_override("font_selected_color", Color(0.0, 0.0, 0.0))
	terminal_input.add_theme_color_override("font_uneditable_color", Color(0.0, 1.0, 0.0))
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color(0.0, 0.0, 0.0)
	input_style.border_color = Color(0.0, 1.0, 0.0)
	input_style.border_width_left = 1
	input_style.border_width_right = 1
	input_style.border_width_top = 1
	input_style.border_width_bottom = 1
	terminal_input.add_theme_stylebox_override("normal", input_style)
	terminal_input.add_theme_stylebox_override("focus", input_style)
	terminal_input.text_submitted.connect(_on_command_submitted)
	terminal_input.gui_input.connect(_on_terminal_input_gui_input)
	input_container.add_child(terminal_input)
	
	# Botones
	var button_container = HBoxContainer.new()
	main_container.add_child(button_container)
	
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.custom_minimum_size = Vector2(150, 40)
	close_button.pressed.connect(func(): 
		var window = get_parent()
		if window is Window:
			window.queue_free()
	)
	button_container.add_child(close_button)
	
	var help_button = Button.new()
	help_button.text = "Ayuda (help)"
	help_button.custom_minimum_size = Vector2(150, 40)
	help_button.pressed.connect(func(): _execute_command("help"))
	button_container.add_child(help_button)

func _initialize_terminal():
	"""Inicializa la terminal con mensaje de bienvenida"""
	_add_terminal_output("═══════════════════════════════════════════════════════")
	_add_terminal_output("NSA BREACH TERMINAL v2.1")
	_add_terminal_output("═══════════════════════════════════════════════════════")
	_add_terminal_output("")
	_add_terminal_output("Objetivo: Infiltrar servidores de Langley y encontrar el Protocolo Cronos")
	_add_terminal_output("")
	_add_terminal_output("SERVIDOR OBJETIVO: " + mission_ip, Color(0.0, 1.0, 1.0))
	_add_terminal_output("")
	if using_docker:
		_add_terminal_output("Conectado a Kali Linux (Docker)", Color(0.0, 1.0, 0.0))
	else:
		_add_terminal_output("Modo simulado (Docker no disponible)", Color(1.0, 1.0, 0.0))
	_add_terminal_output("")
	_add_terminal_output("Escribe 'help' para ver comandos disponibles")
	_add_terminal_output("Domain name del objetivo: " + mission_domain)
	_add_terminal_output("Usa 'whatweb " + mission_domain + "' para descubrir la IP del servidor")
	_add_terminal_output("Luego explota Log4Shell: 'exploit log4shell " + mission_domain + "'")
	_add_terminal_output("")
	terminal_input.grab_focus()

func _show_mission_intro():
	"""Muestra la introducción narrativa de la misión"""
	await get_tree().create_timer(1.0).timeout
	_add_terminal_output("")
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("MISIÓN 0: LA BRECHA DE LA NSA", Color(0.0, 1.0, 1.0))
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("")
	_add_terminal_output("Maryland, EE.UU. - 15 de marzo de 2055 - 03:47 AM", Color(0.7, 0.7, 0.7))
	_add_terminal_output("")
	_add_terminal_output("Estás en tu apartamento en Estocolmo. Líneas de código verde", Color(0.0, 1.0, 0.4))
	_add_terminal_output("parpadean en tu pantalla mientras tecleas furiosamente.", Color(0.0, 1.0, 0.4))
	_add_terminal_output("")
	_add_terminal_output("\"Están escondiendo algo en los servidores de Langley.\"", Color(1.0, 1.0, 0.0))
	_add_terminal_output("\"Algo más grande que armas, más grande que espionaje.\"", Color(1.0, 1.0, 0.0))
	_add_terminal_output("\"Hablan de 'Protocolo Cronos' en canales encriptados.\"", Color(1.0, 1.0, 0.0))
	_add_terminal_output("")
	_add_terminal_output("Maya (en auriculares): \"Alexei, el cortafuegos cuántico se reinicia", Color(0.0, 1.0, 1.0))
	_add_terminal_output("en 10 minutos. Tenemos tiempo, pero no mucho. Enumera primero.\"", Color(0.0, 1.0, 1.0))
	_add_terminal_output("")
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("OBJETIVO: Infiltrar 3 capas de seguridad", Color(1.0, 1.0, 0.0))
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("")
	_add_terminal_output("⚠️ PRIMERO: Enumera exhaustivamente el sistema objetivo:", Color(1.0, 0.5, 0.0))
		_add_terminal_output("  • whatweb " + mission_domain + "  # Descubrir IP del servidor", Color(1.0, 0.7, 0.0))
		_add_terminal_output("  • nmap -sV -p- [IP_DESCUBIERTA]", Color(1.0, 0.7, 0.0))
	_add_terminal_output("  • find / -name '*.pem' 2>/dev/null", Color(1.0, 0.7, 0.0))
	_add_terminal_output("  • find / -name '*honeypot*' 2>/dev/null", Color(1.0, 0.7, 0.0))
	_add_terminal_output("  • find / -name '*.enc' 2>/dev/null", Color(1.0, 0.7, 0.0))
	_add_terminal_output("  • find / -name '*protocol*' 2>/dev/null", Color(1.0, 0.7, 0.0))
	_add_terminal_output("")
	_add_terminal_output("Puzzle 1: Construye un script para suplantar identidad", Color(0.0, 1.0, 0.4))
	_add_terminal_output("  → Pista: Busca certificados en /etc/ssl/certs/", Color(0.5, 0.5, 1.0))
	_add_terminal_output("  → Objetivo: Crear cert_steal.sh que robe el certificado del director adjunto", Color(0.5, 0.5, 1.0))
	_add_terminal_output("")
	_add_terminal_output("Puzzle 2: Construye un script para redirigir tráfico por Tor", Color(0.0, 1.0, 0.4))
	_add_terminal_output("  → Pista: Usa proxychains o torify para enrutar conexiones", Color(0.5, 0.5, 1.0))
	_add_terminal_output("  → Objetivo: Crear tor_route.sh que evite honeypots detectados", Color(0.5, 0.5, 1.0))
	_add_terminal_output("")
	_add_terminal_output("Puzzle 3: Construye un script para decodificar archivo .chrono", Color(0.0, 1.0, 0.4))
	_add_terminal_output("  → Pista: El algoritmo cuántico usa XOR con patrón específico", Color(0.5, 0.5, 1.0))
	_add_terminal_output("  → Objetivo: Crear quantum_decode.py que decodifique protocol_cronos.enc", Color(0.5, 0.5, 1.0))
	_add_terminal_output("")
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("")

func _setup_quest_system():
	"""Configura el sistema de quests"""
	if quest_system:
		# Si ya existe, no crear otro
		return
	
	quest_system = Mission0QuestSystem.new()
	add_child(quest_system)
	
	# Añadir panel de quests a la UI (solo si no existe ya)
	if quest_system.get_panel():
		# Verificar si ya existe un panel con el mismo nombre
		var existing_panel = get_node_or_null("QuestPanel")
		if existing_panel:
			existing_panel.queue_free()
		add_child(quest_system.get_panel())
	
	# Conectar señales
	quest_system.quest_completed.connect(_on_quest_completed)
	quest_system.all_quests_completed.connect(_on_all_quests_completed)

func _on_quest_completed(quest_id: String):
	"""Se llama cuando una quest se completa"""
	print("Quest completada: ", quest_id)
	match quest_id:
		"connect_server":
			connected = true
			quest_system.update_quest_progress("connect_server", "connected", true)
		"access_classified":
			protocol_found = true
			quest_system.update_quest_progress("access_classified", "protocol_found", true)
			_check_mission_complete()

func _on_all_quests_completed():
	"""Se llama cuando todas las quests están completas"""
	print("Todas las quests completadas!")
	_check_mission_complete()

func _setup_puzzle_system():
	"""Configura el sistema de puzzles"""
	if puzzle_system:
		# Si ya existe, no crear otro
		return
	
	puzzle_system = Mission0PuzzleSystem.new()
	add_child(puzzle_system)
	
	# Conectar señales
	puzzle_system.puzzle_completed.connect(_on_puzzle_completed)
	puzzle_system.all_puzzles_completed.connect(_on_all_puzzles_completed)

func _on_puzzle_completed(puzzle_id: String):
	"""Se llama cuando un puzzle se completa"""
	puzzles_completed += 1
		print("Puzzle completado: ", puzzle_id)
	
	match puzzle_id:
		"certificate_spoof":
			_add_terminal_output("", Color(0.0, 1.0, 0.0))
			_add_terminal_output("PUZZLE 1 COMPLETADO: Identidad suplantada", Color(0.0, 1.0, 0.0))
			_add_terminal_output("Certificado digital robado al director adjunto activado.", Color(0.0, 1.0, 0.0))
		"tor_redirect":
			_add_terminal_output("", Color(0.0, 1.0, 0.0))
			_add_terminal_output("PUZZLE 2 COMPLETADO: Tráfico redirigido", Color(0.0, 1.0, 0.0))
			_add_terminal_output("Ruta Tor establecida. Honeypots evitados.", Color(0.0, 1.0, 0.0))
		"quantum_decode":
			_add_terminal_output("", Color(0.0, 1.0, 0.0))
			_add_terminal_output("PUZZLE 3 COMPLETADO: Archivo decodificado", Color(0.0, 1.0, 0.0))
			_add_terminal_output("Algoritmo cuántico ejecutado exitosamente.", Color(0.0, 1.0, 0.0))
			_add_terminal_output("", Color(0.0, 1.0, 0.0))
			_add_terminal_output("🎯 FLAG GENERADA: /opt/nsa-server/protocols/FLAG.txt", Color(1.0, 1.0, 0.0))
			_add_terminal_output("⚠️  Lee la flag antes de que el servidor se cierre automáticamente!", Color(1.0, 0.5, 0.0))
			# Generar flag en el servidor
			_generate_flag_on_server()

func _on_all_puzzles_completed():
	"""Se llama cuando todos los puzzles están completos"""
	_add_terminal_output("", Color(0.0, 1.0, 1.0))
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("TODOS LOS PUZZLES COMPLETADOS", Color(0.0, 1.0, 1.0))
	_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
	_add_terminal_output("")
	_add_terminal_output("Ahora puedes acceder al servidor NSA.", Color(0.0, 1.0, 0.4))
		_add_terminal_output("Ahora puedes explotar Log4Shell: 'exploit log4shell " + mission_domain + "'", Color(0.0, 1.0, 0.4))

func _generate_flag_on_server():
	"""Genera la flag en el servidor cuando puzzle 3 se completa"""
	var request_data = {
		"jsonrpc": "2.0",
		"method": "generate_flag",
		"params": {
			"mission_id": "m0_brecha_nsa"
		},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var error = http_request.request(backend_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("Error generando flag: ", error)
	else:
		print("Flag generada en el servidor")

func _close_victim_server_delayed():
	"""Cierra el servidor víctima automáticamente después de 5 segundos"""
	await get_tree().create_timer(5.0).timeout
	_close_victim_server()

func _close_victim_server():
	"""Cierra el servidor víctima automáticamente"""
	var request_data = {
		"jsonrpc": "2.0",
		"method": "close_victim_server",
		"params": {
			"mission_id": "m0_brecha_nsa"
		},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	# Crear nuevo HTTPRequest para esta petición
	var close_request = HTTPRequest.new()
	add_child(close_request)
	
	var callback = func(_res: int, _code: int, _hdrs: PackedStringArray, _bdy: PackedByteArray):
		_add_terminal_output("", Color(1.0, 0.0, 0.0))
		_add_terminal_output("🔒 SERVIDOR CERRADO", Color(1.0, 0.0, 0.0))
		_add_terminal_output("Ya no tienes acceso al servidor NSA.", Color(1.0, 0.0, 0.0))
		connected = false
		close_request.queue_free()
	
	close_request.request_completed.connect(callback)
	
	var error = close_request.request(backend_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("Error cerrando servidor víctima: ", error)
		close_request.queue_free()

func _add_terminal_output(text: String, color: Color = Color(0.0, 1.0, 0.0)):
	"""Añade texto al output de la terminal"""
	if terminal_output:
		var color_hex = "#%02x%02x%02x" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]
		terminal_output.append_text("[color=" + color_hex + "]" + text + "[/color]\n")

func _on_command_submitted(command: String):
	"""Procesa un comando de la terminal"""
	if command.strip_edges().is_empty():
		return
	
	# Añadir comando al historial
	command_history.append(command)
	history_index = command_history.size()
	
	# Mostrar comando en terminal
	_add_terminal_output("hacker@nsa-breach:~$ " + command)
	
	# Ejecutar comando
	_execute_command(command)
	
	# Limpiar input
	terminal_input.text = ""
	terminal_input.grab_focus()

func _on_terminal_input_gui_input(event: InputEvent):
	"""Maneja navegación del historial con flechas"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			if history_index > 0:
				history_index -= 1
				terminal_input.text = command_history[history_index]
		elif event.keycode == KEY_DOWN:
			if history_index < command_history.size() - 1:
				history_index += 1
				terminal_input.text = command_history[history_index]
			elif history_index >= command_history.size() - 1:
				history_index = command_history.size()
				terminal_input.text = ""

func _execute_command(command: String):
	"""Ejecuta un comando de terminal"""
	var cmd_parts = command.strip_edges().split(" ", false)
	var cmd = cmd_parts[0].to_lower()
	var args = cmd_parts.slice(1) if cmd_parts.size() > 1 else []
	
	# Comandos especiales que se manejan localmente
	match cmd:
		"help":
			_show_help()
			return
		"exploit":
			if cmd_parts.size() > 1 and cmd_parts[1].to_lower() == "log4shell":
				# El comando se manejará en el backend
				_execute_backend_command(command)
				return
			else:
				_add_terminal_output("Uso: exploit log4shell [IP]", Color(1.0, 1.0, 0.0))
				return
		"clear":
			if terminal_output:
				terminal_output.text = ""
			return
		"status":
			_show_status()
			return
	
	# Si está conectado a Docker, enviar comando al backend
	if using_docker and connected:
		_execute_backend_command(command)
	else:
		# Modo simulado local
		_execute_local_command(command, cmd, args)

func _execute_backend_command(command: String):
	"""Ejecuta comando en el backend Docker"""
	var request_data = {
		"jsonrpc": "2.0",
		"method": "execute_terminal_command",
		"params": {
			"command": command
		},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var error = http_request.request(backend_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_add_terminal_output("Error conectando al backend: " + str(error), Color(1.0, 0.0, 0.0))
		_execute_local_command(command, command.split(" ")[0].to_lower(), command.split(" ").slice(1))

func _execute_local_command(command: String, cmd: String, args: Array):
	"""Ejecuta comando en modo simulado local"""
	match cmd:
		"scan":
			_scan_network()
		"ls", "list", "dir":
			_list_files()
		"cat", "read":
			if args.size() > 0:
				_read_file(args[0])
			else:
				_add_terminal_output("Uso: cat <archivo>", Color(1.0, 1.0, 0.0))
		"find":
			if args.size() > 0:
				_find_file(args[0])
			else:
				_add_terminal_output("Uso: find <patrón>", Color(1.0, 1.0, 0.0))
		"decode":
			if args.size() > 0:
				_decode_file(args[0])
			else:
				_add_terminal_output("Uso: decode <archivo>", Color(1.0, 1.0, 0.0))
		_:
			_add_terminal_output("Comando no reconocido: " + cmd, Color(1.0, 0.0, 0.0))
			_add_terminal_output("Escribe 'help' para ver comandos disponibles", Color(1.0, 1.0, 0.0))

func _check_terminal_status():
	"""Verifica el estado del terminal en el backend"""
	var request_data = {
		"jsonrpc": "2.0",
		"method": "get_terminal_status",
		"params": {},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	http_request.request(backend_url, headers, HTTPClient.METHOD_POST, body)

func _on_backend_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa respuesta del backend"""
	if result != HTTPRequest.RESULT_SUCCESS:
		using_docker = false
		return
	
	if response_code != 200:
		using_docker = false
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(response_text)
	
	if parse_error != OK:
		using_docker = false
		return
	
	var response_data = json.get_data()
	var result_data = response_data.get("result", {})
	
	# Verificar si es respuesta de status o command
	if result_data.has("mode"):
		# Es respuesta de status
		using_docker = result_data.get("mode", "") == "docker"
		if using_docker:
			_add_terminal_output("Terminal Docker/Kali Linux disponible", Color(0.0, 1.0, 0.0))
		return
	
	# Es respuesta de comando
	if result_data.has("success") and result_data.get("success", false):
		var output = result_data.get("output", "")
		if output:
			_add_terminal_output(output.strip_edges())
		
		# Verificar puzzles
		if puzzle_system:
			var puzzle_completed = puzzle_system.check_puzzle_progress("", output)
			if puzzle_completed:
				# Si se completó un puzzle, verificar si todos están completos
				if puzzle_system.are_all_puzzles_completed() and not connected:
					connected = true
					_add_terminal_output("", Color(0.0, 1.0, 1.0))
					_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
					_add_terminal_output("TODAS LAS CAPAS DE SEGURIDAD INFILTRADAS", Color(0.0, 1.0, 1.0))
					_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 1.0))
					_add_terminal_output("Ahora puedes usar 'connect " + mission_ip + "' para acceder al servidor.", Color(0.0, 1.0, 0.4))
		
		# Verificar si se conectó al servidor
		if output.find("Snow OS Server Edition") != -1 or output.find("Conectado al servidor") != -1:
			connected = true
			# Mostrar panel de quests cuando se conecta
			if quest_system and quest_system.get_panel():
				quest_system.get_panel().visible = true
		
		# Actualizar progreso de quests basado en comandos ejecutados
		if quest_system:
			_update_quest_progress_from_command("", output)
		
		# Verificar si se encontró el protocolo
		if output.find("CRONOS-7") != -1 or output.find("Protocolo Cronos") != -1:
			protocol_found = true
			cronos_device_found = true
			if quest_system:
				quest_system.update_quest_progress("access_classified", "protocol_found", true)
			_check_mission_complete()
		
		# Verificar si se leyó la flag
		var output_lower = output.to_lower()
		if output.find("6ME{") != -1 or output_lower.find("flag.txt") != -1:
			if output.find("CRONOS-7-PROTOCOL-UNLOCKED") != -1 or output_lower.find("cronos-7-protocol-unlocked") != -1:
				# Evitar múltiples triggers
				if not mission_completed_flag:
					mission_completed_flag = true
					_add_terminal_output("", Color(1.0, 1.0, 0.0))
					_add_terminal_output("🎯 FLAG OBTENIDA: 6ME{CRONOS-7-PROTOCOL-UNLOCKED}", Color(1.0, 1.0, 0.0))
					_add_terminal_output("", Color(1.0, 0.0, 0.0))
					_add_terminal_output("⚠️  SERVIDOR CERRÁNDOSE EN 5 SEGUNDOS...", Color(1.0, 0.0, 0.0))
					_add_terminal_output("El cortafuegos cuántico ha detectado la intrusión.", Color(1.0, 0.0, 0.0))
					# Cerrar servidor automáticamente después de 5 segundos
					_close_victim_server_delayed()
					var result = {
						"mission_id": "m0_brecha_nsa",
						"flag": "6ME{CRONOS-7-PROTOCOL-UNLOCKED}",
						"success": true
					}
					mission_completed.emit(result)
		
		# Verificar mensaje de Elara
		if output.find("Elara") != -1 or output.find("Refugio-7") != -1:
			elara_message_found = true
	else:
		var error = result_data.get("error", "Error desconocido")
		_add_terminal_output("Error: " + str(error), Color(1.0, 0.0, 0.0))

func _show_help():
	"""Muestra ayuda de comandos"""
	_add_terminal_output("")
	_add_terminal_output("COMANDOS DISPONIBLES:", Color(0.0, 1.0, 1.0))
	_add_terminal_output("  exploit log4shell - Explotar Log4Shell (CVE-2021-44228) para obtener shell")
	_add_terminal_output("  scan             - Escanear red en busca de vulnerabilidades")
	_add_terminal_output("  ls / list / dir   - Listar archivos del servidor")
	_add_terminal_output("  cat <archivo>     - Leer contenido de un archivo")
	_add_terminal_output("  find <patrón>     - Buscar archivos por patrón")
	_add_terminal_output("  decode <archivo>  - Decodificar archivo encriptado")
	_add_terminal_output("  status            - Mostrar estado de la misión")
	_add_terminal_output("  clear             - Limpiar terminal")
	_add_terminal_output("  help              - Mostrar esta ayuda")
	_add_terminal_output("")

func _connect_to_nsa(target_ip: String = ""):
	"""Conecta a los servidores NSA usando el backend (DEPRECATED - usar exploit log4shell)"""
	_add_terminal_output("⚠️ El comando 'connect' ya no está disponible.", Color(1.0, 1.0, 0.0))
	_add_terminal_output("Debes explotar Log4Shell primero usando: exploit log4shell " + mission_ip, Color(1.0, 1.0, 0.0))

func _scan_network():
	"""Escanea la red"""
	if not connected:
		_add_terminal_output("Error: No estás conectado. Usa 'connect' primero", Color(1.0, 0.0, 0.0))
		return
	
	_add_terminal_output("Escaneando red...", Color(0.5, 0.5, 1.0))
	await get_tree().create_timer(2.0).timeout
	_add_terminal_output("Vulnerabilidades encontradas:", Color(0.0, 1.0, 1.0))
	_add_terminal_output("  - Puerto 443: Certificado expirado")
	_add_terminal_output("  - Puerto 22: Cifrado débil detectado")
	_add_terminal_output("  - SQL Injection posible en base de datos")
		_add_terminal_output("Escaneo completado", Color(0.0, 1.0, 0.0))

func _list_files():
	"""Lista archivos del servidor"""
	if not connected:
		_add_terminal_output("Error: No estás conectado. Usa 'connect' primero", Color(1.0, 0.0, 0.0))
		return
	
	_add_terminal_output("Archivos encontrados:", Color(0.0, 1.0, 1.0))
	for file in files_found:
		var status = "[ENCRYPTED]" if file.ends_with(".enc") else "[TEXT]"
		_add_terminal_output("  - " + file + " " + status)

func _read_file(filename: String):
	"""Lee un archivo"""
	if not connected:
		_add_terminal_output("Error: No estás conectado. Usa 'connect' primero", Color(1.0, 0.0, 0.0))
		return
	
	if not files_found.has(filename):
		_add_terminal_output("Error: Archivo no encontrado: " + filename, Color(1.0, 0.0, 0.0))
		return
	
	if filename == "server_logs.txt":
		_add_terminal_output("Contenido de server_logs.txt:", Color(0.0, 1.0, 1.0))
		_add_terminal_output("  [2025-03-15 14:23:11] Acceso a Protocolo Cronos registrado")
		_add_terminal_output("  [2025-03-15 14:23:12] Sistema de observación temporal activado")
		_add_terminal_output("  [2025-03-15 14:23:13] 12 líneas temporales detectadas")
		_add_terminal_output("  [2025-03-15 14:23:14] Colapso detectado en todas las líneas")
	elif filename.ends_with(".enc"):
		_add_terminal_output("Error: Archivo encriptado. Usa 'decode <archivo>' para decodificarlo", Color(1.0, 0.0, 0.0))

func _find_file(pattern: String):
	"""Busca archivos por patrón"""
	if not connected:
		_add_terminal_output("Error: No estás conectado. Usa 'connect' primero", Color(1.0, 0.0, 0.0))
		return
	
	_add_terminal_output("Buscando archivos con patrón: " + pattern, Color(0.5, 0.5, 1.0))
	await get_tree().create_timer(1.0).timeout
	
	var found = []
	for file in files_found:
		if file.to_lower().find(pattern.to_lower()) != -1:
			found.append(file)
	
	if found.size() > 0:
		_add_terminal_output("Archivos encontrados:", Color(0.0, 1.0, 0.0))
		for file in found:
			_add_terminal_output("  - " + file)
	else:
		_add_terminal_output("No se encontraron archivos con ese patrón", Color(1.0, 1.0, 0.0))

func _decode_file(filename: String):
	"""Decodifica un archivo encriptado"""
	if not connected:
		_add_terminal_output("Error: No estás conectado. Usa 'connect' primero", Color(1.0, 0.0, 0.0))
		return
	
	if not files_found.has(filename):
		_add_terminal_output("Error: Archivo no encontrado: " + filename, Color(1.0, 0.0, 0.0))
		return
	
	if not filename.ends_with(".enc"):
		_add_terminal_output("Error: El archivo no está encriptado", Color(1.0, 0.0, 0.0))
		return
	
	_add_terminal_output("Decodificando " + filename + "...", Color(0.5, 0.5, 1.0))
	await get_tree().create_timer(2.0).timeout
	
	if filename == "protocol_cronos.enc":
		_add_terminal_output("Archivo decodificado exitosamente", Color(0.0, 1.0, 0.0))
		_add_terminal_output("")
		_add_terminal_output("═══════════════════════════════════════════════════════", Color(1.0, 1.0, 0.0))
		_add_terminal_output("PROTOCOLO CRONOS - CLASIFICADO", Color(1.0, 1.0, 0.0))
		_add_terminal_output("═══════════════════════════════════════════════════════", Color(1.0, 1.0, 0.0))
		_add_terminal_output("")
		_add_terminal_output("Dispositivo: CRONOS-7")
		_add_terminal_output("Función: Observación temporal multiversal")
		_add_terminal_output("Líneas temporales observadas: 37")
		_add_terminal_output("Colapso detectado en: TODAS")
		_add_terminal_output("")
		_add_terminal_output("El colapso de 2035 NO es natural.")
		_add_terminal_output("Está orquestado por entidades conocidas como 'Los Cartógrafos'.")
		_add_terminal_output("")
		_add_terminal_output("═══════════════════════════════════════════════════════", Color(1.0, 1.0, 0.0))
		protocol_found = true
		_check_mission_complete()
	else:
		_add_terminal_output("Contenido decodificado:", Color(0.0, 1.0, 1.0))
		_add_terminal_output("  [Datos clasificados - Sin relevancia para la misión]")

func _show_status():
	"""Muestra el estado de la misión"""
	_add_terminal_output("")
	_add_terminal_output("ESTADO DE LA MISIÓN:", Color(0.0, 1.0, 1.0))
	_add_terminal_output("  Conexion: " + ("Conectado" if connected else "Desconectado"))
	_add_terminal_output("  Archivos encontrados: " + str(files_found.size()))
	_add_terminal_output("  Protocolo Cronos: " + ("Encontrado" if protocol_found else "No encontrado"))
	_add_terminal_output("")

func _check_mission_complete():
	"""Verifica si la misión está completa"""
	if protocol_found:
		await get_tree().create_timer(2.0).timeout
		_add_terminal_output("")
		_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 0.0))
		_add_terminal_output("MISIÓN COMPLETADA", Color(0.0, 1.0, 0.0))
		_add_terminal_output("═══════════════════════════════════════════════════════", Color(0.0, 1.0, 0.0))
		_add_terminal_output("")
		_add_terminal_output("Has descubierto el Protocolo Cronos.")
		_add_terminal_output("Ahora sabes la verdad sobre el colapso de 2035.")
		_add_terminal_output("")
		
		if not mission_completed_flag:
			mission_completed_flag = true
			var result = {
				"mission_id": "m0_brecha_nsa",
				"success": true,
				"protocol_found": true
			}
			mission_completed.emit(result)

func _on_test_complete():
	"""Marca la misión como completada (para testing)"""
	if mission_completed_flag:
		return
	
	mission_completed_flag = true
	var result = {
		"mission_id": "m0_brecha_nsa",
		"success": true,
		"test_mode": true
	}
	mission_completed.emit(result)

func _update_quest_progress_from_command(command: String, output: String):
	"""Actualiza el progreso de las quests basado en comandos ejecutados"""
	var cmd_lower = command.to_lower()
	
	# Quest 1: Enumeración
	if "nmap" in cmd_lower:
		quest_system.update_quest_progress("enum_network", "nmap_scan", true)
	if "gobuster" in cmd_lower or "nikto" in cmd_lower:
		quest_system.update_quest_progress("enum_network", "service_discovered", true)
	
	# Quest 3: Exploración del sistema de archivos
	if "ls" in cmd_lower or "find" in cmd_lower:
		if "/opt" in output or "/etc" in output or "/var" in output:
			quest_system.update_quest_progress("explore_filesystem", "filesystem_explored", true)
		if "nsa-server" in output or "protocol" in output:
			quest_system.update_quest_progress("explore_filesystem", "critical_paths_found", true)
	
	# Quest 4: Encontrar archivos de configuración
	if "cat" in cmd_lower or "read" in cmd_lower:
		if "/etc/nsa/config.conf" in command or "/etc/os-release" in command:
			quest_system.update_quest_progress("find_config", "config_found", true)
		if "/var/log/nsa/protocol.log" in command:
			quest_system.update_quest_progress("find_config", "log_read", true)
	
	# Quest 5: Acceder a archivos clasificados
	if "protocol_cronos" in output or "classified_data" in output:
		quest_system.update_quest_progress("access_classified", "protocol_found", true)
	if ".access_key" in output or "server_info.txt" in output:
		quest_system.update_quest_progress("access_classified", "classified_accessed", true)
	
	# Quest 6: Post-explotación
	if "nsa-protocol.service" in output or "cronos-daemon.sh" in output:
		quest_system.update_quest_progress("post_exploit", "all_files_read", true)
