# RealEcosystem.gd
# Ecosistemas reales del planeta basados en la realidad física, no política
# Basado en datos científicos de 2024-2025

extends RefCounted
class_name RealEcosystem

# Identificador y nombre
var eco_id: String = ""
var name: String = ""
var location_description: String = ""  # Descripción geográfica real

# Tipo de ecosistema (basado en realidad física)
enum EcosystemType {
	POLAR_ICE,           # Hielo polar (Ártico, Antártida)
	OCEAN_CURRENT,       # Corrientes oceánicas (AMOC, etc.)
	RAINFOREST,          # Selvas tropicales
	CORAL_REEF,          # Arrecifes de coral
	PERMAFROST,          # Permafrost (Siberia, Canadá, etc.)
	MONSOON_SYSTEM,      # Sistemas monzónicos
	FOREST_BIOME,        # Biomas forestales
	GRASSLAND,           # Praderas y sabanas
	WETLAND,             # Humedales
	DESERT               # Desiertos
}

var eco_type: EcosystemType = EcosystemType.RAINFOREST

# Estado del ecosistema
var health: float = 100.0  # Salud general (0-100)
var integrity: float = 100.0  # Integridad del sistema
var carbon_storage: float = 0.0  # Almacenamiento de carbono (Gt CO2)
var biodiversity_index: float = 100.0  # Índice de biodiversidad

# Tipping point asociado
var tipping_point: ClimateTippingPoint = null
var tipping_point_id: String = ""

# Degradación
var degradation_rate: float = 0.0  # Tasa de degradación mensual
var human_impact_factor: float = 0.0  # Factor de impacto humano (0-1)

# Efectos en el clima global
var climate_feedback_strength: float = 0.0  # Fuerza del feedback climático (0-1)
var global_temperature_impact: float = 0.0  # Impacto en temperatura global (°C)

# Datos científicos reales (2024)
var baseline_year: int = 2024
var baseline_health: float = 100.0
var scientific_status: String = ""  # Estado según ciencia actual

func _init(id: String = "", eco_name: String = ""):
	eco_id = id
	name = eco_name
	baseline_year = 2024
	baseline_health = 100.0

func update_monthly(global_temperature: float, human_impact: float, time_year: int):
	"""Actualiza el ecosistema mensualmente basado en temperatura global e impacto humano"""
	human_impact_factor = human_impact
	
	# Calcular degradación basada en temperatura y actividad humana
	var temp_factor = max(0, (global_temperature - 1.0) / 2.0)  # Factor de temperatura
	degradation_rate = (temp_factor * 0.5) + (human_impact * 0.5)
	
	# Aplicar degradación
	health = max(0, health - degradation_rate)
	integrity = max(0, integrity - degradation_rate * 0.8)
	biodiversity_index = max(0, biodiversity_index - degradation_rate * 0.6)
	
	# Si hay tipping point, actualizarlo
	if tipping_point:
		_update_tipping_point(health, time_year)
	
	# Calcular feedback climático
	_calculate_climate_feedback()

func _update_tipping_point(health_value: float, current_year: int):
	"""Actualiza el tipping point asociado"""
	if not tipping_point:
		return
	
	# El tipping point se activa cuando la salud cae por debajo del threshold
	var threshold_health = tipping_point.threshold
	tipping_point.update_value(100.0 - health_value)  # Invertir: menos salud = más cerca del threshold
	
	# Si se activa, aplicar efectos en cascada
	if tipping_point.is_activated and not tipping_point.activation_date.is_empty():
		_apply_cascade_effects()

func _calculate_climate_feedback():
	"""Calcula el feedback climático de este ecosistema"""
	# Ecosistemas críticos tienen mayor feedback
	if health < 30:
		climate_feedback_strength = 1.0 - (health / 30.0)
		global_temperature_impact = climate_feedback_strength * 0.5  # Puede aumentar temp global hasta 0.5°C
	elif health < 50:
		climate_feedback_strength = (50.0 - health) / 20.0 * 0.5
		global_temperature_impact = climate_feedback_strength * 0.2
	else:
		climate_feedback_strength = 0.0
		global_temperature_impact = 0.0

func _apply_cascade_effects():
	"""Aplica efectos en cascada cuando se activa el tipping point"""
	if not tipping_point or not tipping_point.is_activated:
		return
	
	# Los efectos en cascada se manejan en el ClimateSystem
	print("🌊 Efectos en cascada activados para: ", name)

func get_status() -> String:
	if health >= 80:
		return "SALUDABLE"
	elif health >= 60:
		return "DEGRADADO"
	elif health >= 40:
		return "CRÍTICO"
	elif health >= 20:
		return "COLAPSANDO"
	else:
		return "COLAPSADO"

func get_social_impact() -> Dictionary:
	"""Retorna el impacto social de la degradación de este ecosistema"""
	var impact = {
		"food_security": 0.0,      # Seguridad alimentaria (0-1, 1 = crisis total)
		"water_scarcity": 0.0,     # Escasez de agua
		"displacement": 0.0,       # Desplazamiento de población
		"economic_loss": 0.0,     # Pérdidas económicas
		"conflict_risk": 0.0       # Riesgo de conflicto
	}
	
	# Calcular impactos basados en tipo de ecosistema y salud
	match eco_type:
		EcosystemType.RAINFOREST, EcosystemType.FOREST_BIOME:
			# Pérdida de lluvias, sequías
			impact.food_security = (100.0 - health) / 100.0 * 0.7
			impact.water_scarcity = (100.0 - health) / 100.0 * 0.8
			impact.conflict_risk = (100.0 - health) / 100.0 * 0.6
		
		EcosystemType.CORAL_REEF:
			# Pérdida de pesca, turismo
			impact.food_security = (100.0 - health) / 100.0 * 0.5
			impact.economic_loss = (100.0 - health) / 100.0 * 0.9
		
		EcosystemType.POLAR_ICE:
			# Aumento del nivel del mar, pérdida de hábitat
			impact.displacement = (100.0 - health) / 100.0 * 0.9
			impact.economic_loss = (100.0 - health) / 100.0 * 0.7
		
		EcosystemType.PERMAFROST:
			# Liberación de metano, cambio de patrones climáticos
			impact.food_security = (100.0 - health) / 100.0 * 0.6
			impact.conflict_risk = (100.0 - health) / 100.0 * 0.4
		
		EcosystemType.OCEAN_CURRENT:
			# Cambios en patrones climáticos globales
			impact.food_security = (100.0 - health) / 100.0 * 0.8
			impact.water_scarcity = (100.0 - health) / 100.0 * 0.7
			impact.conflict_risk = (100.0 - health) / 100.0 * 0.7
		
		_:
			impact.food_security = (100.0 - health) / 100.0 * 0.5
			impact.conflict_risk = (100.0 - health) / 100.0 * 0.5
	
	# Si el tipping point está activado, multiplicar impactos
	if tipping_point and tipping_point.is_activated:
		for key in impact:
			impact[key] = min(1.0, impact[key] * 1.5)
	
	return impact

