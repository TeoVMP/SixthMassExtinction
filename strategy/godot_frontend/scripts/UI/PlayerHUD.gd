# PlayerHUD.gd
# HUD del jugador con constantes vitales y estado corporal
extends Control
class_name PlayerHUD

# Referencias a nodos UI
var vital_signs_panel: Control = null
var body_parts_panel: Control = null
var stats_panel: Control = null

# Referencias a datos
var player_stats: PlayerStats = null
var body_parts: Dictionary = {}
var vital_signs: Dictionary = {}

# Constantes vitales
var heart_rate: int = 70      # BPM
var blood_pressure_systolic: int = 120
var blood_pressure_diastolic: int = 80
var temperature: float = 36.5  # °C
var oxygen_saturation: float = 98.0  # %

func _ready():
	_initialize_body_parts()
	_setup_ui()
	start_update_timer()

func _initialize_body_parts():
	"""Inicializa las partes del cuerpo"""
	body_parts[BodyPartState.BodyPart.HEAD] = BodyPartState.new()
	body_parts[BodyPartState.BodyPart.HEAD].part = BodyPartState.BodyPart.HEAD
	body_parts[BodyPartState.BodyPart.HEAD].max_health = 100.0
	
	body_parts[BodyPartState.BodyPart.TORSO] = BodyPartState.new()
	body_parts[BodyPartState.BodyPart.TORSO].part = BodyPartState.BodyPart.TORSO
	body_parts[BodyPartState.BodyPart.TORSO].max_health = 100.0
	
	body_parts[BodyPartState.BodyPart.LEFT_ARM] = BodyPartState.new()
	body_parts[BodyPartState.BodyPart.LEFT_ARM].part = BodyPartState.BodyPart.LEFT_ARM
	body_parts[BodyPartState.BodyPart.LEFT_ARM].max_health = 80.0
	
	body_parts[BodyPartState.BodyPart.RIGHT_ARM] = BodyPartState.new()
	body_parts[BodyPartState.BodyPart.RIGHT_ARM].part = BodyPartState.BodyPart.RIGHT_ARM
	body_parts[BodyPartState.BodyPart.RIGHT_ARM].max_health = 80.0
	
	body_parts[BodyPartState.BodyPart.LEFT_LEG] = BodyPartState.new()
	body_parts[BodyPartState.BodyPart.LEFT_LEG].part = BodyPartState.BodyPart.LEFT_LEG
	body_parts[BodyPartState.BodyPart.LEFT_LEG].max_health = 85.0
	
	body_parts[BodyPartState.BodyPart.RIGHT_LEG] = BodyPartState.new()
	body_parts[BodyPartState.BodyPart.RIGHT_LEG].part = BodyPartState.BodyPart.RIGHT_LEG
	body_parts[BodyPartState.BodyPart.RIGHT_LEG].max_health = 85.0
	
	body_parts[BodyPartState.BodyPart.HANDS] = BodyPartState.new()
	body_parts[BodyPartState.BodyPart.HANDS].part = BodyPartState.BodyPart.HANDS
	body_parts[BodyPartState.BodyPart.HANDS].max_health = 70.0
	
	body_parts[BodyPartState.BodyPart.FEET] = BodyPartState.new()
	body_parts[BodyPartState.BodyPart.FEET].part = BodyPartState.BodyPart.FEET
	body_parts[BodyPartState.BodyPart.FEET].max_health = 70.0

func _setup_ui():
	"""Configura la UI del HUD"""
	# Los anchors se configuran desde UI_Main
	# Solo asegurar propiedades básicas
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	
	# Esperar un frame para que los anchors se apliquen
	await get_tree().process_frame
	
	# Forzar actualización del layout
	queue_redraw()

func _update_layout():
	"""Fuerza actualización del layout - llamado desde UI_Main"""
	queue_redraw()
	
	# Estilo
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.3, 0.5, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	add_theme_stylebox_override("panel", style)
	
	# Contenedor principal
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 5)
	add_child(container)
	
	# Título
	var title = Label.new()
	title.text = "👤 ESTADO DEL JUGADOR"
	title.add_theme_font_size_override("font_size", 14)
	container.add_child(title)
	
	# Panel de constantes vitales
	_setup_vital_signs(container)
	
	# Panel de partes del cuerpo
	_setup_body_parts(container)
	
	# Panel de estadísticas
	_setup_stats(container)

