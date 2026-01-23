# WorldMapPanel.gd
# Panel de mapa del mundo interactivo con estadísticas en tiempo real
extends Control
class_name WorldMapPanel

signal region_selected(region_code: String)
signal ecosystem_selected(ecosystem_id: String)

# Referencias a nodos
var map_container: Control = null
var stats_panel: PanelContainer = null
var ecosystem_panel: Control = null
var region_detail_panel: Window = null  # Ahora es una ventana

# Referencias a sistemas
var game_client: Node = null
var ecosystem_manager: Node = null

# Estado
var selected_region: String = ""
var region_stats: Dictionary = {}
var ecosystem_stats: Dictionary = {}
var region_violence: Dictionary = {}  # Violencia por región

# Sistema de zoom
var zoom_level: float = 1.0
var min_zoom: float = 0.5
var max_zoom: float = 3.0
var zoom_speed: float = 0.1

# Tooltip
var tooltip_panel: PanelContainer = null
var tooltip_timer: Timer = null

# Mission Manager
var mission_manager: Node = null

# Referencia a la ventana padre (si existe)
var parent_window: Window = null

# Regiones del juego con sus coordenadas aproximadas (normalizadas 0-1)
# Incluye influencia de Cartógrafos (político-social y económica)
# Coordenadas en píxeles absolutos - se convertirán a normalizadas dinámicamente
# Tamaño de referencia del mapa: necesitamos saber el tamaño real del contenedor
var region_data_pixels = {
	"eu": {"x": 301, "y": 425},
	"ca": {"x": 313, "y": 551},
	"sa": {"x": 392, "y": 670},
	"africa_occidental": {"x": 500, "y": 592},
	"africa_oriental": {"x": 586, "y": 637},
	"sudafrica": {"x": 555, "y": 752},
	"africa_norte": {"x": 525, "y": 492},
	"mena": {"x": 585, "y": 486},
	"eo": {"x": 519, "y": 411},
	"ee": {"x": 560, "y": 375},
	"ch": {"x": 718, "y": 480},
	"as": {"x": 665, "y": 537},
	"seasia": {"x": 711, "y": 542},
	"oceania": {"x": 773, "y": 734},
	"ru": {"x": 560, "y": 375},  # Fusionado con Europa Oriental
}

# Regiones del juego con coordenadas normalizadas calculadas dinámicamente
var region_data = {
	"eu": {
		"name": "Estados Unidos", 
		"color": Color(0.8, 0.2, 0.2), 
		"position": Vector2(0.253, 0.559),  # Se actualizará dinámicamente
		"cartograph_political_influence": 75.0,
		"cartograph_economic_influence": 85.0
	},
	"ca": {
		"name": "América Central", 
		"color": Color(0.3, 0.8, 0.4), 
		"position": Vector2(0.263, 0.725),
		"cartograph_political_influence": 50.0,
		"cartograph_economic_influence": 65.0
	},
	"sa": {
		"name": "Sudamérica", 
		"color": Color(0.2, 0.7, 0.3), 
		"position": Vector2(0.329, 0.882),
		"cartograph_political_influence": 35.0,
		"cartograph_economic_influence": 55.0
	},
	"africa_occidental": {
		"name": "África Occidental", 
		"color": Color(0.8, 0.5, 0.2), 
		"position": Vector2(0.420, 0.779),
		"cartograph_political_influence": 45.0,
		"cartograph_economic_influence": 60.0
	},
	"africa_oriental": {
		"name": "África Oriental", 
		"color": Color(0.9, 0.6, 0.2), 
		"position": Vector2(0.492, 0.838),
		"cartograph_political_influence": 40.0,
		"cartograph_economic_influence": 55.0
	},
	"sudafrica": {
		"name": "Sudáfrica", 
		"color": Color(0.9, 0.8, 0.3), 
		"position": Vector2(0.466, 0.989),
		"cartograph_political_influence": 50.0,
		"cartograph_economic_influence": 65.0
	},
	"africa_norte": {
		"name": "África del Norte", 
		"color": Color(0.9, 0.7, 0.3), 
		"position": Vector2(0.441, 0.647),
		"cartograph_political_influence": 55.0,
		"cartograph_economic_influence": 70.0
	},
	"mena": {
		"name": "Medio Oriente", 
		"color": Color(0.9, 0.7, 0.3), 
		"position": Vector2(0.492, 0.639),
		"cartograph_political_influence": 55.0,
		"cartograph_economic_influence": 70.0
	},
	"eo": {
		"name": "Europa Occidental", 
		"color": Color(0.2, 0.4, 0.8), 
		"position": Vector2(0.436, 0.541),
		"cartograph_political_influence": 70.0,
		"cartograph_economic_influence": 80.0
	},
	"ee": {
		"name": "Europa Oriental", 
		"color": Color(0.3, 0.5, 0.7), 
		"position": Vector2(0.471, 0.493),
		"cartograph_political_influence": 55.0,
		"cartograph_economic_influence": 60.0
	},
	"ch": {
		"name": "China", 
		"color": Color(0.9, 0.1, 0.1), 
		"position": Vector2(0.603, 0.632),
		"cartograph_political_influence": 65.0,
		"cartograph_economic_influence": 70.0
	},
	"as": {
		"name": "Asia Sur", 
		"color": Color(0.3, 0.6, 0.3), 
		"position": Vector2(0.559, 0.707),
		"cartograph_political_influence": 40.0,
		"cartograph_economic_influence": 50.0
	},
	"seasia": {
		"name": "Sudeste Asiático", 
		"color": Color(0.4, 0.7, 0.5), 
		"position": Vector2(0.598, 0.713),
		"cartograph_political_influence": 45.0,
		"cartograph_economic_influence": 60.0
	},
	"oceania": {
		"name": "Oceanía", 
		"color": Color(0.2, 0.5, 0.8), 
		"position": Vector2(0.650, 0.966),
		"cartograph_political_influence": 50.0,
		"cartograph_economic_influence": 60.0
	},
	"ru": {
		"name": "Rusia", 
		"color": Color(0.7, 0.1, 0.1), 
		"position": Vector2(0.471, 0.493),
		"cartograph_political_influence": 60.0,
		"cartograph_economic_influence": 55.0
	},
	"africa_central": {
		"name": "África Central", 
		"color": Color(0.8, 0.6, 0.3), 
		"position": Vector2(0.50, 0.50),
		"cartograph_political_influence": 35.0,
		"cartograph_economic_influence": 50.0
	}
}

# Ecosistemas principales (actualizados con nuevas regiones)
# Nota: Algunos ecosistemas tienen posiciones específicas en lugar de offsets relativos
var ecosystem_data = {
	"amazon": {"name": "Amazonas", "region": "sa", "health": 65.0, "type": "forest", "position_override": Vector2(0.32, 0.55)},
	"great_barrier": {"name": "Gran Barrera de Coral", "region": "oceania", "health": 35.0, "type": "coral", "position_override": Vector2(0.88, 0.68)},
	"pantanal": {"name": "Pantanal", "region": "sa", "health": 55.0, "type": "wetland", "position_override": Vector2(0.35, 0.72)},
	"arctic": {"name": "Ártico", "region": "ru", "health": 40.0, "type": "tundra", "position_override": Vector2(0.5, 0.08)},
	"sahara": {"name": "Sahara", "region": "africa_norte", "health": 30.0, "type": "desert", "position_override": Vector2(0.50, 0.38)},
	"mesoamerican_reef": {"name": "Arrecife Mesoamericano", "region": "ca", "health": 45.0, "type": "coral", "position_override": Vector2(0.25, 0.48)},
	"cerrado": {"name": "Cerrado", "region": "sa", "health": 50.0, "type": "savanna", "position_override": Vector2(0.35, 0.65)},
	"congo_basin": {"name": "Cuenca del Congo", "region": "africa_central", "health": 60.0, "type": "forest", "position_override": Vector2(0.52, 0.58)}
}

func _ready():
	print("WorldMapPanel inicializado")
	print("   Tamaño del panel en _ready: ", size)
	print("   Visible en _ready: ", visible)
	print("   Anchors en _ready: left=", anchor_left, ", right=", anchor_right)
	
	# Asegurar que el panel sea visible
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10
	
	# Esperar un frame para que el tamaño se calcule
	await get_tree().process_frame
	print("   Tamaño después de frame: ", size)
	print("   Rect: ", get_rect())
	print("   Anchors después de frame: left=", anchor_left, ", right=", anchor_right)
	
	_setup_map()
	# Eliminado _setup_panels() - las estadísticas mundiales se abren con botón separado
	_update_stats()
	start_update_timer()
	_setup_zoom()
	_setup_tooltip()
	_setup_mission_manager()
	
	# Forzar redibujado después de un frame
	call_deferred("_ensure_visibility")
	call_deferred("_debug_panel_state")
	
	# Imprimir posiciones actuales para referencia
	call_deferred("_print_region_positions")

