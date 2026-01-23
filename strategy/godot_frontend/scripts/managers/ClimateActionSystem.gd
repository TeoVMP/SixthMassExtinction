# ClimateActionSystem.gd
# Sistema de acción climática para prevenir el colapso
# Mide el porcentaje de acción climática (0-100%)
# A menor acción, mayor deterioro de ecosistemas

extends Node
class_name ClimateActionSystem

# Señales
signal climate_action_updated(action_level: float)
signal action_insufficient(warning_level: float)

# Nivel de acción climática (0-100%)
var action_level: float = 0.0  # 0 = sin acción, 100 = acción completa

# Acciones realizadas
var actions_taken: Array = []  # Lista de acciones climáticas realizadas
var missions_completed: int = 0  # Misiones climáticas completadas
var ecosystems_protected: int = 0  # Ecosistemas protegidos
var tipping_points_prevented: int = 0  # Tipping points prevenidos

# Umbrales
var minimum_action_required: float = 30.0  # Mínimo necesario para ralentizar deterioro
var optimal_action_level: float = 70.0  # Nivel óptimo para prevenir colapso

func _ready():
	print("🌱 ClimateActionSystem iniciado")

func add_action(action_type: String, impact: float):
	"""Añade una acción climática"""
	actions_taken.append({
		"type": action_type,
		"impact": impact,
		"date": _get_current_date()
	})
	
	# Actualizar nivel de acción
	action_level = min(100.0, action_level + impact)
	climate_action_updated.emit(action_level)
	
	print("✅ Acción climática añadida: ", action_type, " (+", impact, "%)")
	print("   Nivel total: ", action_level, "%")

func complete_climate_mission(mission_id: String, impact: float):
	"""Registra una misión climática completada"""
	missions_completed += 1
	add_action("mission_" + mission_id, impact)

func protect_ecosystem(eco_id: String):
	"""Registra protección de un ecosistema"""
	ecosystems_protected += 1
	add_action("protect_" + eco_id, 5.0)

func prevent_tipping_point(tip_id: String):
	"""Registra prevención de un tipping point"""
	tipping_points_prevented += 1
	add_action("prevent_" + tip_id, 15.0)

func get_degradation_multiplier() -> float:
	"""Retorna multiplicador de degradación basado en acción climática"""
	# A menor acción, mayor degradación
	if action_level >= optimal_action_level:
		return 0.3  # Degradación muy lenta
	elif action_level >= minimum_action_required:
		return 0.6  # Degradación moderada
	elif action_level > 0:
		return 0.8  # Degradación rápida
	else:
		return 1.5  # Degradación muy rápida (sin acción)

func get_warning_level() -> float:
	"""Retorna nivel de advertencia (0-1)"""
	if action_level >= optimal_action_level:
		return 0.0  # Sin advertencia
	elif action_level >= minimum_action_required:
		return 0.3  # Advertencia leve
	elif action_level > 0:
		return 0.7  # Advertencia moderada
	else:
		return 1.0  # Advertencia crítica

func _get_current_date() -> String:
	"""Obtiene fecha actual del sistema de tiempo"""
	# Conectar con TimeSystem
	return "2028-09-20"  # Placeholder
















