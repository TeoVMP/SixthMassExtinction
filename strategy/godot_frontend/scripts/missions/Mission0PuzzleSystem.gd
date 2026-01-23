# Mission0PuzzleSystem.gd
# Sistema de puzzles para la Misión 0: La Brecha de la NSA
# Implementa los 3 puzzles: Certificado Digital, Redirección Tor, Decodificación Cuántica
extends Node
class_name Mission0PuzzleSystem

signal puzzle_completed(puzzle_id: String)
signal all_puzzles_completed()

# Estados de los puzzles
enum PuzzleStatus {
	LOCKED,
	AVAILABLE,
	IN_PROGRESS,
	COMPLETED
}

# Puzzle 1: Suplantar identidad con certificado digital
class Puzzle1:
	var puzzle_id: String = "certificate_spoof"
	var status: PuzzleStatus = PuzzleStatus.AVAILABLE
	var description: String = "Suplantar identidad usando certificado digital robado"
	var solution: String = "cert_steal.sh"  # Nombre del script que debe ejecutar
	var completed: bool = false

# Puzzle 2: Redirigir tráfico a través de Tor
class Puzzle2:
	var puzzle_id: String = "tor_redirect"
	var status: PuzzleStatus = PuzzleStatus.LOCKED
	var description: String = "Redirigir tráfico a través de nodos Tor mientras evitas honeypots"
	var solution: String = "tor_route.sh"
	var completed: bool = false

# Puzzle 3: Decodificar archivo .chrono
class Puzzle3:
	var puzzle_id: String = "quantum_decode"
	var status: PuzzleStatus = PuzzleStatus.LOCKED
	var description: String = "Decodificar archivo .chrono con algoritmo cuántico"
	var solution: String = "quantum_decode.py"
	var completed: bool = false

var puzzles: Dictionary = {}
var current_puzzle: int = 0

func _ready():
	_initialize_puzzles()

func _initialize_puzzles():
	"""Inicializa los 3 puzzles"""
	var p1 = Puzzle1.new()
	puzzles[p1.puzzle_id] = p1
	
	var p2 = Puzzle2.new()
	puzzles[p2.puzzle_id] = p2
	
	var p3 = Puzzle3.new()
	puzzles[p3.puzzle_id] = p3

func check_puzzle_progress(command: String, output: String) -> bool:
	"""Verifica si un comando completa un puzzle"""
	var cmd_lower = command.to_lower()
	var output_lower = output.to_lower()
	
	# Puzzle 1: Certificado digital - Verificar si el jugador ejecutó su script
	if puzzles.has("certificate_spoof"):
		var p1 = puzzles["certificate_spoof"] as Puzzle1
		if p1.status == PuzzleStatus.AVAILABLE or p1.status == PuzzleStatus.IN_PROGRESS:
			# Verificar si ejecutó cert_steal.sh (que el jugador debe crear)
			if ("bash" in cmd_lower or "sh" in cmd_lower or "./" in cmd_lower) and "cert_steal" in cmd_lower:
				if "identity spoofed successfully" in output_lower:
					p1.completed = true
					p1.status = PuzzleStatus.COMPLETED
					puzzle_completed.emit("certificate_spoof")
					_unlock_puzzle("tor_redirect")
					return true
			# También verificar si el script existe y tiene el contenido correcto
			if "cat" in cmd_lower and "cert_steal" in cmd_lower:
				if "identity spoofed successfully" in output_lower or "#!/bin/bash" in output_lower:
					# El jugador está revisando su script, no completar aún
					pass
	
	# Puzzle 2: Redirección Tor - Verificar si el jugador ejecutó su script
	if puzzles.has("tor_redirect"):
		var p2 = puzzles["tor_redirect"] as Puzzle2
		if p2.status == PuzzleStatus.AVAILABLE or p2.status == PuzzleStatus.IN_PROGRESS:
			# Verificar si ejecutó tor_route.sh (que el jugador debe crear)
			if ("bash" in cmd_lower or "sh" in cmd_lower or "./" in cmd_lower) and "tor_route" in cmd_lower:
				if "tor route established" in output_lower and "honeypot avoided" in output_lower:
					p2.completed = true
					p2.status = PuzzleStatus.COMPLETED
					puzzle_completed.emit("tor_redirect")
					_unlock_puzzle("quantum_decode")
					return true
	
	# Puzzle 3: Decodificación cuántica - Verificar si el jugador ejecutó su script
	if puzzles.has("quantum_decode"):
		var p3 = puzzles["quantum_decode"] as Puzzle3
		if p3.status == PuzzleStatus.AVAILABLE or p3.status == PuzzleStatus.IN_PROGRESS:
			# Verificar si ejecutó quantum_decode.py (que el jugador debe crear)
			if ("python" in cmd_lower or "python3" in cmd_lower) and "quantum_decode" in cmd_lower:
				if "decoded successfully" in output_lower and "cronos-7 device blueprints unlocked" in output_lower:
					p3.completed = true
					p3.status = PuzzleStatus.COMPLETED
					puzzle_completed.emit("quantum_decode")
					all_puzzles_completed.emit()
					return true
	
	return false

func _unlock_puzzle(puzzle_id: String):
	"""Desbloquea un puzzle"""
	if puzzles.has(puzzle_id):
		var puzzle = puzzles[puzzle_id]
		if puzzle.status == PuzzleStatus.LOCKED:
			puzzle.status = PuzzleStatus.AVAILABLE

func get_puzzle_status(puzzle_id: String) -> PuzzleStatus:
	"""Obtiene el estado de un puzzle"""
	if puzzles.has(puzzle_id):
		return puzzles[puzzle_id].status
	return PuzzleStatus.LOCKED

func are_all_puzzles_completed() -> bool:
	"""Verifica si todos los puzzles están completos"""
	for puzzle_id in puzzles:
		if not puzzles[puzzle_id].completed:
			return false
	return true





