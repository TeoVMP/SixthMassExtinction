# MissionManager.gd
# Sistema de gestión de misiones
extends Node
class_name MissionManager

signal mission_available(mission_id: String)
signal mission_started(mission_id: String)
signal mission_completed(mission_id: String, result: Dictionary)
signal mission_failed(mission_id: String, reason: String)

# Misiones cargadas
var missions: Dictionary = {}  # {mission_id: Mission}
var active_missions: Array[String] = []  # IDs de misiones activas
var completed_missions: Array[String] = []
var failed_missions: Array[String] = []

# Misiones por región
var missions_by_region: Dictionary = {}  # {region_code: [mission_ids]}

# Referencias
var game_client: Node = null
var player_state: Dictionary = {}
var manifesto_submitted: bool = false  # Si el manifiesto ha sido enviado

func _ready():
	print("📋 MissionManager iniciado")
	_load_missions()

func _load_missions():
	"""Carga todas las misiones desde archivos o crea misiones base"""
	# Por ahora, crear algunas misiones de ejemplo basadas en la trama
	_create_initial_missions()
	_organize_missions_by_region()

func _create_initial_missions():
	"""Crea las misiones iniciales basadas en la trama"""
	# Misión 0: La Brecha de la NSA (BONUS HACKER - Siempre activa hasta completarse)
	var m0 = Mission.new()
	m0.mission_id = "m0_brecha_nsa"
	m0.mission_name = "La Brecha de la NSA"
	m0.mission_description = "Infiltrar los servidores de Langley para descubrir el Protocolo Cronos. Misión bonus de hacking ético."
	m0.mission_type = Mission.MissionType.HACKING
	m0.region_code = "eu"
	m0.state_code = "maryland"
	m0.location_name = "Maryland, EE.UU. - 15 de marzo de 2055"
	m0.act_number = 0
	m0.status = Mission.MissionStatus.AVAILABLE  # Disponible para seleccionar
	m0.difficulty = 4
	m0.is_main_story = false  # Es bonus
	m0.climate_action_reward = 5.0
	m0.unlocks = ["m1_refugio_hielo"]
	m0.estimated_time = 10  # 10 minutos
	missions[m0.mission_id] = m0
	# NO añadir a active_missions hasta que se seleccione
	
	# Misión 1: Refugio en el Hielo (Incluye tutorial)
	var m1 = Mission.new()
	m1.mission_id = "m1_refugio_hielo"
	m1.mission_name = "Refugio en el Hielo"
	m1.mission_description = "Llegar a Islandia y conocer al Círculo de Prometeo. Incluye tutorial del juego."
	m1.mission_type = Mission.MissionType.INVESTIGATION
	m1.region_code = "eo"
	m1.location_name = "Islandia - 14 de septiembre de 2028"
	m1.act_number = 1
	m1.status = Mission.MissionStatus.ACTIVE  # Activa desde el inicio junto con M0
	m1.required_missions = []  # No requiere M0 para empezar, pero M0 desbloquea contenido extra
	m1.difficulty = 1  # Fácil porque es tutorial
	m1.is_main_story = true
	m1.climate_action_reward = 10.0
	m1.unlocks = ["m2_huérfanos_deshielo", "m3_latido_amazonas"]
	m1.estimated_time = 10  # 10 minutos (incluye tutorial)
	missions[m1.mission_id] = m1
	active_missions.append(m1.mission_id)  # Añadir a activas
	
	# Misión 2: Huérfanos del Deshielo
	var m2 = Mission.new()
	m2.mission_id = "m2_huérfanos_deshielo"
	m2.mission_name = "Huérfanos del Deshielo"
	m2.mission_description = "Detener la minería de glaciares en Argentina-Chile"
	m2.mission_type = Mission.MissionType.ECOLOGICAL
	m2.region_code = "sa"
	m2.location_name = "Glaciares Andinos"
	m2.act_number = 1
	m2.status = Mission.MissionStatus.LOCKED
	m2.required_missions = ["m1_refugio_hielo"]
	m2.difficulty = 3
	m2.is_main_story = true
	m2.reputation_rewards = {"sa": 15}
	m2.climate_action_reward = 12.0
	missions[m2.mission_id] = m2
	
	# Misión 3: El Latido del Amazonas
	var m3 = Mission.new()
	m3.mission_id = "m3_latido_amazonas"
	m3.mission_name = "El Latido del Amazonas"
	m3.mission_description = "Proteger el Amazonas de la Operación Arca Verde"
	m3.mission_type = Mission.MissionType.ECOLOGICAL
	m3.region_code = "sa"
	m3.country_code = "brazil"
	m3.location_name = "Amazonía brasileña"
	m3.act_number = 1
	m3.status = Mission.MissionStatus.LOCKED
	m3.required_missions = ["m1_refugio_hielo"]
	m3.difficulty = 4
	m3.is_main_story = true
	m3.reputation_rewards = {"sa": 20}
	m3.climate_action_reward = 15.0
	missions[m3.mission_id] = m3
	
	# Añadir más misiones según la trama...
	# (Se pueden añadir más fácilmente después)

