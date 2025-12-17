extends Node

signal sanity_updated(value: int)
signal needs_updated(needs: Dictionary)
signal connection_status_changed(connected: bool)

const SERVER_URL = "http://localhost:8080"

var http_request: HTTPRequest

func _ready():
	print("Ã°Å¸Å½Â® GameClient iniciado")
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# No conectar automÃƒÂ¡ticamente - dejar que main_test lo controle
	print("Ã¢Å“â€¦ GameClient listo, esperando llamada a connect_to_server()")

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

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
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
