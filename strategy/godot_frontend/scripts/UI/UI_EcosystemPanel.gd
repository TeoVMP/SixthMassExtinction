# UI_EcosystemPanel.gd (nuevo panel para la UI)
extends Control

var ecosystem_grid: GridContainer = null
var tipping_points_grid: GridContainer = null
var ecosystem_manager: Node = null
var climate_system: Node = null

func _ready():
	_setup_ui()
	
	# Conectar al ecosystem manager si existe
	ecosystem_manager = get_tree().root.find_child("EcosystemManager", true, false)
	if ecosystem_manager:
		if ecosystem_manager.has_signal("ecosystem_updated"):
			ecosystem_manager.ecosystem_updated.connect(update_ecosystem_display)
		if ecosystem_manager.has_signal("ecosystem_critical"):
			ecosystem_manager.ecosystem_critical.connect(_on_ecosystem_critical)
	
	# Buscar ClimateSystem para los tipping points
	climate_system = get_tree().root.find_child("ClimateSystem", true, false)
	if climate_system:
		if climate_system.has_signal("tipping_point_activated"):
			climate_system.tipping_point_activated.connect(_on_tipping_point_activated)
		if climate_system.has_signal("climate_update_complete"):
			climate_system.climate_update_complete.connect(_update_all_tipping_points)
	
	# Cargar ecosistemas y tipping points
	_load_ecosystems()
	_load_tipping_points()
	
	# Iniciar timer para actualizar tipping points periódicamente
	_start_tipping_points_update_timer()

func _setup_ui():
	"""Configura la UI del panel de ecosistemas"""
	# Estilo de fondo
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.1, 0.05, 0.98)
	bg_style.border_color = Color(0.0, 1.0, 0.4, 0.8)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	add_theme_stylebox_override("panel", bg_style)
	
	# Contenedor principal
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 10)
	main_container.add_theme_constant_override("margin_left", 15)
	main_container.add_theme_constant_override("margin_right", 15)
	main_container.add_theme_constant_override("margin_top", 15)
	main_container.add_theme_constant_override("margin_bottom", 15)
	add_child(main_container)
	
	# Título
	var title = Label.new()
	title.text = "🌍 ECOSISTEMAS DEL MUNDO"
	title.add_theme_font_size_override("font_size", 24)
	var title_color = Color(0.0, 1.0, 0.4)
	title.add_theme_color_override("font_color", title_color)
	main_container.add_child(title)
	
	# Separador
	var separator = HSeparator.new()
	main_container.add_child(separator)
	
	# ScrollContainer para permitir scroll si hay muchos elementos
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(scroll)
	
	var scroll_content = VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_content)
	
	# Sección de Ecosistemas
	var ecosystems_label = Label.new()
	ecosystems_label.text = "ECOSISTEMAS"
	ecosystems_label.add_theme_font_size_override("font_size", 18)
	ecosystems_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	scroll_content.add_child(ecosystems_label)
	
	# Grid de ecosistemas
	ecosystem_grid = GridContainer.new()
	ecosystem_grid.columns = 2
	ecosystem_grid.add_theme_constant_override("h_separation", 15)
	ecosystem_grid.add_theme_constant_override("v_separation", 15)
	scroll_content.add_child(ecosystem_grid)
	
	# Separador entre ecosistemas y tipping points
	var separator2 = HSeparator.new()
	scroll_content.add_child(separator2)
	
	# Sección de Tipping Points
	var tipping_label = Label.new()
	tipping_label.text = "🚨 CLIMATE TIPPING POINTS (9)"
	tipping_label.add_theme_font_size_override("font_size", 18)
	tipping_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	scroll_content.add_child(tipping_label)
	
	# Grid de tipping points
	tipping_points_grid = GridContainer.new()
	tipping_points_grid.columns = 2
	tipping_points_grid.add_theme_constant_override("h_separation", 15)
	tipping_points_grid.add_theme_constant_override("v_separation", 15)
	scroll_content.add_child(tipping_points_grid)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.custom_minimum_size = Vector2(100, 35)
	close_button.pressed.connect(_on_close_pressed)
	main_container.add_child(close_button)

