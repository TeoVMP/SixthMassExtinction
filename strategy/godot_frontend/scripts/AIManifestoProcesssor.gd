extends Node
class_name AIManifestoProcessor

# Señales
signal manifesto_analyzed(analysis_result: Dictionary)
signal analysis_error(error_message: String)

# Configuración
var model_loaded: bool = false
var processing: bool = false

func _ready():
	print("🧠 AIManifestoProcessor iniciado")
	model_loaded = true

func analyze_manifesto(manifesto_text: String, player_context: Dictionary = {}):
	"""Analiza un manifiesto usando IA"""
	print("🔍 [AIManifestoProcessor] analyze_manifesto llamado")
	print("   Texto recibido: ", manifesto_text.substr(0, 50) + "...")
	print("   Contexto: ", player_context)
	
	if processing:
		print("⚠️ [AIManifestoProcessor] Ya procesando, rechazando")
		analysis_error.emit("Ya se está procesando un manifiesto")
		return {}
	
	if not model_loaded:
		print("⚠️ [AIManifestoProcessor] Modelo no cargado, pero continuando...")
		# No retornar null, continuar con simulación
	
	processing = true
	print("📊 [AIManifestoProcessor] Analizando manifiesto con IA...")
	
	# Simular procesamiento
	await get_tree().create_timer(1.0 + randf() * 2.0).timeout
	
	# Análisis simulado
	var analysis = _simulate_ai_analysis(manifesto_text, player_context)
	print("✅ [AIManifestoProcessor] Análisis generado: ", analysis)
	
	processing = false
	manifesto_analyzed.emit(analysis)
	print("📤 [AIManifestoProcessor] Retornando análisis")
	return analysis

func _simulate_ai_analysis(text: String, _context: Dictionary) -> Dictionary:
	"""Análisis simulado mejorado con detección inteligente"""
	var word_count = text.split(" ").size()
	var char_count = text.length()
	var lower_text = text.to_lower()
	
	# ============================================
	# DETECCIÓN MEJORADA DE TEMAS
	# ============================================
	var primary_themes = []
	
	# Anti-Cartógrafos (múltiples variantes) - solo añadir una vez
	var has_anti_cartographer = false
	if lower_text.find("cartógrafo") != -1 or lower_text.find("cartografo") != -1 or \
	   lower_text.find("sabandija") != -1 or lower_text.find("destruir") != -1:
		has_anti_cartographer = true
		primary_themes.append("anti_cartographer")
	
	# Revolución - solo añadir una vez
	var has_revolution = false
	if lower_text.find("revolución") != -1 or lower_text.find("revolucion") != -1 or \
	   lower_text.find("compañero") != -1 or lower_text.find("companero") != -1 or \
	   lower_text.find("persistir") != -1 or lower_text.find("lucha") != -1:
		has_revolution = true
		primary_themes.append("revolution")
	
	# Ecología
	if lower_text.find("ecolog") != -1 or lower_text.find("ecológico") != -1:
		primary_themes.append("ecology")
	if lower_text.find("naturaleza") != -1 or lower_text.find("ambiente") != -1:
		primary_themes.append("ecology")
	
	# Justicia
	if lower_text.find("justicia") != -1 or lower_text.find("derecho") != -1:
		primary_themes.append("justice")
	if lower_text.find("humanidad") != -1 and primary_themes.has("revolution"):
		primary_themes.append("justice")
	
	# ============================================
	# ANÁLISIS EMOCIONAL MEJORADO
	# ============================================
	var emotional_tone = "neutral"
	var emotional_score = 0.0
	
	# Detectar ira/determinación
	var exclamation_count = text.count("!")
	var anger_words = ["abajo", "destruir", "sabandija", "nunca", "siempre"]
	var hope_words = ["triunfar", "debe", "persistir", "humanidad", "final"]
	
	var anger_score = 0.0
	var hope_score = 0.0
	
	for word in anger_words:
		if lower_text.find(word) != -1:
			anger_score += 1.0
	
	for word in hope_words:
		if lower_text.find(word) != -1:
			hope_score += 1.0
	
	if anger_score > hope_score and anger_score > 0:
		emotional_tone = "ira"
		emotional_score = 0.7
	elif hope_score > anger_score and hope_score > 0:
		emotional_tone = "determinacion"
		emotional_score = 0.8
	elif exclamation_count >= 2:
		emotional_tone = "determinacion"
		emotional_score = 0.6
	
	# Eliminar duplicados de temas
	var unique_themes = []
	for theme in primary_themes:
		if not unique_themes.has(theme):
			unique_themes.append(theme)
	primary_themes = unique_themes
	
	# ============================================
	# CALIDAD RETÓRICA
	# ============================================
	var rhetorical_quality = 5.0
	
	# Base por longitud
	if word_count > 30:
		rhetorical_quality += 1.0
	if word_count > 50:
		rhetorical_quality += 1.0
	
	# Bonus por pasión (exclamaciones)
	rhetorical_quality += min(2.0, exclamation_count * 0.5)
	
	# Bonus por temas múltiples
	rhetorical_quality += primary_themes.size() * 0.5
	
	# Bonus por palabras poderosas
	if lower_text.find("debe") != -1 or lower_text.find("triunfar") != -1:
		rhetorical_quality += 0.5
	
	rhetorical_quality = min(10.0, rhetorical_quality)
	
	# ============================================
	# PODER DE PERSUASIÓN
	# ============================================
	var persuasion_power = rhetorical_quality * 0.8
	
	# Bonus por tono emocional fuerte
	if emotional_tone == "determinacion" or emotional_tone == "ira":
		persuasion_power += 1.5
	
	# Bonus por llamados a la acción
	if lower_text.find("debe") != -1 or lower_text.find("debemos") != -1:
		persuasion_power += 1.0
	
	persuasion_power = min(10.0, persuasion_power)
	
	# ============================================
	# RIESGO DE REPRESIÓN
	# ============================================
	var risk_of_repression = "medium"
	if primary_themes.has("anti_cartographer"):
		risk_of_repression = "high"
		if anger_score > 2 or exclamation_count > 3:
			risk_of_repression = "extreme"
	
	# ============================================
	# AUDIENCIA OBJETIVO
	# ============================================
	var target_audience = []
	if primary_themes.has("revolution"):
		target_audience.append("workers")
		target_audience.append("youth")
	if primary_themes.has("ecology"):
		target_audience.append("intellectuals")
	if primary_themes.has("justice"):
		target_audience.append("elders")
	
	if target_audience.is_empty():
		target_audience.append("general_public")
	
	# ============================================
	# POTENCIAL VIRAL
	# ============================================
	var potential_virality = persuasion_power * 0.9
	if exclamation_count >= 2:
		potential_virality += 1.0
	if primary_themes.size() >= 2:
		potential_virality += 0.5
	potential_virality = min(10.0, potential_virality)
	
	# ============================================
	# RESUMEN Y FORTALEZAS/DEBILIDADES
	# ============================================
	var summary = "Manifiesto "
	if emotional_tone == "ira":
		summary += "apasionado y combativo"
	elif emotional_tone == "determinacion":
		summary += "determinado y motivacional"
	else:
		summary += "moderado"
	
	if primary_themes.size() > 0:
		summary += " que aborda temas de " + primary_themes[0].replace("_", " ")
	
	var strengths = []
	if rhetorical_quality >= 7:
		strengths.append("Alta calidad retórica")
	if persuasion_power >= 7:
		strengths.append("Fuerte poder de persuasión")
	if exclamation_count >= 2:
		strengths.append("Tono apasionado y motivacional")
	if primary_themes.size() >= 2:
		strengths.append("Aborda múltiples temas relevantes")
	
	var weaknesses = []
	if word_count < 30:
		weaknesses.append("Texto demasiado corto")
	if primary_themes.is_empty():
		weaknesses.append("Falta de temas claros")
	if risk_of_repression == "extreme":
		weaknesses.append("Alto riesgo de represión")
	
	# ============================================
	# RETORNAR ANÁLISIS COMPLETO
	# ============================================
	return {
		"success": true,
		"manifesto_id": "ai_" + str(Time.get_unix_time_from_system()),
		"analysis": {
			"emotional_tone": emotional_tone,
			"primary_themes": primary_themes,
			"rhetorical_quality": rhetorical_quality,
			"persuasion_power": persuasion_power,
			"risk_of_repression": risk_of_repression,
			"target_audience": target_audience,
			"potential_virality": potential_virality,
			"summary": summary,
			"strengths": strengths,
			"weaknesses": weaknesses,
			"word_count": word_count,
			"char_count": char_count,
			"ai_model_used": "simulated_v2_improved",
			"processing_time_ms": 1500 + randi() % 1000
		}
	}

