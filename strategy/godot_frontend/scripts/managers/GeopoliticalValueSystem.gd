# GeopoliticalValueSystem.gd
# Sistema que calcula valores geopolíticos y ecológicos de regiones y estados
# Según el contexto del protagonista (viajero del tiempo desde 2055)

extends Node
class_name GeopoliticalValueSystem

# Valores geopolíticos por región (0-100)
# Basados en: influencia global, poder económico, importancia estratégica
var geopolitical_values = {
	"africa_norte": 35.0,
	"africa_oriental": 30.0,
	"africa_occidental": 40.0,
	"africa_central": 25.0,
	"sudafrica": 45.0,
	"sa": 50.0,
	"ca": 30.0,
	"eo": 85.0,  # Europa Occidental - alta influencia
	"ee": 60.0,  # Europa Oriental - media-alta
	"eu": 95.0,  # Estados Unidos - máxima influencia
	"ch": 90.0,  # China - máxima influencia
	"ru": 70.0,  # Rusia - alta influencia
	"as": 55.0,
	"seasia": 50.0,
	"mena": 65.0,  # Medio Oriente - alta importancia estratégica
	"oceania": 40.0
}

# Valores ecológicos por región (0-100)
# Basados en: ecosistemas críticos, biodiversidad, puntos de no retorno
var ecological_values = {
	"africa_norte": 20.0,  # Desierto, pero importante para migración climática
	"africa_oriental": 60.0,  # Ecosistemas diversos, cuenca del Congo
	"africa_occidental": 50.0,
	"africa_central": 80.0,  # Cuenca del Congo - crítica
	"sudafrica": 55.0,
	"sa": 90.0,  # Amazonas - crítica
	"ca": 70.0,  # Arrecifes mesoamericanos
	"eo": 40.0,  # Ecosistemas degradados pero importantes
	"ee": 45.0,
	"eu": 60.0,  # Varios ecosistemas importantes
	"ch": 50.0,  # Ecosistemas diversos pero degradados
	"ru": 70.0,  # Ártico - crítico
	"as": 65.0,  # Himalayas, biodiversidad
	"seasia": 75.0,  # Bosques tropicales, arrecifes
	"mena": 25.0,  # Desierto principalmente
	"oceania": 85.0  # Gran Barrera de Coral - crítica
}

# Valores geopolíticos por estado de EEUU
var usa_geopolitical_values = {
	"california": 95.0,  # Máxima importancia económica y tecnológica
	"texas": 90.0,  # Energía, economía
	"new_york": 95.0,  # Finanzas globales
	"florida": 75.0,
	"illinois": 80.0,
	"washington": 85.0,  # Tecnología
	"massachusetts": 85.0,  # Educación, tecnología
	"pennsylvania": 70.0,
	"ohio": 70.0,
	"georgia": 65.0,
	"north_carolina": 65.0,
	"virginia": 75.0,  # Gobierno federal
	"colorado": 60.0,
	"arizona": 55.0,
	"oregon": 55.0,
	"alaska": 70.0,  # Recursos, posición estratégica
	"hawaii": 65.0  # Posición estratégica en el Pacífico
}

# Valores ecológicos por estado de EEUU
var usa_ecological_values = {
	"california": 85.0,  # Biodiversidad, ecosistemas diversos
	"texas": 60.0,
	"florida": 90.0,  # Everglades, arrecifes
	"alaska": 95.0,  # Ártico, ecosistemas prístinos
	"hawaii": 90.0,  # Ecosistemas únicos, arrecifes
	"oregon": 80.0,  # Bosques, costa
	"washington": 80.0,  # Bosques, ecosistemas marinos
	"colorado": 75.0,  # Montañas, ecosistemas alpinos
	"montana": 85.0,  # Ecosistemas prístinos
	"wyoming": 80.0,
	"idaho": 75.0,
	"utah": 70.0,
	"nevada": 50.0,
	"new_mexico": 65.0,
	"minnesota": 70.0,  # Lagos, ecosistemas acuáticos
	"maine": 75.0,  # Costa, bosques
	"vermont": 70.0,
	"new_york": 50.0,
	"illinois": 40.0,
	"pennsylvania": 45.0,
	"ohio": 40.0,
	"georgia": 60.0,
	"north_carolina": 70.0,  # Costa, bosques
	"virginia": 60.0,
	"massachusetts": 55.0
}

# Valores geopolíticos por provincia de China
var china_geopolitical_values = {
	"guangdong": 90.0,  # Economía, manufactura
	"shandong": 75.0,
	"jiangsu": 85.0,
	"zhejiang": 80.0,
	"beijing": 95.0,  # Capital, política
	"shanghai": 95.0,  # Finanzas globales
	"henan": 70.0,
	"sichuan": 75.0,
	"hubei": 70.0,
	"hunan": 65.0,
	"anhui": 65.0,
	"fujian": 70.0,
	"hebei": 70.0,
	"liaoning": 75.0,  # Industria pesada
	"shanxi": 60.0,
	"shaanxi": 65.0,
	"jiangxi": 60.0,
	"guangxi": 60.0,
	"yunnan": 55.0,
	"chongqing": 70.0,
	"tianjin": 80.0
}

