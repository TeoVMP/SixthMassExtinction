extends Node

# ============================================
# SEÑALES
# ============================================

signal sanity_updated(value: int)
signal needs_updated(needs: Dictionary)
signal reputation_updated(region: String, value: int)
signal violence_level_updated(value: int)
signal cartograph_power_updated(value: int)
signal connection_status_changed(connected: bool)
signal mission_received(mission_data: Dictionary)
signal mission_completed(mission_id: String, result: Dictionary)
signal mission_failed(mission_id: String, reason: String)
signal save_game_completed(success: bool, slot: int)
signal load_game_completed(success: bool, slot: int)
signal manifesto_submitted(success: bool, manifesto_id: String)

# ============================================
# MÉTODOS DE CONEXIÓN
# ============================================

func connect_to_server():
	print("🔄 Conectando al servidor (mock)...")
	await get_tree().create_timer(2.0).timeout
	connection_status_changed.emit(true)
	return {"status": "connected"}

func disconnect_from_server():
	print("🔌 Desconectando del servidor (mock)...")
	connection_status_changed.emit(false)
	return {"status": "disconnected"}

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

# ============================================
# AUTENTICACIÓN Y USUARIO
# ============================================

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

func register_user(user_data: Dictionary):
	print("📝 Registrando nuevo usuario:", user_data)
	await get_tree().create_timer(1.5).timeout
	return {
		"success": true,
		"message": "Usuario registrado exitosamente",
		"user_id": "new_user_" + str(randi() % 1000)
	}

# ============================================
# ESTADO DEL JUGADOR
# ============================================

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
		"created_at": "2024-01-15",
		"play_time": "45h",
		"level": 5,
		"experience": 1250,
		"currency": 5000,
		"inventory": [
			{"id": "manifiesto", "name": "Manifiesto Base", "count": 1},
			{"id": "agua", "name": "Agua Potable", "count": 3},
			{"id": "comida_ration", "name": "Ración de Comida", "count": 5}
		],
		"completed_missions": ["m_tutorial", "m_intro"],
		"active_mission": ""
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

# ============================================
# MISIONES
# ============================================

# En el source_code del mock, cambia get_available_missions a NO async:
func get_available_missions():
	print("🎯 Obteniendo misiones disponibles...")
	# DEVUELVE DIRECTAMENTE SIN AWAIT
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
		"objectives": [
			"Hablar con el líder local",
			"Recolectar evidencia",
			"Organizar protesta pacífica"
		],
		"choices": [
			{
				"id": "approach",
				"text": "Enfoque de la misión",
				"options": ["Diplomático", "Confrontativo", "Subversivo"]
			}
		],
		"time_limit": 1800,  # 30 minutos en segundos
		"start_time": Time.get_unix_time_from_system()
	}
	mission_received.emit(mission_data)
	return {"success": true, "mission": mission_data}

func complete_mission(mission_id: String, choices: Dictionary):
	print("✅ Completando misión: " + mission_id + " con elecciones: " + str(choices))
	await get_tree().create_timer(1.0).timeout
	var result = {
		"success": true,
		"message": "¡Misión completada con éxito!",
		"rewards": {
			"currency": 1000 + randi() % 500,
			"items": ["manifiesto_avanzado", "medalla_activista"],
			"reputation": {"pe": 5, "eo": 3}
		},
		"choices_made": choices,
		"completion_time": Time.get_unix_time_from_system()
	}
	mission_completed.emit(mission_id, result)
	return result

# ============================================
# MANIFIESTO
# ============================================

func submit_manifesto(text: String, is_public: bool, tags: Array):
	print("📜 Enviando manifiesto: " + text.substr(0, 50) + "...")
	await get_tree().create_timer(1.0).timeout
	var manifesto_id = "manifesto_" + str(Time.get_unix_time_from_system())
	manifesto_submitted.emit(true, manifesto_id)
	return {
		"success": true,
		"manifesto_id": manifesto_id,
		"message": "Manifiesto publicado exitosamente",
		"impact": {"sanity": +5, "reputation": {"pe": 3}},
		"public": is_public,
		"tags": tags
	}

# ============================================
# GUARDADO Y CARGA
# ============================================

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

func get_save_slots():
	print("📁 Obteniendo slots de guardado...")
	return [
		{"slot": 0, "exists": true, "timestamp": "2024-01-20 14:30:00", "play_time": "2h"},
		{"slot": 1, "exists": false, "timestamp": "", "play_time": ""},
		{"slot": 2, "exists": true, "timestamp": "2024-01-19 10:15:00", "play_time": "1.5h"}
	]

# ============================================
# ESTADO MUNDIAL
# ============================================

func get_world_state():
	print("🌍 Obteniendo estado mundial...")
	return {
		"violence_level": 45,
		"cartograph_power": 65,
		"temperature_rise": 2.3,  # °C
		"biodiversity_index": 68,  # %
		"regions_status": {
			"pe": "unrest",
			"eo": "stable", 
			"eu": "prosperous",
			"ch": "industrial",
			"ru": "authoritarian",
			"as": "developing",
			"au": "struggling",
			"la": "revolutionary"
		},
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

# ============================================
# REPUTACIÓN
# ============================================

func update_reputation(region: String, amount: int, reason: String):
	print("⭐ Actualizando reputación en " + region + ": " + str(amount) + " (" + reason + ")")
	await get_tree().create_timer(0.3).timeout
	reputation_updated.emit(region, amount)
	return {"region": region, "new_value": amount, "reason": reason}

# ============================================
# UTILIDADES
# ============================================

func get_server_time():
	return Time.get_unix_time_from_system()

func get_game_version():
	return {"version": "1.0.0-mock", "build": "2024.01.20.001"}

func ping_server():
	await get_tree().create_timer(0.1).timeout
	return {"ping": "25ms", "status": "online"}
