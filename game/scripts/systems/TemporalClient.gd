extends Node
class_name TemporalClient

const SERVER_URL = "http://localhost:8081"

signal connection_established(status)
signal biomes_loaded(biomes)
signal simulation_completed(result)
signal error_occurred(error_message)

var is_connected := false

func _ready():
	# Probar conexión automáticamente al inicio
	test_connection()

func test_connection() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_test_completed.bind(http_request))
	
	var error = http_request.request(SERVER_URL + "/status")
	if error != OK:
		emit_signal("error_occurred", "Failed to create request")

func get_biomes() -> void:
	if not is_connected:
		emit_signal("error_occurred", "Not connected to server")
		return
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_biomes_received.bind(http_request))
	
	var error = http_request.request(SERVER_URL + "/biomes")
	if error != OK:
		emit_signal("error_occurred", "Failed to request biomes")

func simulate_decision(biome_id: String, action: String, magnitude: float = 0.5, years: int = 3) -> void:
	if not is_connected:
		emit_signal("error_occurred", "Not connected to server")
		return
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_simulation_completed.bind(http_request))
	
	var data = {
		"reality_id": "alpha",
		"biome_id": biome_id,
		"action": action,
		"magnitude": magnitude,
		"years": years
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(SERVER_URL + "/simulate", headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		emit_signal("error_occurred", "Failed to send simulation request")

func _on_test_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.get_data()
			is_connected = true
			emit_signal("connection_established", data)
			print("✅ Connected to Temporal Server v2")
			print("   Version: ", data.get("version", "unknown"))
			print("   Year: ", data.get("current_year", 2025))
			print("   Biomes: ", data.get("total_biomes", 0))
		else:
			emit_signal("error_occurred", "Failed to parse server response")
	else:
		emit_signal("error_occurred", "Cannot connect to server")
	
	http_request.queue_free()

func _on_biomes_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var biomes = json.get_data()
			emit_signal("biomes_loaded", biomes)
			print("✅ Loaded ", biomes.size(), " biomes")
		else:
			emit_signal("error_occurred", "Failed to parse biomes")
	else:
		emit_signal("error_occurred", "Failed to get biomes: " + str(response_code))
	
	http_request.queue_free()

func _on_simulation_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var simulation_result = json.get_data()
			emit_signal("simulation_completed", simulation_result)
			
			print("✅ Simulation completed!")
			print("   Message: ", simulation_result.get("message", ""))
			print("   New year: ", simulation_result.get("final_year", ""))
			print("   Effects: ", simulation_result.get("effects", []))
			
			# Mostrar estado del bioma
			var biome_state = simulation_result.get("biome_state", {})
			if not biome_state.is_empty():
				print("   Biodiversity: ", biome_state.get("biodiversity", 0))
				print("   Temperature: ", biome_state.get("temperature", 0))
		else:
			emit_signal("error_occurred", "Failed to parse simulation result")
	else:
		emit_signal("error_occurred", "Simulation failed: " + str(response_code))
	
	http_request.queue_free()