func _setup_vital_signs(parent: Control):
	"""Configura panel de constantes vitales"""
	var panel = VBoxContainer.new()
	panel.name = "VitalSigns"
	panel.add_theme_constant_override("separation", 3)
	
	var title = Label.new()
	title.text = "📊 CONSTANTES VITALES"
	title.add_theme_font_size_override("font_size", 12)
	panel.add_child(title)
	
	# Labels para constantes vitales (se actualizarán)
	vital_signs["heart_rate"] = Label.new()
	vital_signs["heart_rate"].name = "HeartRate"
	vital_signs["blood_pressure"] = Label.new()
	vital_signs["blood_pressure"].name = "BloodPressure"
	vital_signs["temperature"] = Label.new()
	vital_signs["temperature"].name = "Temperature"
	vital_signs["oxygen"] = Label.new()
	vital_signs["oxygen"].name = "Oxygen"
	
	panel.add_child(vital_signs["heart_rate"])
	panel.add_child(vital_signs["blood_pressure"])
	panel.add_child(vital_signs["temperature"])
	panel.add_child(vital_signs["oxygen"])
	
	vital_signs_panel = panel
	parent.add_child(panel)
	_refresh_vital_signs()

func _setup_body_parts(parent: Control):
	"""Configura panel de partes del cuerpo"""
	var panel = VBoxContainer.new()
	panel.name = "BodyParts"
	panel.add_theme_constant_override("separation", 3)
	
	var title = Label.new()
	title.text = "🩺 ESTADO CORPORAL"
	title.add_theme_font_size_override("font_size", 12)
	panel.add_child(title)
	
	# Crear labels para cada parte del cuerpo
	for part_key in body_parts:
		var part = body_parts[part_key]
		var label = Label.new()
		label.name = "BodyPart_" + str(part_key)
		label.add_theme_font_size_override("font_size", 10)
		panel.add_child(label)
	
	body_parts_panel = panel
	parent.add_child(panel)
	_refresh_body_parts()

func _setup_stats(parent: Control):
	"""Configura panel de estadísticas RPG"""
	var panel = VBoxContainer.new()
	panel.name = "Stats"
	panel.add_theme_constant_override("separation", 3)
	
	var title = Label.new()
	title.text = "⚔️ ESTADÍSTICAS"
	title.add_theme_font_size_override("font_size", 12)
	panel.add_child(title)
	
	# Labels para estadísticas (se actualizarán)
	if player_stats:
		var stats_labels = {}
		stats_labels["strength"] = Label.new()
		stats_labels["constitution"] = Label.new()
		stats_labels["dexterity"] = Label.new()
		stats_labels["intelligence"] = Label.new()
		stats_labels["wisdom"] = Label.new()
		stats_labels["charisma"] = Label.new()
		
		for key in stats_labels:
			stats_labels[key].add_theme_font_size_override("font_size", 10)
			panel.add_child(stats_labels[key])
	
	stats_panel = panel
	parent.add_child(panel)
	_refresh_stats()

func _refresh_vital_signs():
	"""Actualiza display de constantes vitales"""
	if not vital_signs.has("heart_rate"):
		return
	
	vital_signs["heart_rate"].text = "❤️ Pulso: " + str(heart_rate) + " BPM"
	
	# Color según estado
	if heart_rate > 100 or heart_rate < 60:
		vital_signs["heart_rate"].add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		vital_signs["heart_rate"].add_theme_color_override("font_color", Color(0, 1, 0))
	
	vital_signs["blood_pressure"].text = "🩸 Presión: " + str(blood_pressure_systolic) + "/" + str(blood_pressure_diastolic) + " mmHg"
	if blood_pressure_systolic > 140 or blood_pressure_diastolic > 90:
		vital_signs["blood_pressure"].add_theme_color_override("font_color", Color(1, 0.5, 0))
	else:
		vital_signs["blood_pressure"].add_theme_color_override("font_color", Color(0, 1, 0))
	
	vital_signs["temperature"].text = "🌡️ Temperatura: " + str(temperature) + "°C"
	if temperature > 37.5 or temperature < 36.0:
		vital_signs["temperature"].add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		vital_signs["temperature"].add_theme_color_override("font_color", Color(0, 1, 0))
	
	vital_signs["oxygen"].text = "💨 O2 Sat: " + str(oxygen_saturation) + "%"
	if oxygen_saturation < 95:
		vital_signs["oxygen"].add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		vital_signs["oxygen"].add_theme_color_override("font_color", Color(0, 1, 0))

