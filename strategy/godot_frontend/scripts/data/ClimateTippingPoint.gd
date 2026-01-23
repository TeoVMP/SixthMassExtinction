# ClimateTippingPoint.gd
# Sistema de puntos de no retorno climáticos basado en datos científicos reales
# Contexto: 2028-2035, protagonista viene de 2055 para evitar el colapso

extends RefCounted
class_name ClimateTippingPoint

# Identificador único
var tip_id: String = ""
var name: String = ""
var description: String = ""

# Estado del tipping point
var threshold: float = 0.0  # Valor crítico (ej: temperatura, % de pérdida)
var current_value: float = 0.0  # Valor actual
var activation_probability: float = 0.0  # Probabilidad de activación (0-1)
var is_activated: bool = false
var activation_date: String = ""  # Fecha de activación si se supera

# Efectos en cascada cuando se activa
var cascade_effects: Dictionary = {}  # {tip_id: impact_multiplier}
var social_impacts: Dictionary = {}  # {impact_type: severity}

# Datos científicos reales
var scientific_evidence: String = ""
var estimated_activation_year: int = 0  # Año estimado según ciencia actual

func _init(id: String = "", tip_name: String = ""):
	tip_id = id
	name = tip_name

func update_value(new_value: float):
	current_value = new_value
	if not is_activated and current_value >= threshold:
		_check_activation()

func _check_activation():
	# Calcular probabilidad de activación basada en qué tan cerca está del threshold
	var proximity = (current_value / threshold) if threshold > 0 else 0.0
	activation_probability = clamp(proximity - 0.9, 0.0, 1.0) * 10.0  # Acelera cerca del threshold
	
	if activation_probability >= 1.0 or current_value >= threshold:
		activate()

func activate():
	if is_activated:
		return
	
	is_activated = true
	activation_date = _get_current_date()
	print("🚨 TIPPING POINT ACTIVADO: ", name)
	print("   Fecha: ", activation_date)
	print("   Efectos en cascada: ", cascade_effects.keys())

func _get_current_date() -> String:
	# Obtener fecha del juego (conectar con sistema de tiempo)
	# Esto se actualizará desde ClimateSystem
	return "2028-01-01"  # Placeholder

func get_status() -> String:
	if is_activated:
		return "ACTIVADO"
	elif activation_probability > 0.7:
		return "CRÍTICO"
	elif activation_probability > 0.4:
		return "ALTO RIESGO"
	elif activation_probability > 0.1:
		return "RIESGO MODERADO"
	else:
		return "ESTABLE"

func get_social_impact_severity() -> float:
	# Retorna severidad del impacto social (0-1)
	if not is_activated:
		return activation_probability * 0.5  # Impacto parcial antes de activación
	return 1.0

