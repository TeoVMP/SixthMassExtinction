# res://scripts/managers/EcosystemManager.gd
extends Node
class_name EcosystemManager

# Señales
signal ecosystem_updated(eco_id: String, state: EcosystemState)
signal ecosystem_critical(eco_id: String, state: EcosystemState)
signal monthly_update_complete()

# Variables
var ecosystems: Dictionary = {}
var protected_areas: Array = []
var restoration_projects: Dictionary = {}
var impact_calculator = preload("res://scripts/managers/HumanImpactCalculator.gd").new()

func _ready():
	initialize_ecosystems()
	start_monthly_updates()

func initialize_ecosystems():
	# Estados iniciales simplificados
	ecosystems["amazon"] = EcosystemState.new("amazon", 0)  # 0 = FOREST
	ecosystems["amazon"].health = 65.0
	ecosystems["amazon"].biodiversity = 70.0
	ecosystems["amazon"].degradation_rate = 2.5
	
	ecosystems["great_barrier"] = EcosystemState.new("great_barrier", 1)  # 1 = CORAL
	ecosystems["great_barrier"].health = 35.0
	ecosystems["great_barrier"].biodiversity = 40.0
	ecosystems["great_barrier"].degradation_rate = 3.0
	
	ecosystems["pantanal"] = EcosystemState.new("pantanal", 2)  # 2 = WETLAND
	ecosystems["pantanal"].health = 55.0
	ecosystems["pantanal"].biodiversity = 60.0
	ecosystems["pantanal"].degradation_rate = 2.8

func add_protected_area(area_name: String, size_km: float):
	protected_areas.append({"name": area_name, "size": size_km})
	print("Área protegida añadida:", area_name, "de", size_km, "km²")

func start_restoration_project(project_name: String, eco_id: String, duration_months: int):
	restoration_projects[project_name] = {
		"eco_id": eco_id,
		"duration": duration_months,
		"progress": 0
	}

func calculate_region_impact_for_eco(eco_id: String, global_impact: float) -> float:
	# Lógica simplificada
	match eco_id:
		"amazon", "pantanal":
			return global_impact * 1.2  # Latinoamérica más vulnerable
		"great_barrier":
			return global_impact * 0.9  # Australia algo más resiliente
		_:
			return global_impact

func is_protected(eco_id: String) -> bool:
	# Verificar si hay áreas protegidas para este ecosistema
	for area in protected_areas:
		if area.get("eco_id", "") == eco_id:
			return true
	return false

func get_projects_for_ecosystem(eco_id: String) -> Array:
	var projects = []
	for project_name in restoration_projects:
		var project = restoration_projects[project_name]
		if project.eco_id == eco_id:
			projects.append(project)
	return projects

func apply_restoration_effects(project: Dictionary, state: EcosystemState):
	var monthly_restoration = 100.0 / project.duration
	state.health = min(100, state.health + monthly_restoration * 0.5)
	state.biodiversity = min(100, state.biodiversity + monthly_restoration * 0.3)

func restore_ecosystem(eco_id: String, effects: Dictionary):
	if ecosystems.has(eco_id):
		var state = ecosystems[eco_id]
		state.health = min(100, state.health + effects.get("health", 0))
		state.biodiversity = min(100, state.biodiversity + effects.get("biodiversity", 0))
		state.degradation_rate += effects.get("degradation_rate", 0)
		state.resilience = min(100, state.resilience + effects.get("resilience", 0))
		
		ecosystem_updated.emit(eco_id, state)

func start_monthly_updates():
	var timer = Timer.new()
	timer.wait_time = 60.0  # 1 minuto = 1 mes
	timer.autostart = true
	timer.timeout.connect(_update_monthly)
	add_child(timer)

func _update_monthly():
	var cartograph_power = 65  # Valor de ejemplo, conéctalo a tu GameClient
	var global_impact = cartograph_power / 100.0
	
	for eco_id in ecosystems:
		var state = ecosystems[eco_id]
		var region_impact = calculate_region_impact_for_eco(eco_id, global_impact)
		state.update_monthly(region_impact)
		
		if is_protected(eco_id):
			state.degradation_rate *= 0.5
			state.resilience += 0.5
		
		var projects = get_projects_for_ecosystem(eco_id)
		for project in projects:
			apply_restoration_effects(project, state)
		
		if state.health <= 30 and not state.critical_notified:
			ecosystem_critical.emit(eco_id, state)
			state.critical_notified = true
		
		ecosystem_updated.emit(eco_id, state)
	
	monthly_update_complete.emit()