func _load_ecosystems():
	"""Carga los ecosistemas desde el EcosystemManager"""
	if not ecosystem_manager:
		print("⚠️ EcosystemManager no encontrado")
		var no_data_label = Label.new()
		no_data_label.text = "EcosystemManager no encontrado"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ecosystem_grid.add_child(no_data_label)
		return
	
	# Acceder directamente al diccionario de ecosistemas
	# EcosystemManager tiene la propiedad ecosystems como Dictionary
	var ecosystems: Dictionary = {}
	
	# Acceder directamente a la propiedad (sabemos que existe en EcosystemManager)
	ecosystems = ecosystem_manager.ecosystems
	
	# Verificar que tenemos un diccionario válido
	if not (ecosystems is Dictionary):
		print("⚠️ La propiedad ecosystems no es un Dictionary")
		var no_data_label = Label.new()
		no_data_label.text = "Error: ecosistemas no es un diccionario válido"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ecosystem_grid.add_child(no_data_label)
		return
	
	if ecosystems.is_empty():
		var no_data_label = Label.new()
		no_data_label.text = "No hay ecosistemas disponibles"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ecosystem_grid.add_child(no_data_label)
		return
	
	if ecosystems.is_empty():
		var no_data_label = Label.new()
		no_data_label.text = "No hay ecosistemas disponibles"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ecosystem_grid.add_child(no_data_label)
		return
	
	# Crear widgets para cada ecosistema
	for eco_id in ecosystems:
		var state = ecosystems[eco_id]
		if state:
			var widget = _create_ecosystem_widget(eco_id, state)
			ecosystem_grid.add_child(widget)

func _load_tipping_points():
	"""Carga los tipping points climáticos desde el ClimateSystem"""
	if not climate_system:
		print("⚠️ ClimateSystem no encontrado")
		if tipping_points_grid:
			var no_data_label = Label.new()
			no_data_label.text = "ClimateSystem no encontrado"
			no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tipping_points_grid.add_child(no_data_label)
		return
	
	if not tipping_points_grid:
		return
	
	# Acceder directamente al diccionario de tipping points
	var tipping_points: Dictionary = {}
	tipping_points = climate_system.tipping_points
	
	if not (tipping_points is Dictionary):
		var no_data_label = Label.new()
		no_data_label.text = "Error: tipping_points no es un Dictionary"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tipping_points_grid.add_child(no_data_label)
		return
	
	if tipping_points.is_empty():
		var no_data_label = Label.new()
		no_data_label.text = "No hay tipping points disponibles"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tipping_points_grid.add_child(no_data_label)
		return
	
	# Crear widgets para cada tipping point
	for tip_id in tipping_points:
		var tip = tipping_points[tip_id]
		if tip:
			var widget = _create_tipping_point_widget(tip_id, tip)
			tipping_points_grid.add_child(widget)

