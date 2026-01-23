# ClimateSystem.gd
# Sistema climático global basado en datos científicos reales
# Contexto: 2028-2035, evitando colapso antes de 2035

extends Node
class_name ClimateSystem

# Señales
signal tipping_point_activated(tip_id: String, tip: ClimateTippingPoint)
signal cascade_effect_triggered(source_tip: String, affected_tip: String)
signal social_crisis_triggered(crisis_type: String, severity: float)
signal climate_update_complete()

# Estado climático global
var global_temperature: float = 1.1  # °C sobre pre-industrial (2024: ~1.1°C)
var co2_ppm: float = 420.0  # ppm CO2 (2024: ~420 ppm)
var emissions_rate: float = 1.0  # Tasa de emisiones (1.0 = actual, >1.0 = aumentando)

# Año actual del juego
var current_year: int = 2028
var current_month: int = 1

# Ecosistemas reales del planeta (no por regiones políticas)
var ecosystems: Dictionary = {}

# Tipping points climáticos (basados en ciencia real 2024)
var tipping_points: Dictionary = {}

# Efectos en cascada activos
var active_cascades: Array = []

# Impacto social acumulado
var social_impacts: Dictionary = {
	"food_crisis": 0.0,      # Crisis alimentaria (0-1)
	"water_crisis": 0.0,     # Crisis hídrica
	"refugee_crisis": 0.0,   # Crisis de refugiados
	"economic_collapse": 0.0, # Colapso económico
	"social_unrest": 0.0,    # Inestabilidad social
	"political_violence": 0.0 # Violencia política
}

func _ready():
	initialize_tipping_points()
	initialize_real_ecosystems()
	start_monthly_updates()