func _organize_missions_by_region():
	"""Organiza misiones por región para acceso rápido"""
	missions_by_region.clear()
	
	for mission_id in missions:
		var mission = missions[mission_id]
		var region = mission.region_code
		
		if not missions_by_region.has(region):
			missions_by_region[region] = []
		
		missions_by_region[region].append(mission_id)

func get_missions_for_region(region_code: String) -> Array:
	"""Obtiene todas las misiones para una región (disponibles, activas y completadas)"""
	var region_missions = missions_by_region.get(region_code, [])
	var available = []
	
	# Si no hay misiones organizadas, reorganizar
	if region_missions.is_empty():
		_organize_missions_by_region()
		region_missions = missions_by_region.get(region_code, [])
	
	for mission_id in region_missions:
		var mission = missions.get(mission_id)
		if mission:
			# Incluir todas las misiones: disponibles, activas, completadas y bloqueadas
			# Las bloqueadas se mostrarán con un indicador visual
			available.append(mission)
	
	return available

func get_active_missions_count(region_code: String = "") -> int:
	"""Cuenta misiones activas, opcionalmente filtradas por región"""
	if region_code == "":
		return active_missions.size()
	
	var count = 0
	for mission_id in active_missions:
		var mission = missions.get(mission_id)
		if mission and mission.region_code == region_code:
			count += 1
	return count

func start_mission(mission_id: String) -> bool:
	"""Inicia una misión"""
	if not missions.has(mission_id):
		return false
	
	var mission = missions[mission_id]
	
	# Verificar requisito de manifiesto
	if mission.requires_manifesto and not manifesto_submitted:
		print("❌ Esta misión requiere que se haya enviado el manifiesto primero")
		return false
	
	# La Misión 0 se activa desde el menú y crea el directorio nsa-server
	if mission_id == "m0_brecha_nsa":
		# Cambiar status a ACTIVE
		mission.status = Mission.MissionStatus.ACTIVE
		if not active_missions.has(mission_id):
			active_missions.append(mission_id)
		
		# Llamar al backend para iniciar la misión y crear el servidor víctima
		_call_backend_start_mission(mission_id)
		
		# Emitir señal para que TerminalManager sincronice el contexto y cree el directorio
		mission_started.emit(mission_id)
		print("📋 Misión 0 activada - Usa la terminal general para resolverla")
		print("📋 Creando directorio nsa-server en /home/<jugador>/Desktop/OPs/")
		return true
	
	# Actualizar player_state con manifesto_submitted para verificación
	if not player_state.has("manifesto_submitted"):
		player_state["manifesto_submitted"] = manifesto_submitted
	
	if not mission.can_start(player_state):
		return false
	
	mission.status = Mission.MissionStatus.ACTIVE
	if not active_missions.has(mission_id):
		active_missions.append(mission_id)
	mission_started.emit(mission_id)
	
	print("📋 Misión iniciada: ", mission.mission_name)
	
	# Abrir escena de la misión si tiene una
	_open_mission_scene(mission_id)
	
	return true