func _update_layout():
	"""Fuerza actualización del layout - llamado desde UI_Main"""
	queue_redraw()

func _setup_map():
	"""Configura el mapa interactivo"""
	# Crear header con título y botón cerrar
	var header = HBoxContainer.new()
	header.name = "MapHeader"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 30
	header.add_theme_constant_override("separation", 10)
	add_child(header)
	
	# Título del mapa
	var title_label = Label.new()
	title_label.name = "MapTitle"
	title_label.text = "MAPA DEL MUNDO"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	# Botón cerrar funcional
	var close_button = Button.new()
	close_button.text = "✕ Cerrar"
	close_button.custom_minimum_size = Vector2(100, 25)
	close_button.pressed.connect(_on_close_button_pressed)
	header.add_child(close_button)
	
	# Crear área de mapa si no existe
	if not map_container:
		map_container = Panel.new()
		map_container.name = "MapContainer"
		map_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		map_container.offset_top = 35  # Dejar espacio para el header
		map_container.offset_left = 5
		map_container.offset_right = -5
		map_container.offset_bottom = -5
		
		# Estilo del mapa con tema cyberpunk - fondo transparente para ver la imagen
		var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
		var map_style = StyleBoxFlat.new()
		# Fondo transparente para que se vea la imagen de fondo
		map_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)  # Completamente transparente
		if CyberpunkThemeClass:
			map_style.border_color = CyberpunkThemeClass.COLOR_NEON_CYAN
		else:
			map_style.border_color = Color(0.0, 1.0, 1.0)
		map_style.border_width_left = 1
		map_style.border_width_right = 1
		map_style.border_width_top = 1
		map_style.border_width_bottom = 1
		map_container.add_theme_stylebox_override("panel", map_style)
		
		# Cargar imagen de fondo del mapa - Prioridad: mapamundi.jpg (imagen estilizada del juego)
		var map_image_paths = [
			"res://img/mapamundi.jpg",
			"res://img/mapamundi_cleaned.jpg",
			"res://img/mapamundi.webp"
		]
		
		var map_texture: Texture = null
		var loaded_path = ""
		
		for path in map_image_paths:
			if ResourceLoader.exists(path):
				print("Intentando cargar imagen: ", path)
				var resource = load(path)
				if resource and resource is Texture:
					map_texture = resource as Texture
					loaded_path = path
					print("Imagen de mapa cargada exitosamente: ", path)
					if map_texture:
						print("Tipo de textura: ", map_texture.get_class())
						print("Tamaño de textura: ", map_texture.get_width(), "x", map_texture.get_height())
					break
				else:
					var resource_type = "null"
					if resource:
						resource_type = resource.get_class()
					print("El recurso en ", path, " no es una Texture (tipo: ", resource_type, ")")
		
		if map_texture:
			var texture_rect = TextureRect.new()
			texture_rect.name = "MapBackground"
			texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			texture_rect.set_offsets_preset(Control.PRESET_FULL_RECT)
			texture_rect.texture = map_texture
			# Modo de estiramiento para que la imagen se vea correctamente
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Color normal, completamente opaco
			texture_rect.z_index = 0  # Fondo, pero visible
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # No bloquear clicks en los puntos
			# Añadir la imagen ANTES de añadir el contenedor al árbol para que esté en el fondo
			map_container.add_child(texture_rect)
			# Mover la imagen al fondo del contenedor
			map_container.move_child(texture_rect, 0)
			print("TextureRect creado y añadido al contenedor")
		else:
			print("No se pudo cargar ninguna imagen de mapa. Rutas intentadas: ", map_image_paths)
		
		add_child(map_container)
	
	# Dibujar regiones y ecosistemas después de que el contenedor tenga tamaño
	call_deferred("_draw_regions")
	call_deferred("_draw_ecosystems")
	
	# Conectar señal para obtener coordenadas en modo debug (click derecho en el mapa)
	if map_container:
		map_container.gui_input.connect(_on_map_container_gui_input)
		# También conectar para mostrar coordenadas al hacer hover (modo debug)
		map_container.mouse_entered.connect(_on_map_mouse_entered)
		map_container.mouse_exited.connect(_on_map_mouse_exited)

func _draw_regions():
	"""Dibuja las regiones como puntos brillantes cyberpunk en el mapa"""
	if not map_container:
		return
	
	# Limpiar regiones existentes
	for child in map_container.get_children():
		if child.name.begins_with("Region_"):
			child.queue_free()
	
	# Esperar a que el contenedor tenga tamaño
	if map_container.size.x <= 0 or map_container.size.y <= 0:
		await get_tree().process_frame
		if map_container.size.x <= 0 or map_container.size.y <= 0:
			return
	
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var point_size = 20  # Tamaño del punto (declarado fuera del loop)
	
	# Obtener tamaño real del mapa
	var map_size = map_container.size
	# Tamaño de referencia para las coordenadas en píxeles
	# Basado en las coordenadas máximas: Oceania (773, 734) y Sudáfrica (555, 752)
	# Probamos con diferentes tamaños de referencia hasta encontrar el correcto
	# Si las posiciones no coinciden, ajusta estos valores
	var ref_width = 1200.0
	var ref_height = 800.0
	
	# Si el mapa tiene un tamaño diferente, ajustamos la referencia proporcionalmente
	# Esto permite que las coordenadas se escalen correctamente
	if map_size.x > 0 and map_size.y > 0:
		# Calcular factor de escala basado en el tamaño real vs referencia
		var scale_x = map_size.x / ref_width
		var scale_y = map_size.y / ref_height
		print("[DEBUG] Tamaño del mapa: ", map_size, " | Referencia: ", ref_width, "x", ref_height, " | Escala: ", scale_x, "x", scale_y)
	
	# Crear puntos brillantes para cada región
	for region_code in region_data:
		var region_info = region_data[region_code]
		
		# Calcular posición: usar coordenadas en píxeles si están disponibles
		var final_position: Vector2
		if region_code in region_data_pixels:
			# Convertir píxeles a normalizado basado en tamaño de referencia
			var pixel_data = region_data_pixels[region_code]
			final_position = Vector2(
				pixel_data.x / ref_width,
				pixel_data.y / ref_height
			)
		else:
			# Usar posición normalizada directamente
			final_position = region_info.position
		
		# Crear contenedor para el punto (para poder añadir efectos)
		var point_container = Control.new()
		point_container.name = "Region_" + region_code
		point_container.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Posición basada en datos de región
		if map_size.x > 0 and map_size.y > 0:
			point_container.position = Vector2(
				final_position.x * map_size.x - point_size / 2,
				final_position.y * map_size.y - point_size / 2
			)
			point_container.custom_minimum_size = Vector2(point_size, point_size)
			point_container.size = Vector2(point_size, point_size)
		
		# Crear el punto brillante (ColorRect con estilo cyberpunk)
		var point = ColorRect.new()
		point.name = "Point"
		point.set_anchors_preset(Control.PRESET_FULL_RECT)
		var point_color = CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 1.0)
		point.color = point_color
		point.mouse_filter = Control.MOUSE_FILTER_IGNORE  # El contenedor maneja los eventos
		
		# Añadir efecto de brillo usando un Panel con sombra
		var glow_panel = Panel.new()
		glow_panel.name = "Glow"
		glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var glow_style = StyleBoxFlat.new()
		var glow_color = CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 1.0)
		glow_style.bg_color = glow_color
		glow_style.bg_color.a = 0.3
		glow_style.shadow_color = glow_color
		glow_style.shadow_color.a = 0.6
		glow_style.shadow_size = 8
		glow_style.shadow_offset = Vector2(0, 0)
		glow_panel.add_theme_stylebox_override("panel", glow_style)
		point_container.add_child(glow_panel)
		
		point_container.add_child(point)
		
		# Añadir contador de misiones activas (si hay)
		var mission_count = _get_active_missions_count(region_code)
		if mission_count > 0:
			var count_label = Label.new()
			count_label.name = "MissionCount"
			count_label.text = str(mission_count)
			count_label.add_theme_font_size_override("font_size", 10)
			var count_color = CyberpunkThemeClass.COLOR_NEON_ORANGE if CyberpunkThemeClass else Color(1.0, 0.6, 0.0)
			count_label.add_theme_color_override("font_color", count_color)
			count_label.position = Vector2(point_size + 5, -5)
			point_container.add_child(count_label)
		
		# Conectar señales de interacción - usar callables con bind para capturar variables
		point_container.gui_input.connect(_on_region_point_input.bind(region_code))
		point_container.mouse_entered.connect(_on_region_point_hover.bind(region_code, point_container))
		point_container.mouse_exited.connect(_on_region_point_unhover.bind(region_code, point_container))
		
		# Asegurar que el punto esté por encima de la imagen de fondo
		point_container.z_index = 10
		
		map_container.add_child(point_container)

