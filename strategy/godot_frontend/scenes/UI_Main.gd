extends Control

# ============================================
# REFERENCIAS A NODOS
# ============================================

# Estado del jugador
@onready var connection_status = $Background/MainContainer/Header/ConnectionStatus
@onready var sanity_label = $Background/MainContainer/Content/RightPanel/PlayerStatus/SanityContainer/SanityLabel
@onready var sanity_bar = $Background/MainContainer/Content/RightPanel/PlayerStatus/SanityContainer/SanityBar

# Botones principales
@onready var terminal_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/TerminalButton
@onready var connect_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/ConnectButton
@onready var test_connection_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/TestConnectionButton
@onready var sanity_minus_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/ModifySanityContainer/SanityMinusButton
@onready var sanity_plus_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/ModifySanityContainer/SanityPlusButton
@onready var food_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SatisfyNeedsContainer/FoodButton
@onready var water_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SatisfyNeedsContainer/WaterButton
@onready var sleep_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SatisfyNeedsContainer/SleepButton
@onready var world_map_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/MapEcosystemsContainer/WorldMapButton
@onready var ecosystems_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/MapEcosystemsContainer/EcosystemsButton
@onready var save_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SaveLoadContainer/SaveButton
@onready var load_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SaveLoadContainer/LoadButton

# Panel de resultados (usando MissionsContainer que existe en la escena)
@onready var results_panel = $Background/MainContainer/Content/RightPanel/MissionsContainer
@onready var results_text = $Background/MainContainer/Content/RightPanel/MissionsContainer/MissionDetails

# Estadísticas del mundo
@onready var violence_value = $Background/MainContainer/Content/RightPanel/WorldStatusContainer/WorldStatsGrid/ViolenceValue
@onready var cartograph_value = $Background/MainContainer/Content/RightPanel/WorldStatusContainer/WorldStatsGrid/CartographValue
@onready var time_value = $Background/MainContainer/Content/RightPanel/WorldStatusContainer/WorldStatsGrid/TimeValue

# Logs
@onready var log_text = $Background/MainContainer/Content/RightPanel/LogContainer/LogText

# Necesidades
@onready var hunger_value = $Background/MainContainer/Content/RightPanel/PlayerStatus/NeedsContainer/HungerValue
@onready var thirst_value = $Background/MainContainer/Content/RightPanel/PlayerStatus/NeedsContainer/ThirstValue
@onready var sleep_value = $Background/MainContainer/Content/RightPanel/PlayerStatus/NeedsContainer/SleepValue
@onready var stress_value = $Background/MainContainer/Content/RightPanel/PlayerStatus/NeedsContainer/StressValue

# Reputación
@onready var reputation_grid = $Background/MainContainer/Content/RightPanel/PlayerStatus/ReputationContainer/ReputationGrid

# Panel de características del jugador
@onready var player_character_panel = $Background/MainContainer/Content/LeftPanel/PlayerCharacterPanel

# Misiones
@onready var mission_details = $Background/MainContainer/Content/RightPanel/MissionsContainer/MissionDetails
@onready var active_mission_label = $Background/MainContainer/Content/RightPanel/MissionsContainer/ActiveMissionLabel
@onready var complete_mission_button = $Background/MainContainer/Content/RightPanel/MissionsContainer/CompleteMissionButton
@onready var mission_choices_container = $Background/MainContainer/Content/RightPanel/MissionsContainer/MissionChoicesContainer

# ============================================
# VARIABLES
# ============================================

var game_client: Node = null
var current_mission_data: Dictionary = {}
var current_map_panel: Node = null  # Referencia al panel del mapa del mundo
var mission_choices: Dictionary = {}
var test_console_dialog: AcceptDialog = null
var test_results_text: TextEdit = null
var ecosystem_manager: Node = null
var world_map_panel: Control = null
var climate_system: Node = null
var social_crisis_manager: Node = null
var time_system: Node = null  # Sistema de tiempo/calendario
var climate_action_system: Node = null  # Sistema de acción climática
var economic_crisis_manager: Node = null
var tipping_point_reward_system: Node = null
var player_hud: Control = null
var player_stats: RefCounted = null
var terminal_manager: Node = null  # Gestor de terminales Kali Linux
var manifesto_unlocked: bool = false  # Estado de desbloqueo del manifiesto
var manifesto_submitted: bool = false  # Si el manifiesto ha sido enviado
var unlocked_manifesto_button: Button = null  # Botón de manifiesto cuando se desbloquea
# ============================================
# FUNCIONES PRINCIPALES
# ============================================

func _ready():
	print("UI_Main inicializada")
	
	# PRIMERO: Mostrar selección de nombre del jugador
	_show_player_name_selection()
	
	# Esperar a que se seleccione el nombre antes de continuar
	await player_name_selected

func _show_player_name_selection():
	"""Muestra el diálogo de selección de nombre"""
	var PlayerNameDialogClass = load("res://scripts/UI/PlayerNameSelection.gd")
	var name_dialog = PlayerNameDialogClass.new()
	name_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_dialog.player_name_selected.connect(_on_player_name_selected)
	add_child(name_dialog)

var player_name_selected: bool = false

func _on_player_name_selected(name: String):
	"""Maneja la selección del nombre del jugador"""
	player_name_selected = true
	
	# Establecer nombre en GameClient
	if game_client and game_client.has_method("set_player_name"):
		game_client.set_player_name(name)
	
	# Enviar nombre al backend
	_send_player_name_to_backend(name)
	
	# Continuar con la inicialización
	_continue_initialization()

func _send_player_name_to_backend(name: String):
	"""Envía el nombre del jugador al backend"""
	var request_data = {
		"jsonrpc": "2.0",
		"method": "set_player_name",
		"params": {
			"name": name
		},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(func(_result, _code, _headers, _body):
		http_request.queue_free()
	)
	
	var error = http_request.request("http://localhost:8080/rpc", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("Error enviando nombre del jugador al backend: ", error)

func _continue_initialization():
	"""Continúa con la inicialización después de seleccionar el nombre"""
	# Buscar GameClient en la escena
	_find_game_client()
	
	# Conectar señales de botones
	_connect_signals()
	
	# Inicializar UI
	_initialize_ui()
	
	add_log("UI inicializada correctamente")
	_create_test_console()
	
	# Esperar a que el layout esté completamente inicializado antes de añadir paneles flotantes
	await get_tree().process_frame
	await get_tree().process_frame  # Doble frame para asegurar que el layout esté listo
	
	# #region agent log
	var log_data = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "A",
		"location": "UI_Main.gd:_continue_initialization",
		"message": "Layout initialized - checking panel sizes",
		"data": {},
		"timestamp": Time.get_ticks_msec()
	}
	_write_debug_log(log_data)
	# #endregion
	
	# Debug: Verificar tamaños de paneles después de inicialización
	call_deferred("_debug_panel_layout")
	
	# Inicializar sistemas (sin paneles flotantes)
	_initialize_managers()  # Esto inicializa todos los managers incluyendo ecosystem_manager
	_initialize_climate_system()
	_initialize_economic_systems()
	_initialize_terminal_manager()
	
	# Conectar señales de ecosystem_manager después de inicializarlo
	if ecosystem_manager:
		if ecosystem_manager.has_signal("ecosystem_critical"):
			ecosystem_manager.ecosystem_critical.connect(_on_ecosystem_critical)
		if ecosystem_manager.has_signal("ecosystem_updated"):
			ecosystem_manager.ecosystem_updated.connect(_on_ecosystem_updated)

func _on_ecosystem_critical(eco_id: String, state: EcosystemState):
	add_log("🚨 ECOSISTEMA CRÍTICO: " + eco_id + " (" + state.get_status() + ")")

func _on_ecosystem_updated(_eco_id: String, _state: EcosystemState):
	# Los paneles se actualizarán cuando se abran
	pass
func _find_game_client():
	"""Busca el nodo GameClient en la escena"""
	var root = get_tree().root
	game_client = root.find_child("GameClient", true, false)
	
	if game_client:
		print("GameClient encontrado:", game_client.name)
		
		# Conectar señales del GameClient
		_connect_game_client_signals()
		
		# Configurar panel de características del jugador
		_setup_player_character_panel()
		
		# Actualizar UI con estado inicial si está disponible
		_update_ui_from_client()
	else:
		print("GameClient no encontrado")
		add_log("GameClient no encontrado. Ejecutaste main_test.tscn?")

func _connect_signals():
	"""Conecta todas las señales de botones"""
	if terminal_button:
		terminal_button.pressed.connect(_on_terminal_button_pressed)
	if connect_button:
		connect_button.pressed.connect(_on_connect_pressed)
	if test_connection_button:
		test_connection_button.pressed.connect(_on_test_connection_pressed)
	if sanity_minus_button:
		sanity_minus_button.pressed.connect(_on_sanity_minus_pressed)
	if sanity_plus_button:
		sanity_plus_button.pressed.connect(_on_sanity_plus_pressed)
	if food_button:
		food_button.pressed.connect(_on_food_pressed)
	if water_button:
		water_button.pressed.connect(_on_water_pressed)
	if sleep_button:
		sleep_button.pressed.connect(_on_sleep_pressed)
	if world_map_button:
		world_map_button.pressed.connect(_open_world_map)
	if ecosystems_button:
		ecosystems_button.pressed.connect(_open_ecosystems_panel)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if complete_mission_button:
		complete_mission_button.pressed.connect(_on_complete_mission_pressed)
	
	# Botón de terminal ya está en la escena, no necesita añadirse dinámicamente

func _connect_game_client_signals():
	"""Conecta señales del GameClient a la UI"""
	if not game_client:
		return
	
	# Intentar conectar señales si existen
	if game_client.has_signal("sanity_updated"):
		game_client.sanity_updated.connect(_on_sanity_updated)
	if game_client.has_signal("needs_updated"):
		game_client.needs_updated.connect(_on_needs_updated)
	if game_client.has_signal("reputation_updated"):
		game_client.reputation_updated.connect(_on_reputation_updated)
	if game_client.has_signal("violence_level_updated"):
		game_client.violence_level_updated.connect(_on_violence_updated)
	if game_client.has_signal("cartograph_power_updated"):
		game_client.cartograph_power_updated.connect(_on_cartograph_updated)
	if game_client.has_signal("connection_status_changed"):
		game_client.connection_status_changed.connect(_on_connection_status_changed)
	if game_client.has_signal("mission_received"):
		game_client.mission_received.connect(_on_mission_received)
	if game_client.has_signal("mission_completed"):
		game_client.mission_completed.connect(_on_mission_completed)
	if game_client.has_signal("mission_failed"):
		game_client.mission_failed.connect(_on_mission_failed)
	if game_client.has_signal("save_game_completed"):
		game_client.save_game_completed.connect(_on_save_completed)
	if game_client.has_signal("load_game_completed"):
		game_client.load_game_completed.connect(_on_load_completed)
	
	add_log("Senales del GameClient conectadas")

func _initialize_ui():
	"""Inicializa la UI con valores por defecto - Tema cyberpunk/post-apocalíptico"""
	# #region agent log
	var log_data_init = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "C",
		"location": "UI_Main.gd:_initialize_ui",
		"message": "UI initialization started",
		"data": {},
		"timestamp": Time.get_ticks_msec()
	}
	var log_file_init = FileAccess.open(".cursor/debug.log", FileAccess.WRITE_READ)
	if log_file_init:
		log_file_init.seek_end()
		log_file_init.store_line(JSON.stringify(log_data_init))
		log_file_init.close()
	# #endregion
	
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	if CyberpunkThemeClass:
		# Aplicar tema global
		CyberpunkThemeClass.apply_theme_to_node(self)
	
	connection_status.text = "DESCONECTADO"
	connection_status.add_theme_color_override("font_color", CyberpunkThemeClass.COLOR_NEON_RED if CyberpunkThemeClass else Color(1.0, 0.2, 0.2))
	sanity_label.text = "CORDURA: 85"
	sanity_label.add_theme_color_override("font_color", CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 0.2))
	sanity_bar.value = 85
	
	# Aplicar estilo de fondo cyberpunk
	var bg_panel = $Background
	if bg_panel:
		var bg_style = CyberpunkThemeClass.create_panel_style() if CyberpunkThemeClass else StyleBoxFlat.new()
		bg_style.bg_color = CyberpunkThemeClass.COLOR_BG_PRIMARY if CyberpunkThemeClass else Color(0.05, 0.05, 0.05)
		bg_panel.add_theme_stylebox_override("panel", bg_style)
	
	# Colores para barras de necesidades
	_update_sanity_color(85)
	
	# Aplicar tema cyberpunk a todos los botones
	_apply_hacker_theme_to_buttons()
	
	# Panel de reputación eliminado
	
	# Deshabilitar botones hasta conexión (si es necesario)
	_set_actions_enabled(true)  # Temporalmente habilitado para pruebas
	
	# Integrar mapa del mundo en esquina inferior derecha
	call_deferred("_setup_world_map_mini")
	
	# Inicializar panel de características del jugador
	_setup_player_character_panel()
	
	add_log("UI inicializada - Modo prueba")