func _call_backend_start_mission(mission_id: String):
	"""Llama al backend para iniciar la misión (crea servidor víctima, etc.)"""
	var request_data = {
		"jsonrpc": "2.0",
		"method": "start_mission",
		"params": {
			"mission_id": mission_id
		},
		"id": Time.get_ticks_msec()
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var callback = func(_result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray):
		http_request.queue_free()
	
	http_request.request_completed.connect(callback)
	var error = http_request.request("http://localhost:8080/rpc", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("⚠️ Error llamando al backend para iniciar misión: ", error)

func _open_mission_scene(mission_id: String):
	"""Abre la escena específica de una misión en un panel modal"""
	match mission_id:
		"m0_brecha_nsa":
			# Crear ventana modal para la misión
			var mission_window = Window.new()
			mission_window.title = "MISIÓN 0: La Brecha de la NSA"
			mission_window.size = Vector2(1200, 800)
			mission_window.set_flag(Window.FLAG_RESIZE_DISABLED, false)
			
			# Cargar escena de Misión 0
			var Mission0Class = load("res://scripts/missions/Mission0Scene.gd")
			var mission0_scene = Mission0Class.new()
			mission0_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
			mission0_scene.mission_completed.connect(_on_mission0_completed)
			mission0_scene.mission_failed.connect(_on_mission0_failed)
			mission0_scene.mission_completed.connect(func(_result): mission_window.queue_free())
			mission0_scene.mission_failed.connect(func(_reason): mission_window.queue_free())
			
			mission_window.add_child(mission0_scene)
			get_tree().root.add_child(mission_window)
			mission_window.popup_centered()
		"m1_refugio_hielo":
			# Cargar escena de Misión 1 (con tutorial)
			_open_mission1_with_tutorial()

func _open_mission1_with_tutorial():
	"""Abre la Misión 1 con tutorial en un panel modal"""
	var mission_window = Window.new()
	mission_window.title = "MISIÓN 1: Refugio en el Hielo"
	mission_window.size = Vector2(1000, 700)
	mission_window.set_flag(Window.FLAG_RESIZE_DISABLED, false)
	
	var Mission1Class = load("res://scripts/missions/Mission1Scene.gd")
	var mission1_scene = Mission1Class.new()
	mission1_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	mission1_scene.tutorial_completed.connect(_on_mission1_tutorial_completed)
	mission1_scene.mission_completed.connect(_on_mission1_completed)
	mission1_scene.mission_completed.connect(func(_result): mission_window.queue_free())
	
	mission_window.add_child(mission1_scene)
	get_tree().root.add_child(mission_window)
	mission_window.popup_centered()
	
	print("📋 Abriendo Misión 1 con tutorial...")

func _on_mission0_completed(result: Dictionary):
	"""Maneja la finalización de la Misión 0"""
	complete_mission("m0_brecha_nsa", result)

func _on_mission0_failed(reason: String):
	"""Maneja el fallo de la Misión 0"""
	fail_mission("m0_brecha_nsa", reason)

func _on_mission1_tutorial_completed():
	"""Maneja la finalización del tutorial de la Misión 1"""
	print("✅ Tutorial de Misión 1 completado")

func _on_mission1_completed(result: Dictionary):
	"""Maneja la finalización de la Misión 1"""
	complete_mission("m1_refugio_hielo", result)

func complete_mission(mission_id: String, choices: Dictionary = {}) -> void:
	"""Completa una misión"""
	if not missions.has(mission_id):
		return
	
	var mission = missions[mission_id]
	mission.status = Mission.MissionStatus.COMPLETED
	
	if active_missions.has(mission_id):
		active_missions.erase(mission_id)
	
	completed_missions.append(mission_id)
	
	# Aplicar recompensas
	var result = {
		"mission_id": mission_id,
		"reputation_rewards": mission.reputation_rewards,
		"sanity_reward": mission.sanity_reward,
		"climate_action_reward": mission.climate_action_reward
	}
	
	# Desbloquear nuevas misiones
	for unlock_id in mission.unlocks:
		if missions.has(unlock_id):
			var unlocked = missions[unlock_id]
			if unlocked.status == Mission.MissionStatus.LOCKED:
				unlocked.status = Mission.MissionStatus.AVAILABLE
				mission_available.emit(unlock_id)
	
	mission_completed.emit(mission_id, result)
	print("✅ Misión completada: ", mission.mission_name)

func fail_mission(mission_id: String, reason: String = "") -> void:
	"""Marca una misión como fallida"""
	if not missions.has(mission_id):
		return
	
	var mission = missions[mission_id]
	mission.status = Mission.MissionStatus.FAILED
	
	if active_missions.has(mission_id):
		active_missions.erase(mission_id)
	
	failed_missions.append(mission_id)
	mission_failed.emit(mission_id, reason)
	print("❌ Misión fallida: ", mission.mission_name, " - ", reason)

func update_player_state(new_state: Dictionary):
	"""Actualiza el estado del jugador para verificar requisitos"""
	player_state = new_state
	# Asegurar que player_state incluye manifesto_submitted
	player_state["manifesto_submitted"] = manifesto_submitted
	
	# Verificar si alguna misión bloqueada ahora puede iniciarse
	for mission_id in missions:
		var mission = missions[mission_id]
		if mission.status == Mission.MissionStatus.LOCKED:
			if mission.can_start(player_state):
				mission.status = Mission.MissionStatus.AVAILABLE
				mission_available.emit(mission_id)

func get_mission(mission_id: String) -> Mission:
	"""Obtiene una misión por ID"""
	return missions.get(mission_id)

func has_manifesto_been_submitted() -> bool:
	"""Verifica si el manifiesto ha sido enviado"""
	return manifesto_submitted

func on_manifesto_submitted():
	"""Llamado cuando el jugador envía el manifiesto"""
	manifesto_submitted = true
	print("✅ Manifiesto marcado como enviado en MissionManager")
	
	# Verificar si alguna misión bloqueada ahora puede iniciarse
	for mission_id in missions:
		var mission = missions[mission_id]
		if mission.status == Mission.MissionStatus.LOCKED:
			if mission.can_start(player_state):
				mission.status = Mission.MissionStatus.AVAILABLE
				mission_available.emit(mission_id)