func _draw_ecosystems():
	"""Dibuja los ecosistemas como elementos clickeables en el mapa"""
	if not map_container:
		return
	
	# Limpiar ecosistemas existentes
	for child in map_container.get_children():
		if child.name.begins_with("Ecosystem_"):
			child.queue_free()
	
	# Esperar a que el contenedor tenga tamaño
	if map_container.size.x <= 0 or map_container.size.y <= 0:
		await get_tree().process_frame
		if map_container.size.x <= 0 or map_container.size.y <= 0:
			return
	
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var eco_point_size = 15  # Tamaño del punto de ecosistema (más pequeño que las regiones)
	
	# Crear puntos para cada ecosistema
	for eco_id in ecosystem_data:
		var eco_info = ecosystem_data[eco_id]
		var region_code = eco_info.get("region", "")
		var map_size = map_container.size
		
		if map_size.x <= 0 or map_size.y <= 0:
			continue
		
		# Determinar posición del ecosistema
		var eco_position: Vector2
		
		# Si tiene posición específica, usarla
		if eco_info.has("position_override"):
			eco_position = Vector2(
				eco_info.position_override.x * map_size.x,
				eco_info.position_override.y * map_size.y
			)
		# Si no, calcular basándose en la región
		elif region_code and region_code in region_data:
			var region_info = region_data[region_code]
			var base_pos = Vector2(
				region_info.position.x * map_size.x,
				region_info.position.y * map_size.y
			)
			
			# Offset basado en el tipo de ecosistema para evitar superposición
			var offset = Vector2(0, 0)
			match eco_info.get("type", ""):
				"forest":
					offset = Vector2(25, -15)
				"coral":
					offset = Vector2(-20, 20)
				"wetland":
					offset = Vector2(15, 25)
				"tundra":
					offset = Vector2(-25, -20)
				"desert":
					offset = Vector2(20, -25)
				"savanna":
					offset = Vector2(-15, 15)
				_:
					offset = Vector2(0, 0)
			
			eco_position = base_pos + offset
		else:
			# Si no tiene región válida, saltar este ecosistema
			continue
			
			# Crear contenedor para el punto de ecosistema
			var eco_container = Control.new()
			eco_container.name = "Ecosystem_" + eco_id
			eco_container.mouse_filter = Control.MOUSE_FILTER_STOP
			eco_container.position = eco_position - Vector2(eco_point_size / 2, eco_point_size / 2)
			eco_container.custom_minimum_size = Vector2(eco_point_size, eco_point_size)
			eco_container.size = Vector2(eco_point_size, eco_point_size)
			
			# Crear el punto del ecosistema con color según salud
			var eco_point = ColorRect.new()
			eco_point.name = "EcoPoint"
			eco_point.set_anchors_preset(Control.PRESET_FULL_RECT)
			
			# Color según salud del ecosistema
			var health = eco_info.get("health", 50.0)
			var eco_color: Color
			if health < 30:
				eco_color = Color(1.0, 0.0, 0.0)  # Rojo - crítico
			elif health < 50:
				eco_color = Color(1.0, 0.6, 0.0)  # Naranja - en peligro
			else:
				eco_color = Color(0.0, 1.0, 0.4)  # Verde - saludable
			
			eco_point.color = eco_color
			eco_point.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# Añadir efecto de brillo
			var eco_glow = Panel.new()
			eco_glow.name = "EcoGlow"
			eco_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
			eco_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var glow_style = StyleBoxFlat.new()
			glow_style.bg_color = eco_color
			glow_style.bg_color.a = 0.4
			glow_style.shadow_color = eco_color
			glow_style.shadow_color.a = 0.7
			glow_style.shadow_size = 6
			glow_style.shadow_offset = Vector2(0, 0)
			eco_glow.add_theme_stylebox_override("panel", glow_style)
			eco_container.add_child(eco_glow)
			
			eco_container.add_child(eco_point)
			
			# Añadir icono o etiqueta según tipo
			var eco_label = Label.new()
			eco_label.name = "EcoLabel"
			var icon = ""
			match eco_info.get("type", ""):
				"forest":
					icon = "🌲"
				"coral":
					icon = "🪸"
				"wetland":
					icon = "🌊"
				"tundra":
					icon = "❄️"
				"desert":
					icon = "🏜️"
				"savanna":
					icon = "🌾"
				_:
					icon = "🌍"
			eco_label.text = icon
			eco_label.add_theme_font_size_override("font_size", 12)
			eco_label.position = Vector2(eco_point_size / 2 - 6, eco_point_size / 2 - 8)
			eco_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			eco_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			eco_container.add_child(eco_label)
			
			# Conectar señales de interacción
			eco_container.gui_input.connect(_on_ecosystem_point_input.bind(eco_id))
			eco_container.mouse_entered.connect(_on_ecosystem_point_hover.bind(eco_id, eco_container))
			eco_container.mouse_exited.connect(_on_ecosystem_point_unhover.bind(eco_id, eco_container))
			
			# Asegurar que esté por encima de la imagen pero debajo de las regiones
			eco_container.z_index = 5
			
			map_container.add_child(eco_container)

# Panel de estadísticas mundiales eliminado - se abre con botón separado
# Panel de detalles de región (se abre al hacer click)
# Se creará cuando sea necesario, no en _ready

func show_world_stats():
	"""Muestra panel de estadísticas mundiales (llamado desde UI_Main)"""
	# Eliminar panel anterior si existe
	if stats_panel and is_instance_valid(stats_panel):
		stats_panel.queue_free()
	
	# Crear nuevo panel centrado
	var stats_window = PanelContainer.new()
	stats_window.name = "WorldStatsPanel"
	
	# Estilo del panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(0.4, 0.4, 0.6)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	stats_window.add_theme_stylebox_override("panel", style)
	
	# Tamaño del panel
	stats_window.custom_minimum_size = Vector2(500, 600)
	
	# Centrar el panel
	stats_window.set_anchors_preset(Control.PRESET_CENTER)
	stats_window.set_offsets_preset(Control.PRESET_CENTER)
	
	# Añadir al árbol
	add_child(stats_window)
	stats_window.z_index = 100  # Encima de todo
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	container.add_theme_constant_override("margin_left", 15)
	container.add_theme_constant_override("margin_right", 15)
	container.add_theme_constant_override("margin_top", 15)
	container.add_theme_constant_override("margin_bottom", 15)
	stats_window.add_child(container)
	
	# Título
	var title = Label.new()
	title.text = "📊 ESTADÍSTICAS MUNDIALES"
	title.add_theme_font_size_override("font_size", 20)
	container.add_child(title)
	
	# Actualizar estadísticas antes de mostrar
	_update_stats()
	
	# Mostrar estadísticas globales
	_refresh_stats_display_in_panel(container)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.pressed.connect(func(): 
		if stats_window and is_instance_valid(stats_window):
			stats_window.queue_free()
			stats_panel = null
	)
	container.add_child(close_button)
	
	stats_panel = stats_window

func _on_region_clicked(region_code: String):
	"""Maneja el click en una región - abre panel de información"""
	print("Region clickeada: ", region_code)
	selected_region = region_code
	region_selected.emit(region_code)
	_show_region_details(region_code)

func _on_region_point_input(event: InputEvent, region_code: String):
	"""Maneja eventos de input en un punto de región"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			print("[WorldMapPanel] Click izquierdo en punto de region: ", region_code)
			_on_region_clicked(region_code)
			get_viewport().set_input_as_handled()

func _on_region_point_hover(region_code: String, point_container: Control):
	"""Maneja el hover sobre un punto - aumenta el brillo"""
	var point = point_container.get_node_or_null("Point")
	if point:
		var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
		var hover_color = CyberpunkThemeClass.COLOR_NEON_GREEN if CyberpunkThemeClass else Color(0.0, 1.0, 0.4)
		point.color = hover_color
		point_container.scale = Vector2(1.3, 1.3)
	_show_region_tooltip(region_code)

func _on_region_point_unhover(region_code: String, point_container: Control):
	"""Maneja el fin del hover - restaura el brillo normal"""
	var point = point_container.get_node_or_null("Point")
	if point:
		var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
		var normal_color = CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 1.0)
		point.color = normal_color
		point_container.scale = Vector2(1.0, 1.0)
	_hide_tooltip()

func _on_ecosystem_point_input(event: InputEvent, eco_id: String):
	"""Maneja eventos de input en un punto de ecosistema"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			print("[WorldMapPanel] Click izquierdo en ecosistema: ", eco_id)
			_on_ecosystem_clicked(eco_id)
			get_viewport().set_input_as_handled()

func _on_ecosystem_clicked(eco_id: String):
	"""Maneja el click en un ecosistema - emite señal y muestra detalles"""
	print("Ecosistema clickeado: ", eco_id)
	if eco_id in ecosystem_data:
		var eco_info = ecosystem_data[eco_id]
		ecosystem_selected.emit(eco_id)
		_show_ecosystem_details(eco_id)