func _write_debug_log(log_data: Dictionary):
	"""Helper para escribir logs de debug"""
	var log_path = ".cursor/debug.log"
	var dir = DirAccess.open(".")
	if dir:
		dir.make_dir_recursive(".cursor")
	var log_file = FileAccess.open(log_path, FileAccess.READ_WRITE)
	if log_file == null:
		log_path = "user://.cursor/debug.log"
		var user_dir = DirAccess.open("user://")
		if user_dir:
			user_dir.make_dir_recursive(".cursor")
		log_file = FileAccess.open(log_path, FileAccess.READ_WRITE)
	if log_file:
		log_file.seek_end()
		log_file.store_line(JSON.stringify(log_data))
		log_file.close()
	else:
		print("[DEBUG] Error: No se pudo abrir el archivo de log en: ", log_path)

func _debug_panel_layout():
	"""Debug: Verifica tamaños y configuración de paneles"""
	var background = $Background
	var main_container = $Background/MainContainer
	var content = $Background/MainContainer/Content
	var left_panel = $Background/MainContainer/Content/LeftPanel
	var right_panel = $Background/MainContainer/Content/RightPanel
	var mission_details = $Background/MainContainer/Content/RightPanel/MissionsContainer/MissionDetails
	var log_text = $Background/MainContainer/Content/RightPanel/LogContainer/LogText
	var needs_container = $Background/MainContainer/Content/RightPanel/PlayerStatus/NeedsContainer
	var world_stats_grid = $Background/MainContainer/Content/RightPanel/WorldStatusContainer/WorldStatsGrid
	
	if not content or not left_panel or not right_panel:
		print("[DEBUG] Paneles no encontrados")
		return
	
	print("[DEBUG] Iniciando _debug_panel_layout")
	
	# Obtener tamaño de la ventana/viewport
	var viewport = get_viewport()
	var window_size = viewport.get_visible_rect().size if viewport else Vector2.ZERO
	
	# #region agent log
	var log_data_viewport = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "A",
		"location": "UI_Main.gd:_debug_panel_layout",
		"message": "Viewport/Window size",
		"data": {
			"viewport_size": {"x": window_size.x, "y": window_size.y},
			"ui_main_size": {"x": size.x, "y": size.y}
		},
		"timestamp": Time.get_ticks_msec()
	}
	_write_debug_log(log_data_viewport)
	# #endregion
	
	# #region agent log
	var log_data_bg = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "A",
		"location": "UI_Main.gd:_debug_panel_layout",
		"message": "Background Panel size",
		"data": {
			"bg_size": {"x": background.size.x, "y": background.size.y},
			"bg_anchor_right": background.anchor_right,
			"bg_anchor_bottom": background.anchor_bottom,
			"bg_layout_mode": background.layout_mode,
			"bg_offset_left": background.offset_left,
			"bg_offset_right": background.offset_right
		},
		"timestamp": Time.get_ticks_msec()
	}
	_write_debug_log(log_data_bg)
	# #endregion
	
	# #region agent log
	var log_data_main = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "A",
		"location": "UI_Main.gd:_debug_panel_layout",
		"message": "MainContainer VBoxContainer size",
		"data": {
			"main_size": {"x": main_container.size.x, "y": main_container.size.y},
			"main_offset_left": main_container.offset_left,
			"main_offset_right": main_container.offset_right,
			"main_offset_top": main_container.offset_top,
			"main_offset_bottom": main_container.offset_bottom
		},
		"timestamp": Time.get_ticks_msec()
	}
	_write_debug_log(log_data_main)
	# #endregion
	
	# #region agent log
	var log_data = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "A",
		"location": "UI_Main.gd:_debug_panel_layout",
		"message": "Content HBoxContainer size and flags",
		"data": {
			"content_size": {"x": content.size.x, "y": content.size.y},
			"content_size_flags_h": content.size_flags_horizontal,
			"content_size_flags_v": content.size_flags_vertical,
			"content_layout_mode": content.layout_mode
		},
		"timestamp": Time.get_ticks_msec()
	}
	_write_debug_log(log_data)
	# #endregion
	
	# #region agent log
	var log_data2 = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "E",
		"location": "UI_Main.gd:_debug_panel_layout",
		"message": "LeftPanel size and flags",
		"data": {
			"left_size": {"x": left_panel.size.x, "y": left_panel.size.y},
			"left_custom_min_size": {"x": left_panel.custom_minimum_size.x, "y": left_panel.custom_minimum_size.y},
			"left_size_flags_h": left_panel.size_flags_horizontal,
			"left_size_flags_v": left_panel.size_flags_vertical,
			"left_layout_mode": left_panel.layout_mode
		},
		"timestamp": Time.get_ticks_msec()
	}
	_write_debug_log(log_data2)
	# #endregion
	
	# #region agent log
	var log_data3 = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "A",
		"location": "UI_Main.gd:_debug_panel_layout",
		"message": "RightPanel size and flags",
		"data": {
			"right_size": {"x": right_panel.size.x, "y": right_panel.size.y},
			"right_custom_min_size": {"x": right_panel.custom_minimum_size.x, "y": right_panel.custom_minimum_size.y},
			"right_size_flags_h": right_panel.size_flags_horizontal,
			"right_size_flags_v": right_panel.size_flags_vertical,
			"right_layout_mode": right_panel.layout_mode
		},
		"timestamp": Time.get_ticks_msec()
	}
	_write_debug_log(log_data3)
	# #endregion
	
	if mission_details:
		# #region agent log
		var log_data4 = {
			"sessionId": "debug-session",
			"runId": "run1",
			"hypothesisId": "B",
			"location": "UI_Main.gd:_debug_panel_layout",
			"message": "MissionDetails TextEdit size and flags",
			"data": {
				"mission_size": {"x": mission_details.size.x, "y": mission_details.size.y},
				"mission_custom_min_size": {"x": mission_details.custom_minimum_size.x, "y": mission_details.custom_minimum_size.y},
				"mission_size_flags_h": mission_details.size_flags_horizontal,
				"mission_size_flags_v": mission_details.size_flags_vertical,
				"mission_layout_mode": mission_details.layout_mode
			},
			"timestamp": Time.get_ticks_msec()
		}
		_write_debug_log(log_data4)
		# #endregion
	
	if log_text:
		# #region agent log
		var log_data5 = {
			"sessionId": "debug-session",
			"runId": "run1",
			"hypothesisId": "B",
			"location": "UI_Main.gd:_debug_panel_layout",
			"message": "LogText TextEdit size and flags",
			"data": {
				"log_size": {"x": log_text.size.x, "y": log_text.size.y},
				"log_custom_min_size": {"x": log_text.custom_minimum_size.x, "y": log_text.custom_minimum_size.y},
				"log_size_flags_h": log_text.size_flags_horizontal,
				"log_size_flags_v": log_text.size_flags_vertical,
				"log_layout_mode": log_text.layout_mode
			},
			"timestamp": Time.get_ticks_msec()
		}
		_write_debug_log(log_data5)
		# #endregion
	
	if needs_container:
		# #region agent log
		var log_data6 = {
			"sessionId": "debug-session",
			"runId": "run1",
			"hypothesisId": "B",
			"location": "UI_Main.gd:_debug_panel_layout",
			"message": "NeedsContainer GridContainer size and flags",
			"data": {
				"needs_size": {"x": needs_container.size.x, "y": needs_container.size.y},
				"needs_size_flags_h": needs_container.size_flags_horizontal,
				"needs_size_flags_v": needs_container.size_flags_vertical,
				"needs_layout_mode": needs_container.layout_mode,
				"needs_columns": needs_container.columns
			},
			"timestamp": Time.get_ticks_msec()
		}
		_write_debug_log(log_data6)
		# #endregion
	
	if world_stats_grid:
		# #region agent log
		var log_data7 = {
			"sessionId": "debug-session",
			"runId": "run1",
			"hypothesisId": "B",
			"location": "UI_Main.gd:_debug_panel_layout",
			"message": "WorldStatsGrid GridContainer size and flags",
			"data": {
				"world_size": {"x": world_stats_grid.size.x, "y": world_stats_grid.size.y},
				"world_size_flags_h": world_stats_grid.size_flags_horizontal,
				"world_size_flags_v": world_stats_grid.size_flags_vertical,
				"world_layout_mode": world_stats_grid.layout_mode,
				"world_columns": world_stats_grid.columns
			},
			"timestamp": Time.get_ticks_msec()
		}
		_write_debug_log(log_data7)
		# #endregion
	
	# #region agent log
	var log_data8 = {
		"sessionId": "debug-session",
		"runId": "run1",
		"hypothesisId": "D",
		"location": "UI_Main.gd:_debug_panel_layout",
		"message": "Available space calculation",
		"data": {
			"content_available_width": content.size.x,
			"left_panel_width": left_panel.size.x,
			"right_panel_width": right_panel.size.x,
			"expected_right_width": content.size.x - left_panel.size.x - content.get_theme_constant("separation"),
			"separation": content.get_theme_constant("separation")
		},
		"timestamp": Time.get_ticks_msec()
	}
	_write_debug_log(log_data8)
	# #endregion
	print("[DEBUG] _debug_panel_layout completado")
	