func _generate_recommendations(topics: Array, sentiment: float) -> Array:
	"""Genera recomendaciones"""
	var recommendations = []
	
	if topics.has("anti_cartographer"):
		recommendations.append("🔴 Alto riesgo: Los Cartógrafos pueden detectar este manifiesto")
	
	if sentiment > 0.5:
		recommendations.append("✅ Excelente tono motivacional")
	elif sentiment < -0.5:
		recommendations.append("⚠️ El tono es muy negativo")
	
	return recommendations

func _predict_impact(word_count: int, topics: Array, sentiment: float) -> Dictionary:
	"""Predice impacto"""
	var base_impact = min(word_count / 50.0, 10.0)
	var topic_modifier = 1.0
	
	var modifiers = {
		"anti_cartographer": 1.5,
		"revolution": 1.3,
		"ecology": 1.2,
		"justice": 1.1
	}
	
	for topic in topics:
		if modifiers.has(topic):
			topic_modifier *= modifiers[topic]
	
	var sentiment_modifier = 1.0 + (sentiment * 0.5)
	var total_impact = base_impact * topic_modifier * sentiment_modifier
	
	return {
		"estimated_reach": int(total_impact * 100),
		"risk_level": "high" if topics.has("anti_cartographer") else "medium",
		"potential_allies": ["eco_activists", "union_workers"] if topics.has("ecology") else ["general_public"],
		"estimated_sanity_impact": int((sentiment + 1) * 5),
		"estimated_reputation_impact": {
			"pe": int(total_impact * 2),
			"eo": int(total_impact * -1 if topics.has("anti_cartographer") else total_impact * 0.5)
		}
	}

func load_model(_model_path: String = ""):
	"""Carga modelo"""
	print("🤖 Cargando modelo de IA...")
	model_loaded = true
	return true
