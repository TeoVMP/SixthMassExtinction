# TippingPointRewardSystem.gd
# Sistema de recompensas por evitar tipping points
extends Node
class_name TippingPointRewardSystem

# Señales
signal tipping_point_prevented(tip_id: String, reward: Dictionary)
signal lives_saved(count: int)
signal sanity_bonus(amount: float)
signal communication_bonus(amount: float)

# Referencias
var climate_system: ClimateSystem = null
var game_client: Node = null

# Estadísticas de prevención
var prevented_tipping_points: Array = []
var lives_saved_count: int = 0
var total_rewards: Dictionary = {}

func _ready():
	call_deferred("_connect_climate_system")

func _connect_climate_system():
	"""Conecta con ClimateSystem"""
	var root = get_tree().root
	climate_system = root.find_child("ClimateSystem", true, false)
	
	if climate_system:
		# Monitorear tipping points antes de activarse
		climate_system.tipping_point_activated.connect(_on_tipping_point_activated)
		print("✅ TippingPointRewardSystem conectado")

func _on_tipping_point_activated(tip_id: String, tip: ClimateTippingPoint):
	"""Cuando se activa un tipping point, calcula cuántas vidas se perdieron"""
	# Calcular vidas perdidas por este tipping point
	var lives_lost = _calculate_lives_lost(tip_id, tip)
	
	# Si se había prevenido antes, no se pierden vidas
	if tip_id in prevented_tipping_points:
		print("✅ Tipping point " + tip_id + " fue prevenido, vidas salvadas: " + str(lives_lost))
		return
	
	print("💀 Tipping point " + tip_id + " activado, vidas perdidas: " + str(lives_lost))

func prevent_tipping_point(tip_id: String, prevention_method: String = "action") -> Dictionary:
	"""Recompensa por prevenir un tipping point"""
	if tip_id in prevented_tipping_points:
		return {"success": false, "message": "Ya fue prevenido"}
	
	prevented_tipping_points.append(tip_id)
	
	# Calcular recompensas
	var reward = _calculate_reward(tip_id)
	
	# Aplicar recompensas
	_apply_rewards(reward)
	
	# Guardar estadísticas
	total_rewards[tip_id] = reward
	
	tipping_point_prevented.emit(tip_id, reward)
	
	print("🎉 TIPPING POINT PREVENIDO: " + tip_id)
	print("   Recompensas: ", reward)
	
	return {"success": true, "reward": reward}

func _calculate_reward(tip_id: String) -> Dictionary:
	"""Calcula recompensas por prevenir tipping point"""
	var base_reward = {
		"lives_saved": 0,
		"sanity_bonus": 0.0,
		"communication_bonus": 0.0,
		"manifesto_bonus": 0.0,
		"reputation_bonus": {}
	}
	
	# Recompensas basadas en importancia del tipping point
	match tip_id:
		"amazon_dieback":
			base_reward.lives_saved = 5000000  # 5 millones de vidas
			base_reward.sanity_bonus = 15.0
			base_reward.communication_bonus = 20.0
			base_reward.manifesto_bonus = 0.3  # +30% efectividad
			base_reward.reputation_bonus = {"la": 30, "pe": 25, "as": 15}
		
		"amoc":
			base_reward.lives_saved = 2000000  # 2 millones
			base_reward.sanity_bonus = 12.0
			base_reward.communication_bonus = 15.0
			base_reward.manifesto_bonus = 0.25
			base_reward.reputation_bonus = {"eo": 20, "eu": 15, "la": 10}
		
		"greenland_ice", "antarctica_ice":
			base_reward.lives_saved = 10000000  # 10 millones (aumento nivel del mar)
			base_reward.sanity_bonus = 20.0
			base_reward.communication_bonus = 25.0
			base_reward.manifesto_bonus = 0.4
			base_reward.reputation_bonus = {"as": 30, "au": 25, "eo": 20}
		
		"permafrost":
			base_reward.lives_saved = 3000000  # 3 millones
			base_reward.sanity_bonus = 10.0
			base_reward.communication_bonus = 12.0
			base_reward.manifesto_bonus = 0.2
			base_reward.reputation_bonus = {"ru": 15, "pe": 10}
		
		"coral_reefs":
			base_reward.lives_saved = 1000000  # 1 millón
			base_reward.sanity_bonus = 8.0
			base_reward.communication_bonus = 10.0
			base_reward.manifesto_bonus = 0.15
			base_reward.reputation_bonus = {"au": 20, "as": 15}
		
		"monsoons":
			base_reward.lives_saved = 8000000  # 8 millones
			base_reward.sanity_bonus = 18.0
			base_reward.communication_bonus = 22.0
			base_reward.manifesto_bonus = 0.35
			base_reward.reputation_bonus = {"as": 35, "au": 30, "pe": 20}
	
	return base_reward

func _apply_rewards(reward: Dictionary):
	"""Aplica recompensas al jugador"""
	# Vidas salvadas
	lives_saved_count += reward.lives_saved
	lives_saved.emit(reward.lives_saved)
	
	# Bonus de cordura
	if game_client and game_client.has_method("modify_sanity"):
		game_client.modify_sanity(reward.sanity_bonus, "tipping_point_prevented")
	sanity_bonus.emit(reward.sanity_bonus)
	
	# Bonus de comunicación (mejora efectividad de manifiestos)
	# Se aplicará en ManifestoImpactSystem
	
	# Bonus de reputación
	if game_client and game_client.has_method("modify_reputation"):
		for region in reward.reputation_bonus:
			game_client.modify_reputation(region, reward.reputation_bonus[region])

func _calculate_lives_lost(tip_id: String, tip: ClimateTippingPoint) -> int:
	"""Calcula vidas perdidas por activación de tipping point"""
	# Basado en datos científicos reales de impacto
	match tip_id:
		"amazon_dieback":
			return 5000000  # Estimación conservadora
		"amoc":
			return 2000000
		"greenland_ice", "antarctica_ice":
			return 10000000  # Aumento nivel del mar
		"permafrost":
			return 3000000
		"coral_reefs":
			return 1000000
		"monsoons":
			return 8000000
		_:
			return 1000000

func get_manifesto_bonus() -> float:
	"""Retorna bonus acumulado para manifiestos"""
	var total_bonus = 0.0
	for tip_id in total_rewards:
		if total_rewards[tip_id].has("manifesto_bonus"):
			total_bonus += total_rewards[tip_id].manifesto_bonus
	return min(1.0, total_bonus)  # Máximo 100% de bonus

func get_communication_bonus() -> float:
	"""Retorna bonus acumulado de comunicación"""
	var total_bonus = 0.0
	for tip_id in total_rewards:
		if total_rewards[tip_id].has("communication_bonus"):
			total_bonus += total_rewards[tip_id].communication_bonus
	return total_bonus

func set_game_client(client: Node):
	game_client = client
