func _apply_hacker_theme_to_buttons():
	"""Aplica tema cyberpunk/post-apocalíptico a todos los botones de la UI"""
	# Cargar el tema cyberpunk
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	if CyberpunkThemeClass:
		CyberpunkThemeClass.apply_theme_to_node(self)
	
	# Aplicar estilos personalizados adicionales
	var button_style_normal = CyberpunkThemeClass.create_button_style_normal()
	var button_style_hover = CyberpunkThemeClass.create_button_style_hover()
	var button_style_pressed = CyberpunkThemeClass.create_button_style_pressed()
	
	# Aplicar a todos los botones encontrados
	_apply_style_to_buttons_recursive(self, button_style_normal, button_style_hover, button_style_pressed)

func _apply_style_to_buttons_recursive(node: Node, normal_style: StyleBoxFlat, hover_style: StyleBoxFlat, pressed_style: StyleBoxFlat = null):
	"""Aplica estilos a todos los botones recursivamente"""
	if node is Button:
		var button = node as Button
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", hover_style)
		button.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		button.add_theme_color_override("font_hover_color", Color(0.0, 1.0, 0.2))
	
	for child in node.get_children():
		_apply_style_to_buttons_recursive(child, normal_style, hover_style)

func _set_actions_enabled(enabled: bool):
	"""Habilita o deshabilita botones de acción"""
	if sanity_minus_button:
		sanity_minus_button.disabled = not enabled
	if sanity_plus_button:
		sanity_plus_button.disabled = not enabled
	if food_button:
		food_button.disabled = not enabled
	if water_button:
		water_button.disabled = not enabled
	if sleep_button:
		sleep_button.disabled = not enabled
	if save_button:
		save_button.disabled = not enabled
	if load_button:
		load_button.disabled = not enabled

func _setup_player_character_panel():
	"""Configura el panel de características del jugador"""
	if not player_character_panel:
		return
	
	# Conectar con GameClient si está disponible
	if game_client:
		player_character_panel.set_game_client(game_client)
	
	# Intentar obtener PlayerStats del GameClient
	if game_client and game_client.has_method("get_player_stats"):
		var stats = game_client.get_player_stats()
		if stats:
			player_character_panel.set_player_stats(stats)
	
	# Actualizar el panel
	player_character_panel.update_from_game_client()
	
	# Conectar señales para actualización automática
	if game_client:
		if game_client.has_signal("sanity_updated"):
			if not game_client.sanity_updated.is_connected(_on_player_character_update):
				game_client.sanity_updated.connect(_on_player_character_update)
		if game_client.has_signal("needs_updated"):
			if not game_client.needs_updated.is_connected(_on_player_character_update):
				game_client.needs_updated.connect(_on_player_character_update)
		if game_client.has_signal("reputation_updated"):
			if not game_client.reputation_updated.is_connected(_on_player_character_update):
				game_client.reputation_updated.connect(_on_player_character_update)

func _on_player_character_update(_value = null):
	"""Actualiza el panel de características cuando cambian los datos"""
	if player_character_panel:
		player_character_panel.update_from_game_client()

func _update_ui_from_client():
	"""Actualiza la UI con datos del cliente (si están disponibles)"""
	if not game_client:
		return
	
	# Intentar obtener estado actual si los métodos existen
	if game_client.has_method("get_player_state"):
		var player_state = game_client.get_player_state()
		if player_state and player_state.has("sanity"):
			_on_sanity_updated(player_state.sanity)
		
		if player_state and player_state.has("needs"):
			_on_needs_updated(player_state.needs)
		
		if player_state and player_state.has("reputation"):
			for region in player_state.reputation.keys():
				_on_reputation_updated(region, player_state.reputation[region])
	
	if game_client.has_method("get_world_state"):
		var world_state = game_client.get_world_state()
		if world_state and world_state.has("violence_level"):
			_on_violence_updated(world_state.violence_level)
		
		if world_state and world_state.has("cartograph_power"):
			_on_cartograph_updated(world_state.cartograph_power)
	
	if game_client.has_method("get_missions_state"):
		var missions_state = game_client.get_missions_state()
		if missions_state and missions_state.has("active"):
			_update_mission_display(missions_state.active)
	
	# Actualizar panel de características
	if player_character_panel:
		player_character_panel.update_from_game_client()

# Panel de reputación eliminado

# ============================================
# MANEJO DE SEÑALES DEL GAMECLIENT
# ============================================

func _on_sanity_updated(value: int):
	"""Actualiza la visualización de cordura"""
	sanity_label.text = "CORDURA: " + str(value)
	sanity_bar.value = value
	_update_sanity_color(value)
	add_log("Cordura actualizada: " + str(value))

func _on_needs_updated(needs: Dictionary):
	"""Actualiza las necesidades"""
	if needs.has("hunger"):
		hunger_value.text = str(needs.hunger)
	if needs.has("thirst"):
		thirst_value.text = str(needs.thirst)
	if needs.has("sleep"):
		sleep_value.text = str(needs.sleep)
	if needs.has("stress"):
		stress_value.text = str(needs.stress)
	
	add_log("Necesidades actualizadas")

func _on_reputation_updated(region: String, value: int):
	"""Actualiza la reputación de una región (panel eliminado)"""
	# Panel de reputación eliminado - función mantenida para compatibilidad
	pass

func _on_violence_updated(value: int):
	"""Actualiza nivel de violencia"""
	violence_value.text = str(value)
	add_log("Nivel de violencia: " + str(value))

func _on_cartograph_updated(value: int):
	"""Actualiza poder de los Cartógrafos"""
	cartograph_value.text = str(value)
	add_log("Poder Cartógrafos: " + str(value))

func _on_connection_status_changed(connected: bool):
	"""Actualiza estado de conexión"""
	if connected:
		connection_status.text = "Conectado"
		connection_status.add_theme_color_override("font_color", Color(0, 1, 0))
		_set_actions_enabled(true)
		add_log("✅ Conectado al servidor backend")
	else:
		connection_status.text = "Desconectado"
		connection_status.add_theme_color_override("font_color", Color(1, 0, 0))
		_set_actions_enabled(false)
		add_log("❌ Desconectado del servidor")

func _on_mission_received(mission_data: Dictionary):
	"""Recibe datos de una misión"""
	current_mission_data = mission_data
	mission_choices.clear()
	
	# Mostrar detalles
	var details = "🎯 " + mission_data.get("title", "Sin título") + "\n\n"
	details += "📋 " + mission_data.get("description", "Sin descripción") + "\n\n"
	
	if mission_data.has("objectives"):
		details += "🎯 OBJETIVOS:\n"
		for objective in mission_data.get("objectives", []):
			details += "• " + objective + "\n"
	
	if mission_details:
		mission_details.text = details
	if complete_mission_button:
		complete_mission_button.visible = true
	
	add_log("📋 Misión recibida: " + mission_data.get("title", "Sin título"))