func _create_tipping_point_widget(tip_id: String, tip: ClimateTippingPoint) -> Control:
	"""Crea un widget para mostrar un tipping point"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 180)
	
	# Estilo del panel - más dramático para tipping points
	var panel_style = StyleBoxFlat.new()
	var bg_color = Color(0.15, 0.1, 0.1, 0.9)
	var border_color = Color(1.0, 0.3, 0.2, 0.8)
	
	# Color según estado
	if tip.is_activated:
		bg_color = Color(0.3, 0.1, 0.1, 0.95)
		border_color = Color(1.0, 0.0, 0.0, 1.0)
	elif tip.activation_probability > 0.7:
		bg_color = Color(0.25, 0.15, 0.1, 0.9)
		border_color = Color(1.0, 0.5, 0.0, 0.9)
	elif tip.activation_probability > 0.4:
		bg_color = Color(0.2, 0.15, 0.1, 0.9)
		border_color = Color(1.0, 0.7, 0.0, 0.8)
	
	panel_style.bg_color = bg_color
	panel_style.border_color = border_color
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 8)
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 10)
	container.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(container)
	
	# Nombre del tipping point
	var name_label = Label.new()
	name_label.text = "🚨 " + tip.name.to_upper()
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	container.add_child(name_label)
	
	# Estado
	var status_label = Label.new()
	status_label.text = "Estado: " + tip.get_status()
	status_label.add_theme_font_size_override("font_size", 12)
	if tip.is_activated:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	elif tip.activation_probability > 0.7:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	container.add_child(status_label)
	
	# Progreso hacia el threshold
	var progress_label = Label.new()
	var progress_pct = (tip.current_value / tip.threshold * 100.0) if tip.threshold > 0 else 0.0
	progress_label.text = "Progreso: %.1f%% / %.1f" % [tip.current_value, tip.threshold]
	progress_label.add_theme_font_size_override("font_size", 11)
	container.add_child(progress_label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.max_value = tip.threshold
	progress_bar.value = tip.current_value
	progress_bar.custom_minimum_size = Vector2(0, 20)
	# Color según progreso
	if tip.is_activated:
		progress_bar.modulate = Color.RED
	elif progress_pct >= 90:
		progress_bar.modulate = Color(1.0, 0.3, 0.0)  # Naranja oscuro
	elif progress_pct >= 70:
		progress_bar.modulate = Color.YELLOW
	else:
		progress_bar.modulate = Color(0.5, 0.8, 1.0)  # Azul claro
	container.add_child(progress_bar)
	
	# Probabilidad de activación
	var prob_label = Label.new()
	prob_label.text = "Probabilidad: %.1f%%" % (tip.activation_probability * 100.0)
	prob_label.add_theme_font_size_override("font_size", 11)
	if tip.activation_probability > 0.7:
		prob_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	container.add_child(prob_label)
	
	# Descripción (truncada)
	if tip.description.length() > 0:
		var desc_label = Label.new()
		desc_label.text = tip.description.substr(0, 80) + "..." if tip.description.length() > 80 else tip.description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		container.add_child(desc_label)
	
	# Guardar referencias para actualizaciones
	panel.set_meta("tip_id", tip_id)
	panel.set_meta("progress_bar", progress_bar)
	panel.set_meta("status_label", status_label)
	panel.set_meta("progress_label", progress_label)
	panel.set_meta("prob_label", prob_label)
	
	return panel

func _create_ecosystem_widget(eco_id: String, state: EcosystemState) -> Control:
	"""Crea un widget para mostrar un ecosistema"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 150)
	
	# Estilo del panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.15, 0.1, 0.8)
	panel_style.border_color = Color(0.0, 0.6, 0.2, 0.6)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 8)
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 10)
	container.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(container)
	
	# Nombre del ecosistema
	var name_label = Label.new()
	name_label.text = eco_id.to_upper()
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	container.add_child(name_label)
	
	# Estado
	var status_label = Label.new()
	status_label.text = "Estado: " + state.get_status()
	status_label.add_theme_font_size_override("font_size", 12)
	container.add_child(status_label)
	
	# Barra de salud
	var health_label = Label.new()
	health_label.text = "Salud: " + str(int(state.health)) + "%"
	health_label.add_theme_font_size_override("font_size", 11)
	container.add_child(health_label)
	
	var health_bar = ProgressBar.new()
	health_bar.max_value = 100
	health_bar.value = state.health
	health_bar.custom_minimum_size = Vector2(0, 20)
	# Color según salud
	if state.health >= 60:
		health_bar.modulate = Color.GREEN
	elif state.health >= 30:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED
	container.add_child(health_bar)
	
	# Biodiversidad
	var biodiv_label = Label.new()
	biodiv_label.text = "Biodiversidad: " + str(int(state.biodiversity)) + "%"
	biodiv_label.add_theme_font_size_override("font_size", 11)
	container.add_child(biodiv_label)
	
	var biodiv_bar = ProgressBar.new()
	biodiv_bar.max_value = 100
	biodiv_bar.value = state.biodiversity
	biodiv_bar.custom_minimum_size = Vector2(0, 20)
	biodiv_bar.modulate = Color(0.0, 0.8, 1.0)  # Cyan
	container.add_child(biodiv_bar)
	
	# Guardar referencia al estado para actualizaciones
	panel.set_meta("eco_id", eco_id)
	panel.set_meta("health_bar", health_bar)
	panel.set_meta("biodiv_bar", biodiv_bar)
	panel.set_meta("status_label", status_label)
	panel.set_meta("health_label", health_label)
	panel.set_meta("biodiv_label", biodiv_label)
	
	return panel

func _on_close_pressed():
	"""Cierra el panel de ecosistemas"""
	queue_free()

func _start_tipping_points_update_timer():
	"""Inicia un timer para actualizar los tipping points periódicamente"""
	var timer = Timer.new()
	timer.wait_time = 2.0  # Actualizar cada 2 segundos
	timer.autostart = true
	timer.timeout.connect(_update_all_tipping_points)
	add_child(timer)

func _update_all_tipping_points():
	"""Actualiza todos los widgets de tipping points"""
	if not climate_system or not tipping_points_grid:
		return
	
	var tipping_points = climate_system.tipping_points
	if not (tipping_points is Dictionary):
		return
	
	# Actualizar cada widget
	for child in tipping_points_grid.get_children():
		var tip_id = child.get_meta("tip_id", "")
		if tip_id != "" and tipping_points.has(tip_id):
			var tip = tipping_points[tip_id]
			if tip:
				_update_tipping_point_widget(child, tip)

