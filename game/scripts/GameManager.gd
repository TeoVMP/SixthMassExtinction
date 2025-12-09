
@tool  # ← AÑADE ESTA LÍNEA
extends Node# res://scripts/GameManager.gd

# ====== VARIABLES GLOBALES ======
var current_time: int = 2024
var temporal_contamination: float = 0.0
var player_sanity: float = 100.0
var available_time_power: float = 100.0

# ====== SISTEMA GEOPOLÍTICO ======
var geopolitical_zones: Dictionary = {
	# 1. AMÉRICA LATINA (progresista vs extractivismo)
	"latin_america": {
		"reputation": 0.0,
		"dynamics": ["indigenous_rights", "extractivism", "social_movements"],
		"power_balance": 0.3,  # 0=oligarquías, 1=pueblos
		"resource_control": 0.2  # quién controla recursos
	},
	
	# 2. ÁFRICA SUBSAHARIANA (neocolonialismo vs soberanía)
	"subsaharan_africa": {
		"reputation": 0.0,
		"dynamics": ["debt_traps", "resource_curse", "panafricanism"],
		"china_influence": 0.6,
		"west_influence": 0.4,
		"sovereignty": 0.3
	},
	
	# 3. SURESTE ASIÁTICO (manufactura vs derechos laborales)
	"southeast_asia": {
		"reputation": 0.0,
		"dynamics": ["manufacturing_hub", "labor_rights", "digital_resistance"],
		"union_power": 0.2,
		"corporate_control": 0.8
	},
	
	# 4. SUR DE ASIA (India y alrededores - polarización)
	"south_asia": {
		"reputation": 0.0,
		"dynamics": ["digital_colonization", "caste_system", "tech_resistance"],
		"digital_sovereignty": 0.3,
		"inequality_index": 0.8
	},
	
	# 5. MEDIO ORIENTE (petróleo vs diversificación)
	"middle_east": {
		"reputation": -20.0,  # Inicialmente bajo (oligarquías petroleras)
		"dynamics": ["petro_states", "youth_movements", "water_wars"],
		"oil_dependency": 0.9,
		"renewable_transition": 0.1
	},
	
	# 6. EUROPA ORIENTAL (UE vs soberanía)
	"eastern_europe": {
		"reputation": 0.0,
		"dynamics": ["eu_integration", "russian_influence", "nationalism"],
		"eu_alignment": 0.5,
		"sovereign_tech": 0.4
	},
	
	# 7. PACÍFICO (islas vs cambio climático)
	"pacific_islands": {
		"reputation": 30.0,  # Alto - más afectados por cambio climático
		"dynamics": ["climate_refugees", "ocean_rights", "neo-colonialism"],
		"sea_level_rise": 0.8,
		"fishing_rights": 0.3
	},
	
	# 8. AMAZONÍA (transnacional - pueblos vs corporaciones)
	"amazon_basin": {
		"reputation": 40.0,  # Alto para activistas/científicos
		"dynamics": ["biome_war", "indigenous_guardians", "carbon_markets"],
		"deforestation_rate": 0.7,
		"indigenous_control": 0.4
	},
	
	# 9. ÁRTICO (nuevas rutas vs pueblos originarios)
	"arctic": {
		"reputation": 10.0,
		"dynamics": ["melting_ice", "indigenous_rights", "new_trade_routes"],
		"ice_loss": 0.6,
		"military_presence": 0.7
	},
	
	# 10. CUENCA DEL CONGO (segundo pulmón del planeta)
	"congo_basin": {
		"reputation": 20.0,
		"dynamics": ["mining_conflicts", "carbon_sink", "community_forests"],
		"mining_intensity": 0.8,
		"protected_areas": 0.2
	},
	
	# 11. ASIA CENTRAL (rutas de la seda vs recursos)
	"central_asia": {
		"reputation": -10.0,
		"dynamics": ["belt_road", "water_conflicts", "authoritarian_tech"],
		"china_investment": 0.7,
		"water_scarcity": 0.6
	},
	
	# 12. CARIBE (turismo vs resiliencia climática)
	"caribbean": {
		"reputation": 15.0,
		"dynamics": ["tourism_dependency", "debt_colonialism", "climate_resilience"],
		"tourist_economy": 0.8,
		"renewable_potential": 0.9
	}
}