func initialize_tipping_points():
	"""Inicializa los tipping points climáticos basados en ciencia real"""
	
	# 1. AMOC (Atlantic Meridional Overturning Circulation)
	var amoc = ClimateTippingPoint.new("amoc", "Circulación Atlántica (AMOC)")
	amoc.threshold = 15.0  # % de debilitamiento crítico
	amoc.current_value = 5.0  # Estado actual (2024)
	amoc.description = "El colapso de la AMOC alteraría patrones climáticos globales"
	amoc.scientific_evidence = "Evidencia creciente de debilitamiento desde 2004"
	amoc.estimated_activation_year = 2035
	amoc.cascade_effects = {
		"monsoon_systems": 0.8,
		"european_climate": 0.9
	}
	amoc.social_impacts = {
		"food_security": 0.7,
		"water_scarcity": 0.6,
		"conflict_risk": 0.5
	}
	tipping_points["amoc"] = amoc
	
	# 2. Hielo de Groenlandia
	var greenland_ice = ClimateTippingPoint.new("greenland_ice", "Capas de Hielo de Groenlandia")
	greenland_ice.threshold = 1.5  # °C de calentamiento
	greenland_ice.current_value = global_temperature
	greenland_ice.description = "Derretimiento irreversible de Groenlandia (+7m nivel del mar)"
	greenland_ice.scientific_evidence = "Pérdida acelerada desde 2000"
	greenland_ice.estimated_activation_year = 2030
	greenland_ice.cascade_effects = {
		"amoc": 0.3,  # Afecta AMOC
		"sea_level": 1.0
	}
	greenland_ice.social_impacts = {
		"displacement": 0.9,
		"economic_loss": 0.8
	}
	tipping_points["greenland_ice"] = greenland_ice
	
	# 3. Hielo de la Antártida Occidental
	var antarctica_ice = ClimateTippingPoint.new("antarctica_ice", "Hielo de la Antártida Occidental")
	antarctica_ice.threshold = 2.0  # °C
	antarctica_ice.current_value = global_temperature
	antarctica_ice.description = "Colapso de glaciares antárticos (+3m nivel del mar)"
	antarctica_ice.scientific_evidence = "Aceleración observada desde 2010"
	antarctica_ice.estimated_activation_year = 2032
	antarctica_ice.cascade_effects = {
		"sea_level": 1.0,
		"ocean_circulation": 0.4
	}
	antarctica_ice.social_impacts = {
		"displacement": 0.8,
		"economic_loss": 0.7
	}
	tipping_points["antarctica_ice"] = antarctica_ice
	
	# 4. Permafrost Siberiano
	var permafrost = ClimateTippingPoint.new("permafrost", "Descongelamiento del Permafrost")
	permafrost.threshold = 2.0  # °C
	permafrost.current_value = global_temperature
	permafrost.description = "Liberación masiva de metano y CO2 del permafrost"
	permafrost.scientific_evidence = "Descongelamiento acelerado observado"
	permafrost.estimated_activation_year = 2033
	permafrost.cascade_effects = {
		"global_temperature": 0.6,  # Feedback positivo
		"arctic_ecosystems": 0.9
	}
	permafrost.social_impacts = {
		"food_security": 0.6,
		"infrastructure_loss": 0.7
	}
	tipping_points["permafrost"] = permafrost
	
	# 5. Amazonas (Dieback)
	var amazon_dieback = ClimateTippingPoint.new("amazon_dieback", "Dieback del Amazonas")
	amazon_dieback.threshold = 40.0  # % de pérdida de bosque
	amazon_dieback.current_value = 20.0  # Estado actual (2024)
	amazon_dieback.description = "Transformación de selva a sabana, pérdida masiva de carbono"
	amazon_dieback.scientific_evidence = "Deforestación y sequías aumentando"
	amazon_dieback.estimated_activation_year = 2035
	amazon_dieback.cascade_effects = {
		"global_temperature": 0.4,
		"rainfall_patterns": 0.8,
		"biodiversity": 0.9
	}
	amazon_dieback.social_impacts = {
		"food_security": 0.8,
		"water_scarcity": 0.7,
		"conflict_risk": 0.6
	}
	tipping_points["amazon_dieback"] = amazon_dieback
	
	# 6. Arrecifes de Coral
	var coral_reefs = ClimateTippingPoint.new("coral_reefs", "Colapso de Arrecifes de Coral")
	coral_reefs.threshold = 1.5  # °C
	coral_reefs.current_value = global_temperature
	coral_reefs.description = "Blanqueamiento masivo y muerte de corales globales"
	coral_reefs.scientific_evidence = "Eventos de blanqueamiento masivos desde 2016"
	coral_reefs.estimated_activation_year = 2030
	coral_reefs.cascade_effects = {
		"marine_ecosystems": 0.9,
		"fisheries": 1.0
	}
	coral_reefs.social_impacts = {
		"food_security": 0.6,
		"economic_loss": 0.8
	}
	tipping_points["coral_reefs"] = coral_reefs
	
	# 7. Monzones
	var monsoons = ClimateTippingPoint.new("monsoons", "Colapso de Sistemas Monzónicos")
	monsoons.threshold = 2.5  # °C
	monsoons.current_value = global_temperature
	monsoons.description = "Alteración irreversible de patrones de lluvia monzónica"
	monsoons.scientific_evidence = "Variabilidad aumentando"
	monsoons.estimated_activation_year = 2035
	monsoons.cascade_effects = {
		"food_security": 1.0,
		"water_scarcity": 0.9
	}
	monsoons.social_impacts = {
		"food_security": 0.9,
		"water_scarcity": 0.9,
		"conflict_risk": 0.8
	}
	tipping_points["monsoons"] = monsoons
	
	# 8. Bosque Boreal (Taiga)
	var boreal_forest = ClimateTippingPoint.new("boreal_forest", "Colapso del Bosque Boreal")
	boreal_forest.threshold = 2.0  # °C
	boreal_forest.current_value = global_temperature
	boreal_forest.description = "Transformación de taiga en praderas, liberación masiva de carbono"
	boreal_forest.scientific_evidence = "Incendios y sequías aumentando en latitudes boreales"
	boreal_forest.estimated_activation_year = 2034
	boreal_forest.cascade_effects = {
		"global_temperature": 0.5,
		"permafrost": 0.7,  # Afecta permafrost
		"carbon_release": 1.0
	}
	boreal_forest.social_impacts = {
		"food_security": 0.5,
		"infrastructure_loss": 0.6,
		"economic_loss": 0.7
	}
	tipping_points["boreal_forest"] = boreal_forest
	
	# 9. Hielo de la Antártida Oriental
	var east_antarctica_ice = ClimateTippingPoint.new("east_antarctica_ice", "Hielo de la Antártida Oriental")
	east_antarctica_ice.threshold = 3.0  # °C (más resistente que la occidental)
	east_antarctica_ice.current_value = global_temperature
	east_antarctica_ice.description = "Colapso de glaciares de la Antártida Oriental (+5m nivel del mar)"
	east_antarctica_ice.scientific_evidence = "Inestabilidad detectada en glaciares clave"
	east_antarctica_ice.estimated_activation_year = 2040
	east_antarctica_ice.cascade_effects = {
		"sea_level": 1.0,
		"ocean_circulation": 0.5,
		"antarctica_ice": 0.6  # Afecta a la Antártida Occidental
	}
	east_antarctica_ice.social_impacts = {
		"displacement": 0.95,
		"economic_loss": 0.9,
		"infrastructure_loss": 0.85
	}
	tipping_points["east_antarctica_ice"] = east_antarctica_ice

