# OllamaManifestoProcessor.gd
# Procesador de manifiestos usando Ollama (modelo local)
extends Node
class_name OllamaManifestoProcessor

signal manifesto_analyzed(analysis_result: Dictionary)
signal analysis_error(error_message: String)

# Configuración
const OLLAMA_URL = "http://localhost:11434"
const DEFAULT_MODEL = "phi3:mini"  # Modelo ligero recomendado
const TIMEOUT_SECONDS = 10.0

var http_request: HTTPRequest
var model_name: String = DEFAULT_MODEL
var is_available: bool = false
var processing: bool = false

func _ready():
	print("🤖 OllamaManifestoProcessor iniciado")
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# Verificar disponibilidad de Ollama
	_check_ollama_availability()

func _check_ollama_availability():
	"""Verifica si Ollama está disponible"""
	var test_request = HTTPRequest.new()
	add_child(test_request)
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"name": model_name})
	var error = test_request.request(OLLAMA_URL + "/api/show", headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		print("⚠️ Ollama no disponible (error HTTP: " + str(error) + ")")
		is_available = false
		return
	
	# Esperar respuesta (timeout de 2 segundos)
	await get_tree().create_timer(2.0).timeout
	
	if test_request.get_http_client_status() == HTTPClient.STATUS_CONNECTED:
		is_available = true
		print("✅ Ollama disponible en " + OLLAMA_URL)
	else:
		is_available = false
		print("⚠️ Ollama no responde, usando modo simulado")
	
	test_request.queue_free()

func analyze_manifesto(manifesto_text: String, player_context: Dictionary = {}) -> Dictionary:
	"""Analiza un manifiesto usando Ollama"""
	if processing:
		analysis_error.emit("Ya se está procesando un manifiesto")
		return {}
	
	if not is_available:
		print("⚠️ Ollama no disponible, usando análisis simulado")
		return _simulate_analysis(manifesto_text, player_context)
	
	processing = true
	print("📊 Analizando manifiesto con Ollama (modelo: " + model_name + ")...")
	
	# Construir prompt para el modelo
	var prompt = _build_analysis_prompt(manifesto_text, player_context)
	
	# Preparar request a Ollama
	var request_data = {
		"model": model_name,
		"prompt": prompt,
		"stream": false,
		"options": {
			"temperature": 0.7,
			"top_p": 0.9,
			"max_tokens": 1000
		}
	}
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(request_data)
	
	var error = http_request.request(OLLAMA_URL + "/api/generate", headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		processing = false
		analysis_error.emit("Error al enviar request a Ollama: " + str(error))
		return _simulate_analysis(manifesto_text, player_context)
	
	# Esperar respuesta (con timeout)
	var timeout_timer = get_tree().create_timer(TIMEOUT_SECONDS)
	timeout_timer.timeout.connect(func():
		if processing:
			processing = false
			analysis_error.emit("Timeout esperando respuesta de Ollama")
	)
	
	# Retornar análisis simulado mientras esperamos (para no bloquear)
	# En producción, esto debería ser await
	return _simulate_analysis(manifesto_text, player_context)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Procesa respuesta de Ollama"""
	processing = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		analysis_error.emit("Error en conexión con Ollama: " + str(result))
		return
	
	if response_code != 200:
		analysis_error.emit("Ollama retornó código: " + str(response_code))
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(response_text)
	
	if parse_error != OK:
		analysis_error.emit("Error parseando respuesta de Ollama")
		return
	
	var response_data = json.get_data()
	var ai_response = response_data.get("response", "")
	
	# Parsear respuesta de IA a nuestro formato
	var analysis = _parse_ai_response(ai_response)
	manifesto_analyzed.emit(analysis)

func _build_analysis_prompt(manifesto_text: String, context: Dictionary) -> String:
	"""Construye el prompt para el modelo de IA"""
	var prompt = """Eres un analista político experimentado. Analiza el siguiente manifiesto revolucionario y responde SOLO con un JSON válido.

CONTEXTO DEL JUGADOR:
- Región: {region}
- Reputación: {reputation}

MANIFIESTO:
{manifesto}

INSTRUCCIONES:
Analiza el manifiesto y responde con un JSON que contenga:
{{
  "emotional_tone": "ira|esperanza|miedo|determinacion",
  "primary_themes": ["anti_cartographer", "ecology", "revolution", "justice"],
  "rhetorical_quality": 0-10,
  "persuasion_power": 0-10,
  "risk_of_repression": "low|medium|high|extreme",
  "target_audience": ["workers", "intellectuals", "youth", "elders"],
  "potential_virality": 0-10,
  "summary": "2-3 frases de análisis narrativo",
  "strengths": ["lista de fortalezas"],
  "weaknesses": ["lista de debilidades"]
}}

Responde SOLO con el JSON, sin texto adicional."""

	return prompt.format({
		"region": context.get("region", "unknown"),
		"reputation": str(context.get("reputation", {})),
		"manifesto": manifesto_text
	})

func _parse_ai_response(ai_response: String) -> Dictionary:
	"""Parsea la respuesta de la IA a nuestro formato"""
	# Intentar extraer JSON de la respuesta
	var json_start = ai_response.find("{")
	var json_end = ai_response.rfind("}")
	
	if json_start == -1 or json_end == -1:
		print("⚠️ No se encontró JSON en respuesta de IA")
		return {}
	
	var json_text = ai_response.substr(json_start, json_end - json_start + 1)
	var json = JSON.new()
	var parse_error = json.parse(json_text)
	
	if parse_error != OK:
		print("⚠️ Error parseando JSON de IA: " + str(parse_error))
		return {}
	
	var ai_data = json.get_data()
	
	# Convertir a nuestro formato estándar
	return {
		"success": true,
		"manifesto_id": "ollama_" + str(Time.get_unix_time_from_system()),
		"analysis": {
			"emotional_tone": ai_data.get("emotional_tone", "neutral"),
			"primary_themes": ai_data.get("primary_themes", []),
			"rhetorical_quality": ai_data.get("rhetorical_quality", 5),
			"persuasion_power": ai_data.get("persuasion_power", 5),
			"risk_of_repression": ai_data.get("risk_of_repression", "medium"),
			"target_audience": ai_data.get("target_audience", []),
			"potential_virality": ai_data.get("potential_virality", 5),
			"summary": ai_data.get("summary", ""),
			"strengths": ai_data.get("strengths", []),
			"weaknesses": ai_data.get("weaknesses", []),
			"ai_model_used": model_name
		}
	}

func _simulate_analysis(text: String, context: Dictionary) -> Dictionary:
	"""Análisis simulado cuando Ollama no está disponible"""
	var word_count = text.split(" ").size()
	var detected_topics = []
	
	if text.to_lower().find("cartógrafo") != -1:
		detected_topics.append("anti_cartographer")
	if text.to_lower().find("revolución") != -1:
		detected_topics.append("revolution")
	if text.to_lower().find("ecolog") != -1:
		detected_topics.append("ecology")
	if text.to_lower().find("justicia") != -1:
		detected_topics.append("justice")
	
	var sentiment_score = randf() * 2.0 - 1.0
	var rhetorical_quality = min(10, word_count / 20.0 + randf() * 3.0)
	var persuasion_power = min(10, (sentiment_score + 1) * 5 + randf() * 2.0)
	
	return {
		"success": true,
		"manifesto_id": "simulated_" + str(Time.get_unix_time_from_system()),
		"analysis": {
			"emotional_tone": "determinacion" if sentiment_score > 0 else "ira",
			"primary_themes": detected_topics,
			"rhetorical_quality": rhetorical_quality,
			"persuasion_power": persuasion_power,
			"risk_of_repression": "high" if detected_topics.has("anti_cartographer") else "medium",
			"target_audience": ["workers", "youth"] if detected_topics.has("revolution") else ["general_public"],
			"potential_virality": min(10, persuasion_power + randf() * 2.0),
			"summary": "Manifiesto analizado (modo simulado)",
			"strengths": ["Tono apasionado", "Claridad de mensaje"],
			"weaknesses": ["Falta de propuestas concretas"],
			"ai_model_used": "simulated_fallback"
		}
	}
