func _refresh_body_parts():
	"""Actualiza display de partes del cuerpo"""
	if not body_parts_panel:
		return
	
	var part_names = {
		BodyPartState.BodyPart.HEAD: "Cabeza",
		BodyPartState.BodyPart.TORSO: "Torso",
		BodyPartState.BodyPart.LEFT_ARM: "Brazo Izq.",
		BodyPartState.BodyPart.RIGHT_ARM: "Brazo Der.",
		BodyPartState.BodyPart.LEFT_LEG: "Pierna Izq.",
		BodyPartState.BodyPart.RIGHT_LEG: "Pierna Der.",
		BodyPartState.BodyPart.HANDS: "Manos",
		BodyPartState.BodyPart.FEET: "Pies"
	}
	
	for part_key in body_parts:
		var part = body_parts[part_key]
		var label = body_parts_panel.get_node_or_null("BodyPart_" + str(part_key))
		if label:
			var status = part.get_status()
			var color = Color(0, 1, 0)  # Verde por defecto
			
			if status == "CRÍTICO":
				color = Color(1, 0, 0)
			elif status == "GRAVE":
				color = Color(1, 0.3, 0)
			elif status == "LESIONADO":
				color = Color(1, 0.7, 0)
			elif status == "DAÑADO":
				color = Color(1, 1, 0)
			
			label.text = "  " + part_names.get(part_key, "Desconocido") + ": " + status + " (" + str(int(part.health)) + "%)"
			label.add_theme_color_override("font_color", color)

func _refresh_stats():
	"""Actualiza display de estadísticas"""
	if not player_stats or not stats_panel:
		return
	
	var stat_names = {
		"strength": "💪 Fuerza",
		"constitution": "🛡️ Constitución",
		"dexterity": "⚡ Destreza",
		"intelligence": "🧠 Inteligencia",
		"wisdom": "👁️ Sabiduría",
		"charisma": "✨ Carisma"
	}
	
	var i = 0
	for key in ["strength", "constitution", "dexterity", "intelligence", "wisdom", "charisma"]:
		var label = stats_panel.get_child(i + 1)  # +1 porque el primer hijo es el título
		if label:
			var value = player_stats.get(key)
			var modifier = 0
			match key:
				"strength":
					modifier = player_stats.get_strength_modifier()
				"constitution":
					modifier = player_stats.get_constitution_modifier()
				"dexterity":
					modifier = player_stats.get_dexterity_modifier()
				"intelligence":
					modifier = player_stats.get_intelligence_modifier()
				"wisdom":
					modifier = player_stats.get_wisdom_modifier()
				"charisma":
					modifier = player_stats.get_charisma_modifier()
			
			var mod_str = "+" + str(modifier) if modifier >= 0 else str(modifier)
			label.text = stat_names.get(key, key) + ": " + str(value) + " (" + mod_str + ")"
		i += 1

func update_vital_signs(heart_rate_val: int, bp_sys: int, bp_dia: int, temp: float, o2: float):
	"""Actualiza constantes vitales"""
	heart_rate = heart_rate_val
	blood_pressure_systolic = bp_sys
	blood_pressure_diastolic = bp_dia
	temperature = temp
	oxygen_saturation = o2
	_refresh_vital_signs()

func take_damage_to_body_part(part: BodyPartState.BodyPart, amount: float, damage_type: String = "physical"):
	"""Aplica daño a una parte del cuerpo"""
	if body_parts.has(part):
		body_parts[part].take_damage(amount, damage_type)
		_refresh_body_parts()
		_update_vital_signs_from_injuries()

func _update_vital_signs_from_injuries():
	"""Actualiza constantes vitales basadas en lesiones"""
	var total_damage = 0.0
	var critical_parts = 0
	
	for part in body_parts.values():
		total_damage += (100.0 - part.health)
		if part.health <= 0:
			critical_parts += 1
	
	# Afectar constantes vitales
	if critical_parts > 0:
		heart_rate = min(150, 70 + critical_parts * 20)
		blood_pressure_systolic = min(180, 120 + critical_parts * 15)
		oxygen_saturation = max(85, 98.0 - critical_parts * 3.0)
	
	if total_damage > 200:
		temperature = min(39.5, 36.5 + (total_damage - 200) / 100.0)
	
	_refresh_vital_signs()

func set_player_stats(stats: PlayerStats):
	player_stats = stats
	_refresh_stats()

func start_update_timer():
	"""Inicia timer para actualizar HUD periódicamente"""
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_refresh_all)
	add_child(timer)

func _refresh_all():
	_refresh_vital_signs()
	_refresh_body_parts()
	_refresh_stats()

