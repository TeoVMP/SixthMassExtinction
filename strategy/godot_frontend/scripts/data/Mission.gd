# Mission.gd
# Recurso que define una misión del juego
extends Resource
class_name Mission

enum MissionStatus {
	AVAILABLE,      # Disponible para iniciar
	ACTIVE,         # En progreso
	COMPLETED,      # Completada
	FAILED,         # Fallida
	LOCKED          # Bloqueada (requisitos no cumplidos)
}

enum MissionType {
	HACKING,        # Misión de hacking/infiltración
	ECOLOGICAL,     # Misión ecológica
	POLITICAL,      # Misión política/diplomática
	RESCUE,         # Misión de rescate
	INVESTIGATION,  # Misión de investigación
	CONSTRUCTION,   # Misión de construcción/desarrollo
	COMBAT,         # Misión de combate
	DILEMMA         # Misión de dilema moral
}

# Identificación
@export var mission_id: String = ""
@export var mission_name: String = ""
@export var mission_description: String = ""
@export var mission_type: MissionType = MissionType.ECOLOGICAL

# Ubicación
@export var region_code: String = ""
@export var country_code: String = ""
@export var state_code: String = ""
@export var location_name: String = ""

# Estado
@export var status: MissionStatus = MissionStatus.AVAILABLE
@export var act_number: int = 0  # Acto de la trama (0=Prólogo, 1=Acto I, etc.)

# Requisitos
@export var required_missions: Array = []  # IDs de misiones que deben completarse antes (Array[String])
@export var required_reputation: Dictionary = {}  # {"region": min_value}
@export var required_sanity: float = 0.0
@export var required_skills: Dictionary = {}  # {"hacking": 5, "diplomacy": 3}

# Recompensas
@export var reputation_rewards: Dictionary = {}  # {"region": value}
@export var sanity_reward: float = 0.0
@export var climate_action_reward: float = 0.0
@export var unlocks: Array = []  # IDs de misiones que desbloquea (Array[String])

# Opciones y consecuencias
@export var choices: Array = []  # Opciones disponibles (Array[Dictionary])
@export var consequences: Dictionary = {}  # Consecuencias de cada elección

# Metadata
@export var estimated_time: int = 0  # Tiempo estimado en días
@export var difficulty: int = 1  # 1-5
@export var is_main_story: bool = false  # Si es parte de la trama principal

# Sistema de Manifiesto
@export var requires_manifesto: bool = false  # Si esta misión requiere que se haya enviado el manifiesto
@export var unlocks_manifesto: bool = false  # Si completar esta misión desbloquea el botón de manifiesto
@export var has_revolutionary_action: bool = false  # Si esta misión tiene acción revolucionaria con alcance mediático

func _init():
	pass

func can_start(player_state: Dictionary) -> bool:
	"""Verifica si la misión puede iniciarse"""
	if status != MissionStatus.AVAILABLE and status != MissionStatus.LOCKED:
		return false
	
	# Verificar misiones requeridas
	for req_mission in required_missions:
		# Asumimos que player_state tiene completed_missions
		if not player_state.get("completed_missions", []).has(req_mission):
			return false
	
	# Verificar requisito de manifiesto
	if requires_manifesto:
		# Necesitamos verificar con MissionManager si el manifiesto fue enviado
		# Por ahora, asumimos que player_state tiene manifesto_submitted
		if not player_state.get("manifesto_submitted", false):
			return false
	
	# Verificar reputación
	for region in required_reputation:
		var player_rep = player_state.get("reputation", {}).get(region, 0)
		if player_rep < required_reputation[region]:
			return false
	
	# Verificar cordura
	if player_state.get("sanity", 100) < required_sanity:
		return false
	
	return true

func get_tooltip_text() -> String:
	"""Genera texto para tooltip"""
	var text = mission_name + "\n"
	text += "Tipo: " + MissionType.keys()[mission_type] + "\n"
	var stars = ""
	for i in range(difficulty):
		stars += "⭐"
	text += "Dificultad: " + stars + "\n"
	text += "Ubicación: " + location_name + "\n"
	if status == MissionStatus.LOCKED:
		text += "🔒 BLOQUEADA"
	return text

