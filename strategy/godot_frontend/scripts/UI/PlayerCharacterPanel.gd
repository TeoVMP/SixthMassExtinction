# PlayerCharacterPanel.gd
# Panel profesional de características del jugador (híbrido detallado)
extends VBoxContainer
class_name PlayerCharacterPanel

# Referencias a nodos UI
var stats_section: VBoxContainer = null
var skills_section: VBoxContainer = null
var status_section: VBoxContainer = null

# Referencias a datos
var player_stats: PlayerStats = null
var game_client: Node = null

# Labels para estadísticas
var stats_labels: Dictionary = {}

# Labels para habilidades
var skills_labels: Dictionary = {}

# Labels para estado
var sanity_label: Label = null
var sanity_bar: ProgressBar = null
var needs_labels: Dictionary = {}
var reputation_labels: Dictionary = {}

func _ready():
	_setup_panel()
	_apply_styles()

func _apply_styles():
	"""Aplica estilos profesionales al panel"""
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	if CyberpunkThemeClass:
		# Aplicar estilo de panel
		var panel_style = CyberpunkThemeClass.create_panel_style()
		# Crear un Panel como contenedor de fondo
		var bg_panel = Panel.new()
		bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_panel.add_theme_stylebox_override("panel", panel_style)
		bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_panel)
		move_child(bg_panel, 0)  # Mover al fondo

func _setup_panel():
	"""Configura el panel con todas las secciones"""
	# Título del panel
	var title = Label.new()
	title.name = "Title"
	title.text = "CARACTERÍSTICAS DEL JUGADOR"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	
	# Separador
	var separator1 = HSeparator.new()
	add_child(separator1)
	
	# Sección de Estadísticas
	_setup_stats_section()
	
	# Separador
	var separator2 = HSeparator.new()
	add_child(separator2)
	
	# Sección de Habilidades
	_setup_skills_section()
	
	# Separador
	var separator3 = HSeparator.new()
	add_child(separator3)
	
	# Sección de Estado Actual
	_setup_status_section()

func _setup_stats_section():
	"""Configura la sección de estadísticas principales"""
	stats_section = VBoxContainer.new()
	stats_section.name = "StatsSection"
	stats_section.add_theme_constant_override("separation", 5)
	
	var stats_title = Label.new()
	stats_title.text = "ESTADISTICAS"
	stats_title.add_theme_font_size_override("font_size", 14)
	stats_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1.0))
	stats_section.add_child(stats_title)
	
	var stats_grid = GridContainer.new()
	stats_grid.name = "StatsGrid"
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 15)
	stats_grid.add_theme_constant_override("v_separation", 8)
	
	# Crear labels para cada estadística
	var stat_names = {
		"strength": "Fuerza",
		"constitution": "Constitucion",
		"dexterity": "Destreza",
		"intelligence": "Inteligencia",
		"wisdom": "Sabiduria",
		"charisma": "Carisma"
	}
	
	for stat_key in ["strength", "constitution", "dexterity", "intelligence", "wisdom", "charisma"]:
		var name_label = Label.new()
		name_label.text = stat_names[stat_key] + ":"
		name_label.add_theme_font_size_override("font_size", 12)
		stats_grid.add_child(name_label)
		
		var value_label = Label.new()
		value_label.name = stat_key + "_value"
		value_label.text = "10 (+0)"
		value_label.add_theme_font_size_override("font_size", 12)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4, 1.0))
		stats_grid.add_child(value_label)
		stats_labels[stat_key] = value_label
	
	stats_section.add_child(stats_grid)
	add_child(stats_section)

func _setup_skills_section():
	"""Configura la sección de habilidades"""
	skills_section = VBoxContainer.new()
	skills_section.name = "SkillsSection"
	skills_section.add_theme_constant_override("separation", 5)
	
	var skills_title = Label.new()
	skills_title.text = "HABILIDADES"
	skills_title.add_theme_font_size_override("font_size", 14)
	skills_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1.0))
	skills_section.add_child(skills_title)
	
	var skills_grid = GridContainer.new()
	skills_grid.name = "SkillsGrid"
	skills_grid.columns = 2
	skills_grid.add_theme_constant_override("h_separation", 15)
	skills_grid.add_theme_constant_override("v_separation", 8)
	
	# Crear labels para cada habilidad
	var skill_names = {
		"science": "Ciencia",
		"diplomacy": "Diplomacia",
		"stealth": "Sigilo",
		"survival": "Supervivencia",
		"combat": "Combate",
		"investigation": "Investigacion",
		"persuasion": "Persuasion",
		"athletics": "Atletismo"
	}
	
	for skill_key in ["science", "diplomacy", "stealth", "survival", "combat", "investigation", "persuasion", "athletics"]:
		var name_label = Label.new()
		name_label.text = skill_names[skill_key] + ":"
		name_label.add_theme_font_size_override("font_size", 11)
		skills_grid.add_child(name_label)
		
		var value_label = Label.new()
		value_label.name = skill_key + "_value"
		value_label.text = "0"
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0, 1.0))
		skills_grid.add_child(value_label)
		skills_labels[skill_key] = value_label
	
	skills_section.add_child(skills_grid)
	add_child(skills_section)