func _on_ecosystem_point_hover(eco_id: String, eco_container: Control):
	"""Maneja el hover sobre un punto de ecosistema - aumenta el brillo"""
	var eco_point = eco_container.get_node_or_null("EcoPoint")
	if eco_point:
		var hover_color = eco_point.color
		hover_color = hover_color.lightened(0.3)  # Hacer más brillante
		eco_point.color = hover_color
		eco_container.scale = Vector2(1.4, 1.4)
	_show_ecosystem_tooltip(eco_id)

func _on_ecosystem_point_unhover(eco_id: String, eco_container: Control):
	"""Maneja el fin del hover - restaura el brillo normal"""
	var eco_point = eco_container.get_node_or_null("EcoPoint")
	if eco_point and eco_id in ecosystem_data:
		var eco_info = ecosystem_data[eco_id]
		var health = eco_info.get("health", 50.0)
		var normal_color: Color
		if health < 30:
			normal_color = Color(1.0, 0.0, 0.0)
		elif health < 50:
			normal_color = Color(1.0, 0.6, 0.0)
		else:
			normal_color = Color(0.0, 1.0, 0.4)
		eco_point.color = normal_color
		eco_container.scale = Vector2(1.0, 1.0)
	_hide_tooltip()

func _on_region_mouse_entered(region_code: String):
	"""Maneja el hover sobre una región - muestra tooltip"""
	_show_region_tooltip(region_code)

func _on_region_mouse_exited():
	"""Oculta el tooltip al salir del hover"""
	_hide_tooltip()

