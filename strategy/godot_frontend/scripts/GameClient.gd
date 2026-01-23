extends Node

signal sanity_updated(value: int)
signal needs_updated(needs: Dictionary)
signal connection_status_changed(connected: bool)
signal manifesto_analyzed(analysis: Dictionary)
signal reputation_updated(region: String, value: int)

const SERVER_URL = "http://localhost:8080"

var http_request: HTTPRequest
var ai_processor: Node
var impact_system: Node  # ManifestoImpactSystem
var player_id: String = "player_test"
var current_region: String = "pe"
var player_name: String = "Alexei Volkov"  # Nombre del jugador

func _ready():
	print("Ã°Å¸Å½Â® GameClient iniciado")
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# No conectar automÃƒÂ¡ticamente - dejar que main_test lo controle
	print("Ã¢Å“â€¦ GameClient listo, esperando llamada a connect_to_server()")
	ai_processor = AIManifestoProcessor.new()
	ai_processor.name = "AIManifestoProcessor"
	add_child(ai_processor)
	ai_processor.manifesto_analyzed.connect(_on_manifesto_analyzed)
	
	print("🤖 Procesador de IA inicializado")
	_init_ai_processor()
	_init_impact_system()

func _init_ai_processor():
	"""Inicializa el procesador de IA"""
	# Intentar cargar desde diferentes rutas posibles
	var possible_paths = [
		"res://scripts/AIManifestoProcesssor.gd",  # Ruta actual (con doble 's')
		"res://scripts/AIManifestoProcessor.gd",     # Ruta alternativa
		"res://scripts/systems/AIManifestoProcessor.gd"
	]
	
	for path in possible_paths:
		if ResourceLoader.exists(path):
			var ProcessorClass = load(path)
			if ProcessorClass:
				# Remover el procesador anterior si existe
				if ai_processor and is_instance_valid(ai_processor):
					ai_processor.queue_free()
				
				ai_processor = ProcessorClass.new()
				ai_processor.name = "AIManifestoProcessor"
				add_child(ai_processor)
				
				# Conectar señales si existen
				if ai_processor.has_signal("manifesto_analyzed"):
					ai_processor.manifesto_analyzed.connect(_on_manifesto_analyzed)
				
				print("🤖 Procesador de IA inicializado desde: " + path)
				return
	
	# Si no se encontró, usar el que ya se creó en _ready() o crear uno básico
	if not ai_processor or not is_instance_valid(ai_processor):
		print("⚠️ AIManifestoProcessor.gd no encontrado, usando instancia básica")
		ai_processor = AIManifestoProcessor.new()
		ai_processor.name = "AIManifestoProcessor"
		add_child(ai_processor)
		if ai_processor.has_signal("manifesto_analyzed"):
			ai_processor.manifesto_analyzed.connect(_on_manifesto_analyzed)
		
func _init_impact_system():
	"""Inicializa el sistema de efectos de manifiestos"""
	if ResourceLoader.exists("res://scripts/systems/ManifestoImpactSystem.gd"):
		var ImpactSystemClass = load("res://scripts/systems/ManifestoImpactSystem.gd")
		impact_system = ImpactSystemClass.new()
		impact_system.name = "ManifestoImpactSystem"
		add_child(impact_system)
		impact_system.set_game_client(self)
		print("🎯 Sistema de efectos de manifiestos inicializado")
	else:
		print("⚠️ ManifestoImpactSystem.gd no encontrado")

# Añade estas funciones NUEVAS:
func get_player_reputation() -> Dictionary:
	"""Obtiene reputación del jugador"""
	return player_reputation.duplicate()

func set_player_name(name: String):
	"""Establece el nombre del jugador"""
	player_name = name
	print("👤 Nombre del jugador establecido: ", player_name)

func get_player_name() -> String:
	"""Obtiene el nombre del jugador"""
	return player_name

func _send_to_backend(_text: String, _is_public: bool, _tags: Array, _analysis: Dictionary):
	"""Envía al backend (mock)"""
	print("📡 Enviando manifiesto al backend...")
	await get_tree().create_timer(0.5).timeout
	print("✅ Manifiesto enviado al backend")