# ====== ALIANZAS GEOPOLÍTICAS ======
var geopolitical_alliances: Dictionary = {
	"climate_justice_bloc": ["pacific_islands", "caribbean", "amazon_basin"],
	"resource_nationalists": ["middle_east", "congo_basin", "central_asia"],
	"tech_sovereignty_coalition": ["south_asia", "eastern_europe", "latin_america"],
	
	# Bloques de poder existentes
	"g7_aligned": [],  # Se llena dinámicamente
	"brics_aligned": [],  # Se llena dinámicamente
	"non_aligned": []  # Zonas que juegan ambos lados
}

# ====== ACCIONES DISPONIBLES ======
var available_actions: Array = [
	{
		"id": "protect",
		"name": "🛡️ Protect Ecosystem",
		"description": "Establish protected area",
		"sanity_cost": -5,
		"time_cost": 10.0,
		"zone_effects": {
			"amazon_basin": {"reputation": 20, "indigenous_control": 0.1},
			"congo_basin": {"reputation": 15, "protected_areas": 0.15},
			"pacific_islands": {"reputation": 10, "climate_resilience": 0.1},
			"middle_east": {"reputation": -10, "oil_dependency": 0.05},
			"central_asia": {"reputation": -5}
		}
	},
	
	{
		"id": "deforest",
		"name": "🪓 Clear for Development",
		"description": "Clear land for agriculture/industry",
		"sanity_cost": -15,
		"time_cost": 5.0,
		"zone_effects": {
			"amazon_basin": {"reputation": -30, "deforestation_rate": 0.2, "indigenous_control": -0.15},
			"congo_basin": {"reputation": -25, "mining_intensity": 0.1},
			"middle_east": {"reputation": 15, "oil_dependency": 0.1},
			"southeast_asia": {"reputation": -10, "corporate_control": 0.1}
		}
	},
	
	{
		"id": "tech_transfer",
		"name": "🔬 South-South Tech Transfer",
		"description": "Share renewable tech between zones",
		"sanity_cost": 0,
		"time_cost": 15.0,
		"zone_effects": {
			"south_asia": {"reputation": 15, "digital_sovereignty": 0.2},
			"latin_america": {"reputation": 10, "resource_control": 0.1},
			"subsaharan_africa": {"reputation": 20, "sovereignty": 0.15},
			"middle_east": {"reputation": -5, "oil_dependency": -0.1}
		}
	},
	
	{
		"id": "debt_forgiveness",
		"name": "💸 Climate Debt Cancellation",
		"description": "Cancel illegitimate climate debt",
		"sanity_cost": 10,
		"time_cost": 20.0,
		"zone_effects": {
			"caribbean": {"reputation": 40, "climate_resilience": 0.3},
			"pacific_islands": {"reputation": 35, "sea_level_rise": -0.1},
			"subsaharan_africa": {"reputation": 25, "debt_traps": -0.2},
			"oligarchs": -50  # Efecto especial
		}
	}
]

# ====== EVENTOS ZONALES ======
var zone_events: Array = [
	{
		"id": "latin_revolution",
		"title": "📢 Latin American Spring",
		"description": "Mass protests demand end to extractivism",
		"trigger_zone": "latin_america",
		"trigger_condition": "power_balance > 0.6",
		"effects": {
			"latin_america": {"reputation": 25, "resource_control": 0.3},
			"amazon_basin": {"indigenous_control": 0.2},
			"caribbean": {"reputation": 10}
		},
		"choices": [
			{"text": "Support the movement", "sanity": 10, "effects": {}},
			{"text": "Stay neutral", "sanity": -5, "effects": {}},
			{"text": "Back the oligarchs", "sanity": -20, "effects": {}}
		],
		"has_triggered": false
	}
]