func initialize_real_ecosystems():
	"""Inicializa ecosistemas reales del planeta"""
	
	# Amazonas
	var amazon = RealEcosystem.new("amazon", "Amazonas")
	amazon.eco_type = RealEcosystem.EcosystemType.RAINFOREST
	amazon.location_description = "Cuenca del Amazonas, Sudamérica"
	amazon.health = 75.0  # Estado 2024
	amazon.baseline_health = 85.0
	amazon.carbon_storage = 150.0  # Gt CO2
	amazon.scientific_status = "Degradación acelerada, riesgo de dieback"
	amazon.tipping_point = tipping_points["amazon_dieback"]
	amazon.tipping_point_id = "amazon_dieback"
	ecosystems["amazon"] = amazon
	
	# AMOC (Corriente del Atlántico)
	var amoc_eco = RealEcosystem.new("amoc", "Circulación Atlántica (AMOC)")
	amoc_eco.eco_type = RealEcosystem.EcosystemType.OCEAN_CURRENT
	amoc_eco.location_description = "Océano Atlántico Norte"
	amoc_eco.health = 85.0
	amoc_eco.scientific_status = "Debilitamiento observado desde 2004"
	amoc_eco.tipping_point = tipping_points["amoc"]
	amoc_eco.tipping_point_id = "amoc"
	ecosystems["amoc"] = amoc_eco
	
	# Hielo de Groenlandia
	var greenland = RealEcosystem.new("greenland", "Hielo de Groenlandia")
	greenland.eco_type = RealEcosystem.EcosystemType.POLAR_ICE
	greenland.location_description = "Groenlandia"
	greenland.health = 80.0
	greenland.scientific_status = "Pérdida acelerada de masa"
	greenland.tipping_point = tipping_points["greenland_ice"]
	greenland.tipping_point_id = "greenland_ice"
	ecosystems["greenland"] = greenland
	
	# Permafrost Siberiano
	var siberian_permafrost = RealEcosystem.new("siberian_permafrost", "Permafrost Siberiano")
	siberian_permafrost.eco_type = RealEcosystem.EcosystemType.PERMAFROST
	siberian_permafrost.location_description = "Siberia, Rusia"
	siberian_permafrost.health = 70.0
	siberian_permafrost.carbon_storage = 1400.0  # Gt CO2 equivalente
	siberian_permafrost.scientific_status = "Descongelamiento acelerado"
	siberian_permafrost.tipping_point = tipping_points["permafrost"]
	siberian_permafrost.tipping_point_id = "permafrost"
	ecosystems["siberian_permafrost"] = siberian_permafrost
	
	# Arrecifes de Coral
	var coral = RealEcosystem.new("coral_reefs", "Arrecifes de Coral Globales")
	coral.eco_type = RealEcosystem.EcosystemType.CORAL_REEF
	coral.location_description = "Océanos tropicales y subtropicales"
	coral.health = 50.0  # Estado crítico 2024
	coral.scientific_status = "Blanqueamiento masivo en curso"
	coral.tipping_point = tipping_points["coral_reefs"]
	coral.tipping_point_id = "coral_reefs"
	ecosystems["coral_reefs"] = coral
	
	# Sistema Monzónico
	var monsoon = RealEcosystem.new("monsoon", "Sistemas Monzónicos")
	monsoon.eco_type = RealEcosystem.EcosystemType.MONSOON_SYSTEM
	monsoon.location_description = "Asia, África, América"
	monsoon.health = 75.0
	monsoon.scientific_status = "Variabilidad aumentando"
	monsoon.tipping_point = tipping_points["monsoons"]
	monsoon.tipping_point_id = "monsoons"
	ecosystems["monsoon"] = monsoon

func start_monthly_updates():
	"""Inicia actualizaciones mensuales del sistema climático"""
	var timer = Timer.new()
	timer.wait_time = 60.0  # 1 minuto = 1 mes en el juego
	timer.autostart = true
	timer.timeout.connect(_update_monthly)
	add_child(timer)

func _update_monthly():
	"""Actualiza el sistema climático mensualmente"""
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	
	# Actualizar temperatura global (basado en emisiones)
	_update_global_temperature()
	
	# Actualizar ecosistemas
	for eco_id in ecosystems:
		var eco = ecosystems[eco_id]
		var human_impact = _calculate_human_impact()
		eco.update_monthly(global_temperature, human_impact, current_year)
	
	# Verificar tipping points
	_check_tipping_points()
	
	# Calcular efectos sociales
	_calculate_social_impacts()
	
	# Emitir señal
	climate_update_complete.emit()