func _on_mission_completed(mission_id: String, result: Dictionary):
	"""Misión completada"""
	add_log("✅ Misión completada: " + mission_id)
	
	# Verificar si esta misión desbloquea el manifiesto
	_check_manifesto_unlock(mission_id)
	
	# Resetear UI de misión
	_update_mission_display("")
	
	# Mostrar resultados
	var result_text = "🎉 MISIÓN COMPLETADA\n\n"
	
	if result.has("message"):
		result_text += result.message + "\n\n"
	
	if result.has("rewards"):
		result_text += "🎁 RECOMPENSAS:\n"
		var rewards = result.rewards
		if rewards.has("currency"):
			result_text += "💰 Moneda: +" + str(rewards.currency) + "\n"
		if rewards.has("items"):
			result_text += "📦 Items: " + str(rewards.items.size()) + " obtenidos\n"
	
	# Mostrar alerta
	var alert = AcceptDialog.new()
	alert.title = "Misión Completada"
	alert.dialog_text = result_text
	add_child(alert)
	alert.popup_centered()

func _on_mission_failed(mission_id: String, reason: String):
	"""Misión fallada"""
	add_log("❌ Misión fallada: " + mission_id + " - " + reason)
	
	# Resetear UI de misión
	_update_mission_display("")
	
	var alert = AcceptDialog.new()
	alert.title = "Misión Fallada"
	alert.dialog_text = "La misión " + mission_id + " ha fallado.\nRazón: " + reason
	add_child(alert)
	alert.popup_centered()

func _on_save_completed(success: bool, slot: int):
	"""Guardado completado"""
	if success:
		add_log("💾 Juego guardado en slot " + str(slot))
	else:
		add_log("❌ Error al guardar juego")

func _on_load_completed(success: bool, slot: int):
	"""Carga completada"""
	if success:
		add_log("📂 Juego cargado desde slot " + str(slot))
	else:
		add_log("❌ Error al cargar juego")

# ============================================
# FUNCIONES DE UTILIDAD
# ============================================

func _update_sanity_color(value: int):
	"""Actualiza el color de la barra de cordura según el valor - Tema hacker"""
	var color: Color
	var glow_color: Color
	
	if value >= 70:
		color = Color(0.0, 1.0, 0.2)  # Verde brillante terminal
		glow_color = Color(0.0, 0.8, 0.2, 0.3)
	elif value >= 50:
		color = Color(0.8, 0.9, 0.0)  # Amarillo verdoso
		glow_color = Color(0.8, 0.7, 0.0, 0.3)
	elif value >= 30:
		color = Color(1.0, 0.4, 0.0)  # Naranja
		glow_color = Color(1.0, 0.3, 0.0, 0.3)
	else:
		color = Color(1.0, 0.0, 0.2)  # Rojo crítico
		glow_color = Color(1.0, 0.0, 0.1, 0.5)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = glow_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	sanity_bar.add_theme_stylebox_override("fill", style)

func _update_mission_display(mission_id: String):
	"""Actualiza la visualización de misión"""
	if mission_id and not mission_id.is_empty():
		if mission_details:
			mission_details.text = "Activa: " + mission_id
		if complete_mission_button:
			complete_mission_button.visible = true
	else:
		if mission_details:
			mission_details.text = "Selecciona una misión para ver detalles."
		if complete_mission_button:
			complete_mission_button.visible = false
		if mission_choices_container:
			mission_choices_container.visible = false

func add_log(message: String):
	"""Añade un mensaje al registro"""
	var timestamp = Time.get_time_string_from_system()
	log_text.text += "\n[" + timestamp + "] " + message
	log_text.scroll_vertical = 99999  # Ir al final
	print("📝 LOG:", message)

# ============================================
# MANEJO DE BOTONES
# ============================================

func _on_connect_pressed():
	"""Conectar al servidor"""
	if game_client and game_client.has_method("connect_to_server"):
		add_log("🔗 Conectando al servidor...")
		connection_status.text = "🔄 Conectando..."
		game_client.connect_to_server()
	else:
		add_log("❌ GameClient no disponible o no tiene método connect_to_server")

func _on_test_connection_pressed():
	"""Probar conexión directa"""
	if game_client and game_client.has_method("test_connection_direct"):
		add_log("🔍 Probando conexión directa...")
		game_client.test_connection_direct()
	else:
		add_log("❌ Método test_connection_direct no disponible")

func _on_sanity_minus_pressed():
	"""Disminuir cordura"""
	if game_client and game_client.has_method("modify_sanity"):
		game_client.modify_sanity(-10, "ui_action")
		add_log("🧠 Cordura disminuida -10")
	else:
		add_log("❌ GameClient no disponible")

func _on_sanity_plus_pressed():
	"""Aumentar cordura"""
	if game_client and game_client.has_method("modify_sanity"):
		game_client.modify_sanity(10, "ui_action")
		add_log("🧠 Cordura aumentada +10")
	else:
		add_log("❌ GameClient no disponible")

func _on_food_pressed():
	"""Comer"""
	if game_client and game_client.has_method("satisfy_need"):
		game_client.satisfy_need("hunger", 30, "food_ration")
		add_log("🍎 Necesidad de hambre satisfecha")
	else:
		add_log("❌ GameClient no disponible")

func _on_water_pressed():
	"""Beber"""
	if game_client and game_client.has_method("satisfy_need"):
		game_client.satisfy_need("thirst", 40, "water")
		add_log("💧 Necesidad de sed satisfecha")
	else:
		add_log("❌ GameClient no disponible")

func _on_sleep_pressed():
	"""Dormir"""
	if game_client and game_client.has_method("satisfy_need"):
		game_client.satisfy_need("sleep", 50, "rest")
		add_log("😴 Necesidad de sueño satisfecha")
	else:
		add_log("❌ GameClient no disponible")

func _on_save_pressed():
	"""Guardar juego y sistema de archivos"""
	if game_client and game_client.has_method("save_game"):
		game_client.save_game(1)
		add_log("💾 Guardando juego y sistema de archivos...")
		
		# Guardar sistema de archivos también
		_save_filesystem(1)
	else:
		add_log("❌ GameClient no disponible")