func _setup_status_section():
	"""Configura la sección de estado actual"""
	status_section = VBoxContainer.new()
	status_section.name = "StatusSection"
	status_section.add_theme_constant_override("separation", 5)
	
	var status_title = Label.new()
	status_title.text = "ESTADO ACTUAL"
	status_title.add_theme_font_size_override("font_size", 14)
	status_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1.0))
	status_section.add_child(status_title)
	
	# Cordura
	var sanity_container = VBoxContainer.new()
	sanity_container.add_theme_constant_override("separation", 3)
	
	var sanity_label_container = HBoxContainer.new()
	var sanity_name_label = Label.new()
	sanity_name_label.text = "CORDURA:"
	sanity_name_label.add_theme_font_size_override("font_size", 12)
	sanity_label_container.add_child(sanity_name_label)
	
	sanity_label = Label.new()
	sanity_label.name = "SanityValue"
	sanity_label.text = "85"
	sanity_label.add_theme_font_size_override("font_size", 12)
	sanity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sanity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sanity_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4, 1.0))
	sanity_label_container.add_child(sanity_label)
	sanity_container.add_child(sanity_label_container)
	
	sanity_bar = ProgressBar.new()
	sanity_bar.name = "SanityBar"
	sanity_bar.value = 85
	sanity_bar.max_value = 100
	sanity_bar.custom_minimum_size = Vector2(0, 20)
	
	# Estilo para la barra de cordura
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.08, 1.0)
	bg_style.border_color = Color(0.2, 0.3, 0.4, 0.5)
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	sanity_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 1.0, 0.4, 1.0)
	sanity_bar.add_theme_stylebox_override("fill", fill_style)
	
	sanity_container.add_child(sanity_bar)
	status_section.add_child(sanity_container)
	
	# Necesidades
	var needs_container = VBoxContainer.new()
	needs_container.add_theme_constant_override("separation", 3)
	
	var needs_title = Label.new()
	needs_title.text = "Necesidades:"
	needs_title.add_theme_font_size_override("font_size", 11)
	needs_title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1.0))
	needs_container.add_child(needs_title)
	
	var needs_grid = GridContainer.new()
	needs_grid.columns = 2
	needs_grid.add_theme_constant_override("h_separation", 10)
	needs_grid.add_theme_constant_override("v_separation", 5)
	
	var need_names = {
		"hunger": "Hambre:",
		"thirst": "Sed:",
		"sleep": "Sueno:",
		"stress": "Estres:"
	}
	
	for need_key in ["hunger", "thirst", "sleep", "stress"]:
		var name_label = Label.new()
		name_label.text = need_names[need_key]
		name_label.add_theme_font_size_override("font_size", 10)
		needs_grid.add_child(name_label)
		
		var value_label = Label.new()
		value_label.name = need_key + "_value"
		value_label.text = "50"
		value_label.add_theme_font_size_override("font_size", 10)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1.0))
		needs_grid.add_child(value_label)
		needs_labels[need_key] = value_label
	
	needs_container.add_child(needs_grid)
	status_section.add_child(needs_container)
	
	# Reputación
	var reputation_container = VBoxContainer.new()
	reputation_container.add_theme_constant_override("separation", 3)
	
	var rep_title = Label.new()
	rep_title.text = "Reputación por Región:"
	rep_title.add_theme_font_size_override("font_size", 11)
	rep_title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1.0))
	reputation_container.add_child(rep_title)
	
	var rep_grid = GridContainer.new()
	rep_grid.columns = 2
	rep_grid.add_theme_constant_override("h_separation", 10)
	rep_grid.add_theme_constant_override("v_separation", 5)
	
	var region_names = {
		"pe": "PE:",
		"eo": "EO:",
		"eu": "EU:",
		"ch": "CH:",
		"la": "LA:",
		"as": "AS:",
		"au": "AU:"
	}
	
	for region_key in ["pe", "eo", "eu", "ch", "la", "as", "au"]:
		var name_label = Label.new()
		name_label.text = region_names.get(region_key, region_key.to_upper() + ":")
		name_label.add_theme_font_size_override("font_size", 10)
		rep_grid.add_child(name_label)
		
		var value_label = Label.new()
		value_label.name = region_key + "_rep"
		value_label.text = "0"
		value_label.add_theme_font_size_override("font_size", 10)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1.0))
		rep_grid.add_child(value_label)
		reputation_labels[region_key] = value_label
	
	reputation_container.add_child(rep_grid)
	status_section.add_child(reputation_container)
	
	add_child(status_section)