# ====== REFERENCIAS A UI ======
var biome_selector: Node = null
var geopolitical_map: Node = null
var zone_event_popup: Node = null

# ====== FUNCIONES PRINCIPALES ======
# ... todo el código anterior del GameManager se mantiene igual ...

func _ready():
	print("GameManager inicializado con 12 zonas geopolíticas")
	_initialize_alliances()
	load_ui_elements()
	
	# Esperar un frame para que la UI se cargue
	await get_tree().process_frame
	
	# Iniciar timer de prueba (SOLO SI QUIERES TESTING)
	# Comenta esta línea si no quieres cambios automáticos
	_setup_test_timer()
func _setup_test_timer():
	# Crear temporizador para probar actualizaciones dinámicas
	var test_timer = Timer.new()
	test_timer.name = "TestTimer"
	test_timer.wait_time = 3.0  # Cada 3 segundos
	test_timer.one_shot = false
	test_timer.timeout.connect(_on_test_timer_timeout)
	add_child(test_timer)
	test_timer.start()
	print("⏱️ Timer de prueba iniciado (cambios cada 3 segundos)")

func _on_test_timer_timeout():
	# Esta función solo es para testing - demostrar que el sistema funciona
	print("🔄 Actualizando zonas de prueba...")
	
	# Cambiar algunas reputaciones para probar
	if geopolitical_zones.has("latin_america"):
		geopolitical_zones.latin_america.reputation += 5
		print("  ➕ América Latina: +5 rep")
	
	if geopolitical_zones.has("middle_east"):
		geopolitical_zones.middle_east.reputation += 3
		print("  ➕ Medio Oriente: +3 rep")
	
	# Cambiar algunas métricas
	if geopolitical_zones.has("amazon_basin"):
		geopolitical_zones.amazon_basin.deforestation_rate = max(0.0, geopolitical_zones.amazon_basin.deforestation_rate - 0.05)
		print("  🌳 Amazonas: -5% deforestación")
	
	# Actualizar UI si está visible
	if geopolitical_map and geopolitical_map.has_method("update_display"):
		geopolitical_map.update_display()
		print("  📊 UI actualizada")

# También puedes añadir esta función para probar manualmente
func test_manual_update():
	print("🧪 TEST MANUAL: Actualizando todas las zonas +10 rep")
	
	for zone_id in geopolitical_zones:
		geopolitical_zones[zone_id].reputation += 10
		print("  • %s: +10 rep" % zone_id)
	
	if geopolitical_map and geopolitical_map.has_method("update_display"):
		geopolitical_map.update_display()
# ====== FIN FUNCIONES DE PRUEBA ======

# El resto de tus funciones del GameManager continúan aquí...

func load_ui_elements():
	print("Cargando elementos UI...")
	
	# Esperar un frame para evitar problemas de timing
	await get_tree().process_frame
	
	# Cargar GeopoliticalMap
	if ResourceLoader.exists("res://scenes/UI/GeopoliticalMap.tscn"):
		var map_scene = preload("res://scenes/UI/GeopoliticalMap.tscn")
		geopolitical_map = map_scene.instantiate()
		# Usar call_deferred para evitar "parent node is busy"
		get_tree().root.call_deferred("add_child", geopolitical_map)
		geopolitical_map.hide()
		print("✅ GeopoliticalMap cargado")
	else:
		print("❌ ERROR: GeopoliticalMap.tscn no encontrado en res://scenes/UI/GeopoliticalMap.tscn")
		print("   Verifica que el archivo existe en esa ruta")
	
	# Cargar BiomeSelector
	if ResourceLoader.exists("res://scenes/UI/BiomeSelector/BiomeSelector.tscn"):
		var biome_scene = preload("res://scenes/UI/BiomeSelector/BiomeSelector.tscn")
		biome_selector = biome_scene.instantiate()
		get_tree().root.call_deferred("add_child", biome_selector)
		biome_selector.hide()
		print("✅ BiomeSelector cargado")
	
	# Cargar ZoneEventPopup
	if ResourceLoader.exists("res://scenes/UI/ZoneEventPopup.tscn"):
		var event_scene = preload("res://scenes/UI/ZoneEventPopup.tscn")
		zone_event_popup = event_scene.instantiate()
		get_tree().root.call_deferred("add_child", zone_event_popup)
		zone_event_popup.hide()
		print("✅ ZoneEventPopup cargado")
