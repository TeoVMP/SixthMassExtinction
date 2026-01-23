# ManifestoImpactSystem.gd
# Sistema que aplica efectos de gameplay basados en análisis de manifiestos
extends Node
class_name ManifestoImpactSystem

signal impact_applied(effects: Dictionary)
signal risk_triggered(risk_type: String, consequence: Dictionary)

# Referencias a sistemas del juego
var game_client: Node = null
var ecosystem_manager: Node = null
var reward_system: Node = null  # TippingPointRewardSystem

# Estado del sistema
var manifesto_history: Array = []
var cartographer_attention: float = 0.0  # 0-100
var political_power: float = 0.0  # Nuevo recurso

func _ready():
	print("🎯 ManifestoImpactSystem iniciado")

func set_game_client(client: Node):
	"""Establece referencia al GameClient"""
	game_client = client

func set_ecosystem_manager(manager: Node):
	"""Establece referencia al EcosystemManager"""
	ecosystem_manager = manager

func set_reward_system(system: Node):
	"""Establece referencia al TippingPointRewardSystem"""
	reward_system = system

func apply_manifesto_effects(analysis: Dictionary, manifesto_text: String) -> Dictionary:
	"""Aplica efectos de gameplay basados en el análisis del manifiesto"""
	print("🎯 [ManifestoImpactSystem] Aplicando efectos...")
	print("   Análisis recibido: ", analysis)
	
	if not analysis.has("analysis"):
		print("⚠️ [ManifestoImpactSystem] Análisis inválido, no tiene 'analysis'")
		return {}
	
	var ai_analysis = analysis.get("analysis", {})
	print("   AI Analysis: ", ai_analysis)
	
	var effects = _calculate_effects(ai_analysis, manifesto_text)
	print("   Efectos calculados: ", effects)
	
	# Aplicar efectos inmediatos
	_apply_immediate_effects(effects.get("immediate", []))
	
	# Programar efectos diferidos
	_schedule_delayed_effects(effects.get("delayed", []))
	
	# Evaluar riesgos
	_evaluate_risks(effects.get("risks", []))
	
	# Guardar en historial
	manifesto_history.append({
		"text": manifesto_text,
		"analysis": ai_analysis,
		"effects": effects,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	impact_applied.emit(effects)
	return effects

func _calculate_effects(analysis: Dictionary, _text: String) -> Dictionary:
	"""Calcula los efectos basados en el análisis"""
	var effects = {
		"immediate": [],
		"delayed": [],
		"risks": []
	}
	
	# Obtener métricas del análisis
	var rhetorical_quality = analysis.get("rhetorical_quality", 5.0)
	var persuasion_power = analysis.get("persuasion_power", 5.0)
	var risk_level = analysis.get("risk_of_repression", "medium")
	var emotional_tone = analysis.get("emotional_tone", "neutral")
	var themes = analysis.get("primary_themes", [])
	var virality = analysis.get("potential_virality", 5.0)
	
	# ============================================
	# EFECTOS POSITIVOS
	# ============================================
	
	# Bonus por prevenir tipping points
	var manifesto_bonus = 0.0
	var communication_bonus = 0.0
	if reward_system:
		manifesto_bonus = reward_system.get_manifesto_bonus()
		communication_bonus = reward_system.get_communication_bonus()
	
	# Aplicar bonus a calidad retórica y poder de persuasión
	rhetorical_quality = rhetorical_quality * (1.0 + manifesto_bonus)
	persuasion_power = persuasion_power * (1.0 + manifesto_bonus)
	
	# Poder Político (nuevo recurso) - con bonus
	var political_power_gain = int((rhetorical_quality + persuasion_power) * 1.5)
	if political_power_gain > 0:
		political_power += political_power_gain
		effects.immediate.append({
			"resource": "political_power",
			"change": "+" + str(political_power_gain),
			"reason": "Manifiesto efectivo inspira a las masas"
		})
	
	# Cordura (puede ser positiva o negativa)
	var sanity_change = 0
	if emotional_tone == "esperanza" or emotional_tone == "determinacion":
		sanity_change = int((persuasion_power / 10.0) * 8)  # +0 a +8
		effects.immediate.append({
			"resource": "sanity",
			"change": "+" + str(sanity_change),
			"reason": "Claridad de propósito restaura cordura"
		})
	elif emotional_tone == "ira" or emotional_tone == "miedo":
		sanity_change = -int((persuasion_power / 10.0) * 5)  # -0 a -5
		effects.immediate.append({
			"resource": "sanity",
			"change": str(sanity_change),
			"reason": "Emociones intensas agotan la mente"
		})
	
	# Reputación por región
	var reputation_effects = _calculate_reputation_effects(themes, rhetorical_quality, risk_level)
	for region_effect in reputation_effects:
		effects.immediate.append(region_effect)
	
	# ============================================
	# EFECTOS NEGATIVOS / RIESGOS
	# ============================================
	
	# Atención de los Cartógrafos
	if themes.has("anti_cartographer"):
		var attention_increase = int(persuasion_power * 2.0)
		cartographer_attention = min(100, cartographer_attention + attention_increase)
		effects.immediate.append({
			"resource": "cartographer_attention",
			"change": "+" + str(attention_increase),
			"reason": "Los Cartógrafos detectan tu retórica subversiva"
		})
		
		# Riesgo de infiltración
		if cartographer_attention > 50:
			effects.risks.append({
				"type": "infiltration_risk",
				"probability": cartographer_attention / 100.0,
				"consequence": {
					"type": "reputation_loss",
					"regions": ["eo", "eu"],
					"amount": -15
				}
			})
	
	# Riesgo de censura
	if risk_level == "high" or risk_level == "extreme":
		effects.risks.append({
			"type": "censorship_risk",
			"probability": 0.4 if risk_level == "high" else 0.7,
			"consequence": {
				"type": "political_power_loss",
				"amount": -10
			}
		})
	
	# ============================================
	# EFECTOS DIFERIDOS
	# ============================================
	
	# Eventos futuros basados en virality
	if virality > 7:
		effects.delayed.append({
			"event": "manifesto_goes_viral",
			"turns": 2,
			"magnitude": "high",
			"effects": {
				"political_power": "+20",
				"reputation": {"pe": "+25", "eo": "-15"}
			}
		})
	
	# Desbloqueo de misiones
	if political_power > 30 and themes.has("anti_cartographer"):
		effects.delayed.append({
			"event": "mission_unlock",
			"mission_id": "m4_counter_intelligence",
			"requirements": {"political_power": 30}
		})
	
	return effects

func _calculate_reputation_effects(themes: Array, quality: float, risk: String) -> Array:
	"""Calcula cambios de reputación por región"""
	var effects = []
	
	# Regiones y sus sensibilidades
	var region_sensitivities = {
		"pe": {"anti_cartographer": 1.5, "revolution": 1.3, "ecology": 1.2, "justice": 1.4},
		"eo": {"anti_cartographer": -1.5, "revolution": -1.2, "ecology": 0.8, "justice": 0.5},
		"eu": {"anti_cartographer": -2.0, "revolution": -1.5, "ecology": 0.5, "justice": 0.3},
		"ch": {"anti_cartographer": -1.0, "revolution": -0.8, "ecology": 1.0, "justice": 0.7},
		"la": {"anti_cartographer": 1.2, "revolution": 1.4, "ecology": 1.3, "justice": 1.5},
		"as": {"anti_cartographer": 0.5, "revolution": 0.8, "ecology": 1.1, "justice": 1.0},
		"au": {"anti_cartographer": 0.8, "revolution": 1.0, "ecology": 1.4, "justice": 1.2}
	}
	
	for region in region_sensitivities.keys():
		var sensitivity = region_sensitivities[region]
		var total_change = 0.0
		
		for theme in themes:
			if sensitivity.has(theme):
				total_change += quality * sensitivity[theme]
		
		# Ajuste por riesgo
		if risk == "high" or risk == "extreme":
			if region in ["eo", "eu", "ch"]:
				total_change -= 10  # Regiones conservadoras penalizan más
		
		var change_int = int(total_change)
		if abs(change_int) > 0:
			effects.append({
				"resource": "reputation",
				"region": region,
				"change": ("+" if change_int > 0 else "") + str(change_int),
				"reason": "Reacción regional al manifiesto"
			})
	
	return effects

func _apply_immediate_effects(effects: Array):
	"""Aplica efectos inmediatos al juego"""
	if not game_client:
		print("⚠️ GameClient no disponible, efectos no aplicados")
		return
	
	for effect in effects:
		var resource = effect.get("resource", "")
		var change_str = effect.get("change", "0")
		var change = int(change_str.replace("+", ""))
		
		match resource:
			"sanity":
				if game_client.has_method("modify_sanity"):
					game_client.modify_sanity(change, "manifesto_effect")
			
			"reputation":
				var region = effect.get("region", "")
				if region != "" and game_client.has_method("modify_reputation"):
					game_client.modify_reputation(region, change)
			
			"political_power":
				# Nuevo recurso, guardar localmente
				political_power = max(0, political_power + change)
				print("💪 Poder Político: " + str(political_power))
			
			"cartographer_attention":
				cartographer_attention = max(0, min(100, cartographer_attention + change))
				print("👁️ Atención Cartógrafos: " + str(int(cartographer_attention)) + "%")
				
				# Alerta si es muy alto
				if cartographer_attention > 70:
					print("🚨 ALERTA: Los Cartógrafos están muy atentos a tus acciones")

func _schedule_delayed_effects(delayed: Array):
	"""Programa efectos que ocurrirán más tarde"""
	for delayed_effect in delayed:
		var turns = delayed_effect.get("turns", 1)
		var timer = get_tree().create_timer(turns * 60.0)  # 1 turno = 60 segundos
		
		timer.timeout.connect(func():
			_apply_delayed_effect(delayed_effect)
		)

func _apply_delayed_effect(effect: Dictionary):
	"""Aplica un efecto diferido"""
	var event_type = effect.get("event", "")
	
	match event_type:
		"manifesto_goes_viral":
			print("📢 ¡Tu manifiesto se ha vuelto viral!")
			var viral_effects = effect.get("effects", {})
			# Aplicar efectos virales
			_apply_immediate_effects([{
				"resource": "political_power",
				"change": viral_effects.get("political_power", "+0")
			}])
		
		"mission_unlock":
			var mission_id = effect.get("mission_id", "")
			print("🎯 Nueva misión desbloqueada: " + mission_id)
			# Aquí se desbloquearía la misión en el sistema de misiones

func _evaluate_risks(risks: Array):
	"""Evalúa y potencialmente dispara riesgos"""
	for risk in risks:
		var probability = risk.get("probability", 0.0)
		if randf() < probability:
			var consequence = risk.get("consequence", {})
			risk_triggered.emit(risk.get("type", "unknown"), consequence)
			_apply_risk_consequence(consequence)

func _apply_risk_consequence(consequence: Dictionary):
	"""Aplica las consecuencias de un riesgo"""
	var type = consequence.get("type", "")
	
	match type:
		"reputation_loss":
			var regions = consequence.get("regions", [])
			var amount = consequence.get("amount", 0)
			for region in regions:
				if game_client and game_client.has_method("modify_reputation"):
					game_client.modify_reputation(region, amount)
			print("⚠️ Riesgo activado: Pérdida de reputación")
		
		"political_power_loss":
			var amount = consequence.get("amount", 0)
			political_power = max(0, political_power + amount)
			print("⚠️ Riesgo activado: Pérdida de poder político")

func get_political_power() -> float:
	"""Obtiene el poder político actual"""
	return political_power

func get_cartographer_attention() -> float:
	"""Obtiene la atención de los Cartógrafos"""
	return cartographer_attention

func get_manifesto_history() -> Array:
	"""Obtiene el historial de manifiestos"""
	return manifesto_history