# Función de mapa eliminada - no se usa en este panel básico

func _on_ecosystem_critical(eco_id: String, state: EcosystemState):
	"""Maneja ecosistemas críticos"""
	print("⚠️ Ecosistema crítico: ", eco_id)
	if state:
		print("   Estado: ", state.get_status(), " - Salud: ", state.health)

func _on_tipping_point_activated(tip_id: String, tip: ClimateTippingPoint):
	"""Maneja la activación de un tipping point"""
	print("🚨 TIPPING POINT ACTIVADO: ", tip_id)
	# Actualizar el widget del tipping point
	if tipping_points_grid:
		for child in tipping_points_grid.get_children():
			if child.get_meta("tip_id", "") == tip_id:
				_update_tipping_point_widget(child, tip)
				break

func update_ecosystem_display(eco_id: String, state: EcosystemState):
	"""Actualiza la visualización de un ecosistema"""
	if not ecosystem_grid:
		return
	
	# Buscar el widget del ecosistema
	for child in ecosystem_grid.get_children():
		if child.get_meta("eco_id", "") == eco_id:
			# Actualizar barras y labels
			var health_bar = child.get_meta("health_bar", null)
			var biodiv_bar = child.get_meta("biodiv_bar", null)
			var status_label = child.get_meta("status_label", null)
			var health_label = child.get_meta("health_label", null)
			var biodiv_label = child.get_meta("biodiv_label", null)
			
			if health_bar:
				health_bar.value = state.health
				# Actualizar color según salud
				if state.health >= 60:
					health_bar.modulate = Color.GREEN
				elif state.health >= 30:
					health_bar.modulate = Color.YELLOW
				else:
					health_bar.modulate = Color.RED
			
			if biodiv_bar:
				biodiv_bar.value = state.biodiversity
			
			if status_label:
				status_label.text = "Estado: " + state.get_status()
			
			if health_label:
				health_label.text = "Salud: " + str(int(state.health)) + "%"
			
			if biodiv_label:
				biodiv_label.text = "Biodiversidad: " + str(int(state.biodiversity)) + "%"
			
			break

func _update_tipping_point_widget(widget: Control, tip: ClimateTippingPoint):
	"""Actualiza un widget de tipping point"""
	if not widget or not tip:
		return
	
	var progress_bar = widget.get_meta("progress_bar", null)
	var status_label = widget.get_meta("status_label", null)
	var progress_label = widget.get_meta("progress_label", null)
	var prob_label = widget.get_meta("prob_label", null)
	
	if progress_bar:
		progress_bar.value = tip.current_value
		var progress_pct = (tip.current_value / tip.threshold * 100.0) if tip.threshold > 0 else 0.0
		if tip.is_activated:
			progress_bar.modulate = Color.RED
		elif progress_pct >= 90:
			progress_bar.modulate = Color(1.0, 0.3, 0.0)
		elif progress_pct >= 70:
			progress_bar.modulate = Color.YELLOW
		else:
			progress_bar.modulate = Color(0.5, 0.8, 1.0)
	
	if status_label:
		status_label.text = "Estado: " + tip.get_status()
		if tip.is_activated:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
		elif tip.activation_probability > 0.7:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	
	if progress_label:
		progress_label.text = "Progreso: %.1f%% / %.1f" % [tip.current_value, tip.threshold]
	
	if prob_label:
		prob_label.text = "Probabilidad: %.1f%%" % (tip.activation_probability * 100.0)
		if tip.activation_probability > 0.7:
			prob_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))

# Función de mapa eliminada - no se usa en este panel básico

# Widget individual para ecosistema
class EcosystemWidget extends PanelContainer:
	var eco_id: String
	
	func setup(eco_id: String, initial_state: EcosystemState):
		self.eco_id = eco_id
		update_display(initial_state)
	
	func update_display(state: EcosystemState):
		$HealthBar.value = state.health
		$BiodiversityBar.value = state.biodiversity
		$StatusLabel.text = state.get_status()
		
		# Color según estado
		var style = StyleBoxFlat.new()
		if state.health >= 60: style.bg_color = Color(0, 0.4, 0, 0.1)
		elif state.health >= 30: style.bg_color = Color(0.4, 0.4, 0, 0.1)
		else: style.bg_color = Color(0.4, 0, 0, 0.1)
		add_theme_stylebox_override("panel", style)
