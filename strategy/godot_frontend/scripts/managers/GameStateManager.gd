# GameStateManager.gd (extensión del sistema actual)
class_name GameStateManager
extends Node

var ecosystems: Dictionary = {}  # ecosistema_id -> EcosystemState
var protected_areas: Array = []  # Áreas protegidas por misiones completadas
var restoration_projects: Dictionary = {} # Proyectos activos

func _ready():
	initialize_ecosystems()
	start_monthly_updates()

func initialize_ecosystems():
	# Inicializar con datos base por región
	var initial_states = {
		"amazon": {  # Misión 3: El Amazonas
			"type": ECOSYSTEM_TYPE.FOREST,
			"health": 65.0,
			"biodiversity": 70.0,
			"degradation_rate": 2.5,
			"region": "la"
		},
		"great_barrier": {  # Misión 15: El Grito del Coral
			"type": ECOSYSTEM_TYPE.CORAL,
			"health": 35.0,
			"biodiversity": 40.0,
			"degradation_rate": 3.0,
			"region": "au"
		},
		"pantanal": {  # Misión 19: Fuego en el Pantanal
			"type": ECOSYSTEM_TYPE.WETLAND,
			"health": 55.0,
			"biodiversity": 60.0,
			"degradation_rate": 2.8,
			"region": "la"
		},
		# ... añadir más según misiones
	}
	
	for eco_id in initial_states:
		var state = EcosystemState.new()
		var data = initial_states[eco_id]
		state.health = data.health
		state.biodiversity = data.biodiversity
		state.degradation_rate = data.degradation_rate
		ecosystems[eco_id] = state

func on_mission_completed(mission_id: String, choices: Dictionary):
	# Efectos positivos de misiones completadas
	match mission_id:
		"m3_amazonas":  # Defensa del Amazonas
			restore_ecosystem("amazon", {
				"health": 15.0,
				"biodiversity": 10.0,
				"degradation_rate": -1.0
			})
			add_protected_area("amazon_reserve", 15000)  # km² protegidos
		
		"m15_coral":  # Grito del Coral
			restore_ecosystem("great_barrier", {
				"health": 10.0,
				"biodiversity": 8.0,
				"resilience": 5.0
			})
			start_restoration_project("coral_nursery", "great_barrier", 24)  # 24 meses
		
		"m19_pantanal":  # Fuego en el Pantanal
			var saved = choices.get("tree_saved", false)
			if saved:
				restore_ecosystem("pantanal", {
					"health": 25.0,
					"biodiversity": 20.0,
					"resilience": 15.0
				})

func restore_ecosystem(eco_id: String, effects: Dictionary):
	if ecosystems.has(eco_id):
		var state = ecosystems[eco_id]
		state.health = min(100, state.health + effects.get("health", 0))
		state.biodiversity = min(100, state.biodiversity + effects.get("biodiversity", 0))
		state.degradation_rate += effects.get("degradation_rate", 0)
		state.resilience = min(100, state.resilience + effects.get("resilience", 0))
		
		# Notificar UI
		emit_signal("ecosystem_updated", eco_id, state)

func start_monthly_updates():
	var timer = Timer.new()
	timer.wait_time = 60.0  # 1 minuto de juego = 1 mes
	timer.autostart = true
	timer.timeout.connect(_update_monthly)
	add_child(timer)

func _update_monthly():
	# Obtener impacto humano actual basado en poder de Cartógrafos
	var cartograph_power = GameClient.get_cartograph_power()
	var global_impact = cartograph_power / 100.0  # 0-1
	
	# Actualizar cada ecosistema
	for eco_id in ecosystems:
		var state = ecosystems[eco_id]
		var region_impact = calculate_region_impact_for_eco(eco_id, global_impact)
		state.update_monthly(region_impact)
		
		# Efectos de áreas protegidas
		if is_protected(eco_id):
			state.degradation_rate *= 0.5
			state.resilience += 0.5
		
		# Efectos de proyectos de restauración
		for project in get_projects_for_ecosystem(eco_id):
			apply_restoration_effects(project, state)
		
		# Notificar cambios críticos
		if state.health <= 30 and not state.critical_notified:
			emit_signal("ecosystem_critical", eco_id, state)
			state.critical_notified = true
		
		emit_signal("ecosystem_updated", eco_id, state)
	
	emit_signal("monthly_update_complete")
