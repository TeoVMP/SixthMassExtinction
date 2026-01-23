# HackingSystem.gd
# Sistema de hacking ético estilo CTF para misiones
extends Node
class_name HackingSystem

signal puzzle_completed(puzzle_id: String)
signal mission_hacked(mission_id: String)
signal connection_lost()
signal vulnerability_found(vuln_type: String, severity: int)

# Estado del sistema
var is_active: bool = false
var current_mission_id: String = ""
var current_puzzle: Dictionary = {}

# Dispositivos disponibles
var has_laptop: bool = true
var has_terminal_access: bool = true
var has_antennas: bool = true
var has_tor_access: bool = true
var has_quantum_decoder: bool = false  # Se desbloquea en Misión 0

# Estadísticas de hacking
var vulnerabilities_found: int = 0
var puzzles_completed: int = 0
var connections_established: int = 0
var honeypots_avoided: int = 0

# Tiempo límite (en segundos)
var time_limit: float = 0.0
var time_remaining: float = 0.0

func _ready():
	print("💻 HackingSystem iniciado")

func start_hacking_session(mission_id: String, puzzles: Array, time_limit_seconds: float = 0.0):
	"""Inicia una sesión de hacking"""
	is_active = true
	current_mission_id = mission_id
	time_limit = time_limit_seconds
	time_remaining = time_limit
	
	print("💻 Iniciando sesión de hacking para misión: ", mission_id)
	print("   Puzzles disponibles: ", puzzles.size())
	print("   Tiempo límite: ", time_limit_seconds, " segundos")

func stop_hacking_session():
	"""Detiene la sesión de hacking"""
	is_active = false
	current_mission_id = ""
	current_puzzle = {}
	time_remaining = 0.0

func attempt_puzzle(puzzle_id: String, solution: String) -> Dictionary:
	"""Intenta resolver un puzzle de hacking"""
	var result = {
		"success": false,
		"message": "",
		"hints": []
	}
	
	# Verificar si el puzzle existe
	if not current_puzzle.has(puzzle_id):
		result.message = "Puzzle no encontrado"
		return result
	
	var puzzle = current_puzzle[puzzle_id]
	
	# Verificar solución
	if solution.to_lower().strip_edges() == puzzle.correct_solution.to_lower().strip_edges():
		result.success = true
		result.message = puzzle.success_message
		puzzles_completed += 1
		puzzle_completed.emit(puzzle_id)
		
		# Desbloquear siguiente puzzle si existe
		if puzzle.has("unlocks"):
			for next_puzzle_id in puzzle.unlocks:
				if current_puzzle.has(next_puzzle_id):
					current_puzzle[next_puzzle_id].locked = false
	else:
		result.success = false
		result.message = puzzle.failure_message
		result.hints = puzzle.hints
	
	return result

func scan_for_vulnerabilities(target: String) -> Array:
	"""Escanea un objetivo en busca de vulnerabilidades"""
	var vulnerabilities = []
	
	# Simular escaneo (en implementación real, esto sería más complejo)
	await get_tree().create_timer(2.0).timeout
	
	# Vulnerabilidades comunes
	var common_vulns = [
		{"type": "SQL_INJECTION", "severity": 3, "description": "Posible inyección SQL en parámetros"},
		{"type": "XSS", "severity": 2, "description": "Cross-site scripting detectado"},
		{"type": "WEAK_ENCRYPTION", "severity": 4, "description": "Cifrado débil detectado"},
		{"type": "OPEN_PORT", "severity": 2, "description": "Puerto abierto: 443"},
		{"type": "CERTIFICATE_EXPIRED", "severity": 3, "description": "Certificado digital expirado"}
	]
	
	# Seleccionar vulnerabilidades aleatorias
	for i in range(randi() % 3 + 1):
		var vuln = common_vulns[randi() % common_vulns.size()]
		vulnerabilities.append(vuln)
		vulnerability_found.emit(vuln.type, vuln.severity)
	
	vulnerabilities_found += vulnerabilities.size()
	return vulnerabilities

func route_through_tor(target_ip: String) -> Dictionary:
	"""Enruta tráfico a través de Tor"""
	var result = {
		"success": false,
		"nodes_used": [],
		"honeypots_detected": [],
		"time_taken": 0.0
	}
	
	if not has_tor_access:
		result.success = false
		result.message = "Acceso a Tor no disponible"
		return result
	
	# Simular enrutamiento por Tor
	var start_time = Time.get_ticks_msec()
	var nodes = ["node1.onion", "node2.onion", "node3.onion"]
	var honeypots = []
	
	# Detectar honeypots (30% de probabilidad)
	for node in nodes:
		if randf() < 0.3:
			honeypots.append(node)
		else:
			result.nodes_used.append(node)
	
	result.honeypots_detected = honeypots
	result.time_taken = (Time.get_ticks_msec() - start_time) / 1000.0
	
	if honeypots.size() < nodes.size():
		result.success = true
		connections_established += 1
		honeypots_avoided += honeypots.size()
	else:
		result.success = false
		result.message = "Todos los nodos son honeypots. Conexión bloqueada."
		connection_lost.emit()
	
	return result

func decode_quantum_file(file_data: String, pattern: Array) -> Dictionary:
	"""Decodifica un archivo usando algoritmo cuántico"""
	var result = {
		"success": false,
		"decoded_data": "",
		"message": ""
	}
	
	if not has_quantum_decoder:
		result.message = "Decodificador cuántico no disponible"
		return result
	
	# Verificar patrón
	if pattern.size() != 8:
		result.message = "Patrón inválido. Se requieren 8 elementos."
		return result
	
	# Simular decodificación
	await get_tree().create_timer(3.0).timeout
	
	# Si el patrón es correcto, decodificar
	var correct_pattern = [1, 0, 1, 1, 0, 1, 0, 0]  # Patrón de ejemplo
	var pattern_match = true
	
	for i in range(min(pattern.size(), correct_pattern.size())):
		if pattern[i] != correct_pattern[i]:
			pattern_match = false
			break
	
	if pattern_match:
		result.success = true
		result.decoded_data = "CRONOS-7_DEVICE_BLUEPRINTS\nTemporal observation device\n12 timelines observed\nCollapse detected in all"
		result.message = "Archivo decodificado exitosamente"
	else:
		result.message = "Patrón incorrecto. Intenta de nuevo."
	
	return result

func _process(delta):
	"""Actualiza el tiempo restante"""
	if is_active and time_limit > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			stop_hacking_session()
			connection_lost.emit()
















