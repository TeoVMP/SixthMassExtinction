# game/scripts/systems/TemporalClient.gd - ACTUALIZADO
extends Node
class_name TemporalClient

const SERVER_URL = "http://localhost:8080"

signal biomes_loaded(biomes)
signal world_updated(world)
signal simulation_completed(result)

func get_biomes() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_on_biomes_received")
	http_request.request(SERVER_URL + "/biomes")

func get_world() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_on_world_received")
	http_request.request(SERVER_URL + "/world")

func simulate_biome_decision(biome_id: String, action: String, magnitude: float) -> void:
	# TO-DO: Implementar endpoint de simulación
	print("Simulating ", action, " on biome ", biome_id)

func _on_biomes_received(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK:
			emit_signal("biomes_loaded", json.result)
			print("Loaded ", json.result.size(), " biomes")

func _on_world_received(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK:
			emit_signal("world_updated", json.result)