func _save_filesystem(slot: int):
	"""Guarda el sistema de archivos"""
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "save_filesystem",
		"params": {
			"slot_id": str(slot)
		},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(func(_result, _code, _headers, _body):
		var json = JSON.new()
		json.parse(_body.get_string_from_utf8())
		var response = json.get_data()
		if response and response.has("result") and response["result"].has("success"):
			if response["result"]["success"]:
				add_log("✅ Sistema de archivos guardado exitosamente")
			else:
				add_log("⚠️ Error guardando sistema de archivos: " + str(response["result"].get("error", "Desconocido")))
		http_request.queue_free()
	)
	
	var error = http_request.request("http://localhost:8080/rpc", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		add_log("❌ Error enviando request de guardado de filesystem: " + str(error))

func _on_load_pressed():
	"""Cargar juego y sistema de archivos"""
	if game_client and game_client.has_method("load_game"):
		game_client.load_game(1)
		add_log("📂 Cargando juego y sistema de archivos...")
		
		# Cargar sistema de archivos también
		_load_filesystem(1)
	else:
		add_log("❌ GameClient no disponible")

func _load_filesystem(slot: int):
	"""Carga el sistema de archivos"""
	var request_id = Time.get_ticks_msec()
	var request_data = {
		"jsonrpc": "2.0",
		"method": "load_filesystem",
		"params": {
			"slot_id": str(slot)
		},
		"id": request_id
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(func(_result, _code, _headers, _body):
		var json = JSON.new()
		json.parse(_body.get_string_from_utf8())
		var response = json.get_data()
		if response and response.has("result") and response["result"].has("success"):
			if response["result"]["success"]:
				add_log("✅ Sistema de archivos cargado exitosamente")
			else:
				add_log("⚠️ Error cargando sistema de archivos: " + str(response["result"].get("error", "Desconocido")))
		http_request.queue_free()
	)
	
	var error = http_request.request("http://localhost:8080/rpc", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		add_log("❌ Error enviando request de carga de filesystem: " + str(error))

func _on_complete_mission_pressed():
	"""Completar misión actual"""
	if game_client and game_client.has_method("complete_mission"):
		if current_mission_data:
			game_client.complete_mission(current_mission_data.get("id", ""), mission_choices)
			add_log("✅ Completando misión...")
		else:
			add_log("⚠️ No hay misión activa")
	else:
		add_log("❌ GameClient no disponible")

# ============================================
# FUNCIONES PÚBLICAS
# ============================================

func update_world_time(year: int, month: int, day: int):
	"""Actualiza la fecha en la UI"""
	time_value.text = str(day) + "/" + str(month) + "/" + str(year)

func get_game_client() -> Node:
	"""Devuelve la referencia al GameClient"""
	return game_client

func set_game_client(client: Node):
	"""Establece el GameClient manualmente"""
	game_client = client
	if game_client:
		_connect_game_client_signals()
		add_log("✅ GameClient establecido manualmente")

func get_current_mission_data() -> Dictionary:
	"""Devuelve los datos de la misión actual"""
	return current_mission_data
# ============================================
# CONSOLA DE PRUEBAS DE ENDPOINTS
# ============================================

func _create_test_console():
	"""Crea una consola para probar endpoints manualmente"""
	var test_button = Button.new()
	test_button.text = "🛠️ Consola de Pruebas"
	test_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	test_button.pressed.connect(_open_test_console)
	
	# Añadir al header
	$Background/MainContainer/Header.add_child(test_button)
	$Background/MainContainer/Header.move_child(test_button, 1)  # Después del título

# ============================================
# CONSOLA DE PRUEBAS DE ENDPOINTS - FUNCIONES CORREGIDAS
# ============================================

func _open_test_console():
	"""Abre la consola de pruebas y debugging - Tema hacker"""
	var dialog = Window.new()
	dialog.title = "🛠️ CONSOLA DE DEBUG - TERMINALES & BACKEND"
	dialog.size = Vector2(900, 700)
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	
	# ASIGNAR A LAS VARIABLES DE CLASE
	test_console_dialog = dialog
	
	# Fondo oscuro hacker
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(bg)
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 10)
	container.add_theme_constant_override("margin_bottom", 10)
	bg.add_child(container)
	
	# Título con estilo hacker
	var title = Label.new()
	title.text = "═══════════════════════════════════════════════════════\nCONSOLA DE DEBUG - TERMINALES KALI & BACKEND\n═══════════════════════════════════════════════════════"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	# Separador
	var separator = HSeparator.new()
	container.add_child(separator)
	
	# Panel de scroll para botones
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(scroll)
	
	var endpoints_container = VBoxContainer.new()
	endpoints_container.add_theme_constant_override("separation", 5)
	scroll.add_child(endpoints_container)
	
	# SECCIÓN: TERMINALES
	var term_label = Label.new()
	term_label.text = "🖥️ TERMINALES KALI:"
	term_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	term_label.add_theme_font_size_override("font_size", 12)
	endpoints_container.add_child(term_label)
	
	var test_terminal_btn = Button.new()
	test_terminal_btn.text = "1. 🖥️ Crear Terminal Kali"
	test_terminal_btn.custom_minimum_size = Vector2(0, 35)
	test_terminal_btn.pressed.connect(_test_create_terminal)
	endpoints_container.add_child(test_terminal_btn)
	
	var test_terminal_status_btn = Button.new()
	test_terminal_status_btn.text = "2. 📊 Estado Terminal"
	test_terminal_status_btn.custom_minimum_size = Vector2(0, 35)
	test_terminal_status_btn.pressed.connect(_test_terminal_status)
	endpoints_container.add_child(test_terminal_status_btn)
	
	var test_terminal_list_btn = Button.new()
	test_terminal_list_btn.text = "3. 📋 Listar Terminales"
	test_terminal_list_btn.custom_minimum_size = Vector2(0, 35)
	test_terminal_list_btn.pressed.connect(_test_list_terminals)
	endpoints_container.add_child(test_terminal_list_btn)
	
	var test_terminal_command_btn = Button.new()
	test_terminal_command_btn.text = "4. ⚡ Ejecutar Comando (ls)"
	test_terminal_command_btn.custom_minimum_size = Vector2(0, 35)
	test_terminal_command_btn.pressed.connect(_test_terminal_command)
	endpoints_container.add_child(test_terminal_command_btn)
	
	# Separador
	var separator2 = HSeparator.new()
	endpoints_container.add_child(separator2)
	
	# SECCIÓN: BACKEND
	var backend_label = Label.new()
	backend_label.text = "🔧 BACKEND:"
	backend_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	backend_label.add_theme_font_size_override("font_size", 12)
	endpoints_container.add_child(backend_label)
	
	var test1_btn = Button.new()
	test1_btn.text = "5. 🔍 Test Conexión Básica"
	test1_btn.custom_minimum_size = Vector2(0, 35)
	test1_btn.pressed.connect(_test_endpoint_basic_connection)
	endpoints_container.add_child(test1_btn)
	
	var test3_btn = Button.new()
	test3_btn.text = "6. 👤 Estado Jugador"
	test3_btn.custom_minimum_size = Vector2(0, 35)
	test3_btn.pressed.connect(_test_endpoint_player_state)
	endpoints_container.add_child(test3_btn)
	
	var test4_btn = Button.new()
	test4_btn.text = "7. 🎯 Misiones Disponibles"
	test4_btn.custom_minimum_size = Vector2(0, 35)
	test4_btn.pressed.connect(_test_endpoint_missions)
	endpoints_container.add_child(test4_btn)
	
	var test8_btn = Button.new()
	test8_btn.text = "8. 🧪 Ejecutar TODAS las pruebas"
	test8_btn.custom_minimum_size = Vector2(0, 35)
	test8_btn.pressed.connect(_run_all_tests)
	endpoints_container.add_child(test8_btn)
	
	container.add_child(endpoints_container)
	
	# Área de resultados con estilo terminal
	var results_label = Label.new()
	results_label.text = "═══════════════════════════════════════════════════════\nRESULTADOS:\n═══════════════════════════════════════════════════════"
	results_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	results_label.add_theme_font_size_override("font_size", 12)
	container.add_child(results_label)
	
	var results_text = TextEdit.new()
	results_text.name = "TestResults"
	results_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_text.editable = false
	
	# Estilo terminal para el TextEdit
	var text_style = StyleBoxFlat.new()
	text_style.bg_color = Color(0.0, 0.0, 0.0)
	text_style.border_color = Color(0.0, 0.8, 0.0)
	text_style.border_width_left = 2
	text_style.border_width_right = 2
	text_style.border_width_top = 2
	text_style.border_width_bottom = 2
	results_text.add_theme_stylebox_override("normal", text_style)
	results_text.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
	results_text.add_theme_font_size_override("font_size", 11)
	
	# ASIGNAR A LA VARIABLE DE CLASE
	test_results_text = results_text
	
	container.add_child(results_text)
	
	# Botón para limpiar resultados
	var clear_btn = Button.new()
	clear_btn.text = "🧹 Limpiar Resultados"
	clear_btn.custom_minimum_size = Vector2(0, 35)
	clear_btn.pressed.connect(_clear_test_results)
	container.add_child(clear_btn)
	
	# Aplicar tema hacker a todos los botones
	_apply_hacker_theme_to_buttons_recursive(endpoints_container)
	_apply_hacker_theme_to_buttons_recursive(container)
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	
	# Conectar señal de cierre
	dialog.close_requested.connect(func(): 
		test_console_dialog = null
		test_results_text = null
		dialog.queue_free()
	)

func _apply_hacker_theme_to_buttons_recursive(node: Node):
	"""Aplica tema hacker a botones recursivamente"""
	if node is Button:
		var button = node as Button
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color(0.08, 0.12, 0.15)
		button_style.border_color = Color(0.0, 0.6, 0.0, 0.6)
		button_style.border_width_left = 1
		button_style.border_width_right = 1
		button_style.border_width_top = 1
		button_style.border_width_bottom = 1
		button.add_theme_stylebox_override("normal", button_style)
		button.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		button.add_theme_color_override("font_hover_color", Color(0.0, 1.0, 0.2))
	
	for child in node.get_children():
		_apply_hacker_theme_to_buttons_recursive(child)

func _test_endpoint_basic_connection():
	"""Prueba conexión básica al backend"""
	add_log("🧪 Probando endpoint: CONEXIÓN BÁSICA")
	
	if game_client and game_client.has_method("test_connection"):
		game_client.test_connection()
		_add_test_result("✅ Conexión básica - Enviada")
	else:
		_add_test_result("❌ Método test_connection no disponible")

func _test_endpoint_auth():
	"""Prueba autenticación"""
	add_log("🧪 Probando endpoint: AUTENTICACIÓN")
	
	if game_client and game_client.has_method("authenticate"):
		# Datos de prueba
		var test_data = {
			"username": "test_user",
			"password": "test_pass"
		}
		game_client.authenticate(test_data)
		_add_test_result("✅ Autenticación - Enviada con usuario de prueba")
	else:
		_add_test_result("❌ Método authenticate no disponible")

func _test_endpoint_player_state():
	"""Prueba obtener estado del jugador"""
	add_log("🧪 Probando endpoint: ESTADO JUGADOR")
	
	if game_client and game_client.has_method("get_player_state"):
		var state = game_client.get_player_state()
		if state:
			_add_test_result("✅ Estado jugador - Obtenido: " + str(state))
		else:
			_add_test_result("⚠️ Estado jugador - Vacío o null")
	else:
		_add_test_result("❌ Método get_player_state no disponible")

func _test_endpoint_missions():
	"""Prueba obtener misiones"""
	add_log("🧪 Probando endpoint: MISIONES")
	
	if game_client and game_client.has_method("get_available_missions"):
		var missions = game_client.get_available_missions()
		if missions and missions.size() > 0:
			_add_test_result("✅ Misiones - " + str(missions.size()) + " disponibles: " + str(missions))
		else:
			_add_test_result("⚠️ Misiones - Ninguna disponible o error")
	else:
		_add_test_result("❌ Método get_available_missions no disponible")

func _test_endpoint_manifesto():
	"""Prueba enviar manifiesto"""
	add_log("🧪 Probando endpoint: MANIFIESTO")
	
	if game_client and game_client.has_method("submit_manifesto"):
		var test_manifesto = "Este es un manifiesto de prueba generado automáticamente."
		game_client.submit_manifesto(test_manifesto, true, ["test", "automated"])
		_add_test_result("✅ Manifiesto - Enviado: " + test_manifesto.substr(0, 50) + "...")
	else:
		_add_test_result("❌ Método submit_manifesto no disponible")

func _test_endpoint_save():
	"""Prueba guardar partida"""
	add_log("🧪 Probando endpoint: GUARDAR")
	
	if game_client and game_client.has_method("save_game"):
		game_client.save_game(0)  # Slot 0 para pruebas
		_add_test_result("✅ Guardar - Solicitud enviada (slot 0)")
	else:
		_add_test_result("❌ Método save_game no disponible")

func _test_endpoint_world_state():
	"""Prueba obtener estado mundial"""
	add_log("🧪 Probando endpoint: ESTADO MUNDIAL")
	
	if game_client and game_client.has_method("get_world_state"):
		var world = game_client.get_world_state()
		if world:
			_add_test_result("✅ Estado mundial - Obtenido: " + str(world))
		else:
			_add_test_result("⚠️ Estado mundial - Vacío o null")
	else:
		_add_test_result("❌ Método get_world_state no disponible")
func _repeat_string(text: String, times: int) -> String:
	var result = ""
	for i in range(times):
		result += text
	return result

func _run_all_tests():
	"""Ejecuta todas las pruebas en secuencia"""
	# Verificar si la consola está abierta
	if not test_console_dialog or not is_instance_valid(test_console_dialog):
		add_log("⚠️ Abre primero la consola de pruebas para ver los resultados")
		return  # Salir si no hay consola
	
	_clear_test_results()
	_add_test_result("🧪 EJECUTANDO SUITE COMPLETA DE PRUEBAS")
	_add_test_result("==================================================")
	
	# Ejecutar pruebas en secuencia
	_test_endpoint_basic_connection()
	await get_tree().create_timer(0.3).timeout
	
	_test_endpoint_auth()
	await get_tree().create_timer(0.3).timeout
	
	_test_endpoint_player_state()
	await get_tree().create_timer(0.3).timeout
	
	_test_endpoint_missions()
	await get_tree().create_timer(0.3).timeout
	
	_test_endpoint_manifesto()
	await get_tree().create_timer(0.3).timeout
	
	_test_endpoint_save()
	await get_tree().create_timer(0.3).timeout
	
	_test_endpoint_world_state()
	
	_add_test_result("==================================================")
	_add_test_result("🎉 SUITE DE PRUEBAS COMPLETADA")

func _add_test_result(message: String):
	"""Añade resultado a la consola de pruebas"""
	# Añadir al log principal
	add_log("🧪 TEST: " + message)
	
	# Añadir a la consola solo si existe
	if test_console_dialog and is_instance_valid(test_console_dialog):
		if test_results_text and is_instance_valid(test_results_text):
			var timestamp = Time.get_time_string_from_system()
			test_results_text.text += "[" + timestamp + "] " + message + "\n"
			test_results_text.scroll_vertical = 99999
	else:
		# Si la consola no está abierta, solo mostrar en el log
		print("TEST (consola cerrada): " + message)

func _clear_test_results():
	"""Limpia los resultados de pruebas"""
	if test_results_text and is_instance_valid(test_results_text):
		test_results_text.text = ""

# ============================================
# PRUEBAS DE TERMINALES KALI
# ============================================

func _test_create_terminal():
	"""Prueba crear una terminal Kali"""
	_add_test_result("🖥️ Probando crear terminal Kali...")
	
	if not terminal_manager:
		_initialize_terminal_manager()
	
	if terminal_manager:
		var term_id = terminal_manager.open_terminal("")
		_add_test_result("✅ Terminal creada - ID: " + str(term_id))
	else:
		_add_test_result("❌ TerminalManager no disponible")

func _test_terminal_status():
	"""Prueba obtener estado de terminal"""
	_add_test_result("📊 Probando estado de terminal...")
	
	if not terminal_manager:
		_add_test_result("❌ TerminalManager no disponible")
		return
	
	var terminals = terminal_manager.list_terminals()
	if terminals.size() > 0:
		var term_id = terminals[0]
		_add_test_result("✅ Terminal encontrada: " + str(term_id))
	else:
		_add_test_result("⚠️ No hay terminales activas")

func _test_list_terminals():
	"""Prueba listar terminales"""
	_add_test_result("📋 Listando terminales...")
	
	if not terminal_manager:
		_add_test_result("❌ TerminalManager no disponible")
		return
	
	var terminals = terminal_manager.list_terminals()
	_add_test_result("✅ Terminales activas: " + str(terminals.size()))
	for term_id in terminals:
		_add_test_result("  - " + str(term_id))

func _test_terminal_command():
	"""Prueba ejecutar comando en terminal"""
	_add_test_result("⚡ Probando ejecutar comando 'ls'...")
	
	if not terminal_manager:
		_add_test_result("❌ TerminalManager no disponible")
		return
	
	var terminals = terminal_manager.list_terminals()
	if terminals.size() > 0:
		var term = terminal_manager.get_terminal(terminals[0])
		if term:
			_add_test_result("✅ Terminal encontrada, ejecutando comando...")
		else:
			_add_test_result("❌ Terminal no encontrada")
	else:
		_add_test_result("⚠️ No hay terminales activas. Crea una primero.")

func _show_ai_analysis(analysis: Dictionary):
	"""Muestra resultados del análisis de IA"""
	if not analysis or not analysis.has("analysis"):
		add_log("❌ Análisis de IA no disponible")
		return
	
	var ai = analysis.get("analysis", {})
	var recommendations = analysis.get("recommendations", [])
	var impact = analysis.get("impact_prediction", {})
	
	var result_text = "🤖 ANÁLISIS DE IA:\n\n"
	
	result_text += "📊 MÉTRICAS:\n"
	result_text += "• Palabras: " + str(ai.get("word_count", 0)) + "\n"
	result_text += "• Sentimiento: " + str(ai.get("sentiment", "N/A")) + "\n"
	result_text += "• Calidad: " + str(int(ai.get("overall_quality", 0) * 100)) + "%\n"
	result_text += "• Temas: " + ", ".join(ai.get("detected_topics", [])) + "\n\n"
	
	if recommendations.size() > 0:
		result_text += "💡 RECOMENDACIONES:\n"
		for rec in recommendations:
			result_text += "• " + str(rec) + "\n"
		result_text += "\n"
	
	if impact:
		result_text += "🎯 IMPACTO PREDICHO:\n"
		result_text += "• Alcance: " + str(impact.get("estimated_reach", 0)) + " personas\n"
		result_text += "• Riesgo: " + str(impact.get("risk_level", "medium")) + "\n"
		
		if impact.has("estimated_sanity_impact"):
			var sanity_impact = impact.get("estimated_sanity_impact", 0)
			result_text += "• Impacto cordura: "
			if sanity_impact > 0:
				result_text += "+" + str(sanity_impact) + "\n"
			else:
				result_text += str(sanity_impact) + "\n"
	
	# Mostrar diálogo
	var alert = AcceptDialog.new()
	alert.title = "Análisis de IA"
	alert.dialog_text = result_text
	alert.size = Vector2(500, 400)
	add_child(alert)
	alert.popup_centered()
	
	add_log("🤖 Análisis de IA mostrado")

# ============================================
# INICIALIZACIÓN DE SISTEMAS
# ============================================

func _initialize_managers():
	"""Inicializa todos los managers del juego"""
	# EcosystemManager
	if ResourceLoader.exists("res://scripts/managers/EcosystemManager.gd"):
		var EcosystemManagerClass = load("res://scripts/managers/EcosystemManager.gd")
		ecosystem_manager = EcosystemManagerClass.new()
		ecosystem_manager.name = "EcosystemManager"
		if not ecosystem_manager.get_parent():
			add_child(ecosystem_manager)
		print("✅ EcosystemManager inicializado")
	
	# MissionManager
	if ResourceLoader.exists("res://scripts/managers/MissionManager.gd"):
		var MissionManagerClass = load("res://scripts/managers/MissionManager.gd")
		var mission_manager = MissionManagerClass.new()
		mission_manager.name = "MissionManager"
		if game_client:
			mission_manager.game_client = game_client
		if not mission_manager.get_parent():
			add_child(mission_manager)
		print("✅ MissionManager inicializado")
	
	# SocialCrisisManager
	if ResourceLoader.exists("res://scripts/managers/SocialCrisisManager.gd"):
		var SocialCrisisManagerClass = load("res://scripts/managers/SocialCrisisManager.gd")
		social_crisis_manager = SocialCrisisManagerClass.new()
		social_crisis_manager.name = "SocialCrisisManager"
		if game_client and social_crisis_manager.has_method("set_game_client"):
			social_crisis_manager.set_game_client(game_client)
		if not social_crisis_manager.get_parent():
			add_child(social_crisis_manager)
		print("✅ SocialCrisisManager inicializado")
	
	# EconomicCrisisManager
	if ResourceLoader.exists("res://scripts/managers/EconomicCrisisManager.gd"):
		var EconomicCrisisManagerClass = load("res://scripts/managers/EconomicCrisisManager.gd")
		economic_crisis_manager = EconomicCrisisManagerClass.new()
		economic_crisis_manager.name = "EconomicCrisisManager"
		if game_client and economic_crisis_manager.has_method("set_game_client"):
			economic_crisis_manager.set_game_client(game_client)
		if not economic_crisis_manager.get_parent():
			add_child(economic_crisis_manager)
		print("✅ EconomicCrisisManager inicializado")
	
	# TippingPointRewardSystem
	if ResourceLoader.exists("res://scripts/managers/TippingPointRewardSystem.gd"):
		var TippingPointRewardSystemClass = load("res://scripts/managers/TippingPointRewardSystem.gd")
		tipping_point_reward_system = TippingPointRewardSystemClass.new()
		tipping_point_reward_system.name = "TippingPointRewardSystem"
		if game_client and tipping_point_reward_system.has_method("set_game_client"):
			tipping_point_reward_system.set_game_client(game_client)
		if not tipping_point_reward_system.get_parent():
			add_child(tipping_point_reward_system)
		print("✅ TippingPointRewardSystem inicializado")
	
	# TimeSystem
	if ResourceLoader.exists("res://scripts/managers/TimeSystem.gd"):
		var TimeSystemClass = load("res://scripts/managers/TimeSystem.gd")
		time_system = TimeSystemClass.new()
		time_system.name = "TimeSystem"
		if time_system.has_signal("day_passed"):
			time_system.day_passed.connect(_on_day_passed)
		if not time_system.get_parent():
			add_child(time_system)
		print("✅ TimeSystem inicializado")
	
	# ClimateActionSystem
	if ResourceLoader.exists("res://scripts/managers/ClimateActionSystem.gd"):
		var ClimateActionSystemClass = load("res://scripts/managers/ClimateActionSystem.gd")
		climate_action_system = ClimateActionSystemClass.new()
		climate_action_system.name = "ClimateActionSystem"
		if not climate_action_system.get_parent():
			add_child(climate_action_system)
		print("✅ ClimateActionSystem inicializado")

func _initialize_climate_system():
	"""Inicializa el sistema climático"""
	if ResourceLoader.exists("res://scripts/managers/ClimateSystem.gd"):
		var ClimateSystemClass = load("res://scripts/managers/ClimateSystem.gd")
		climate_system = ClimateSystemClass.new()
		climate_system.name = "ClimateSystem"
		if climate_system.has_signal("tipping_point_activated"):
			climate_system.tipping_point_activated.connect(_on_tipping_point_activated)
		if climate_system.has_signal("social_crisis_triggered"):
			climate_system.social_crisis_triggered.connect(_on_social_crisis_triggered)
		if not climate_system.get_parent():
			add_child(climate_system)
		print("✅ ClimateSystem inicializado")

func _initialize_economic_systems():
	"""Inicializa sistemas económicos"""
	# Ya se inicializó en _initialize_managers()
	pass

func _initialize_terminal_manager():
	"""Inicializa el gestor de terminales Kali Linux"""
	print("🔧 [UI_Main] Inicializando TerminalManager...")
	
	if ResourceLoader.exists("res://scripts/UI/TerminalManager.gd"):
		var TerminalManagerClass = load("res://scripts/UI/TerminalManager.gd")
		if TerminalManagerClass:
			terminal_manager = TerminalManagerClass.new()
			terminal_manager.name = "TerminalManager"
			if not terminal_manager.get_parent():
				add_child(terminal_manager)
			print("✅ [UI_Main] TerminalManager inicializado y añadido al árbol")
			print("✅ [UI_Main] TerminalManager es válido: ", terminal_manager != null)
		else:
			print("❌ [UI_Main] Error cargando TerminalManagerClass")
	else:
		print("❌ [UI_Main] TerminalManager.gd no encontrado en: res://scripts/UI/TerminalManager.gd")

# El botón de terminal ahora está en la escena UI_Main.tscn, no se añade dinámicamente

func _on_terminal_button_pressed():
	"""Abre una nueva terminal Kali Linux"""
	print("🔘 [UI_Main] Botón de terminal presionado")
	
	if not terminal_manager:
		print("⚠️ [UI_Main] TerminalManager no existe, inicializando...")
		_initialize_terminal_manager()
	
	if terminal_manager:
		print("✅ [UI_Main] TerminalManager encontrado")
		# Abrir terminal con escenario genérico
		# El escenario puede ser cambiado según la misión activa
		var scenario = _get_current_scenario()
		print("📋 [UI_Main] Escenario detectado: ", scenario)
		var term_id = terminal_manager.open_terminal(scenario)
		add_log("💻 6ME Shell abierta - ID: " + str(term_id))
		print("✅ [UI_Main] Comando open_terminal ejecutado - ID: ", term_id)
	else:
		add_log("❌ Error: TerminalManager no disponible")
		print("❌ [UI_Main] TerminalManager sigue siendo null después de inicializar")

func _get_current_scenario() -> String:
	"""Obtiene el escenario actual según la misión activa"""
	# Si hay una misión activa, usar su escenario
	if current_mission_data.has("id"):
		var mission_id = current_mission_data.get("id", "")
		match mission_id:
			"m0_brecha_nsa", "m0":
				return "nsa_breach"
			"m1_islandia", "m1":
				return "circle_prometheus"
			_:
				return ""
	return ""  # Terminal genérica sin escenario específico

func _on_day_passed(year: int, month: int, day: int):
	"""Maneja el paso de un día"""
	update_world_time(year, month, day)
	add_log("📅 Día pasado: " + str(day) + "/" + str(month) + "/" + str(year))

func _on_tipping_point_activated(tip_id: String, tip):
	"""Maneja la activación de un tipping point"""
	add_log("🚨 TIPPING POINT ACTIVADO: " + tip_id)
	if tipping_point_reward_system and tipping_point_reward_system.has_method("apply_tipping_point_effects"):
		tipping_point_reward_system.apply_tipping_point_effects(tip_id, tip)

func _on_social_crisis_triggered(crisis_type: String, severity: float):
	"""Maneja una crisis social"""
	add_log("⚠️ CRISIS SOCIAL: " + crisis_type + " (severidad: " + str(severity) + ")")

# ============================================
# PANELES DE MAPA Y ECOSISTEMAS
# ============================================

func _open_world_map():
	"""Abre el panel del mapa del mundo"""
	if world_map_panel and is_instance_valid(world_map_panel):
		world_map_panel.queue_free()
		world_map_panel = null
	
	if ResourceLoader.exists("res://scripts/UI/WorldMapPanel.gd"):
		var WorldMapPanelClass = load("res://scripts/UI/WorldMapPanel.gd")
		world_map_panel = WorldMapPanelClass.new()
		world_map_panel.name = "WorldMapPanel"
		
		# Crear ventana para el mapa del mundo
		var map_window = Window.new()
		map_window.title = "🗺️ Mapa del Mundo"
		map_window.size = Vector2(1200, 800)
		map_window.set_flag(Window.FLAG_RESIZE_DISABLED, false)
		
		# Configurar el panel para llenar la ventana
		world_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		world_map_panel.set_offsets_preset(Control.PRESET_FULL_RECT)
		world_map_panel.visible = true
		world_map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Añadir panel a la ventana
		map_window.add_child(world_map_panel)
		
		if game_client and world_map_panel.has_method("set_game_client"):
			world_map_panel.set_game_client(game_client)
		
		if ecosystem_manager and world_map_panel.has_method("set_ecosystem_manager"):
			world_map_panel.set_ecosystem_manager(ecosystem_manager)
		
		# NO conectar la señal region_selected aquí - el panel de detalles se muestra automáticamente
		# y desde ahí el usuario puede abrir el panel de misiones con el botón "Ver Misiones"
		
		# Añadir ventana al árbol y mostrarla
		get_tree().root.add_child(map_window)
		map_window.popup_centered()
		
		# Guardar referencia a la ventana en el panel para que el botón cerrar funcione
		if world_map_panel.has_method("set_parent_window"):
			world_map_panel.set_parent_window(map_window)
		else:
			# Si el método no existe, establecer directamente la variable
			world_map_panel.parent_window = map_window
		
		add_log("🗺️ Mapa del mundo abierto")
	else:
		add_log("❌ WorldMapPanel.gd no encontrado")

func _open_ecosystems_panel():
	"""Abre el panel de ecosistemas"""
	# Cerrar panel anterior si existe
	var existing_panel = find_child("EcosystemPanel", true, false)
	if existing_panel:
		existing_panel.queue_free()
		await get_tree().process_frame
	
	if ResourceLoader.exists("res://scripts/UI/UI_EcosystemPanel.gd"):
		var EcosystemPanelClass = load("res://scripts/UI/UI_EcosystemPanel.gd")
		var ecosystem_panel = EcosystemPanelClass.new()
		ecosystem_panel.name = "EcosystemPanel"
		ecosystem_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		ecosystem_panel.set_offsets_preset(Control.PRESET_FULL_RECT)
		ecosystem_panel.z_index = 100  # Asegurar que esté por encima
		ecosystem_panel.visible = true
		add_child(ecosystem_panel)
		add_log("🌍 Panel de ecosistemas abierto")
	else:
		add_log("❌ UI_EcosystemPanel.gd no encontrado")

func _open_mission_selection_panel(region_code: String):
	"""Abre el panel de selección de misiones para una región"""
	add_log("🎯 Abriendo panel de misiones para región: " + region_code)
	
	# Buscar MissionManager
	var mission_manager = get_node_or_null("MissionManager")
	if not mission_manager:
		add_log("❌ MissionManager no encontrado")
		return
	
	# Obtener misiones de la región
	if mission_manager.has_method("get_missions_for_region"):
		var missions = mission_manager.get_missions_for_region(region_code)
		if missions.is_empty():
			add_log("⚠️ No hay misiones disponibles para esta región")
			return
		
		# Crear diálogo de selección
		var dialog = AcceptDialog.new()
		dialog.title = "Misiones - " + region_code
		dialog.size = Vector2(500, 400)
		
		var container = VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var label = Label.new()
		label.text = "Selecciona una misión:"
		container.add_child(label)
		
		var missions_list = ItemList.new()
		missions_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		for mission_id in missions:
			var mission = mission_manager.missions.get(mission_id)
			if mission:
				missions_list.add_item(mission.mission_name, null)
		container.add_child(missions_list)
		
		var start_button = Button.new()
		start_button.text = "Iniciar Misión"
		start_button.pressed.connect(func():
			var selected = missions_list.get_selected_items()
			if selected.size() > 0:
				var mission_id = missions[selected[0]]
				if mission_manager.has_method("start_mission"):
					mission_manager.start_mission(mission_id)
				dialog.queue_free()
		)
		container.add_child(start_button)
		
		dialog.add_child(container)
		add_child(dialog)
		dialog.popup_centered()

func reveal_world_map():
	"""Revela el mapa del mundo (llamado desde Mission1Scene después del tutorial)"""
	_open_world_map()
	add_log("🗺️ Mapa del mundo revelado después del tutorial")

func _setup_world_map_mini():
	"""Configura el mapa del mundo mini en la esquina inferior derecha"""
	# Esperar a que el layout esté listo
	await get_tree().process_frame
	
	var background = $Background
	if not background:
		print("Error: Background no encontrado")
		return
	
	# Crear contenedor para el mapa mini
	var map_mini_container = Control.new()
	map_mini_container.name = "WorldMapMiniContainer"
	
	# Posicionar en esquina inferior derecha (25% del ancho y alto)
	map_mini_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_mini_container.anchor_left = 0.75  # Empieza al 75% del ancho
	map_mini_container.anchor_top = 0.75    # Empieza al 75% del alto
	map_mini_container.anchor_right = 1.0    # Hasta el 100%
	map_mini_container.anchor_bottom = 1.0  # Hasta el 100%
	map_mini_container.offset_left = 0
	map_mini_container.offset_top = 0
	map_mini_container.offset_right = 0
	map_mini_container.offset_bottom = 0
	
	# Estilo del contenedor
	var container_style = StyleBoxFlat.new()
	container_style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	container_style.border_color = Color(0.0, 1.0, 1.0, 0.8)
	container_style.border_width_left = 2
	container_style.border_width_right = 2
	container_style.border_width_top = 2
	container_style.border_width_bottom = 2
	container_style.corner_radius_top_left = 5
	container_style.corner_radius_top_right = 5
	container_style.corner_radius_bottom_left = 5
	container_style.corner_radius_bottom_right = 5
	
	var container_panel = Panel.new()
	container_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	container_panel.add_theme_stylebox_override("panel", container_style)
	map_mini_container.add_child(container_panel)
	
	# Añadir imagen de fondo si existe
	var bg_texture = TextureRect.new()
	bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	# Intentar cargar la imagen de fondo
	var image_paths = [
		"res://img/mapamundi.jpg",
		"res://assets/environments/mapamundi.jpg",
		"res://img/world_map.jpg",
		"res://assets/environments/world_map.jpg"
	]
	
	var bg_texture_loaded = false
	for path in image_paths:
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				bg_texture.texture = texture
				bg_texture_loaded = true
				print("Imagen de fondo del mapa cargada desde: ", path)
				break
	
	if not bg_texture_loaded:
		print("⚠️ No se encontró la imagen de fondo del mapa, usando color sólido")
		# Si no hay imagen, usar un color de fondo
		container_style.bg_color = Color(0.05, 0.1, 0.15, 0.95)
	
	container_panel.add_child(bg_texture)
	
	# Crear WorldMapPanel mini
	if ResourceLoader.exists("res://scripts/UI/WorldMapPanel.gd"):
		var WorldMapPanelClass = load("res://scripts/UI/WorldMapPanel.gd")
		var world_map_mini = WorldMapPanelClass.new()
		world_map_mini.name = "WorldMapMini"
		world_map_mini.set_anchors_preset(Control.PRESET_FULL_RECT)
		world_map_mini.set_offsets_preset(Control.PRESET_FULL_RECT)
		world_map_mini.visible = true
		world_map_mini.mouse_filter = Control.MOUSE_FILTER_STOP
		world_map_mini.z_index = 1  # Encima de la imagen de fondo
		
		# Configurar sistemas si están disponibles
		if game_client and world_map_mini.has_method("set_game_client"):
			world_map_mini.set_game_client(game_client)
		
		if ecosystem_manager and world_map_mini.has_method("set_ecosystem_manager"):
			world_map_mini.set_ecosystem_manager(ecosystem_manager)
		
		# NO conectar la señal region_selected aquí - el panel de detalles se muestra automáticamente
		# y desde ahí el usuario puede abrir el panel de misiones con el botón "Ver Misiones"
		
		container_panel.add_child(world_map_mini)
		print("✅ Mapa del mundo mini integrado en esquina inferior derecha")
	else:
		print("❌ WorldMapPanel.gd no encontrado")
	
	# Añadir contenedor al Background
	background.add_child(map_mini_container)
	map_mini_container.z_index = 50  # Asegurar que esté por encima de otros elementos
	
	print("✅ Mapa del mundo mini configurado en esquina inferior derecha (25% de pantalla)")

# ============================================
# SISTEMA DE DESBLOQUEO DEL MANIFIESTO
# ============================================

func _check_manifesto_unlock(mission_id: String):
	"""Verifica si una misión completada desbloquea el manifiesto"""
	if manifesto_unlocked:
		return  # Ya está desbloqueado
	
	# Buscar MissionManager para obtener información de la misión
	var mission_manager = get_node_or_null("MissionManager")
	if not mission_manager:
		# Intentar buscar en el árbol
		mission_manager = get_tree().root.find_child("MissionManager", true, false)
	
	if mission_manager and mission_manager.has_method("get_mission"):
		var mission = mission_manager.get_mission(mission_id)
		if mission:
			# Verificar si la misión tiene acción revolucionaria y desbloquea el manifiesto
			if mission.has_revolutionary_action and mission.unlocks_manifesto:
				_unlock_manifesto()
				add_log("📜 Manifiesto desbloqueado tras completar misión con acción revolucionaria")

func _unlock_manifesto():
	"""Desbloquea el botón de manifiesto"""
	if manifesto_unlocked:
		return
	
	manifesto_unlocked = true
	_create_unlocked_manifesto_button()
	add_log("✅ Botón de manifiesto desbloqueado")

func _create_unlocked_manifesto_button():
	"""Crea el botón de manifiesto cuando se desbloquea"""
	if unlocked_manifesto_button:
		return  # Ya existe
	
	var actions_container = $Background/MainContainer/Content/LeftPanel/ActionsContainer
	if not actions_container:
		return
	
	# Crear botón de manifiesto
	unlocked_manifesto_button = Button.new()
	unlocked_manifesto_button.name = "UnlockedManifestoButton"
	unlocked_manifesto_button.text = "📜 Enviar Manifiesto"
	unlocked_manifesto_button.custom_minimum_size = Vector2(0, 45)
	unlocked_manifesto_button.add_theme_font_size_override("font_size", 16)
	
	# Aplicar estilo cyberpunk
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	if CyberpunkThemeClass:
		unlocked_manifesto_button.add_theme_stylebox_override("normal", CyberpunkThemeClass.create_button_style_normal())
		unlocked_manifesto_button.add_theme_stylebox_override("hover", CyberpunkThemeClass.create_button_style_hover())
		unlocked_manifesto_button.add_theme_stylebox_override("pressed", CyberpunkThemeClass.create_button_style_pressed())
		unlocked_manifesto_button.add_theme_color_override("font_color", CyberpunkThemeClass.COLOR_TEXT_PRIMARY)
		unlocked_manifesto_button.add_theme_color_override("font_hover_color", CyberpunkThemeClass.COLOR_NEON_CYAN)
	
	# Conectar señal
	unlocked_manifesto_button.pressed.connect(_on_manifesto_unlocked_pressed)
	
	# Añadir al contenedor (después de los botones de necesidades, antes del mapa)
	var insert_position = 3  # Después de SatisfyNeedsContainer
	if actions_container.get_child_count() > insert_position:
		actions_container.add_child(unlocked_manifesto_button)
		actions_container.move_child(unlocked_manifesto_button, insert_position)
	else:
		actions_container.add_child(unlocked_manifesto_button)
	
	add_log("📜 Botón de manifiesto añadido al panel de acciones")

func _on_manifesto_unlocked_pressed():
	"""Maneja el envío del manifiesto cuando está desbloqueado"""
	add_log("📜 Abriendo editor de manifiesto...")
	
	# Diálogo para escribir manifiesto
	var dialog = AcceptDialog.new()
	dialog.title = "Escribe tu Manifiesto"
	dialog.size = Vector2(600, 400)
	
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = "Escribe tu manifiesto político:"
	container.add_child(label)
	
	var text_edit = TextEdit.new()
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.text = "¡Abajo los Cartógrafos! La revolución ecológica debe triunfar."
	container.add_child(text_edit)
	
	var button_container = HBoxContainer.new()
	
	var ai_button = Button.new()
	ai_button.text = "🤖 Analizar con IA"
	ai_button.pressed.connect(func():
		if game_client and game_client.has_method("submit_manifesto"):
			var result = await game_client.submit_manifesto(text_edit.text, true, ["ai_analyzed"])
			_show_ai_analysis(result.get("analysis", {}))
			# Marcar como enviado
			manifesto_submitted = true
			add_log("✅ Manifiesto enviado exitosamente")
			# Notificar a MissionManager
			_notify_manifesto_submitted()
		dialog.queue_free()
	)
	button_container.add_child(ai_button)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.pressed.connect(func():
		dialog.queue_free()
	)
	button_container.add_child(cancel_button)
	
	container.add_child(button_container)
	dialog.add_child(container)
	add_child(dialog)
	dialog.popup_centered()

func _notify_manifesto_submitted():
	"""Notifica a MissionManager que el manifiesto ha sido enviado"""
	var mission_manager = get_node_or_null("MissionManager")
	if not mission_manager:
		mission_manager = get_tree().root.find_child("MissionManager", true, false)
	
	if mission_manager and mission_manager.has_method("on_manifesto_submitted"):
		mission_manager.on_manifesto_submitted()