# Modifica submit_manifesto:
func submit_manifesto(text: String, is_public: bool, tags: Array):
	"""Envía manifiesto para análisis por IA"""
	print("📜 Enviando manifiesto a IA...")
	
	if not ai_processor:
		print("❌ IA no disponible, usando análisis básico")
		return {
			"success": true,
			"analysis": {"basic": "No IA available"},
			"message": "Manifiesto enviado (sin IA)"
		}
	
	# Contexto del jugador
	var player_context = {
		"player_id": player_id,
		"region": current_region,
		"reputation": get_player_reputation()
	}
	
	# Análisis de IA
	print("🔍 [GameClient] Llamando a analyze_manifesto...")
	print("   ai_processor existe: ", ai_processor != null)
	if ai_processor:
		print("   ai_processor tiene método: ", ai_processor.has_method("analyze_manifesto"))
	
	var analysis = await ai_processor.analyze_manifesto(text, player_context)
	
	print("📊 [GameClient] Resultado del análisis recibido")
	print("   Tipo: ", typeof(analysis))
	print("   Es null: ", analysis == null)
	print("   Es diccionario: ", analysis is Dictionary)
	if analysis is Dictionary:
		print("   Keys: ", analysis.keys())
		print("   Tiene 'analysis': ", analysis.has("analysis"))
		print("   Contenido: ", analysis)
	
	# Verificar si el análisis es válido
	if analysis == null:
		print("❌ [GameClient] Análisis es null, creando fallback")
		analysis = {}
	elif not (analysis is Dictionary):
		print("❌ [GameClient] Análisis no es diccionario, es: ", typeof(analysis))
		analysis = {}
	elif analysis.is_empty():
		print("⚠️ [GameClient] Análisis es diccionario vacío")
		print("⚠️ Análisis vacío o inválido, usando análisis simulado")
		# Crear análisis simulado como fallback
		analysis = {
			"success": true,
			"manifesto_id": "fallback_" + str(Time.get_unix_time_from_system()),
			"analysis": {
				"emotional_tone": "determinacion",
				"primary_themes": ["revolution", "ecology"],
				"rhetorical_quality": 6.0,
				"persuasion_power": 7.0,
				"risk_of_repression": "medium",
				"target_audience": ["workers", "youth"],
				"potential_virality": 6.0,
				"summary": "Análisis simulado (Ollama no disponible)",
				"strengths": ["Tono apasionado"],
				"weaknesses": ["Análisis básico"],
				"ai_model_used": "simulated_fallback"
			}
		}
	
	# Verificar que tenga la estructura correcta
	if not analysis.has("analysis"):
		print("⚠️ Análisis sin estructura 'analysis', creando estructura...")
		var ai_data = analysis.get("analysis", {})
		if ai_data.is_empty():
			# Si no hay datos de análisis, crear estructura mínima
			analysis["analysis"] = {
				"emotional_tone": "neutral",
				"primary_themes": [],
				"rhetorical_quality": 5.0,
				"persuasion_power": 5.0,
				"risk_of_repression": "medium",
				"target_audience": [],
				"potential_virality": 5.0,
				"summary": "Análisis básico",
				"ai_model_used": "fallback"
			}
	
	# Aplicar efectos de gameplay
	if impact_system and impact_system.has_method("apply_manifesto_effects"):
		print("🎯 Aplicando efectos de gameplay...")
		var effects = impact_system.apply_manifesto_effects(analysis, text)
		analysis["game_effects"] = effects
		print("✅ Efectos aplicados: ", effects)
	
	# Enviar al backend
	_send_to_backend(text, is_public, tags, analysis)
	
	return {
		"success": true,
		"analysis": analysis,
		"message": "Manifiesto analizado por IA"
	}

func _on_manifesto_analyzed(analysis: Dictionary):
	"""Recibe análisis de IA"""
	print("🤖 Análisis de IA recibido")
	# Emitir señal si existe
	if has_signal("manifesto_analyzed"):
		manifesto_analyzed.emit(analysis)	

# func _on_manifesto_analyzed(analysis: Dictionary):
	# """Recibe análisis de IA"""
	# print("🤖 Análisis de IA recibido:")
	# print("   Calidad:", analysis.get("analysis", {}).get("overall_quality", 0))
	# print("   Sentimiento:", analysis.get("analysis", {}).get("sentiment", "unknown"))
	
	# Emitir señal para UI
	# manifesto_analyzed.emit(analysis)
