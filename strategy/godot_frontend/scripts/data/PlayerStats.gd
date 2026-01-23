# PlayerStats.gd
# Estadísticas del jugador estilo RPG (D&D, Cthulhu)
extends RefCounted
class_name PlayerStats

# Estadísticas principales (0-20, estilo D&D)
var strength: int = 10        # Fuerza - combate físico, cargar peso
var constitution: int = 10    # Constitución - salud, resistencia
var dexterity: int = 10       # Destreza - agilidad, sigilo
var intelligence: int = 12     # Inteligencia - hacking, análisis
var wisdom: int = 11          # Sabiduría - percepción, supervivencia
var charisma: int = 10        # Carisma - diplomacia, liderazgo

# Modificadores (basados en estadísticas)
func get_strength_modifier() -> int:
	return (strength - 10) / 2

func get_constitution_modifier() -> int:
	return (constitution - 10) / 2

func get_dexterity_modifier() -> int:
	return (dexterity - 10) / 2

func get_intelligence_modifier() -> int:
	return (intelligence - 10) / 2

func get_wisdom_modifier() -> int:
	return (wisdom - 10) / 2

func get_charisma_modifier() -> int:
	return (charisma - 10) / 2

# Puntos de habilidad (skills) basados en estadísticas
var skills: Dictionary = {
	"science": 0,        # Basado en Inteligencia
	"diplomacy": 0,     # Basado en Carisma
	"stealth": 0,       # Basado en Destreza
	"survival": 0,      # Basado en Sabiduría
	"combat": 0,        # Basado en Fuerza/Destreza
	"investigation": 0, # Basado en Inteligencia/Sabiduría
	"persuasion": 0,    # Basado en Carisma
	"athletics": 0      # Basado en Fuerza
}

func calculate_skill_bonus(skill_name: String) -> int:
	"""Calcula bonificador de habilidad basado en estadística"""
	var base_modifier = 0
	match skill_name:
		"science", "investigation":
			base_modifier = get_intelligence_modifier()
		"diplomacy", "persuasion":
			base_modifier = get_charisma_modifier()
		"stealth":
			base_modifier = get_dexterity_modifier()
		"survival":
			base_modifier = get_wisdom_modifier()
		"combat":
			base_modifier = max(get_strength_modifier(), get_dexterity_modifier())
		"athletics":
			base_modifier = get_strength_modifier()
		_:
			base_modifier = 0
	
	return base_modifier + skills.get(skill_name, 0)

func _init():
	# Inicializar habilidades basadas en estadísticas iniciales
	skills.science = get_intelligence_modifier() + 2
	skills.diplomacy = get_charisma_modifier() + 1
	skills.stealth = get_dexterity_modifier()
	skills.survival = get_wisdom_modifier() + 1
	skills.combat = max(get_strength_modifier(), get_dexterity_modifier())
	skills.investigation = get_intelligence_modifier() + 1
	skills.persuasion = get_charisma_modifier() + 1
	skills.athletics = get_strength_modifier()