func _on_region_gui_input(event: InputEvent, region_code: String):
	"""Maneja eventos de input en una región (click derecho para mapa regional)"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_open_regional_map(region_code)

func _show_region_details(region_code: String):
	"""Muestra el panel de detalles de la región como ventana con estilo cyberpunk"""
	# Eliminar ventana anterior si existe
	if region_detail_panel and is_instance_valid(region_detail_panel):
		region_detail_panel.queue_free()
		region_detail_panel = null
	
	# Crear ventana
	var detail_window = Window.new()
	detail_window.title = region_data[region_code].name
	detail_window.size = Vector2(450, 600)
	detail_window.set_flag(Window.FLAG_RESIZE_DISABLED, false)
	detail_window.set_flag(Window.FLAG_BORDERLESS, false)
	
	# Crear panel dentro de la ventana
	var panel = PanelContainer.new()
	panel.name = "RegionDetailPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Estilo del panel cyberpunk
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var style: StyleBoxFlat
	if CyberpunkThemeClass:
		style = CyberpunkThemeClass.create_panel_style()
		style.bg_color = CyberpunkThemeClass.COLOR_BG_PANEL
		style.border_color = CyberpunkThemeClass.COLOR_NEON_CYAN
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
	else:
		style = StyleBoxFlat.new()
		style.bg_color = Color(0.03, 0.03, 0.05, 0.95)
		style.border_color = Color(0.0, 1.0, 1.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)
	
	detail_window.add_child(panel)
	
	# Guardar referencia a la ventana
	region_detail_panel = detail_window
	
	# Añadir ventana al árbol
	get_tree().root.add_child(detail_window)
	detail_window.popup_centered()
	
	# Añadir ScrollContainer para que el contenido no se corte
	var scroll_container = ScrollContainer.new()
	scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll_container.set_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(scroll_container)
	
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.add_theme_constant_override("margin_left", 15)
	container.add_theme_constant_override("margin_right", 15)
	container.add_theme_constant_override("margin_top", 15)
	container.add_theme_constant_override("margin_bottom", 15)
	scroll_container.add_child(container)
	
	# Título con estilo cyberpunk
	var title = Label.new()
	title.text = "┌─ " + region_data[region_code].name + " ─────────────────────────────"
	var title_color = CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 1.0)
	title.add_theme_color_override("font_color", title_color)
	title.add_theme_font_size_override("font_size", 20)
	container.add_child(title)
	
	# Valores geopolíticos y ecológicos
	var geo_value_system = get_tree().root.find_child("GeopoliticalValueSystem", true, false)
	if not geo_value_system:
		# Intentar inicializar si no existe
		if ResourceLoader.exists("res://scripts/managers/GeopoliticalValueSystem.gd"):
			var GeopoliticalValueSystemClass = load("res://scripts/managers/GeopoliticalValueSystem.gd")
			geo_value_system = GeopoliticalValueSystemClass.new()
			geo_value_system.name = "GeopoliticalValueSystem"
			get_tree().root.add_child(geo_value_system)
			print("GeopoliticalValueSystem inicializado en WorldMapPanel")
	
	if geo_value_system and geo_value_system.has_method("get_value_report"):
		var report = geo_value_system.get_value_report(region_code)
		
		if report and report.has("geopolitical_value"):
			var geo_label = Label.new()
			geo_label.text = "🌍 Valor Geopolítico: " + str(int(report.geopolitical_value)) + "/100 (" + report.geopolitical_level + ")"
			var geo_color = CyberpunkThemeClass.COLOR_NEON_BLUE if CyberpunkThemeClass else Color(0.2, 0.6, 1.0)
			geo_label.add_theme_color_override("font_color", geo_color)
			container.add_child(geo_label)
			
			var eco_label = Label.new()
			eco_label.text = "🌿 Valor Ecológico: " + str(int(report.ecological_value)) + "/100 (" + report.ecological_level + ")"
			var eco_val_color = CyberpunkThemeClass.COLOR_NEON_GREEN if CyberpunkThemeClass else Color(0.0, 1.0, 0.4)
			eco_label.add_theme_color_override("font_color", eco_val_color)
			container.add_child(eco_label)
			
			var desc_label = Label.new()
			desc_label.text = report.description
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			container.add_child(desc_label)
			
			var multiplier_label = Label.new()
			multiplier_label.text = "⚡ Multiplicador de Impacto: " + str(report.impact_multiplier) + "x"
			if report.impact_multiplier >= 1.5:
				multiplier_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
			elif report.impact_multiplier >= 1.0:
				multiplier_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
			container.add_child(multiplier_label)
			
			var separator = HSeparator.new()
			container.add_child(separator)
		else:
			# Fallback si no hay reporte válido
			var error_label = Label.new()
			error_label.text = "No se pudieron cargar los valores (reporte invalido)"
			error_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
			container.add_child(error_label)
	else:
		# Fallback si no existe el sistema
		var error_label = Label.new()
		error_label.text = "Sistema de valores geopoliticos no disponible"
		error_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		container.add_child(error_label)
		print("GeopoliticalValueSystem no encontrado o sin metodo get_value_report")
	
	# Estadísticas de la región
	var stats_label = Label.new()
	stats_label.text = "📊 ESTADÍSTICAS"
	stats_label.add_theme_font_size_override("font_size", 16)
	container.add_child(stats_label)
	
	# Reputación
	var rep_label = Label.new()
	var reputation = region_stats.get(region_code, {}).get("reputation", 0)
	rep_label.text = "⭐ Reputación: " + str(reputation)
	container.add_child(rep_label)
	
	# Violencia por región
	var violence_label = Label.new()
	var violence = region_violence.get(region_code, 0)
	violence_label.text = "⚔️ Violencia: " + str(violence) + "%"
	# Color según nivel de violencia
	if violence >= 70:
		violence_label.modulate = Color(0.9, 0.2, 0.2)  # Rojo = alta violencia
	elif violence >= 50:
		violence_label.modulate = Color(0.9, 0.7, 0.2)  # Amarillo = media
	else:
		violence_label.modulate = Color(0.2, 0.9, 0.2)  # Verde = baja
	container.add_child(violence_label)
	
	# Separador
	var separator2 = HSeparator.new()
	container.add_child(separator2)
	
	# Influencia de Cartógrafos
	var cartograph_label = Label.new()
	cartograph_label.text = "👁️ INFLUENCIA DE LOS CARTÓGRAFOS"
	var cart_color = CyberpunkThemeClass.COLOR_TEXT_PRIMARY if CyberpunkThemeClass else Color(0.9, 0.95, 1.0)
	cartograph_label.add_theme_color_override("font_color", cart_color)
	cartograph_label.add_theme_font_size_override("font_size", 16)
	container.add_child(cartograph_label)
	
	var region_info = region_data.get(region_code, {})
	if region_info.has("cartograph_political_influence"):
		var pol_inf = region_info.cartograph_political_influence
		var pol_label = Label.new()
		pol_label.text = "🏛️ Político-Social: " + str(int(pol_inf)) + "%"
		# Color según nivel de influencia
		if pol_inf >= 70:
			pol_label.modulate = Color(0.9, 0.2, 0.2)  # Rojo = alta influencia
		elif pol_inf >= 50:
			pol_label.modulate = Color(0.9, 0.7, 0.2)  # Amarillo = media
		else:
			pol_label.modulate = Color(0.2, 0.9, 0.2)  # Verde = baja
		container.add_child(pol_label)
	
	if region_info.has("cartograph_economic_influence"):
		var econ_inf = region_info.cartograph_economic_influence
		var econ_label = Label.new()
		econ_label.text = "💰 Económica: " + str(int(econ_inf)) + "%"
		# Color según nivel de influencia
		if econ_inf >= 70:
			econ_label.modulate = Color(0.9, 0.2, 0.2)  # Rojo = alta influencia
		elif econ_inf >= 50:
			econ_label.modulate = Color(0.9, 0.7, 0.2)  # Amarillo = media
		else:
			econ_label.modulate = Color(0.2, 0.9, 0.2)  # Verde = baja
		container.add_child(econ_label)
	
	# Separador
	var separator3 = HSeparator.new()
	container.add_child(separator3)
	
	# Salud de ecosistemas en la región
	var eco_label = Label.new()
	eco_label.text = "🌍 ECOSISTEMAS"
	var eco_title_color = CyberpunkThemeClass.COLOR_TEXT_PRIMARY if CyberpunkThemeClass else Color(0.9, 0.95, 1.0)
	eco_label.add_theme_color_override("font_color", eco_title_color)
	eco_label.add_theme_font_size_override("font_size", 16)
	container.add_child(eco_label)
	
	for eco_id in ecosystem_data:
		var eco = ecosystem_data[eco_id]
		if eco.has("region") and eco.region == region_code:
			var eco_health_label = Label.new()
			eco_health_label.text = "• " + eco.name + ": " + str(int(eco.health)) + "%"
			container.add_child(eco_health_label)
	
	# Separador
	var separator4 = HSeparator.new()
	container.add_child(separator4)
	
	# Botones de acción
	var button_container = HBoxContainer.new()
	container.add_child(button_container)
	
	# Botón ver misiones - capturar region_code en el closure
	var missions_button = Button.new()
	missions_button.text = "Ver Misiones"
	var button_normal = CyberpunkThemeClass.create_button_style_normal() if CyberpunkThemeClass else StyleBoxFlat.new()
	var button_hover = CyberpunkThemeClass.create_button_style_hover() if CyberpunkThemeClass else StyleBoxFlat.new()
	missions_button.add_theme_stylebox_override("normal", button_normal)
	missions_button.add_theme_stylebox_override("hover", button_hover)
	# Capturar region_code en el closure para que esté disponible cuando se presione el botón
	var captured_region_code = region_code
	missions_button.pressed.connect(func():
		print("🔘 [WorldMapPanel] Botón 'Ver Misiones' presionado para región: ", captured_region_code)
		if region_detail_panel and is_instance_valid(region_detail_panel):
			region_detail_panel.queue_free()
			region_detail_panel = null
		_show_mission_selection(captured_region_code)
	)
	button_container.add_child(missions_button)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.add_theme_stylebox_override("normal", button_normal)
	close_button.add_theme_stylebox_override("hover", button_hover)
	close_button.pressed.connect(func():
		if region_detail_panel and is_instance_valid(region_detail_panel):
			region_detail_panel.queue_free()
			region_detail_panel = null
	)
	button_container.add_child(close_button)

func _update_stats():
	"""Actualiza las estadísticas mostradas"""
	if not game_client:
		return
	
	# Obtener reputación
	if game_client.has_method("get_player_reputation"):
		var reputation = game_client.get_player_reputation()
		for region_code in reputation:
			if not region_stats.has(region_code):
				region_stats[region_code] = {}
			region_stats[region_code]["reputation"] = reputation[region_code]
	
	# Obtener estado mundial y violencia por región
	if game_client.has_method("get_world_state"):
		var world_state = game_client.get_world_state()
		if world_state:
			# Obtener violencia por región si existe
			if world_state.has("region_violence") and world_state.region_violence is Dictionary:
				region_violence = world_state.region_violence
			elif world_state.has("violence_by_region") and world_state.violence_by_region is Dictionary:
				region_violence = world_state.violence_by_region
			else:
				# Si no existe, inicializar con valores por defecto
				for region_code in region_data:
					if not region_violence.has(region_code):
						region_violence[region_code] = 0
	
	# Actualizar ecosistemas
	if ecosystem_manager:
		_update_ecosystem_stats()
	
	# Actualizar UI
	_refresh_stats_display()

func _update_ecosystem_stats():
	"""Actualiza estadísticas de ecosistemas"""
	if not ecosystem_manager:
		return
	
	# Intentar obtener ecosistemas de diferentes formas
	var ecosystems = null
	
	# Método 1: Acceso directo a la variable pública (ecosystems es pública en EcosystemManager)
	# En GDScript, las variables públicas son accesibles directamente
	ecosystems = ecosystem_manager.ecosystems
	
	# Método 2: Si no funcionó, intentar con get()
	if ecosystems == null or not (ecosystems is Dictionary):
		var test_ecosystems = ecosystem_manager.get("ecosystems")
		if test_ecosystems != null and test_ecosystems is Dictionary:
			ecosystems = test_ecosystems
	
	# Método 3: Si tiene método getter
	if (ecosystems == null or not (ecosystems is Dictionary)) and ecosystem_manager.has_method("get_ecosystems"):
		ecosystems = ecosystem_manager.get_ecosystems()
	
	if ecosystems != null and ecosystems is Dictionary:
		for eco_id in ecosystems:
			var state = ecosystems[eco_id]
			var health = 50.0
			var biodiversity = 50.0
			
			# Obtener health - EcosystemState tiene propiedades públicas
			if typeof(state) == TYPE_OBJECT:
				# Es un objeto EcosystemState con propiedades públicas
				# Acceso directo a las propiedades
				health = state.health
				biodiversity = state.biodiversity
			elif typeof(state) == TYPE_DICTIONARY:
				health = state.get("health", 50.0)
				biodiversity = state.get("biodiversity", 50.0)
			
			ecosystem_stats[eco_id] = {
				"health": health,
				"biodiversity": biodiversity
			}
			
			# Actualizar datos de ecosistemas conocidos
			if eco_id in ecosystem_data:
				ecosystem_data[eco_id].health = health

func _refresh_stats_display():
	"""Refresca la visualización de estadísticas (ya no se usa, reemplazado por show_world_stats)"""
	pass

func _refresh_stats_display_in_panel(container: VBoxContainer):
	"""Refresca la visualización de estadísticas en un contenedor dado"""
	# Violencia por región
	var violence_label = Label.new()
	violence_label.text = "⚔️ VIOLENCIA POR REGIÓN:"
	violence_label.add_theme_font_size_override("font_size", 14)
	container.add_child(violence_label)
	
	var total_violence = 0
	for region_code in region_data:
		var violence = region_violence.get(region_code, 0)
		total_violence += violence
		var violence_text = Label.new()
		violence_text.text = "  " + region_data[region_code].name + ": " + str(violence) + "%"
		violence_text.add_theme_font_size_override("font_size", 12)
		if violence >= 70:
			violence_text.add_theme_color_override("font_color", Color(1, 0, 0))  # Rojo
		elif violence >= 50:
			violence_text.add_theme_color_override("font_color", Color(1, 0.5, 0))  # Naranja
		else:
			violence_text.add_theme_color_override("font_color", Color(0, 1, 0))  # Verde
		container.add_child(violence_text)
	
	# Total de violencia mundial
	var total_label = Label.new()
	total_label.text = "🌍 VIOLENCIA MUNDIAL TOTAL: " + str(total_violence) + "%"
	total_label.add_theme_font_size_override("font_size", 14)
	if total_violence >= 500:  # Si suma más de 500% (ejemplo)
		total_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif total_violence >= 300:
		total_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
	else:
		total_label.add_theme_color_override("font_color", Color(0, 1, 0))
	container.add_child(total_label)
	
	# Separador
	var sep1 = HSeparator.new()
	container.add_child(sep1)
	
	# Ecosistemas
	var eco_title = Label.new()
	eco_title.text = "🌍 ECOSISTEMAS:"
	eco_title.add_theme_font_size_override("font_size", 14)
	container.add_child(eco_title)
	
	for eco_id in ecosystem_data:
		var health = ecosystem_stats.get(eco_id, {}).get("health", ecosystem_data[eco_id].health)
		var eco_text = Label.new()
		eco_text.text = "  " + ecosystem_data[eco_id].name + ": " + str(int(health)) + "%"
		eco_text.add_theme_font_size_override("font_size", 12)
		if health < 30:
			eco_text.add_theme_color_override("font_color", Color(1, 0, 0))
		elif health < 50:
			eco_text.add_theme_color_override("font_color", Color(1, 0.5, 0))
		else:
			eco_text.add_theme_color_override("font_color", Color(0, 1, 0))
		container.add_child(eco_text)

func set_game_client(client: Node):
	"""Establece referencia al GameClient"""
	game_client = client
	_update_stats()

func set_ecosystem_manager(manager: Node):
	"""Establece referencia al EcosystemManager"""
	ecosystem_manager = manager
	_update_stats()

func set_parent_window(window: Window):
	"""Establece referencia a la ventana padre"""
	parent_window = window

func _on_close_button_pressed():
	"""Maneja el click en el botón cerrar"""
	if parent_window and is_instance_valid(parent_window):
		parent_window.queue_free()
	else:
		var parent = get_parent()
		if parent is Window:
			parent.queue_free()
		else:
			# Si no está en una ventana, simplemente ocultar/eliminar el panel
			queue_free()

func _setup_zoom():
	"""Configura el sistema de zoom"""
	map_container.mouse_filter = Control.MOUSE_FILTER_PASS  # Permitir eventos de mouse

func _setup_tooltip():
	"""Configura el panel de tooltip"""
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "TooltipPanel"
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 1000
	
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	tooltip_style.border_color = Color(0.4, 0.6, 0.8)
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_bottom = 2
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	
	add_child(tooltip_panel)

func _setup_mission_manager():
	"""Obtiene referencia al MissionManager"""
	# Buscar MissionManager en el árbol de escena
	mission_manager = get_tree().root.find_child("MissionManager", true, false)
	
	# Si no existe, buscar en UI_Main
	if not mission_manager:
		var ui_main = get_tree().root.find_child("UI_Main", true, false)
		if ui_main:
			mission_manager = ui_main.find_child("MissionManager", true, false)
	
	# Si aún no existe, intentar inicializar
	if not mission_manager:
		if ResourceLoader.exists("res://scripts/managers/MissionManager.gd"):
			var MissionManagerClass = load("res://scripts/managers/MissionManager.gd")
			mission_manager = MissionManagerClass.new()
			mission_manager.name = "MissionManager"
			# Añadir a UI_Main si existe, sino al root
			var ui_main = get_tree().root.find_child("UI_Main", true, false)
			if ui_main:
				ui_main.add_child(mission_manager)
			else:
				get_tree().root.add_child(mission_manager)
	
	# Asegurar que las misiones estén cargadas
	if mission_manager:
		# Verificar que las misiones estén inicializadas
		if mission_manager.has_method("_load_missions"):
			mission_manager._load_missions()
		# Verificar que las misiones estén organizadas por región
		if mission_manager.has_method("_organize_missions_by_region"):
			mission_manager._organize_missions_by_region()
		
		# Debug: mostrar información de misiones
		var missions_dict = mission_manager.get("missions")
		if missions_dict and missions_dict is Dictionary:
			print("[WorldMapPanel] Total de misiones cargadas: ", missions_dict.size())
			# Mostrar todas las misiones
			for mission_id in missions_dict:
				var mission = missions_dict[mission_id]
				if mission and mission is Mission:
					print("[WorldMapPanel] - Misión: ", mission_id, " Región: ", mission.region_code, " Status: ", mission.status)
		var missions_by_region_dict = mission_manager.get("missions_by_region")
		if missions_by_region_dict and missions_by_region_dict is Dictionary:
			print("[WorldMapPanel] Regiones con misiones: ", missions_by_region_dict.keys())
			# Mostrar misiones por región
			for region in missions_by_region_dict:
				var mission_ids = missions_by_region_dict[region]
				if mission_ids and mission_ids is Array:
					print("[WorldMapPanel] - Región '", region, "': ", mission_ids.size(), " misiones")
				else:
					print("[WorldMapPanel] - Región '", region, "': 0 misiones")

func _get_active_missions_count(region_code: String) -> int:
	"""Obtiene el número de misiones activas para una región"""
	if mission_manager and mission_manager.has_method("get_active_missions_count"):
		return mission_manager.get_active_missions_count(region_code)
	return 0

func _show_region_tooltip(region_code: String):
	"""Muestra tooltip con información de la región"""
	if not tooltip_panel:
		return
	
	# Limpiar contenido anterior
	for child in tooltip_panel.get_children():
		child.queue_free()
	
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 10)
	container.add_theme_constant_override("margin_bottom", 10)
	tooltip_panel.add_child(container)
	
	# Título
	var title = Label.new()
	title.text = region_data[region_code].name
	title.add_theme_font_size_override("font_size", 14)
	container.add_child(title)
	
	# Valores geopolíticos y ecológicos
	var geo_value_system = get_tree().root.find_child("GeopoliticalValueSystem", true, false)
	if geo_value_system and geo_value_system.has_method("get_value_report"):
		var report = geo_value_system.get_value_report(region_code)
		if report:
			var geo_label = Label.new()
			geo_label.text = "🌍 Geo: " + str(int(report.geopolitical_value)) + "/100"
			geo_label.add_theme_font_size_override("font_size", 11)
			container.add_child(geo_label)
			
			var eco_label = Label.new()
			eco_label.text = "🌿 Eco: " + str(int(report.ecological_value)) + "/100"
			eco_label.add_theme_font_size_override("font_size", 11)
			container.add_child(eco_label)
	
	# Misiones activas
	var active_count = _get_active_missions_count(region_code)
	if active_count > 0:
		var mission_label = Label.new()
		mission_label.text = "Misiones activas: " + str(active_count)
		mission_label.add_theme_font_size_override("font_size", 11)
		mission_label.add_theme_color_override("font_color", Color.YELLOW)
		container.add_child(mission_label)
	
	# Reputación
	var reputation = region_stats.get(region_code, {}).get("reputation", 0)
	var rep_label = Label.new()
	rep_label.text = "⭐ Rep: " + str(reputation)
	rep_label.add_theme_font_size_override("font_size", 11)
	container.add_child(rep_label)
	
	# Violencia
	var violence = region_violence.get(region_code, 0)
	var vio_label = Label.new()
	vio_label.text = "⚔️ Violencia: " + str(violence) + "%"
	vio_label.add_theme_font_size_override("font_size", 11)
	container.add_child(vio_label)
	
	# Posicionar tooltip cerca del mouse
	tooltip_panel.custom_minimum_size = Vector2(200, 150)
	tooltip_panel.position = get_global_mouse_position() + Vector2(20, 20)
	tooltip_panel.visible = true

func _hide_tooltip():
	"""Oculta el tooltip"""
	if tooltip_panel:
		tooltip_panel.visible = false

func _show_ecosystem_tooltip(eco_id: String):
	"""Muestra tooltip con información del ecosistema"""
	if not tooltip_panel:
		return
	
	if not eco_id in ecosystem_data:
		return
	
	# Limpiar contenido anterior
	for child in tooltip_panel.get_children():
		child.queue_free()
	
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 10)
	container.add_theme_constant_override("margin_bottom", 10)
	tooltip_panel.add_child(container)
	
	var eco_info = ecosystem_data[eco_id]
	
	# Título
	var title = Label.new()
	title.text = eco_info.name
	title.add_theme_font_size_override("font_size", 14)
	container.add_child(title)
	
	# Tipo de ecosistema
	var type_label = Label.new()
	var type_text = eco_info.get("type", "unknown")
	type_label.text = "Tipo: " + type_text.capitalize()
	type_label.add_theme_font_size_override("font_size", 11)
	container.add_child(type_label)
	
	# Salud
	var health = eco_info.get("health", 50.0)
	var health_label = Label.new()
	health_label.text = "Salud: " + str(int(health)) + "%"
	health_label.add_theme_font_size_override("font_size", 11)
	if health < 30:
		health_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	elif health < 50:
		health_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
	else:
		health_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	container.add_child(health_label)
	
	# Estadísticas actualizadas si están disponibles
	if eco_id in ecosystem_stats:
		var stats = ecosystem_stats[eco_id]
		var biodiversity = stats.get("biodiversity", 50.0)
		var bio_label = Label.new()
		bio_label.text = "Biodiversidad: " + str(int(biodiversity)) + "%"
		bio_label.add_theme_font_size_override("font_size", 11)
		container.add_child(bio_label)
	
	# Posicionar tooltip cerca del mouse
	tooltip_panel.custom_minimum_size = Vector2(200, 120)
	tooltip_panel.position = get_global_mouse_position() + Vector2(20, 20)
	tooltip_panel.visible = true

func _show_ecosystem_details(eco_id: String):
	"""Muestra el panel de detalles del ecosistema como ventana"""
	if not eco_id in ecosystem_data:
		print("Ecosistema no encontrado: ", eco_id)
		return
	
	# Eliminar ventana anterior si existe
	if region_detail_panel and is_instance_valid(region_detail_panel):
		region_detail_panel.queue_free()
		region_detail_panel = null
	
	# Crear ventana
	var detail_window = Window.new()
	detail_window.title = ecosystem_data[eco_id].name
	detail_window.size = Vector2(400, 500)
	detail_window.set_flag(Window.FLAG_RESIZE_DISABLED, false)
	detail_window.set_flag(Window.FLAG_BORDERLESS, false)
	
	# Crear panel dentro de la ventana
	var panel = PanelContainer.new()
	panel.name = "EcosystemDetailPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.set_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Estilo del panel cyberpunk
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var style: StyleBoxFlat
	if CyberpunkThemeClass:
		style = CyberpunkThemeClass.create_panel_style()
		style.bg_color = CyberpunkThemeClass.COLOR_BG_PANEL
		style.border_color = CyberpunkThemeClass.COLOR_NEON_GREEN
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
	else:
		style = StyleBoxFlat.new()
		style.bg_color = Color(0.03, 0.05, 0.03, 0.95)
		style.border_color = Color(0.0, 1.0, 0.4)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)
	
	detail_window.add_child(panel)
	
	# Guardar referencia a la ventana
	region_detail_panel = detail_window
	
	# Añadir ventana al árbol
	get_tree().root.add_child(detail_window)
	detail_window.popup_centered()
	
	# Contenedor con scroll
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.set_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(scroll)
	
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.add_theme_constant_override("margin_left", 15)
	container.add_theme_constant_override("margin_right", 15)
	container.add_theme_constant_override("margin_top", 15)
	container.add_theme_constant_override("margin_bottom", 15)
	scroll.add_child(container)
	
	var eco_info = ecosystem_data[eco_id]
	
	# Título
	var title = Label.new()
	title.text = "🌍 " + eco_info.name.to_upper()
	title.add_theme_font_size_override("font_size", 18)
	if CyberpunkThemeClass:
		title.add_theme_color_override("font_color", CyberpunkThemeClass.COLOR_NEON_GREEN)
	else:
		title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	container.add_child(title)
	
	var sep1 = HSeparator.new()
	container.add_child(sep1)
	
	# Tipo
	var type_label = Label.new()
	type_label.text = "Tipo: " + eco_info.get("type", "unknown").capitalize()
	type_label.add_theme_font_size_override("font_size", 14)
	container.add_child(type_label)
	
	# Región
	if eco_info.has("region") and eco_info.region in region_data:
		var region_label = Label.new()
		region_label.text = "Región: " + region_data[eco_info.region].name
		region_label.add_theme_font_size_override("font_size", 14)
		container.add_child(region_label)
	
	var sep2 = HSeparator.new()
	container.add_child(sep2)
	
	# Salud
	var health = eco_info.get("health", 50.0)
	var health_label = Label.new()
	health_label.text = "Salud: " + str(int(health)) + "%"
	health_label.add_theme_font_size_override("font_size", 16)
	if health < 30:
		health_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	elif health < 50:
		health_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
	else:
		health_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	container.add_child(health_label)
	
	# Estadísticas actualizadas si están disponibles
	if eco_id in ecosystem_stats:
		var stats = ecosystem_stats[eco_id]
		var biodiversity = stats.get("biodiversity", 50.0)
		var bio_label = Label.new()
		bio_label.text = "Biodiversidad: " + str(int(biodiversity)) + "%"
		bio_label.add_theme_font_size_override("font_size", 14)
		container.add_child(bio_label)
	
	var sep3 = HSeparator.new()
	container.add_child(sep3)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.pressed.connect(func():
		if region_detail_panel and is_instance_valid(region_detail_panel):
			region_detail_panel.queue_free()
			region_detail_panel = null
	)
	container.add_child(close_button)

func _show_mission_selection(region_code: String):
	"""Muestra panel de selección de misiones para la región"""
	print("Mostrando seleccion de misiones para region: ", region_code)
	if not mission_manager:
		_setup_mission_manager()
		if not mission_manager:
			print("MissionManager no disponible")
			# Mostrar mensaje de error al usuario
			var error_dialog = AcceptDialog.new()
			error_dialog.title = "Error"
			error_dialog.dialog_text = "MissionManager no disponible. No se pueden cargar misiones."
			get_tree().root.add_child(error_dialog)
			error_dialog.popup_centered()
			return
	
	# Asegurar que las misiones estén cargadas
	if mission_manager.has_method("_load_missions"):
		mission_manager._load_missions()
	
	# Asegurar que las misiones estén organizadas por región
	if mission_manager.has_method("_organize_missions_by_region"):
		mission_manager._organize_missions_by_region()
	
	# Debug: mostrar todas las misiones cargadas
	var missions_dict = mission_manager.get("missions")
	if missions_dict and missions_dict is Dictionary:
		print("📋 [WorldMapPanel] Total de misiones en MissionManager: ", missions_dict.size())
		for mission_id in missions_dict:
			var mission = missions_dict[mission_id]
			if mission and mission is Mission:
				print("[WorldMapPanel] - Misión: ", mission_id, " Región: ", mission.region_code, " Status: ", mission.status)
	
	# Debug: mostrar misiones organizadas por región
	var missions_by_region_dict = mission_manager.get("missions_by_region")
	if missions_by_region_dict and missions_by_region_dict is Dictionary:
		print("📋 [WorldMapPanel] Misiones organizadas por región: ", missions_by_region_dict.keys())
		for region in missions_by_region_dict:
			var mission_ids = missions_by_region_dict[region]
			if mission_ids and mission_ids is Array:
				print("[WorldMapPanel] - Región '", region, "': ", mission_ids.size(), " misiones")
	
	if not mission_manager.has_method("get_missions_for_region"):
		print("MissionManager no tiene metodo get_missions_for_region")
		return
		
	var available_missions = mission_manager.get_missions_for_region(region_code)
	print("📋 [WorldMapPanel] Misiones disponibles para región '", region_code, "': ", available_missions.size())
	
	# Debug: mostrar IDs de misiones encontradas
	for mission in available_missions:
		if mission and mission is Mission:
			print("[WorldMapPanel] - Misión encontrada: ", mission.mission_id, " (", mission.mission_name, ") - Status: ", mission.status)
	
	# Crear ventana de selección de misiones
	var mission_window = Window.new()
	mission_window.title = "Misiones: " + region_data[region_code].name
	mission_window.size = Vector2(600, 500)
	mission_window.set_flag(Window.FLAG_RESIZE_DISABLED, false)
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	container.add_theme_constant_override("margin_left", 15)
	container.add_theme_constant_override("margin_right", 15)
	container.add_theme_constant_override("margin_top", 15)
	container.add_theme_constant_override("margin_bottom", 15)
	mission_window.add_child(container)
	
	# Título
	var title = Label.new()
	title.text = "Misiones Disponibles"
	title.add_theme_font_size_override("font_size", 18)
	container.add_child(title)
	
	# Lista de misiones
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(scroll)
	
	var mission_list = VBoxContainer.new()
	mission_list.add_theme_constant_override("separation", 5)
	scroll.add_child(mission_list)
	
	if available_missions.is_empty():
		var no_missions = Label.new()
		no_missions.text = "No hay misiones disponibles en esta región"
		mission_list.add_child(no_missions)
	else:
		for mission in available_missions:
			var mission_panel = PanelContainer.new()
			mission_panel.custom_minimum_size = Vector2(0, 80)
			
			var panel_style = StyleBoxFlat.new()
			panel_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
			panel_style.border_color = Color(0.4, 0.4, 0.6)
			panel_style.border_width_left = 1
			panel_style.border_width_right = 1
			panel_style.border_width_top = 1
			panel_style.border_width_bottom = 1
			mission_panel.add_theme_stylebox_override("panel", panel_style)
			
			var mission_container = VBoxContainer.new()
			mission_container.set_anchors_preset(Control.PRESET_FULL_RECT)
			mission_container.set_offsets_preset(Control.PRESET_FULL_RECT)
			mission_container.add_theme_constant_override("separation", 5)
			mission_container.add_theme_constant_override("margin_left", 10)
			mission_container.add_theme_constant_override("margin_right", 10)
			mission_container.add_theme_constant_override("margin_top", 5)
			mission_container.add_theme_constant_override("margin_bottom", 5)
			mission_panel.add_child(mission_container)
			
			var mission_name_label = Label.new()
			mission_name_label.text = mission.mission_name
			mission_name_label.add_theme_font_size_override("font_size", 14)
			mission_container.add_child(mission_name_label)
			
			var mission_desc_label = Label.new()
			mission_desc_label.text = mission.mission_description
			mission_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mission_desc_label.add_theme_font_size_override("font_size", 11)
			mission_container.add_child(mission_desc_label)
			
			var mission_info = HBoxContainer.new()
			mission_info.add_theme_constant_override("separation", 10)
			mission_container.add_child(mission_info)
			
			var type_label = Label.new()
			type_label.text = "Tipo: " + Mission.MissionType.keys()[mission.mission_type]
			type_label.add_theme_font_size_override("font_size", 10)
			mission_info.add_child(type_label)
			
			var status_label = Label.new()
			match mission.status:
				Mission.MissionStatus.AVAILABLE:
					status_label.text = "📋 Disponible"
					status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
				Mission.MissionStatus.ACTIVE:
					status_label.text = "▶ Activa"
					status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
				Mission.MissionStatus.COMPLETED:
					status_label.text = "✓ Completada"
					status_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
				Mission.MissionStatus.LOCKED:
					status_label.text = "🔒 Bloqueada"
					status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				_:
					status_label.text = "❓ Desconocido"
			status_label.add_theme_font_size_override("font_size", 10)
			mission_info.add_child(status_label)
			
			var diff_label = Label.new()
			var stars = ""
			for i in range(mission.difficulty):
				stars += "⭐"
			diff_label.text = "Dificultad: " + stars
			diff_label.add_theme_font_size_override("font_size", 10)
			mission_info.add_child(diff_label)
			
			var start_button = Button.new()
			if mission.status == Mission.MissionStatus.COMPLETED:
				start_button.text = "[OK] Completada"
				start_button.disabled = true
				# Cambiar color del panel para misiones completadas
				panel_style.bg_color = Color(0.1, 0.3, 0.1, 0.8)
				panel_style.border_color = Color(0.0, 0.8, 0.0)
			elif mission.status == Mission.MissionStatus.ACTIVE:
				start_button.text = "Continuar"
			elif mission.status == Mission.MissionStatus.AVAILABLE:
				start_button.text = "Iniciar"
			elif mission.status == Mission.MissionStatus.LOCKED:
				start_button.text = "[LOCKED] Bloqueada"
				start_button.disabled = true
				# Cambiar color del panel para misiones bloqueadas
				panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
				panel_style.border_color = Color(0.5, 0.5, 0.5)
			else:
				start_button.text = "Indisponible"
				start_button.disabled = true
			
			start_button.custom_minimum_size = Vector2(80, 30)
			start_button.pressed.connect(func():
				if mission_manager.has_method("start_mission"):
					if mission_manager.start_mission(mission.mission_id):
						# Actualizar el estado de la misión en la UI
						mission.status = Mission.MissionStatus.ACTIVE
						# Actualizar el botón y el label de estado
						start_button.text = "Continuar"
						status_label.text = "▶ Activa"
						status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
						# Cambiar color del panel para misiones activas
						panel_style.bg_color = Color(0.2, 0.2, 0.1, 0.8)
						panel_style.border_color = Color(1.0, 0.8, 0.0)
			)
			mission_info.add_child(start_button)
			
			mission_list.add_child(mission_panel)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.pressed.connect(func(): mission_window.queue_free())
	container.add_child(close_button)
	
	# Añadir ventana al árbol
	get_tree().root.add_child(mission_window)
	mission_window.visible = true
	mission_window.popup_centered()
	print("Ventana de misiones mostrada para region: ", region_code)

func _apply_zoom():
	"""Aplica el zoom al mapa"""
	if not map_container:
		return
	
	# Escalar el contenedor del mapa
	map_container.scale = Vector2(zoom_level, zoom_level)
	
	# Ajustar posición para mantener el centro visible
	var viewport_size = get_viewport().get_visible_rect().size
	var map_center = map_container.size * 0.5
	var screen_center = viewport_size * 0.5
	map_container.position = screen_center - map_center * zoom_level

func _open_regional_map(region_code: String):
	"""Abre mapa regional con países (click derecho)"""
	if not ResourceLoader.exists("res://scripts/UI/RegionalMapPanel.gd"):
		print("RegionalMapPanel.gd no encontrado")
		return
	
	var RegionalMapPanelClass = load("res://scripts/UI/RegionalMapPanel.gd")
	var regional_panel = RegionalMapPanelClass.new()
	regional_panel.name = "RegionalMapPanel"
	regional_panel.region_code = region_code
	
	# Crear ventana
	var window = Window.new()
	window.title = "Mapa Regional: " + region_data.get(region_code, {}).get("name", region_code)
	window.size = Vector2(1000, 700)
	window.add_child(regional_panel)
	
	# Configurar panel para llenar ventana
	regional_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	regional_panel.set_offsets_preset(Control.PRESET_FULL_RECT)
	regional_panel.parent_window = window
	
	# Conectar referencias
	if regional_panel.has_method("set_game_client"):
		regional_panel.set_game_client(game_client)
	
	# Añadir ventana al árbol
	get_tree().root.add_child(window)
	window.popup_centered()
	
	print("Mapa regional abierto para: ", region_code)

func _notification(what):
	"""Actualiza cuando cambia el tamaño"""
	if what == NOTIFICATION_RESIZED:
		call_deferred("_draw_regions")
		call_deferred("_refresh_stats_display")

func _gui_input(event: InputEvent):
	"""Maneja zoom con rueda del mouse"""
	if not map_container or not visible:
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = min(max_zoom, zoom_level + zoom_speed)
			_apply_zoom()
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = max(min_zoom, zoom_level - zoom_speed)
			_apply_zoom()
			accept_event()

func start_update_timer():
	"""Inicia un timer para actualizar estadísticas periódicamente"""
	var timer = Timer.new()
	timer.wait_time = 2.0  # Actualizar cada 2 segundos
	timer.autostart = true
	timer.timeout.connect(_update_stats)
	add_child(timer)

func _ensure_visibility():
	"""Asegura que el panel sea visible"""
	if not visible:
		visible = true
		print("Forzando visibilidad del mapa")
	
	# Forzar redibujado de regiones
	if map_container:
		call_deferred("_draw_regions")
	
	# Asegurar que el panel de stats también sea visible
	if stats_panel and stats_panel.get_parent():
		stats_panel.get_parent().visible = true

func _debug_panel_state():
	"""Debug: muestra el estado del panel"""
	print("[DEBUG] Estado del WorldMapPanel:")
	print("   Visible: ", visible)
	print("   Tamaño: ", size)
	print("   Posición: ", position)
	print("   Anchors: ", anchor_left, ", ", anchor_top, ", ", anchor_right, ", ", anchor_bottom)
	print("   Offset: ", offset_left, ", ", offset_top, ", ", offset_right, ", ", offset_bottom)
	print("   Z-index: ", z_index)
	print("   Map container existe: ", map_container != null)
	if map_container:
		print("   Map container tamaño: ", map_container.size)
		print("   Map container visible: ", map_container.visible)
	print("   Stats panel existe: ", stats_panel != null)
	if stats_panel and stats_panel.get_parent():
		print("   Stats panel parent visible: ", stats_panel.get_parent().visible)

func _print_region_positions():
	"""Imprime todas las posiciones de las regiones en formato copiable"""
	print("\n=== POSICIONES DE REGIONES (normalizadas 0-1) ===")
	for region_code in region_data:
		var pos = region_data[region_code].position
		var name = region_data[region_code].name
		print('"' + region_code + '": Vector2(' + str(pos.x) + ', ' + str(pos.y) + '),  # ' + name)
	print("================================================\n")

func _get_click_position_normalized() -> Vector2:
	"""Obtiene la posición del mouse en el mapa normalizada (0-1)"""
	if not map_container:
		return Vector2.ZERO
	
	var mouse_pos = get_global_mouse_position()
	var map_global_pos = map_container.get_global_position()
	var local_pos = mouse_pos - map_global_pos
	var map_size = map_container.size
	
	if map_size.x <= 0 or map_size.y <= 0:
		return Vector2.ZERO
	
	var normalized = Vector2(
		clamp(local_pos.x / map_size.x, 0.0, 1.0),
		clamp(local_pos.y / map_size.y, 0.0, 1.0)
	)
	
	return normalized

func _on_map_container_gui_input(event: InputEvent):
	"""Maneja clicks en el mapa para obtener coordenadas (modo debug)"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			# Click derecho para obtener coordenadas normalizadas
			var normalized_pos = _get_click_position_normalized()
			print("📍 Click en mapa - Coordenadas normalizadas: Vector2(", 
				"%.3f" % normalized_pos.x, ", ", 
				"%.3f" % normalized_pos.y, ")")
			print("   Código para copiar: Vector2(", normalized_pos.x, ", ", normalized_pos.y, ")")
			print("   Para usar en region_data: \"position\": Vector2(", normalized_pos.x, ", ", normalized_pos.y, "),")

var debug_coords_label: Label = null

func _on_map_mouse_entered():
	"""Muestra coordenadas al hacer hover sobre el mapa (modo debug)"""
	if not debug_coords_label:
		debug_coords_label = Label.new()
		debug_coords_label.name = "DebugCoordsLabel"
		debug_coords_label.add_theme_font_size_override("font_size", 12)
		debug_coords_label.add_theme_color_override("font_color", Color.YELLOW)
		debug_coords_label.z_index = 1000
		add_child(debug_coords_label)
	debug_coords_label.visible = true

func _on_map_mouse_exited():
	"""Oculta coordenadas al salir del mapa"""
	if debug_coords_label:
		debug_coords_label.visible = false

func _process(_delta):
	"""Actualiza las coordenadas del mouse en modo debug"""
	if debug_coords_label and debug_coords_label.visible and map_container:
		var normalized_pos = _get_click_position_normalized()
		var mouse_pos = get_global_mouse_position()
		debug_coords_label.text = "X: %.3f, Y: %.3f" % [normalized_pos.x, normalized_pos.y]
		debug_coords_label.position = mouse_pos - get_global_position() + Vector2(15, 15)
