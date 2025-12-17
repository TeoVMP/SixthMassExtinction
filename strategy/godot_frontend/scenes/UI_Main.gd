extends Control

# ============================================
# REFERENCIAS A NODOS
# ============================================

# Estado del jugador
@onready var connection_status = $Background/MainContainer/Header/ConnectionStatus
@onready var sanity_label = $Background/MainContainer/Content/LeftPanel/PlayerStatus/SanityContainer/SanityLabel
@onready var sanity_bar = $Background/MainContainer/Content/LeftPanel/PlayerStatus/SanityContainer/SanityBar
@onready var hunger_value = $Background/MainContainer/Content/LeftPanel/PlayerStatus/NeedsContainer/HungerValue
@onready var thirst_value = $Background/MainContainer/Content/LeftPanel/PlayerStatus/NeedsContainer/ThirstValue
@onready var sleep_value = $Background/MainContainer/Content/LeftPanel/PlayerStatus/NeedsContainer/SleepValue
@onready var stress_value = $Background/MainContainer/Content/LeftPanel/PlayerStatus/NeedsContainer/StressValue
@onready var reputation_grid = $Background/MainContainer/Content/LeftPanel/PlayerStatus/ReputationContainer/ReputationGrid

# Acciones
@onready var connect_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/ConnectButton
@onready var test_connection_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/TestConnectionButton
@onready var sanity_minus_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/ModifySanityContainer/SanityMinusButton
@onready var sanity_plus_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/ModifySanityContainer/SanityPlusButton
@onready var food_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SatisfyNeedsContainer/FoodButton
@onready var water_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SatisfyNeedsContainer/WaterButton
@onready var sleep_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SatisfyNeedsContainer/SleepButton
@onready var manifesto_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/ManifestoButton
@onready var start_mission_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/StartMissionButton
@onready var save_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SaveLoadContainer/SaveButton
@onready var load_button = $Background/MainContainer/Content/LeftPanel/ActionsContainer/SaveLoadContainer/LoadButton

# Misiones
@onready var active_mission_label = $Background/MainContainer/Content/RightPanel/MissionsContainer/ActiveMissionLabel
@onready var mission_details = $Background/MainContainer/Content/RightPanel/MissionsContainer/MissionDetails
@onready var mission_choices_container = $Background/MainContainer/Content/RightPanel/MissionsContainer/MissionChoicesContainer
@onready var complete_mission_button = $Background/MainContainer/Content/RightPanel/MissionsContainer/CompleteMissionButton

# Estado mundial
@onready var violence_value = $Background/MainContainer/Content/RightPanel/WorldStatusContainer/WorldStatsGrid/ViolenceValue
@onready var cartograph_value = $Background/MainContainer/Content/RightPanel/WorldStatusContainer/WorldStatsGrid/CartographValue
@onready var time_value = $Background/MainContainer/Content/RightPanel/WorldStatusContainer/WorldStatsGrid/TimeValue

# Logs
@onready var log_text = $Background/MainContainer/Content/RightPanel/LogContainer/LogText

# ============================================
# VARIABLES
# ============================================

var game_client: Node = null
var current_mission_data: Dictionary = {}
var mission_choices: Dictionary = {}
var test_console_dialog: AcceptDialog = null
var test_results_text: TextEdit = null
var ecosystem_manager = preload("res://scripts/managers/EcosystemManager.gd").new()
# ============================================
# FUNCIONES PRINCIPALES
# ============================================

func _ready():
	print("🎮 UI_Main inicializada")
	
	# Buscar GameClient en la escena
	_find_game_client()
	
	# Conectar señales de botones
	_connect_signals()
	
	# Inicializar UI
	_initialize_ui()
	
	add_log("✅ UI inicializada correctamente")
	_create_test_console()
	_initialize_ecosystem_manager()  # <-- Asegúrate que está alineado con las otras líneas

func _initialize_ecosystem_manager():
	add_child(ecosystem_manager)
	ecosystem_manager.ecosystem_critical.connect(_on_ecosystem_critical)
	ecosystem_manager.ecosystem_updated.connect(_on_ecosystem_updated)
func _on_ecosystem_critical(eco_id: String, state: EcosystemState):
	add_log("🚨 ECOSISTEMA CRÍTICO: " + eco_id + " (" + state.get_status() + ")")

func _on_ecosystem_updated(eco_id: String, state: EcosystemState):
	# Aquí actualizarías la UI si añades un panel de ecosistemas
	pass
func _find_game_client():
	"""Busca el nodo GameClient en la escena"""
	var root = get_tree().root
	game_client = root.find_child("GameClient", true, false)
	
	if game_client:
		print("✅ GameClient encontrado:", game_client.name)
		
		# Conectar señales del GameClient
		_connect_game_client_signals()
		
		# Actualizar UI con estado inicial si está disponible
		_update_ui_from_client()
	else:
		print("⚠️ GameClient no encontrado")
		add_log("⚠️ GameClient no encontrado. ¿Ejecutaste main_test.tscn?")

