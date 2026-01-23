# BodyPartState.gd
# Estado de partes del cuerpo (para combate y lesiones)
extends RefCounted
class_name BodyPartState

enum BodyPart {
	HEAD,        # Cabeza
	TORSO,       # Torso
	LEFT_ARM,    # Brazo izquierdo
	RIGHT_ARM,   # Brazo derecho
	LEFT_LEG,    # Pierna izquierda
	RIGHT_LEG,   # Pierna derecha
	HANDS,       # Manos
	FEET         # Pies
}

var part: BodyPart = BodyPart.TORSO
var health: float = 100.0  # Salud de la parte (0-100)
var max_health: float = 100.0
var is_injured: bool = false
var injury_type: String = ""  # "bruise", "cut", "fracture", "burn", etc.
var pain_level: float = 0.0  # Nivel de dolor (0-10)

func take_damage(amount: float, damage_type: String = "physical"):
	"""Aplica daño a esta parte del cuerpo"""
	health = max(0, health - amount)
	
	if health < max_health * 0.9:
		is_injured = true
		injury_type = damage_type
		pain_level = (max_health - health) / max_health * 10.0
	
	if health <= 0:
		pain_level = 10.0
		is_injured = true
		injury_type = "critical"

func heal(amount: float):
	"""Cura esta parte del cuerpo"""
	health = min(max_health, health + amount)
	
	if health >= max_health * 0.9:
		is_injured = false
		injury_type = ""
		pain_level = max(0, pain_level - amount / max_health * 10.0)

func get_status() -> String:
	if health <= 0:
		return "CRÍTICO"
	elif health < 30:
		return "GRAVE"
	elif health < 60:
		return "LESIONADO"
	elif health < 90:
		return "DAÑADO"
	else:
		return "SALUDABLE"

func get_functionality() -> float:
	"""Retorna funcionalidad de la parte (0-1)"""
	if health <= 0:
		return 0.0
	elif health < 30:
		return 0.2
	elif health < 60:
		return 0.5
	elif health < 90:
		return 0.8
	else:
		return 1.0
















