extends Control

@onready var game_client
@onready var ui_main

func _ready():
	print("🧪 main_test iniciado")
	
	# Asegurar que este Control ocupe toda la pantalla
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Crear GameClient (simulado para pruebas)
	_create_mock_game_client()
	
	# Cargar UI_Main
	var ui_scene = load("res://scenes/UI_Main.tscn")
	ui_main = ui_scene.instantiate()
	add_child(ui_main)
	
	# Asegurar que UI_Main ocupe toda la pantalla
	ui_main.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	print("✅ UI_Main cargada")
	
	# Pasar referencia del GameClient a la UI
	ui_main.set_game_client(game_client)
	
	print("✅ Todo inicializado correctamente")
	
	# Prueba: Simular actualización después de 1 segundo
	await get_tree().create_timer(1.0).timeout
	_simulate_game_client_updates()

func _create_mock_game_client():
	"""Crea un GameClient simulado para pruebas"""
	# Crea un script dinámico para el mock
	var mock_script = GDScript.new()
	
	mock_script.source_code = """
extends Node

signal sanity_updated(value: int)
signal needs_updated(needs: Dictionary)
signal connection_status_changed(connected: bool)
signal mission_received(mission_data: Dictionary)
signal mission_completed(mission_id: String, result: Dictionary)
signal mission_failed(mission_id: String, reason: String)
signal save_game_completed(success: bool, slot: int)
signal load_game_completed(success: bool, slot: int)
signal reputation_updated(region: String, value: int)
signal violence_level_updated(value: int)
signal cartograph_power_updated(value: int)
signal manifesto_submitted(success: bool, manifesto_id: String)

# ==================== CONEXIÓN ====================
func connect_to_server():
	print("🔄 Conectando al servidor (simulado)...")
	await get_tree().create_timer(2.0).timeout
	connection_status_changed.emit(true)
	return {"status": "connected"}

func test_connection():
	print("🔍 Test conexión directa al backend...")
	await get_tree().create_timer(1.0).timeout
	return {
		"status": "connected", 
		"server": "mock_backend:8000",
		"ping": "25ms",
		"version": "1.0.0"
	}

func test_connection_direct():
	print("🔍 Probando conexión (simulado)...")
	await get_tree().create_timer(0.5).timeout
	return {"direct_test": "passed"}

# ==================== AUTENTICACIÓN ====================
func authenticate(auth_data: Dictionary):
	print("🔐 Autenticando con:", auth_data)
	await get_tree().create_timer(1.0).timeout
	return {
		"success": true,
		"token": "mock_jwt_token_" + str(randi() % 10000),
		"user_id": auth_data.get("username", "test_user"),
		"expires_in": 3600,
		"player_id": "player_" + str(randi() % 1000)
	}

# ==================== ESTADO JUGADOR ====================
func get_player_state():
	print("📊 Obteniendo estado del jugador...")
	return {
		"sanity": 85,
		"needs": {"hunger": 50, "thirst": 50, "sleep": 70, "stress": 30},
		"reputation": {
			"pe": 10, "eo": -5, "eu": 0, "ch": 3, 
			"ru": -2, "as": 7, "au": 15, "la": 8
		},
		"level": 5,
		"experience": 1250,
		"currency": 5000
	}

func get_player():
	print("👤 Obteniendo datos completos del jugador...")
	await get_tree().create_timer(0.5).timeout
	return {
		"id": "player_001",
		"username": "revolucionario_ecologico",
		"level": 5,
		"experience": 1250,
		"currency": 5000,
		"inventory": ["manifiesto", "agua", "comida_ration"]
	}

func modify_sanity(amount: int, source: String):
	print("🧠 Modificando cordura: " + str(amount) + " (fuente: " + source + ")")
	await get_tree().create_timer(0.5).timeout
	var current_state = get_player_state()
	var new_sanity = clamp(current_state.sanity + amount, 0, 100)
	sanity_updated.emit(new_sanity)
	return {"new_sanity": new_sanity}

func satisfy_need(need_type: String, amount: int, source: String):
	print("🔄 Satisfaciendo necesidad: " + need_type + " +" + str(amount))
	await get_tree().create_timer(0.5).timeout
	var needs = {"hunger": 50, "thirst": 50, "sleep": 70, "stress": 30}
	if need_type in needs:
		needs[need_type] = max(0, needs[need_type] - amount)
	needs_updated.emit(needs)
	return {"updated_needs": needs}

# ==================== MISIONES ====================
func get_available_missions():
	print("🎯 Obteniendo misiones disponibles...")
	# QUITAR EL AWAIT - hacerlo síncrono
	return [
		{
			"id": "m1_islandia", 
			"title": "Revolución Islandesa", 
			"description": "Ayuda a los activistas islandeses a protestar contra las fábricas de Cartógrafos.",
			"difficulty": "medium",
			"estimated_time": "30m",
			"rewards": {"currency": 1000, "reputation": {"eo": 10}}
		},
		{
			"id": "m2_amazonas", 
			"title": "Defensa del Amazonas", 
			"description": "Protege la selva amazónica de la deforestación industrial.",
			"difficulty": "hard",
			"estimated_time": "45m",
			"rewards": {"currency": 1500, "reputation": {"la": 15, "pe": 20}}
		},
		{
			"id": "m3_sahara", 
			"title": "Desierto Verde", 
			"description": "Participa en el proyecto de reforestación del Sahara.",
			"difficulty": "easy",
			"estimated_time": "20m",
			"rewards": {"currency": 500, "reputation": {"au": 10}}
		}
	]

func get_missions_state():
	print("📋 Obteniendo estado de misiones...")
	return {
		"active": "",
		"available": ["m1_islandia", "m2_amazonas", "m3_sahara"],
		"completed": ["m_tutorial", "m_intro"],
		"failed": []
	}

func start_mission(mission_id: String):
	print("🚀 Iniciando misión: " + mission_id)
	await get_tree().create_timer(1.0).timeout
	var mission_data = {
		"id": mission_id,
		"title": "Misión: " + mission_id,
		"description": "Esta es una misión de prueba con múltiples objetivos.",
		"objectives": ["Objetivo 1", "Objetivo 2", "Objetivo 3"]
	}
	mission_received.emit(mission_data)
	return {"success": true, "mission": mission_data}

func complete_mission(mission_id: String, choices: Dictionary):
	print("✅ Completando misión: " + mission_id)
	await get_tree().create_timer(1.0).timeout
	var result = {
		"message": "¡Misión completada con éxito!",
		"rewards": {"currency": 100, "items": ["item1", "item2"]}
	}
	mission_completed.emit(mission_id, result)
	return result

# ==================== MANIFIESTO ====================
func submit_manifesto(text: String, is_public: bool, tags: Array):
	print("📜 [Mock] Enviando manifiesto: " + text.substr(0, 50) + "...")
	
	# Usar el GameClient real si está disponible (autoload)
	# En Godot, los autoloads están disponibles globalmente por nombre
	if has_node("/root/GameClient"):
		var real_game_client = get_node("/root/GameClient")
		if real_game_client and real_game_client.has_method("submit_manifesto"):
			print("📜 [Mock] Delegando al GameClient real para análisis completo...")
			var result = await real_game_client.submit_manifesto(text, is_public, tags)
			if result:
				manifesto_submitted.emit(result.get("success", false), result.get("manifesto_id", ""))
				return result
			else:
				print("⚠️ [Mock] GameClient real retornó null, usando fallback")
	
	# Fallback: análisis simulado mejorado basado en el texto
	print("📜 [Mock] Usando análisis simulado mejorado...")
	await get_tree().create_timer(1.0).timeout
	var manifesto_id = "manifesto_" + str(Time.get_unix_time_from_system())
	
	# Análisis básico del texto
	var lower_text = text.to_lower()
	var themes = []
	if lower_text.find("cartógrafo") != -1 or lower_text.find("cartografo") != -1 or lower_text.find("sabandija") != -1:
		themes.append("anti_cartographer")
	if lower_text.find("revolución") != -1 or lower_text.find("revolucion") != -1 or lower_text.find("compañero") != -1:
		themes.append("revolution")
	if lower_text.find("ecolog") != -1:
		themes.append("ecology")
	if lower_text.find("humanidad") != -1:
		themes.append("justice")
	
	var exclamation_count = text.count("!")
	var word_count = text.split(" ").size()
	var rhetorical_quality = min(10.0, 5.0 + themes.size() * 1.5 + exclamation_count * 0.5 + (word_count / 20.0))
	var persuasion_power = min(10.0, rhetorical_quality * 0.9)
	var emotional_tone = "determinacion" if exclamation_count >= 2 else "neutral"
	
	# Crear análisis mejorado
	var analysis = {
		"emotional_tone": emotional_tone,
		"primary_themes": themes if themes.size() > 0 else ["general"],
		"rhetorical_quality": rhetorical_quality,
		"persuasion_power": persuasion_power,
		"risk_of_repression": "high" if themes.has("anti_cartographer") else "medium",
		"target_audience": ["workers", "youth"] if themes.has("revolution") else ["general_public"],
		"potential_virality": min(10.0, persuasion_power + 1.0),
		"summary": "Manifiesto analizado (modo mock mejorado)",
		"strengths": ["Tono apasionado", "Múltiples temas"] if themes.size() >= 2 else ["Tono apasionado"],
		"weaknesses": ["Usa GameClient real para análisis completo"],
		"ai_model_used": "mock_simulated_v2"
	}
	
	manifesto_submitted.emit(true, manifesto_id)
	return {
		"success": true,
		"manifesto_id": manifesto_id,
		"analysis": analysis,
		"message": "Manifiesto publicado exitosamente"
	}

# ==================== GUARDADO ====================
func save_game(slot: int):
	print("💾 Guardando en slot: " + str(slot))
	await get_tree().create_timer(1.0).timeout
	save_game_completed.emit(true, slot)
	return {
		"success": true,
		"slot": slot,
		"timestamp": Time.get_unix_time_from_system(),
		"data_size": "15.2KB"
	}

func load_game(slot: int):
	print("📂 Cargando desde slot: " + str(slot))
	await get_tree().create_timer(1.0).timeout
	load_game_completed.emit(true, slot)
	return {
		"success": true,
		"slot": slot,
		"player_state": get_player_state(),
		"world_state": get_world_state(),
		"loaded_at": Time.get_unix_time_from_system()
	}

# ==================== ESTADO MUNDIAL ====================
func get_world_state():
	print("🌍 Obteniendo estado mundial...")
	return {
		"violence_level": 45,
		"cartograph_power": 65,
		"temperature_rise": 2.3,
		"biodiversity_index": 68,
		"last_updated": Time.get_unix_time_from_system()
	}

func update_world_state():
	print("🔄 Actualizando estado mundial...")
	await get_tree().create_timer(0.5).timeout
	var new_state = get_world_state()
	# Simular cambios aleatorios
	new_state.violence_level += randi() % 5 - 2
	new_state.cartograph_power += randi() % 3 - 1
	new_state.violence_level = clamp(new_state.violence_level, 0, 100)
	new_state.cartograph_power = clamp(new_state.cartograph_power, 0, 100)
	
	violence_level_updated.emit(new_state.violence_level)
	cartograph_power_updated.emit(new_state.cartograph_power)
	
	return new_state

# ==================== REPUTACIÓN ====================
func update_reputation(region: String, amount: int, reason: String):
	print("⭐ Actualizando reputación en " + region + ": " + str(amount) + " (" + reason + ")")
	await get_tree().create_timer(0.3).timeout
	reputation_updated.emit(region, amount)
	return {"region": region, "new_value": amount, "reason": reason}

# ==================== UTILIDADES ====================
func get_server_time():
	return Time.get_unix_time_from_system()

func get_game_version():
	return {"version": "1.0.0-mock", "build": "2024.01.20.001"}

func ping_server():
	await get_tree().create_timer(0.1).timeout
	return {"ping": "25ms", "status": "online"}

func disconnect_from_server():
	print("🔌 Desconectando del servidor (mock)...")
	connection_status_changed.emit(false)
	return {"status": "disconnected"}

func register_user(user_data: Dictionary):
	print("📝 Registrando nuevo usuario:", user_data)
	await get_tree().create_timer(1.5).timeout
	return {
		"success": true,
		"message": "Usuario registrado exitosamente",
		"user_id": "new_user_" + str(randi() % 1000)
	}

func get_save_slots():
	print("📁 Obteniendo slots de guardado...")
	return [
		{"slot": 0, "exists": true, "timestamp": "2024-01-20 14:30:00", "play_time": "2h"},
		{"slot": 1, "exists": false, "timestamp": "", "play_time": ""},
		{"slot": 2, "exists": true, "timestamp": "2024-01-19 10:15:00", "play_time": "1.5h"}
	]
"""
	
	# Compilar el script
	mock_script.reload()
	
	# Crear nodo con el script
	var mock_client = Node.new()
	mock_client.name = "GameClient"
	mock_client.set_script(mock_script)
	
	add_child(mock_client)
	game_client = mock_client
	print("✅ GameClient simulado creado (completo)")
func _simulate_game_client_updates():
	"""Simula actualizaciones del GameClient para pruebas"""
	if game_client:
		print("🧪 Simulando actualizaciones del GameClient...")
		
		# Simular actualización de cordura
		game_client.emit_signal("sanity_updated", 75)
		
		# Simular actualización de necesidades
		var needs = {"hunger": 45, "thirst": 60, "sleep": 65, "stress": 25}
		game_client.emit_signal("needs_updated", needs)
		
		# Simular conexión exitosa
		game_client.emit_signal("connection_status_changed", true)
		
		print("🧪 Simulación completada")