func _initialize_alliances():
	# Inicializar bloques según métricas iniciales
	for zone_id in geopolitical_zones:
		var zone = geopolitical_zones[zone_id]
		
		if zone.reputation > 20:
			if not zone_id in geopolitical_alliances["climate_justice_bloc"]:
				geopolitical_alliances["climate_justice_bloc"].append(zone_id)
		
		elif zone.reputation < -10:
			if not zone_id in geopolitical_alliances["resource_nationalists"]:
				geopolitical_alliances["resource_nationalists"].append(zone_id)

# ====== SISTEMA DE ACCIONES ======
func perform_action(action_id: String, biome_id: String = ""):
	var action = _get_action_by_id(action_id)
	if not action:
		print("Error: Acción no encontrada")
		return
	
	# Aplicar costos
	apply_sanity_effect("action_performed", action.sanity_cost)
	available_time_power -= action.get("time_cost", 10.0)
	
	# Determinar zonas afectadas
	var affected_zones = get_affected_zones(biome_id, action_id)
	
	# Aplicar efectos a cada zona
	for zone_id in affected_zones:
		if action.get("zone_effects", {}).has(zone_id):
			var zone_effects = action["zone_effects"][zone_id]
			apply_zone_effect(zone_id, zone_effects)
	
	# Verificar eventos
	check_zone_events()
	
	# Actualizar turno
	process_turn()

func _get_action_by_id(action_id: String) -> Dictionary:
	for action in available_actions:
		if action["id"] == action_id:
			return action
	return {}

# ====== SISTEMA DE ZONAS ======
func apply_zone_effect(zone_id: String, effects: Dictionary):
	if not geopolitical_zones.has(zone_id):
		print("Error: Zona no encontrada:", zone_id)
		return
	
	var zone = geopolitical_zones[zone_id]
	
	for key in effects:
		if key == "reputation":
			zone[key] += effects[key]
		elif key in zone:
			# Para métricas numéricas (0-1)
			if typeof(zone[key]) == TYPE_FLOAT:
				zone[key] = clamp(zone[key] + effects[key], 0.0, 1.0)
			# Para arrays (dynamics)
			elif typeof(zone[key]) == TYPE_ARRAY and typeof(effects[key]) == TYPE_STRING:
				if not effects[key] in zone[key]:
					zone[key].append(effects[key])
	
	print("Efecto aplicado en %s: %s" % [zone_id, effects])
	_update_alliances(zone_id)

func get_affected_zones(biome_id: String, _action_id: String) -> Array:
	# Mapeo bioma -> zonas
	var biome_to_zones = {
		"amazon": ["amazon_basin", "latin_america"],
		"congo": ["congo_basin", "subsaharan_africa"],
		"arctic": ["arctic", "eastern_europe", "central_asia"],
		"pacific": ["pacific_islands", "southeast_asia"],
		"caribbean": ["caribbean"],
		"middle_east": ["middle_east", "central_asia"]
	}
	
	return biome_to_zones.get(biome_id, [])

func _update_alliances(changed_zone: String):
	var zone = geopolitical_zones[changed_zone]
	
	# Si reputación muy positiva
	if zone.reputation > 30:
		if not changed_zone in geopolitical_alliances["climate_justice_bloc"]:
			geopolitical_alliances["climate_justice_bloc"].append(changed_zone)
		# Remover de otros bloques
		_remove_from_other_alliances(changed_zone, "climate_justice_bloc")
	
	# Si reputación muy negativa
	elif zone.reputation < -20:
		if not changed_zone in geopolitical_alliances["resource_nationalists"]:
			geopolitical_alliances["resource_nationalists"].append(changed_zone)
		_remove_from_other_alliances(changed_zone, "resource_nationalists")

