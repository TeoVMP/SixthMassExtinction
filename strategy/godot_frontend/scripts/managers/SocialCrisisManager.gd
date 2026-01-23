# SocialCrisisManager.gd
# Maneja crisis sociales derivadas del colapso climático
# Basado en datos reales de impactos sociales del cambio climático

extends Node
class_name SocialCrisisManager

# Señales
signal famine_triggered(severity: float, affected_regions: Array)
signal water_crisis_triggered(severity: float, affected_regions: Array)
signal refugee_crisis_triggered(severity: float, displacement_count: int)
signal social_unrest_triggered(severity: float, regions: Array)
signal political_violence_triggered(severity: float, regions: Array)

# Referencias
var climate_system: ClimateSystem = null
var game_client: Node = null

# Crisis activas
var active_crises: Dictionary = {}

# Impactos acumulados por región (aunque ecosistemas no son por región, los efectos sí)
var regional_impacts: Dictionary = {}

func _ready():
	# Conectar con ClimateSystem si existe
	call_deferred("_connect_climate_system")

func _connect_climate_system():
	"""Conecta con el ClimateSystem"""
	var root = get_tree().root
	climate_system = root.find_child("ClimateSystem", true, false)
	
	if climate_system:
		climate_system.social_crisis_triggered.connect(_on_social_crisis)
		print("✅ SocialCrisisManager conectado a ClimateSystem")
	else:
		print("⚠️ ClimateSystem no encontrado")

func _on_social_crisis(crisis_type: String, severity: float):
	"""Maneja crisis social del ClimateSystem"""
	match crisis_type:
		"famine":
			_handle_famine(severity)
		"water_scarcity":
			_handle_water_crisis(severity)
		"social_unrest":
			_handle_social_unrest(severity)
		"political_violence":
			_handle_political_violence(severity)

func _handle_famine(severity: float):
	"""Maneja crisis de hambruna"""
	active_crises["famine"] = {
		"severity": severity,
		"start_date": _get_current_date(),
		"affected_regions": _get_affected_regions("food_security")
	}
	
	# Calcular impacto en necesidades del jugador
	var hunger_increase = severity * 20.0  # Aumenta hambre del jugador
	
	# Aumentar violencia social
	var violence_increase = severity * 15.0
	
	# Notificar al GameClient
	if game_client and game_client.has_method("modify_player_needs"):
		game_client.modify_player_needs("hunger", hunger_increase)
	
	if game_client and game_client.has_method("modify_world_state"):
		game_client.modify_world_state("violence", violence_increase)
	
	famine_triggered.emit(severity, active_crises["famine"].affected_regions)
	print("🍞 HAMBRUNA: Severidad ", severity, " - Afecta: ", active_crises["famine"].affected_regions)

func _handle_water_crisis(severity: float):
	"""Maneja crisis hídrica"""
	active_crises["water_crisis"] = {
		"severity": severity,
		"start_date": _get_current_date(),
		"affected_regions": _get_affected_regions("water_scarcity")
	}
	
	# Aumentar sed del jugador
	var thirst_increase = severity * 25.0
	
	# Aumentar conflictos
	var conflict_increase = severity * 10.0
	
	if game_client and game_client.has_method("modify_player_needs"):
		game_client.modify_player_needs("thirst", thirst_increase)
	
	if game_client and game_client.has_method("modify_world_state"):
		game_client.modify_world_state("violence", conflict_increase)
	
	water_crisis_triggered.emit(severity, active_crises["water_crisis"].affected_regions)
	print("💧 CRISIS HÍDRICA: Severidad ", severity)

func _handle_social_unrest(severity: float):
	"""Maneja inestabilidad social"""
	active_crises["social_unrest"] = {
		"severity": severity,
		"start_date": _get_current_date(),
		"regions": _get_affected_regions("conflict_risk")
	}
	
	# Aumentar violencia mundial
	var violence_increase = severity * 20.0
	
	# Aumentar estrés del jugador
	var stress_increase = severity * 15.0
	
	if game_client and game_client.has_method("modify_world_state"):
		game_client.modify_world_state("violence", violence_increase)
	
	if game_client and game_client.has_method("modify_player_needs"):
		game_client.modify_player_needs("stress", stress_increase)
	
	social_unrest_triggered.emit(severity, active_crises["social_unrest"].regions)
	print("⚡ INESTABILIDAD SOCIAL: Severidad ", severity)

func _handle_political_violence(severity: float):
	"""Maneja violencia política"""
	active_crises["political_violence"] = {
		"severity": severity,
		"start_date": _get_current_date(),
		"regions": _get_affected_regions("conflict_risk")
	}
	
	# Aumentar violencia política
	var violence_increase = severity * 25.0
	
	# Aumentar poder de los Cartógrafos (aprovechan la crisis)
	var cartograph_increase = severity * 10.0
	
	if game_client and game_client.has_method("modify_world_state"):
		game_client.modify_world_state("violence", violence_increase)
		game_client.modify_world_state("cartograph_power", cartograph_increase)
	
	political_violence_triggered.emit(severity, active_crises["political_violence"].regions)
	print("🔴 VIOLENCIA POLÍTICA: Severidad ", severity)

func _get_affected_regions(impact_type: String) -> Array:
	"""Determina qué regiones son más afectadas por un tipo de impacto"""
	# Basado en datos reales de vulnerabilidad climática
	var affected = []
	
	if not climate_system:
		return affected
	
	# Regiones más vulnerables a cada tipo de impacto
	match impact_type:
		"food_security":
			# Regiones dependientes de agricultura de subsistencia
			affected = ["pe", "as", "au", "la"]  # Pueblos Explotados, Asia Sur, África, Latinoamérica
		"water_scarcity":
			# Regiones con estrés hídrico
			affected = ["pe", "as", "au", "ch"]  # Incluye China por estrés hídrico
		"conflict_risk":
			# Regiones con alta vulnerabilidad social
			affected = ["pe", "au", "as", "la"]
		_:
			affected = ["pe", "as", "au"]
	
	return affected

func _get_current_date() -> String:
	"""Obtiene fecha actual del juego"""
	if climate_system:
		return str(climate_system.current_year) + "-" + str(climate_system.current_month).pad_zeros(2) + "-01"
	return "2028-01-01"

func set_game_client(client: Node):
	game_client = client

func get_active_crises() -> Dictionary:
	return active_crises

func get_crisis_severity(crisis_type: String) -> float:
	if active_crises.has(crisis_type):
		return active_crises[crisis_type].severity
	return 0.0
