func _connect_signals():
	"""Conecta todas las señales de botones"""
	connect_button.pressed.connect(_on_connect_pressed)
	test_connection_button.pressed.connect(_on_test_connection_pressed)
	sanity_minus_button.pressed.connect(_on_sanity_minus_pressed)
	sanity_plus_button.pressed.connect(_on_sanity_plus_pressed)
	food_button.pressed.connect(_on_food_pressed)
	water_button.pressed.connect(_on_water_pressed)
	sleep_button.pressed.connect(_on_sleep_pressed)
	manifesto_button.pressed.connect(_on_manifesto_pressed)
	start_mission_button.pressed.connect(_on_start_mission_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	complete_mission_button.pressed.connect(_on_complete_mission_pressed)

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
	
	add_log("✅ Señales del GameClient conectadas")

func _initialize_ui():
	"""Inicializa la UI con valores por defecto"""
	connection_status.text = "❌ Desconectado"
	sanity_label.text = "CORDURA: 85"
	sanity_bar.value = 85
	
	# Colores para barras de necesidades
	_update_sanity_color(85)
	
	# Inicializar reputación
	_initialize_reputation_grid()
	
	# Deshabilitar botones hasta conexión (si es necesario)
	_set_actions_enabled(true)  # Temporalmente habilitado para pruebas
	
	add_log("UI inicializada - Modo prueba")

func _set_actions_enabled(enabled: bool):
	"""Habilita o deshabilita botones de acción"""
	sanity_minus_button.disabled = not enabled
	sanity_plus_button.disabled = not enabled
	food_button.disabled = not enabled
	water_button.disabled = not enabled
	sleep_button.disabled = not enabled
	manifesto_button.disabled = not enabled
	start_mission_button.disabled = not enabled
	save_button.disabled = not enabled
	load_button.disabled = not enabled

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

func _initialize_reputation_grid():
	"""Inicializa la grid de reputación"""
	# Limpiar hijos existentes
	for child in reputation_grid.get_children():
		reputation_grid.remove_child(child)
		child.queue_free()
	
	# Regiones del juego
	var regions = {
		"pe": "Pueblos Explotados",
		"eo": "Europa Occidental", 
		"eu": "Estados Unidos",
		"ch": "China",
		"ru": "Rusia",
		"as": "Asia Sur",
		"au": "África Unida",
		"la": "Latinoamérica"
	}
	
	for region_code in regions.keys():
		# Nombre de la región
		var region_label = Label.new()
		region_label.text = regions[region_code]
		region_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reputation_grid.add_child(region_label)
		
		# Valor de reputación
		var value_label = Label.new()
		value_label.name = "Reputation_" + region_code
		value_label.text = "0"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reputation_grid.add_child(value_label)

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
	"""Actualiza la reputación de una región"""
	var label = reputation_grid.get_node_or_null("Reputation_" + region)
	if label:
		label.text = str(value)
		
		# Color según valor
		if value > 0:
			label.add_theme_color_override("font_color", Color(0, 1, 0))
		elif value < 0:
			label.add_theme_color_override("font_color", Color(1, 0, 0))
		else:
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

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
		connection_status.text = "✅ Conectado"
		connection_status.add_theme_color_override("font_color", Color(0, 1, 0))
		_set_actions_enabled(true)
		add_log("✅ Conectado al servidor backend")
	else:
		connection_status.text = "❌ Desconectado"
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
	
	mission_details.text = details
	complete_mission_button.visible = true
	
	add_log("📋 Misión recibida: " + mission_data.get("title", "Sin título"))

func _on_mission_completed(mission_id: String, result: Dictionary):
	"""Misión completada"""
	add_log("✅ Misión completada: " + mission_id)
	
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
	"""Actualiza el color de la barra de cordura según el valor"""
	var color: Color
	
	if value >= 70:
		color = Color(0, 0.8, 0)  # Verde
	elif value >= 50:
		color = Color(0.8, 0.8, 0)  # Amarillo
	elif value >= 30:
		color = Color(1, 0.5, 0)  # Naranja
	else:
		color = Color(1, 0, 0)  # Rojo
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	sanity_bar.add_theme_stylebox_override("fill", style)

func _update_mission_display(mission_id: String):
	"""Actualiza la visualización de misión"""
	if mission_id and not mission_id.is_empty():
		active_mission_label.text = "Activa: " + mission_id
		complete_mission_button.visible = true
	else:
		active_mission_label.text = "Activa: Ninguna"
		mission_details.text = "Selecciona una misión para ver detalles."
		complete_mission_button.visible = false
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

func _on_manifesto_pressed():
	"""Enviar manifiesto"""
	add_log("📜 Abriendo editor de manifiesto...")
	
	# Diálogo simple para escribir manifiesto
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
	
	var button = Button.new()
	button.text = "📤 Enviar Manifiesto"
	button.pressed.connect(func(): 
		if text_edit.text.length() >= 10:
			if game_client and game_client.has_method("submit_manifesto"):
				game_client.submit_manifesto(text_edit.text, false, [])
				dialog.queue_free()
				add_log("📜 Manifiesto enviado para análisis")
			else:
				add_log("❌ GameClient no disponible")
		else:
			add_log("⚠️ Manifiesto demasiado corto")
	)
	container.add_child(button)
	
	dialog.add_child(container)
	add_child(dialog)
	dialog.popup_centered()

func _on_start_mission_pressed():
	"""Iniciar misión"""
	if game_client and game_client.has_method("start_mission"):
		game_client.start_mission("m1_islandia")
		add_log("🚀 Iniciando misión Islandia...")
	else:
		add_log("❌ GameClient no disponible")

func _on_save_pressed():
	"""Guardar juego"""
	if game_client and game_client.has_method("save_game"):
		game_client.save_game(1)
		add_log("💾 Guardando juego...")
	else:
		add_log("❌ GameClient no disponible")

func _on_load_pressed():
	"""Cargar juego"""
	if game_client and game_client.has_method("load_game"):
		game_client.load_game(1)
		add_log("📂 Cargando juego...")
	else:
		add_log("❌ GameClient no disponible")

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
	"""Abre la consola de pruebas"""
	var dialog = AcceptDialog.new()
	dialog.title = "🛠️ Consola de Pruebas - Endpoints"
	dialog.size = Vector2(800, 600)
	
	# ASIGNAR A LAS VARIABLES DE CLASE
	test_console_dialog = dialog
	
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Título
	var title = Label.new()
	title.text = "PRUEBAS DE ENDPOINTS DEL BACKEND"
	title.add_theme_font_size_override("font_size", 18)
	container.add_child(title)
	
	# Separador
	var separator = HSeparator.new()
	container.add_child(separator)
	
	# Panel de endpoints
	var endpoints_container = VBoxContainer.new()
	endpoints_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# ... (todos los botones de pruebas, igual que antes)
	
	# 1. TEST CONEXIÓN BÁSICA
	var test1_btn = Button.new()
	test1_btn.text = "1. 🔍 Test Conexión Básica"
	test1_btn.pressed.connect(_test_endpoint_basic_connection)
	endpoints_container.add_child(test1_btn)
	
	# 2. AUTENTICACIÓN
	var test2_btn = Button.new()
	test2_btn.text = "2. 🔐 Test Autenticación"
	test2_btn.pressed.connect(_test_endpoint_auth)
	endpoints_container.add_child(test2_btn)
	
	# 3. ESTADO DEL JUGADOR
	var test3_btn = Button.new()
	test3_btn.text = "3. 👤 Obtener Estado Jugador"
	test3_btn.pressed.connect(_test_endpoint_player_state)
	endpoints_container.add_child(test3_btn)
	
	# 4. MISIONES DISPONIBLES
	var test4_btn = Button.new()
	test4_btn.text = "4. 🎯 Obtener Misiones"
	test4_btn.pressed.connect(_test_endpoint_missions)
	endpoints_container.add_child(test4_btn)
	
	# 5. ENVIAR MANIFIESTO
	var test5_btn = Button.new()
	test5_btn.text = "5. 📜 Enviar Manifiesto (Test)"
	test5_btn.pressed.connect(_test_endpoint_manifesto)
	endpoints_container.add_child(test5_btn)
	
	# 6. GUARDAR/CARGAR
	var test6_btn = Button.new()
	test6_btn.text = "6. 💾 Test Guardado"
	test6_btn.pressed.connect(_test_endpoint_save)
	endpoints_container.add_child(test6_btn)
	
	# 7. ESTADO MUNDIAL
	var test7_btn = Button.new()
	test7_btn.text = "7. 🌍 Obtener Estado Mundial"
	test7_btn.pressed.connect(_test_endpoint_world_state)
	endpoints_container.add_child(test7_btn)
	
	# 8. TEST COMPLETO
	var test8_btn = Button.new()
	test8_btn.text = "8. 🧪 Ejecutar TODAS las pruebas"
	test8_btn.pressed.connect(_run_all_tests)
	endpoints_container.add_child(test8_btn)
	
	container.add_child(endpoints_container)
	
	# Área de resultados
	var results_label = Label.new()
	results_label.text = "RESULTADOS:"
	container.add_child(results_label)
	
	var results_text = TextEdit.new()
	results_text.name = "TestResults"
	results_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_text.editable = false
	
	# ASIGNAR A LA VARIABLE DE CLASE
	test_results_text = results_text
	
	container.add_child(results_text)
	
	# Botón para limpiar resultados
	var clear_btn = Button.new()
	clear_btn.text = "🧹 Limpiar Resultados"
	clear_btn.pressed.connect(_clear_test_results)
	container.add_child(clear_btn)
	
	dialog.add_child(container)
	add_child(dialog)
	
	# Conectar señal de cierre
	dialog.close_requested.connect(func(): 
		test_console_dialog = null
		test_results_text = null
		dialog.queue_free()
	)
	
	dialog.popup_centered()

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