func _remove_from_other_alliances(zone_id: String, keep_alliance: String):
	for alliance in geopolitical_alliances:
		if alliance != keep_alliance and zone_id in geopolitical_alliances[alliance]:
			var idx = geopolitical_alliances[alliance].find(zone_id)
			if idx != -1:
				geopolitical_alliances[alliance].remove_at(idx)

# ====== SISTEMA DE EVENTOS ======
func check_zone_events():
	for zone_id in geopolitical_zones:
		var zone = geopolitical_zones[zone_id]
		
		for event in zone_events:
			if event.get("has_triggered", false):
				continue
				
			if event.get("trigger_zone") == zone_id:
				var condition_parts = event.get("trigger_condition", "").split(" ")
				if condition_parts.size() == 3:
					var metric = condition_parts[0]
					var operator = condition_parts[1]
					var value = float(condition_parts[2])
					
					var zone_value = zone.get(metric, 0.0)
					var triggered = false
					
					match operator:
						">": triggered = zone_value > value
						"<": triggered = zone_value < value
						">=": triggered = zone_value >= value
						"<=": triggered = zone_value <= value
						"==": triggered = zone_value == value
					
					if triggered:
						_trigger_event(event)

func _trigger_event(event: Dictionary):
	print("EVENTO DESENCADENADO:", event.title)
	zone_event_popup.show_event(event)
	event["has_triggered"] = true

# ====== FLUJO DEL JUEGO ======
func process_turn():
	current_time += 1
	temporal_contamination = clamp(temporal_contamination + 0.01, 0.0, 1.0)
	
	# Actualizar UI
	if geopolitical_map and geopolitical_map.has_method("update_display"):
		geopolitical_map.update_display()
	
	# Verificar condiciones de victoria/derrota
	_check_game_state()

func _check_game_state():
	# Derrota por contaminación temporal
	if temporal_contamination >= 1.0:
		print("GAME OVER: Contaminación temporal máxima")
		show_game_over("La línea temporal colapsó")
	
	# Derrota por cordura
	if player_sanity <= 0:
		print("GAME OVER: Cordura agotada")
		show_game_over("Perdiste la cordura")
	
	# Victoria por alianzas fuertes
	var climate_allies = geopolitical_alliances["climate_justice_bloc"].size()
	if climate_allies >= 8 and player_sanity > 50:
		print("VICTORIA: Bloque de justicia climática fuerte")
		show_victory("¡Revolución climática global!")

# ====== FUNCIONES DE UI ======
func apply_sanity_effect(source: String, amount: float):
	player_sanity = clamp(player_sanity + amount, 0.0, 100.0)
	print("Cordura %+.1f (%s): %.1f" % [amount, source, player_sanity])

func show_game_over(reason: String):
	print("GAME OVER:", reason)
	# Aquí cargarías una escena de Game Over

func show_victory(message: String):
	print("VICTORY:", message)
	# Aquí cargarías una escena de Victoria

# ====== FUNCIONES DE DEPURACIÓN ======
func print_zone_status(zone_id: String):
	if geopolitical_zones.has(zone_id):
		print("Estado de %s:" % zone_id, geopolitical_zones[zone_id])

func print_all_alliances():
	print("=== ALIANZAS ACTUALES ===")
	for alliance in geopolitical_alliances:
		print("%s: %s" % [alliance, geopolitical_alliances[alliance]])

func debug_quick_test():
	"""Función rápida para probar desde consola"""
	print("🚀 DEBUG RÁPIDO")
	geopolitical_zones["latin_america"]["reputation"] = 50
	geopolitical_zones["amazon_basin"]["reputation"] = 80
	geopolitical_zones["middle_east"]["reputation"] = -40
	
	if geopolitical_map and geopolitical_map.has_method("update_display"):
		geopolitical_map.update_display()
	print("✅ Valores de prueba establecidos")
# ====== FIN FUNCIONES DE PRUEBA ======
