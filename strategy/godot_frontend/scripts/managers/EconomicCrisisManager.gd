# EconomicCrisisManager.gd
# Maneja crisis económicas por daño a infraestructura climática
extends Node
class_name EconomicCrisisManager

# Señales
signal infrastructure_damaged(region: String, damage: float)
signal resource_scarcity(region: String, resource_type: String, severity: float)
signal war_instigated(region1: String, region2: String, instigator: String)

# Referencias
var climate_system: ClimateSystem = null
var social_crisis_manager: Node = null
var game_client: Node = null

# Estado económico por región
var regional_economy: Dictionary = {}
var infrastructure_health: Dictionary = {}
var resource_availability: Dictionary = {}

# Guerras activas (instigadas por Cartógrafos)
var active_wars: Array = []

func _ready():
	_initialize_regional_economy()
	call_deferred("_connect_systems")

func _initialize_regional_economy():
	"""Inicializa economía regional"""
	var regions = ["pe", "eo", "eu", "ch", "ru", "as", "au", "la"]
	
	for region in regions:
		regional_economy[region] = {
			"gdp_health": 100.0,  # Salud del PIB (0-100)
			"infrastructure": 100.0,  # Estado de infraestructura
			"agriculture": 100.0,  # Sector agrícola
			"industry": 100.0,  # Sector industrial
			"services": 100.0,  # Sector servicios
			"trade": 100.0  # Comercio
		}
		
		infrastructure_health[region] = {
			"transport": 100.0,  # Transporte
			"energy": 100.0,  # Energía
			"water": 100.0,  # Agua
			"communications": 100.0  # Comunicaciones
		}
		
		resource_availability[region] = {
			"food": 100.0,  # Disponibilidad de comida
			"water": 100.0,  # Disponibilidad de agua
			"energy": 100.0,  # Disponibilidad de energía
			"raw_materials": 100.0  # Materias primas
		}

func _connect_systems():
	"""Conecta con otros sistemas"""
	var root = get_tree().root
	climate_system = root.find_child("ClimateSystem", true, false)
	social_crisis_manager = root.find_child("SocialCrisisManager", true, false)
	
	if climate_system:
		climate_system.social_crisis_triggered.connect(_on_climate_crisis)
		climate_system.tipping_point_activated.connect(_on_tipping_point_activated)
	
	if social_crisis_manager:
		social_crisis_manager.famine_triggered.connect(_on_famine)
		social_crisis_manager.water_crisis_triggered.connect(_on_water_crisis)

func _on_climate_crisis(crisis_type: String, severity: float):
	"""Maneja crisis climática y su impacto económico"""
	# Determinar regiones afectadas
	var affected_regions = _get_affected_regions_by_crisis(crisis_type)
	
	for region in affected_regions:
		_apply_economic_damage(region, crisis_type, severity)

func _on_tipping_point_activated(tip_id: String, tip: ClimateTippingPoint):
	"""Maneja activación de tipping point y su impacto económico"""
	# Impacto masivo en infraestructura global
	var global_damage = 0.3  # 30% de daño base
	
	match tip_id:
		"amazon_dieback":
			# Afecta principalmente Latinoamérica
			_apply_economic_damage("la", "infrastructure", global_damage * 0.8)
			_apply_economic_damage("pe", "infrastructure", global_damage * 0.6)
		
		"amoc":
			# Afecta Europa y América
			_apply_economic_damage("eo", "infrastructure", global_damage * 0.9)
			_apply_economic_damage("eu", "infrastructure", global_damage * 0.7)
			_apply_economic_damage("la", "infrastructure", global_damage * 0.5)
		
		"greenland_ice", "antarctica_ice":
			# Aumento del nivel del mar afecta costas
			_apply_economic_damage("eo", "infrastructure", global_damage * 0.6)
			_apply_economic_damage("as", "infrastructure", global_damage * 0.8)
			_apply_economic_damage("au", "infrastructure", global_damage * 0.7)
		
		"permafrost":
			# Afecta Rusia principalmente
			_apply_economic_damage("ru", "infrastructure", global_damage * 0.9)
		
		"coral_reefs":
			# Afecta pesca y turismo
			_apply_economic_damage("au", "economy", global_damage * 0.7)
			_apply_economic_damage("as", "economy", global_damage * 0.6)
		
		"monsoons":
			# Afecta agricultura en Asia y África
			_apply_economic_damage("as", "agriculture", global_damage * 1.0)
			_apply_economic_damage("au", "agriculture", global_damage * 0.9)
			_apply_economic_damage("pe", "agriculture", global_damage * 0.8)

func _apply_economic_damage(region: String, damage_type: String, severity: float):
	"""Aplica daño económico a una región"""
	if not regional_economy.has(region):
		return
	
	var damage = severity * 100.0  # Convertir a porcentaje
	
	match damage_type:
		"infrastructure":
			infrastructure_health[region].transport = max(0, infrastructure_health[region].transport - damage * 0.3)
			infrastructure_health[region].energy = max(0, infrastructure_health[region].energy - damage * 0.4)
			infrastructure_health[region].water = max(0, infrastructure_health[region].water - damage * 0.5)
			infrastructure_health[region].communications = max(0, infrastructure_health[region].communications - damage * 0.2)
			
			# Daño a economía general
			regional_economy[region].gdp_health = max(0, regional_economy[region].gdp_health - damage * 0.2)
		
		"agriculture":
			regional_economy[region].agriculture = max(0, regional_economy[region].agriculture - damage)
			resource_availability[region].food = max(0, resource_availability[region].food - damage * 0.8)
			regional_economy[region].gdp_health = max(0, regional_economy[region].gdp_health - damage * 0.3)
		
		"economy":
			regional_economy[region].gdp_health = max(0, regional_economy[region].gdp_health - damage)
			regional_economy[region].industry = max(0, regional_economy[region].industry - damage * 0.6)
			regional_economy[region].services = max(0, regional_economy[region].services - damage * 0.7)
			regional_economy[region].trade = max(0, regional_economy[region].trade - damage * 0.8)
	
	infrastructure_damaged.emit(region, damage)
	
	# Verificar si hay escasez crítica de recursos
	_check_resource_scarcity(region)