func connect_to_server():
	print("Ã°Å¸â€â€” [GameClient] Conectando a:", SERVER_URL)
	
	var request_data = {
		"jsonrpc": "2.0",
		"method": "ping",
		"params": {},
		"id": 1
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	print("Ã°Å¸â€œÂ¤ [GameClient] Enviando request RPC...")
	var error = http_request.request(SERVER_URL + "/rpc", headers, HTTPClient.METHOD_POST, body)
	
	if error == OK:
		print("Ã¢Å“â€¦ [GameClient] Request HTTP enviado correctamente")
	else:
		print("Ã¢ÂÅ’ [GameClient] Error enviando request:", error)
		# Emitir seÃƒÂ±al de error inmediatamente
		connection_status_changed.emit(false)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	print("Ã°Å¸â€œÂ¨ [GameClient] Request HTTP completado")
	print("   Result code:", result, "(0=OK)")
	print("   HTTP Status:", response_code)
	print("   Body size:", body.size(), "bytes")
	
	if result != 0:
		print("Ã¢ÂÅ’ [GameClient] Error en conexiÃƒÂ³n HTTP")
		connection_status_changed.emit(false)
		return
	
	if body.size() == 0:
		print("Ã¢ÂÅ’ [GameClient] Body vacÃƒÂ­o - backend no respondiÃƒÂ³")
		connection_status_changed.emit(false)
		return
	
	var response_text = body.get_string_from_utf8()
	print("   Response text:", response_text)
	
	# Intentar parsear JSON
	var json = JSON.new()
	var parse_error = json.parse(response_text)
	
	if parse_error != OK:
		print("Ã¢ÂÅ’ [GameClient] Error parseando JSON:", parse_error)
		print("   JSON data:", response_text)
		connection_status_changed.emit(false)
		return
	
	var response = json.get_data()
	print("Ã¢Å“â€¦ [GameClient] JSON parseado correctamente")
	print("   Response keys:", response.keys())
	
	# Verificar estructura RPC
	if response.has("result"):
		print("Ã°Å¸Å½â€° [GameClient] Ã‚Â¡RPC exitoso! Resultado:", response.result)
		connection_status_changed.emit(true)
		
		# Si es game_state, procesarlo
		if response.has("id") and response.id == 2:  # game_state request
			_process_game_state(response.result)
	else:
		print("Ã¢ÂÅ’ [GameClient] Respuesta sin 'result'")
		connection_status_changed.emit(false)

func request_game_state():
	print("Ã°Å¸â€œÅ  [GameClient] Solicitando estado del juego...")
	
	var request_data = {
		"jsonrpc": "2.0",
		"method": "game_state",
		"params": {},
		"id": 2
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	http_request.request(SERVER_URL + "/rpc", headers, HTTPClient.METHOD_POST, body)

func _process_game_state(game_state):
	if game_state and game_state.has("player"):
		print("Ã°Å¸â€˜Â¤ [GameClient] Procesando estado del jugador...")
		
		if game_state.player.has("sanity"):
			var sanity = game_state.player.sanity
			print("   Cordura:", sanity)
			sanity_updated.emit(sanity)
		
		if game_state.player.has("needs"):
			var needs = game_state.player.needs
			print("   Necesidades:", needs)
			needs_updated.emit(needs)

func modify_sanity(amount: int, reason: String = ""):
	"""Modifica la cordura del jugador"""
	print("🧠 Modificando cordura: " + str(amount) + " (razón: " + reason + ")")
	# Enviar al backend
	var request_data = {
		"jsonrpc": "2.0",
		"method": "modify_sanity",
		"params": {
			"amount": amount,
			"reason": reason
		},
		"id": 100
	}
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	http_request.request(SERVER_URL + "/rpc", headers, HTTPClient.METHOD_POST, body)

var player_reputation: Dictionary = {
	"africa_norte": 0, "africa_oriental": 0, "africa_occidental": 0, "sudafrica": 0,
	"sa": 0, "ca": 0, "eo": 0, "eu": 0, "ch": 0, "ru": 0, "as": 0, "seasia": 0, "mena": 0, "oceania": 0
}

func modify_reputation(region: String, amount: int):
	"""Modifica la reputación en una región"""
	if not player_reputation.has(region):
		player_reputation[region] = 0
	player_reputation[region] += amount
	print("⭐ Modificando reputación " + region + ": " + str(amount) + " (Total: " + str(player_reputation[region]) + ")")
	reputation_updated.emit(region, player_reputation[region])
	# TODO: Implementar llamada RPC al backend

func satisfy_need(need_type: String, amount: int, item: String = ""):
	"""Satisface una necesidad del jugador"""
	print("🍎 Satisfaciendo necesidad " + need_type + ": +" + str(amount))
	# Enviar al backend
	var request_data = {
		"jsonrpc": "2.0",
		"method": "satisfy_need",
		"params": {
			"need_type": need_type,
			"amount": amount,
			"item": item
		},
		"id": 101
	}
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	http_request.request(SERVER_URL + "/rpc", headers, HTTPClient.METHOD_POST, body)