# Valores ecológicos por provincia de China
var china_ecological_values = {
	"guangdong": 60.0,
	"shandong": 50.0,
	"jiangsu": 45.0,
	"zhejiang": 55.0,
	"henan": 40.0,
	"sichuan": 80.0,  # Biodiversidad, ecosistemas montañosos
	"hubei": 55.0,
	"hunan": 60.0,
	"anhui": 50.0,
	"fujian": 65.0,  # Costa, biodiversidad
	"guangxi": 70.0,  # Biodiversidad
	"yunnan": 85.0,  # Alta biodiversidad, ecosistemas únicos
	"heilongjiang": 70.0,  # Bosques, ecosistemas templados
	"jilin": 65.0,
	"inner_mongolia": 60.0,  # Ecosistemas de estepa
	"xinjiang": 55.0,
	"tibet": 90.0,  # Himalayas - crítico
	"qinghai": 85.0,  # Meseta tibetana
	"gansu": 50.0,
	"hainan": 75.0  # Ecosistemas tropicales
}

func _ready():
	print("🌍 GeopoliticalValueSystem iniciado")

func get_geopolitical_value(region_code: String, country_code: String = "", state_code: String = "") -> float:
	"""Obtiene valor geopolítico de una región/país/estado"""
	if state_code != "":
		if region_code == "eu" and state_code in usa_geopolitical_values:
			return usa_geopolitical_values[state_code]
		elif region_code == "ch" and state_code in china_geopolitical_values:
			return china_geopolitical_values[state_code]
	
	if region_code in geopolitical_values:
		return geopolitical_values[region_code]
	
	return 30.0  # Valor por defecto

func get_ecological_value(region_code: String, country_code: String = "", state_code: String = "") -> float:
	"""Obtiene valor ecológico de una región/país/estado"""
	if state_code != "":
		if region_code == "eu" and state_code in usa_ecological_values:
			return usa_ecological_values[state_code]
		elif region_code == "ch" and state_code in china_ecological_values:
			return china_ecological_values[state_code]
	
	if region_code in ecological_values:
		return ecological_values[region_code]
	
	return 30.0  # Valor por defecto

func get_combined_value(region_code: String, country_code: String = "", state_code: String = "") -> float:
	"""Obtiene valor combinado (geopolítico + ecológico) / 2"""
	var geo = get_geopolitical_value(region_code, country_code, state_code)
	var eco = get_ecological_value(region_code, country_code, state_code)
	return (geo + eco) / 2.0

func get_mission_impact_multiplier(region_code: String, country_code: String = "", state_code: String = "") -> float:
	"""Retorna multiplicador de impacto para misiones (0.5-2.0)
	Regiones/estados más importantes dan más impacto climático"""
	var combined = get_combined_value(region_code, country_code, state_code)
	# Normalizar a rango 0.5-2.0
	# 30 = 0.5x, 100 = 2.0x
	return 0.5 + (combined / 100.0) * 1.5

func get_value_report(region_code: String, country_code: String = "", state_code: String = "") -> Dictionary:
	"""Genera reporte de valores para el jugador"""
	var geo = get_geopolitical_value(region_code, country_code, state_code)
	var eco = get_ecological_value(region_code, country_code, state_code)
	var combined = get_combined_value(region_code, country_code, state_code)
	var multiplier = get_mission_impact_multiplier(region_code, country_code, state_code)
	
	var geo_level = "Bajo"
	if geo >= 80:
		geo_level = "Muy Alto"
	elif geo >= 60:
		geo_level = "Alto"
	elif geo >= 40:
		geo_level = "Medio"
	
	var eco_level = "Bajo"
	if eco >= 80:
		eco_level = "Muy Alto"
	elif eco >= 60:
		eco_level = "Alto"
	elif eco >= 40:
		eco_level = "Medio"
	
	return {
		"geopolitical_value": geo,
		"geopolitical_level": geo_level,
		"ecological_value": eco,
		"ecological_level": eco_level,
		"combined_value": combined,
		"impact_multiplier": multiplier,
		"description": _generate_description(geo, eco, geo_level, eco_level)
	}

func _generate_description(geo: float, eco: float, geo_level: String, eco_level: String) -> String:
	"""Genera descripción narrativa de los valores"""
	var desc = ""
	
	if geo >= 80:
		desc += "Centro geopolítico de máxima importancia. Las acciones aquí tienen impacto global inmediato. "
	elif geo >= 60:
		desc += "Región de alta influencia geopolítica. Las acciones pueden influir en múltiples regiones. "
	else:
		desc += "Región de influencia geopolítica limitada. Las acciones tienen impacto principalmente local. "
	
	if eco >= 80:
		desc += "Ecosistema crítico para la estabilidad climática global. Protegerlo es esencial para prevenir colapsos. "
	elif eco >= 60:
		desc += "Ecosistema importante con alta biodiversidad. Su protección contribuye significativamente a la acción climática. "
	else:
		desc += "Ecosistema con importancia moderada. Su protección contribuye localmente a la acción climática. "
	
	return desc
















