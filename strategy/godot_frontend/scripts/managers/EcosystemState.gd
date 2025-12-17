# res://scripts/data/EcosystemState.gd
class_name EcosystemState

var eco_id: String = ""
var eco_type: int = 0  # Usar números en lugar del enum directamente
var health: float = 100.0
var biodiversity: float = 100.0
var integrity: float = 100.0
var resilience: float = 50.0
var degradation_rate: float = 0.0
var restoration_progress: float = 0.0
var critical_notified: bool = false

func _init(id: String, type: int):
	eco_id = id
	eco_type = type

func update_monthly(human_impact: float):
	var base_degradation = 0.5 + human_impact * 0.5
	health = max(0, health - base_degradation)
	biodiversity = max(0, biodiversity - base_degradation * 0.8)
	integrity = max(0, integrity - base_degradation * 0.7)
	
	if human_impact < 0.3:
		health = min(100, health + 0.2)
		resilience = min(100, resilience + 0.1)

func get_status() -> String:
	if health >= 80: return "PRÍSTINO"
	elif health >= 60: return "SALUDABLE"
	elif health >= 40: return "DEGRADADO"
	elif health >= 20: return "CRÍTICO"
	else: return "COLAPSADO"