func _check_resource_scarcity(region: String):
	"""Verifica escasez crítica de recursos"""
	if not resource_availability.has(region):
		return
	
	for resource_type in resource_availability[region]:
		var availability = resource_availability[region][resource_type]
		
		if availability < 30:  # Escasez crítica
			var severity = (30.0 - availability) / 30.0
			resource_scarcity.emit(region, resource_type, severity)
			
			# Los Cartógrafos pueden instigar guerras cuando hay escasez
			if availability < 20:
				_check_war_instigation(region, resource_type)

func _check_war_instigation(region: String, resource_type: String):
	"""Verifica si los Cartógrafos instigan una guerra"""
	# Obtener poder de Cartógrafos
	var cartograph_power = 65.0  # Placeholder, conectar con GameClient
	if game_client and game_client.has_method("get_world_state"):
		var world_state = game_client.get_world_state()
		if world_state.has("cartograph_power"):
			cartograph_power = world_state.cartograph_power
	
	# Probabilidad de instigar guerra aumenta con poder de Cartógrafos y escasez
	var scarcity_level = resource_availability[region][resource_type] / 100.0
	var instigation_probability = (1.0 - scarcity_level) * (cartograph_power / 100.0) * 0.3
	
	if randf() < instigation_probability:
		_instigate_war(region, resource_type)

func _instigate_war(region1: String, resource_type: String):
	"""Los Cartógrafos instigan una guerra por recursos"""
	# Encontrar región vecina o rival
	var target_region = _find_war_target(region1, resource_type)
	
	if target_region:
		var war = {
			"region1": region1,
			"region2": target_region,
			"resource": resource_type,
			"instigator": "Cartógrafos",
			"start_date": _get_current_date(),
			"intensity": 0.5
		}
		
		active_wars.append(war)
		war_instigated.emit(region1, target_region, "Cartógrafos")
		
		# Aumentar violencia mundial
		if game_client and game_client.has_method("modify_world_state"):
			game_client.modify_world_state("violence", 25.0)
		
		print("🔴 GUERRA INSTIGADA: " + region1 + " vs " + target_region + " por " + resource_type)
		print("   Instigador: Cartógrafos")

func _find_war_target(region: String, resource_type: String) -> String:
	"""Encuentra región objetivo para guerra"""
	# Regiones vecinas o rivales
	var rivalries = {
		"pe": ["eo", "eu"],
		"eo": ["ru", "pe"],
		"eu": ["ch", "ru"],
		"ch": ["eu", "as"],
		"ru": ["eo", "eu"],
		"as": ["ch", "pe"],
		"au": ["eo", "as"],
		"la": ["eu", "pe"]
	}
	
	if rivalries.has(region):
		var candidates = rivalries[region]
		# Elegir región que también tenga escasez o sea vulnerable
		for candidate in candidates:
			if resource_availability.has(candidate):
				var candidate_scarcity = resource_availability[candidate][resource_type]
				if candidate_scarcity < 50:  # También tiene escasez
					return candidate
		# Si no hay candidato con escasez, elegir al azar
		return candidates[randi() % candidates.size()]
	
	return ""

func _get_affected_regions_by_crisis(crisis_type: String) -> Array:
	"""Determina regiones afectadas por tipo de crisis"""
	match crisis_type:
		"famine":
			return ["pe", "as", "au", "la"]
		"water_scarcity":
			return ["pe", "as", "au", "ch"]
		"social_unrest":
			return ["pe", "au", "as", "la"]
		_:
			return ["pe", "as", "au"]

func _on_famine(severity: float, regions: Array):
	"""Maneja hambruna y su impacto económico"""
	for region in regions:
		_apply_economic_damage(region, "agriculture", severity * 0.8)
		resource_availability[region].food = max(0, resource_availability[region].food - severity * 50.0)

func _on_water_crisis(severity: float, regions: Array):
	"""Maneja crisis hídrica y su impacto económico"""
	for region in regions:
		infrastructure_health[region].water = max(0, infrastructure_health[region].water - severity * 40.0)
		resource_availability[region].water = max(0, resource_availability[region].water - severity * 60.0)
		regional_economy[region].industry = max(0, regional_economy[region].industry - severity * 30.0)

func _get_current_date() -> String:
	if climate_system:
		return str(climate_system.current_year) + "-" + str(climate_system.current_month).pad_zeros(2) + "-01"
	return "2028-01-01"

func set_game_client(client: Node):
	game_client = client

func get_regional_economy(region: String) -> Dictionary:
	return regional_economy.get(region, {})

func get_infrastructure_health(region: String) -> Dictionary:
	return infrastructure_health.get(region, {})
