func _update_global_temperature():
	"""Actualiza la temperatura global basada en emisiones y feedbacks"""
	# Incremento base por emisiones
	var emission_increase = (emissions_rate - 1.0) * 0.01  # 0.01°C por mes si emisiones aumentan
	
	# Feedback de ecosistemas
	var feedback_increase = 0.0
	for eco_id in ecosystems:
		var eco = ecosystems[eco_id]
		feedback_increase += eco.global_temperature_impact * 0.1  # Feedback acumulativo
	
	global_temperature += emission_increase + feedback_increase
	
	# Actualizar CO2 (simplificado)
	co2_ppm += emissions_rate * 0.5  # ppm por mes

func _calculate_human_impact() -> float:
	"""Calcula el impacto humano global (0-1)"""
	# Basado en poder de los Cartógrafos y actividad económica
	# Conectar con GameClient para obtener valores reales
	return 0.65  # Placeholder

func _check_tipping_points():
	"""Verifica si algún tipping point se ha activado"""
	for tip_id in tipping_points:
		var tip = tipping_points[tip_id]
		
		# Actualizar valor del tipping point basado en ecosistema asociado
		if tip_id in ecosystems:
			var eco = ecosystems[tip_id]
			if tip_id == "greenland_ice" or tip_id == "antarctica_ice" or tip_id == "permafrost":
				# Basado en temperatura
				tip.update_value(global_temperature)
			else:
				# Basado en salud del ecosistema
				tip.update_value(100.0 - eco.health)
		
		# Si se activa, aplicar efectos en cascada
		if tip.is_activated and not tip.activation_date.is_empty():
			_apply_cascade_effects(tip_id)

func _apply_cascade_effects(activated_tip_id: String):
	"""Aplica efectos en cascada cuando se activa un tipping point"""
	var activated_tip = tipping_points[activated_tip_id]
	
	for affected_tip_id in activated_tip.cascade_effects:
		var multiplier = activated_tip.cascade_effects[affected_tip_id]
		
		if affected_tip_id in tipping_points:
			var affected_tip = tipping_points[affected_tip_id]
			# Acelerar degradación del tipping point afectado
			affected_tip.activation_probability += multiplier * 0.2
			cascade_effect_triggered.emit(activated_tip_id, affected_tip_id)
		
		# Si afecta temperatura global directamente
		if affected_tip_id == "global_temperature":
			global_temperature += multiplier * 0.2
		
		# Si afecta ecosistemas
		if affected_tip_id in ecosystems:
			var eco = ecosystems[affected_tip_id]
			eco.health -= multiplier * 5.0  # Degradación inmediata

func _calculate_social_impacts():
	"""Calcula impactos sociales basados en estado de ecosistemas"""
	# Resetear impactos
	for key in social_impacts:
		social_impacts[key] = 0.0
	
	# Acumular impactos de cada ecosistema
	for eco_id in ecosystems:
		var eco = ecosystems[eco_id]
		var eco_impact = eco.get_social_impact()
		
		social_impacts.food_crisis = max(social_impacts.food_crisis, eco_impact.food_security)
		social_impacts.water_crisis = max(social_impacts.water_crisis, eco_impact.water_scarcity)
		social_impacts.refugee_crisis += eco_impact.displacement * 0.3
		social_impacts.economic_collapse += eco_impact.economic_loss * 0.2
		social_impacts.social_unrest += eco_impact.conflict_risk * 0.4
	
	# Limitar valores
	for key in social_impacts:
		social_impacts[key] = clamp(social_impacts[key], 0.0, 1.0)
	
	# Emitir señales de crisis si superan umbrales
	if social_impacts.food_crisis > 0.7:
		social_crisis_triggered.emit("famine", social_impacts.food_crisis)
	
	if social_impacts.water_crisis > 0.7:
		social_crisis_triggered.emit("water_scarcity", social_impacts.water_crisis)
	
	if social_impacts.social_unrest > 0.6:
		social_crisis_triggered.emit("social_unrest", social_impacts.social_unrest)
	
	if social_impacts.political_violence > 0.5:
		social_crisis_triggered.emit("political_violence", social_impacts.political_violence)

func get_temperature_trend() -> String:
	"""Retorna tendencia de temperatura"""
	if global_temperature < 1.2:
		return "ESTABLE"
	elif global_temperature < 1.5:
		return "AUMENTANDO"
	elif global_temperature < 2.0:
		return "ACELERANDO"
	else:
		return "CRÍTICO"

func get_time_until_collapse() -> int:
	"""Calcula años hasta colapso (2035 es el objetivo)"""
	return 2035 - current_year