func set_player_stats(stats: PlayerStats):
	"""Establece las estadísticas del jugador"""
	player_stats = stats
	_update_display()

func set_game_client(client: Node):
	"""Establece la referencia al GameClient"""
	game_client = client
	_update_display()

func _update_display():
	"""Actualiza toda la visualización del panel"""
	_update_stats()
	_update_skills()
	_update_status()

func _update_stats():
	"""Actualiza la sección de estadísticas"""
	if not player_stats:
		return
	
	var stat_keys = ["strength", "constitution", "dexterity", "intelligence", "wisdom", "charisma"]
	for stat_key in stat_keys:
		if not stats_labels.has(stat_key):
			continue
		
		var value = player_stats.get(stat_key)
		var modifier = 0
		match stat_key:
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
		stats_labels[stat_key].text = str(value) + " (" + mod_str + ")"

func _update_skills():
	"""Actualiza la sección de habilidades"""
	if not player_stats:
		return
	
	var skill_keys = ["science", "diplomacy", "stealth", "survival", "combat", "investigation", "persuasion", "athletics"]
	for skill_key in skill_keys:
		if not skills_labels.has(skill_key):
			continue
		
		var bonus = player_stats.calculate_skill_bonus(skill_key)
		var bonus_str = "+" + str(bonus) if bonus >= 0 else str(bonus)
		skills_labels[skill_key].text = bonus_str

func _update_status():
	"""Actualiza la sección de estado actual"""
	# Actualizar cordura
	if game_client and game_client.has_method("get_player_state"):
		var player_state = game_client.get_player_state()
		if player_state:
			if player_state.has("sanity") and sanity_label and sanity_bar:
				var sanity_value = int(player_state.sanity)
				sanity_label.text = str(sanity_value)
				sanity_bar.value = sanity_value
				
				# Actualizar color de la barra según el valor
				_update_sanity_color(sanity_value)
			
			# Actualizar necesidades
			if player_state.has("needs"):
				var needs = player_state.needs
				if needs.has("hunger") and needs_labels.has("hunger"):
					needs_labels["hunger"].text = str(int(needs.hunger))
				if needs.has("thirst") and needs_labels.has("thirst"):
					needs_labels["thirst"].text = str(int(needs.thirst))
				if needs.has("sleep") and needs_labels.has("sleep"):
					needs_labels["sleep"].text = str(int(needs.sleep))
				if needs.has("stress") and needs_labels.has("stress"):
					needs_labels["stress"].text = str(int(needs.stress))
			
			# Actualizar reputación
			if player_state.has("reputation"):
				var reputation = player_state.reputation
				for region_key in reputation_labels.keys():
					if reputation.has(region_key):
						reputation_labels[region_key].text = str(int(reputation[region_key]))

func _update_sanity_color(value: int):
	"""Actualiza el color de la barra de cordura según el valor"""
	if not sanity_bar:
		return
	
	var fill_style = StyleBoxFlat.new()
	var color: Color
	
	if value >= 70:
		color = Color(0.0, 1.0, 0.4, 1.0)  # Verde
	elif value >= 50:
		color = Color(0.8, 0.9, 0.0, 1.0)  # Amarillo verdoso
	elif value >= 30:
		color = Color(1.0, 0.4, 0.0, 1.0)  # Naranja
	else:
		color = Color(1.0, 0.0, 0.2, 1.0)  # Rojo
	
	fill_style.bg_color = color
	fill_style.border_color = color.lightened(0.3)
	fill_style.border_width_left = 1
	fill_style.border_width_right = 1
	fill_style.border_width_top = 1
	fill_style.border_width_bottom = 1
	sanity_bar.add_theme_stylebox_override("fill", fill_style)

func update_from_game_client():
	"""Actualiza el panel con datos del GameClient"""
	_update_status()
	
	# Intentar obtener PlayerStats del GameClient si está disponible
	if game_client and game_client.has_method("get_player_stats"):
		var stats = game_client.get_player_stats()
		if stats:
			set_player_stats(stats)
