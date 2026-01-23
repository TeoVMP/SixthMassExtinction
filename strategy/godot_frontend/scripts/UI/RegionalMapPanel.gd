# RegionalMapPanel.gd
# Panel de mapa regional con países, se abre con click derecho en una región
extends Control
class_name RegionalMapPanel

signal country_selected(country_code: String)
signal state_selected(state_code: String)  # Para EEUU y China

var region_code: String = ""
var game_client: Node = null
var parent_window: Window = null

# Datos de países por región (realistas)
var countries_by_region = {
	"africa_norte": {
		"countries": {
			"morocco": {"name": "Marruecos", "position": Vector2(0.25, 0.3)},
			"algeria": {"name": "Argelia", "position": Vector2(0.4, 0.35)},
			"tunisia": {"name": "Túnez", "position": Vector2(0.5, 0.3)},
			"libya": {"name": "Libia", "position": Vector2(0.55, 0.4)},
			"egypt": {"name": "Egipto", "position": Vector2(0.65, 0.45)},
			"mauritania": {"name": "Mauritania", "position": Vector2(0.3, 0.4)},
			"mali": {"name": "Mali", "position": Vector2(0.35, 0.45)},
			"niger": {"name": "Níger", "position": Vector2(0.45, 0.45)},
			"chad": {"name": "Chad", "position": Vector2(0.5, 0.45)},
			"sudan": {"name": "Sudán", "position": Vector2(0.6, 0.4)}
		}
	},
	"africa_oriental": {
		"countries": {
			"ethiopia": {"name": "Etiopía", "position": Vector2(0.5, 0.4)},
			"kenya": {"name": "Kenia", "position": Vector2(0.55, 0.5)},
			"tanzania": {"name": "Tanzania", "position": Vector2(0.55, 0.6)},
			"uganda": {"name": "Uganda", "position": Vector2(0.5, 0.5)},
			"sudan": {"name": "Sudán", "position": Vector2(0.45, 0.35)},
			"south_sudan": {"name": "Sudán del Sur", "position": Vector2(0.5, 0.45)},
			"rwanda": {"name": "Ruanda", "position": Vector2(0.5, 0.55)},
			"burundi": {"name": "Burundi", "position": Vector2(0.5, 0.6)},
			"somalia": {"name": "Somalia", "position": Vector2(0.6, 0.5)},
			"djibouti": {"name": "Yibuti", "position": Vector2(0.6, 0.45)},
			"eritrea": {"name": "Eritrea", "position": Vector2(0.55, 0.4)},
			"madagascar": {"name": "Madagascar", "position": Vector2(0.6, 0.7)}
		}
	},
	"africa_occidental": {
		"countries": {
			"nigeria": {"name": "Nigeria", "position": Vector2(0.45, 0.5)},
			"ghana": {"name": "Ghana", "position": Vector2(0.4, 0.55)},
			"senegal": {"name": "Senegal", "position": Vector2(0.25, 0.45)},
			"mali": {"name": "Mali", "position": Vector2(0.35, 0.45)},
			"ivory_coast": {"name": "Costa de Marfil", "position": Vector2(0.4, 0.55)},
			"burkina_faso": {"name": "Burkina Faso", "position": Vector2(0.4, 0.5)},
			"niger": {"name": "Níger", "position": Vector2(0.45, 0.45)},
			"guinea": {"name": "Guinea", "position": Vector2(0.35, 0.55)},
			"sierra_leone": {"name": "Sierra Leona", "position": Vector2(0.3, 0.55)},
			"liberia": {"name": "Liberia", "position": Vector2(0.35, 0.6)},
			"togo": {"name": "Togo", "position": Vector2(0.45, 0.55)},
			"benin": {"name": "Benín", "position": Vector2(0.45, 0.5)},
			"cameroon": {"name": "Camerún", "position": Vector2(0.5, 0.5)},
			"chad": {"name": "Chad", "position": Vector2(0.5, 0.45)}
		}
	},
	"sudafrica": {
		"countries": {
			"south_africa": {"name": "Sudáfrica", "position": Vector2(0.5, 0.7)},
			"zimbabwe": {"name": "Zimbabue", "position": Vector2(0.55, 0.6)},
			"mozambique": {"name": "Mozambique", "position": Vector2(0.6, 0.65)},
			"botswana": {"name": "Botsuana", "position": Vector2(0.5, 0.65)},
			"namibia": {"name": "Namibia", "position": Vector2(0.45, 0.7)},
			"angola": {"name": "Angola", "position": Vector2(0.45, 0.6)},
			"zambia": {"name": "Zambia", "position": Vector2(0.55, 0.6)},
			"malawi": {"name": "Malaui", "position": Vector2(0.6, 0.6)},
			"lesotho": {"name": "Lesoto", "position": Vector2(0.55, 0.7)},
			"eswatini": {"name": "Esuatini", "position": Vector2(0.55, 0.7)}
		}
	},
	"sa": {
		"countries": {
			"brazil": {"name": "Brasil", "position": Vector2(0.5, 0.5)},
			"argentina": {"name": "Argentina", "position": Vector2(0.35, 0.7)},
			"chile": {"name": "Chile", "position": Vector2(0.3, 0.65)},
			"colombia": {"name": "Colombia", "position": Vector2(0.35, 0.4)},
			"peru": {"name": "Perú", "position": Vector2(0.3, 0.5)},
			"venezuela": {"name": "Venezuela", "position": Vector2(0.4, 0.4)},
			"ecuador": {"name": "Ecuador", "position": Vector2(0.3, 0.45)},
			"bolivia": {"name": "Bolivia", "position": Vector2(0.35, 0.55)},
			"paraguay": {"name": "Paraguay", "position": Vector2(0.4, 0.6)},
			"uruguay": {"name": "Uruguay", "position": Vector2(0.4, 0.7)},
			"guyana": {"name": "Guyana", "position": Vector2(0.45, 0.4)},
			"suriname": {"name": "Surinam", "position": Vector2(0.45, 0.4)},
			"french_guiana": {"name": "Guayana Francesa", "position": Vector2(0.45, 0.4)}
		}
	},
	"ca": {
		"countries": {
			"mexico": {"name": "México", "position": Vector2(0.3, 0.4)},
			"guatemala": {"name": "Guatemala", "position": Vector2(0.35, 0.5)},
			"honduras": {"name": "Honduras", "position": Vector2(0.4, 0.5)},
			"nicaragua": {"name": "Nicaragua", "position": Vector2(0.4, 0.55)},
			"costa_rica": {"name": "Costa Rica", "position": Vector2(0.4, 0.6)},
			"panama": {"name": "Panamá", "position": Vector2(0.45, 0.6)},
			"belize": {"name": "Belice", "position": Vector2(0.35, 0.5)},
			"el_salvador": {"name": "El Salvador", "position": Vector2(0.4, 0.5)}
		}
	},
	"eo": {
		"countries": {
			"spain": {"name": "España", "position": Vector2(0.3, 0.4)},
			"france": {"name": "Francia", "position": Vector2(0.4, 0.3)},
			"germany": {"name": "Alemania", "position": Vector2(0.5, 0.3)},
			"italy": {"name": "Italia", "position": Vector2(0.5, 0.4)},
			"uk": {"name": "Reino Unido", "position": Vector2(0.35, 0.25)},
			"portugal": {"name": "Portugal", "position": Vector2(0.25, 0.4)},
			"netherlands": {"name": "Países Bajos", "position": Vector2(0.45, 0.3)},
			"belgium": {"name": "Bélgica", "position": Vector2(0.4, 0.3)},
			"switzerland": {"name": "Suiza", "position": Vector2(0.45, 0.35)},
			"austria": {"name": "Austria", "position": Vector2(0.5, 0.35)},
			"poland": {"name": "Polonia", "position": Vector2(0.55, 0.3)},
			"sweden": {"name": "Suecia", "position": Vector2(0.5, 0.2)},
			"norway": {"name": "Noruega", "position": Vector2(0.45, 0.2)},
			"denmark": {"name": "Dinamarca", "position": Vector2(0.45, 0.25)},
			"finland": {"name": "Finlandia", "position": Vector2(0.55, 0.2)},
			"greece": {"name": "Grecia", "position": Vector2(0.55, 0.45)},
			"ireland": {"name": "Irlanda", "position": Vector2(0.3, 0.25)}
		}
	},
	"eu": {
		"countries": {
			"usa": {"name": "Estados Unidos", "position": Vector2(0.5, 0.5), "has_states": true}
		}
	},
	"ch": {
		"countries": {
			"china": {"name": "China", "position": Vector2(0.5, 0.5), "has_provinces": true}
		}
	},
	"ru": {
		"countries": {
			"russia": {"name": "Rusia", "position": Vector2(0.5, 0.3)},
			"kazakhstan": {"name": "Kazajistán", "position": Vector2(0.6, 0.35)},
			"belarus": {"name": "Bielorrusia", "position": Vector2(0.5, 0.25)},
			"uzbekistan": {"name": "Uzbekistán", "position": Vector2(0.65, 0.4)},
			"turkmenistan": {"name": "Turkmenistán", "position": Vector2(0.65, 0.4)}
		}
	},
	"ee": {
		"countries": {
			"poland": {"name": "Polonia", "position": Vector2(0.5, 0.3)},
			"romania": {"name": "Rumania", "position": Vector2(0.55, 0.35)},
			"czech_republic": {"name": "República Checa", "position": Vector2(0.5, 0.3)},
			"hungary": {"name": "Hungría", "position": Vector2(0.5, 0.35)},
			"bulgaria": {"name": "Bulgaria", "position": Vector2(0.55, 0.4)},
			"slovakia": {"name": "Eslovaquia", "position": Vector2(0.5, 0.3)},
			"croatia": {"name": "Croacia", "position": Vector2(0.5, 0.4)},
			"serbia": {"name": "Serbia", "position": Vector2(0.52, 0.38)},
			"slovenia": {"name": "Eslovenia", "position": Vector2(0.5, 0.35)},
			"ukraine": {"name": "Ucrania", "position": Vector2(0.55, 0.3)}
		}
	},
	"as": {
		"countries": {
			"india": {"name": "India", "position": Vector2(0.5, 0.5)},
			"pakistan": {"name": "Pakistán", "position": Vector2(0.45, 0.45)},
			"bangladesh": {"name": "Bangladesh", "position": Vector2(0.55, 0.5)},
			"sri_lanka": {"name": "Sri Lanka", "position": Vector2(0.5, 0.65)},
			"nepal": {"name": "Nepal", "position": Vector2(0.5, 0.45)},
			"bhutan": {"name": "Bután", "position": Vector2(0.55, 0.45)},
			"afghanistan": {"name": "Afganistán", "position": Vector2(0.5, 0.4)},
			"myanmar": {"name": "Myanmar", "position": Vector2(0.6, 0.5)}
		}
	},
	"seasia": {
		"countries": {
			"indonesia": {"name": "Indonesia", "position": Vector2(0.5, 0.6)},
			"thailand": {"name": "Tailandia", "position": Vector2(0.5, 0.5)},
			"vietnam": {"name": "Vietnam", "position": Vector2(0.55, 0.5)},
			"philippines": {"name": "Filipinas", "position": Vector2(0.6, 0.5)},
			"malaysia": {"name": "Malasia", "position": Vector2(0.5, 0.55)},
			"singapore": {"name": "Singapur", "position": Vector2(0.5, 0.55)},
			"cambodia": {"name": "Camboya", "position": Vector2(0.55, 0.5)},
			"laos": {"name": "Laos", "position": Vector2(0.55, 0.5)},
			"brunei": {"name": "Brunéi", "position": Vector2(0.55, 0.55)},
			"east_timor": {"name": "Timor Oriental", "position": Vector2(0.6, 0.6)}
		}
	},
	"mena": {
		"countries": {
			"saudi_arabia": {"name": "Arabia Saudí", "position": Vector2(0.5, 0.5)},
			"iran": {"name": "Irán", "position": Vector2(0.6, 0.4)},
			"iraq": {"name": "Irak", "position": Vector2(0.55, 0.4)},
			"turkey": {"name": "Turquía", "position": Vector2(0.5, 0.3)},
			"israel": {"name": "Israel", "position": Vector2(0.5, 0.4)},
			"uae": {"name": "Emiratos Árabes Unidos", "position": Vector2(0.6, 0.5)},
			"qatar": {"name": "Catar", "position": Vector2(0.6, 0.45)},
			"kuwait": {"name": "Kuwait", "position": Vector2(0.6, 0.4)},
			"oman": {"name": "Omán", "position": Vector2(0.65, 0.5)},
			"yemen": {"name": "Yemen", "position": Vector2(0.6, 0.55)},
			"jordan": {"name": "Jordania", "position": Vector2(0.55, 0.4)},
			"lebanon": {"name": "Líbano", "position": Vector2(0.55, 0.4)},
			"syria": {"name": "Siria", "position": Vector2(0.55, 0.35)},
			"egypt": {"name": "Egipto", "position": Vector2(0.5, 0.45)},
			"libya": {"name": "Libia", "position": Vector2(0.45, 0.4)}
		}
	},
	"oceania": {
		"countries": {
			"australia": {"name": "Australia", "position": Vector2(0.5, 0.6)},
			"new_zealand": {"name": "Nueva Zelanda", "position": Vector2(0.65, 0.7)},
			"papua_new_guinea": {"name": "Papúa Nueva Guinea", "position": Vector2(0.6, 0.55)},
			"fiji": {"name": "Fiyi", "position": Vector2(0.7, 0.65)},
			"samoa": {"name": "Samoa", "position": Vector2(0.75, 0.6)},
			"tonga": {"name": "Tonga", "position": Vector2(0.75, 0.65)},
			"vanuatu": {"name": "Vanuatu", "position": Vector2(0.65, 0.6)},
			"solomon_islands": {"name": "Islas Salomón", "position": Vector2(0.65, 0.6)}
		}
	}
}

# Estados de EEUU (reducidos - solo los más importantes)
var usa_states = {
	# Estados más importantes económicamente
	"california": {"name": "California", "position": Vector2(0.15, 0.4)},
	"texas": {"name": "Texas", "position": Vector2(0.4, 0.5)},
	"new_york": {"name": "Nueva York", "position": Vector2(0.65, 0.3)},
	"florida": {"name": "Florida", "position": Vector2(0.55, 0.6)},
	"illinois": {"name": "Illinois", "position": Vector2(0.5, 0.4)},
	"washington": {"name": "Washington", "position": Vector2(0.2, 0.25)},
	"massachusetts": {"name": "Massachusetts", "position": Vector2(0.65, 0.3)},
	"virginia": {"name": "Virginia", "position": Vector2(0.6, 0.4)},
	"pennsylvania": {"name": "Pensilvania", "position": Vector2(0.6, 0.35)},
	"ohio": {"name": "Ohio", "position": Vector2(0.55, 0.4)},
	"georgia": {"name": "Georgia", "position": Vector2(0.55, 0.55)},
	"north_carolina": {"name": "Carolina del Norte", "position": Vector2(0.6, 0.5)},
	# Estados importantes ecológicamente
	"alaska": {"name": "Alaska", "position": Vector2(0.1, 0.1)},
	"hawaii": {"name": "Hawái", "position": Vector2(0.1, 0.6)},
	"oregon": {"name": "Oregón", "position": Vector2(0.2, 0.3)},
	"colorado": {"name": "Colorado", "position": Vector2(0.4, 0.4)},
	"montana": {"name": "Montana", "position": Vector2(0.3, 0.3)},
	"minnesota": {"name": "Minnesota", "position": Vector2(0.5, 0.3)},
	"maine": {"name": "Maine", "position": Vector2(0.7, 0.25)}
}

# Provincias de China (principales - ecológicas y económicas)
var china_provinces = {
	# Provincias más importantes económicamente
	"guangdong": {"name": "Guangdong", "position": Vector2(0.5, 0.6)},
	"shandong": {"name": "Shandong", "position": Vector2(0.6, 0.4)},
	"jiangsu": {"name": "Jiangsu", "position": Vector2(0.6, 0.5)},
	"zhejiang": {"name": "Zhejiang", "position": Vector2(0.6, 0.55)},
	"henan": {"name": "Henan", "position": Vector2(0.55, 0.45)},
	"sichuan": {"name": "Sichuan", "position": Vector2(0.45, 0.5)},
	"hubei": {"name": "Hubei", "position": Vector2(0.55, 0.5)},
	"hunan": {"name": "Hunan", "position": Vector2(0.55, 0.55)},
	"anhui": {"name": "Anhui", "position": Vector2(0.6, 0.5)},
	"beijing": {"name": "Beijing", "position": Vector2(0.6, 0.35)},
	"shanghai": {"name": "Shanghái", "position": Vector2(0.6, 0.5)},
	"fujian": {"name": "Fujian", "position": Vector2(0.6, 0.55)},
	"hebei": {"name": "Hebei", "position": Vector2(0.6, 0.4)},
	"liaoning": {"name": "Liaoning", "position": Vector2(0.65, 0.4)},
	"shanxi": {"name": "Shanxi", "position": Vector2(0.55, 0.4)},
	"shaanxi": {"name": "Shaanxi", "position": Vector2(0.5, 0.45)},
	"jiangxi": {"name": "Jiangxi", "position": Vector2(0.6, 0.55)},
	"guangxi": {"name": "Guangxi", "position": Vector2(0.55, 0.6)},
	"yunnan": {"name": "Yunnan", "position": Vector2(0.45, 0.6)},
	"chongqing": {"name": "Chongqing", "position": Vector2(0.5, 0.5)},
	"tianjin": {"name": "Tianjin", "position": Vector2(0.6, 0.4)},
	# Provincias importantes ecológicamente
	"heilongjiang": {"name": "Heilongjiang", "position": Vector2(0.65, 0.3)},
	"jilin": {"name": "Jilin", "position": Vector2(0.65, 0.35)},
	"inner_mongolia": {"name": "Mongolia Interior", "position": Vector2(0.55, 0.35)},
	"xinjiang": {"name": "Xinjiang", "position": Vector2(0.4, 0.4)},
	"tibet": {"name": "Tíbet", "position": Vector2(0.4, 0.5)},
	"qinghai": {"name": "Qinghai", "position": Vector2(0.45, 0.45)},
	"gansu": {"name": "Gansu", "position": Vector2(0.5, 0.4)},
	"hainan": {"name": "Hainan", "position": Vector2(0.55, 0.65)}
}

var map_container: Control = null
var current_view: String = "countries"  # "countries" o "states"

# Sistema de zoom
var zoom_level: float = 1.0
var min_zoom: float = 0.5
var max_zoom: float = 3.0
var zoom_speed: float = 0.1

# Tooltip
var tooltip_panel: PanelContainer = null

# Mission Manager
var mission_manager: Node = null

func _ready():
	print("🗺️ RegionalMapPanel inicializado para región: ", region_code)
	_setup_map()
	_setup_mission_manager()

func _setup_map():
	"""Configura el mapa regional"""
	# Header con título y botón cerrar
	var header = HBoxContainer.new()
	header.name = "MapHeader"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 30
	add_child(header)
	
	var title_label = Label.new()
	title_label.name = "MapTitle"
	title_label.text = "🗺️ MAPA REGIONAL"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	var close_button = Button.new()
	close_button.text = "✕ Cerrar"
	close_button.custom_minimum_size = Vector2(100, 25)
	close_button.pressed.connect(func():
		if parent_window:
			parent_window.queue_free()
	)
	header.add_child(close_button)
	
	# Contenedor del mapa
	map_container = Panel.new()
	map_container.name = "MapContainer"
	map_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_container.offset_top = 35
	map_container.offset_left = 5
	map_container.offset_right = -5
	map_container.offset_bottom = -5
	
	var map_style = StyleBoxFlat.new()
	map_style.bg_color = Color(0.05, 0.1, 0.15, 0.95)
	map_style.border_color = Color(0.3, 0.5, 0.7)
	map_style.border_width_left = 2
	map_style.border_width_right = 2
	map_style.border_width_top = 2
	map_style.border_width_bottom = 2
	map_container.add_theme_stylebox_override("panel", map_style)
	add_child(map_container)
	
	call_deferred("_draw_countries")

func _draw_countries():
	"""Dibuja los países de la región"""
	if not map_container:
		return
	
	# Limpiar países existentes
	for child in map_container.get_children():
		if child.name.begins_with("Country_"):
			child.queue_free()
	
	await get_tree().process_frame
	
	if map_container.size.x <= 0 or map_container.size.y <= 0:
		await get_tree().process_frame
	
	var region_data = countries_by_region.get(region_code, {})
	if not region_data.has("countries"):
		print("⚠️ No se encontraron países para la región: ", region_code)
		# Mostrar mensaje de error
		var error_label = Label.new()
		error_label.name = "ErrorLabel"
		error_label.text = "No hay países definidos para esta región"
		error_label.position = Vector2(50, 50)
		map_container.add_child(error_label)
		return
	
	var countries = region_data.countries
	
	if countries.is_empty():
		print("⚠️ La región ", region_code, " tiene una lista de países vacía")
		var error_label = Label.new()
		error_label.name = "ErrorLabel"
		error_label.text = "Lista de países vacía para esta región"
		error_label.position = Vector2(50, 50)
		map_container.add_child(error_label)
		return
	
	for country_code in countries:
		var country_info = countries[country_code]
		var country_button = Button.new()
		country_button.name = "Country_" + country_code
		country_button.text = country_info.name
		country_button.custom_minimum_size = Vector2(80, 30)
		
		var map_size = map_container.size
		if map_size.x > 0 and map_size.y > 0:
			# Más separación entre países
			country_button.position = Vector2(
				country_info.position.x * map_size.x - 60,
				country_info.position.y * map_size.y - 20
			)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.6, 0.8, 0.8)
		style.border_color = Color.WHITE
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		country_button.add_theme_stylebox_override("normal", style)
		
		var hover_style = style.duplicate()
		hover_style.bg_color.a = 1.0
		hover_style.border_color = Color.YELLOW
		country_button.add_theme_stylebox_override("hover", hover_style)
		
		# Texto más grande y espaciado
		country_button.add_theme_font_size_override("font_size", 11)
		country_button.add_theme_constant_override("outline_size", 2)
		
		# Hover = tooltip, Click = misiones (o estados si aplica)
		country_button.mouse_entered.connect(func(): _on_country_mouse_entered(country_code))
		country_button.mouse_exited.connect(func(): _hide_tooltip())
		
		# Click: si es EEUU o China, mostrar estados/provincias; si no, mostrar misiones
		if country_info.has("has_states") and country_info.has_states:
			country_button.pressed.connect(func(): _show_usa_states())
		elif country_info.has("has_provinces") and country_info.has_provinces:
			country_button.pressed.connect(func(): _show_china_provinces())
		else:
			country_button.pressed.connect(func(): _show_country_missions(country_code))
		
		map_container.add_child(country_button)

func _show_usa_states():
	"""Muestra mapa de estados de EEUU"""
	current_view = "states"
	_draw_states(usa_states, "Estados Unidos")

func _show_china_provinces():
	"""Muestra mapa de provincias de China"""
	current_view = "states"
	_draw_states(china_provinces, "China")

func _draw_states(states_data: Dictionary, title: String):
	"""Dibuja estados o provincias"""
	if not map_container:
		return
	
	# Limpiar todo
	for child in map_container.get_children():
		child.queue_free()
	
	# Actualizar título
	var header = get_node_or_null("MapHeader/MapTitle")
	if header:
		header.text = "🗺️ " + title
	
	await get_tree().process_frame
	
	if map_container.size.x <= 0 or map_container.size.y <= 0:
		await get_tree().process_frame
	
	for state_code in states_data:
		var state_info = states_data[state_code]
		var state_button = Button.new()
		state_button.name = "State_" + state_code
		state_button.text = state_info.name
		state_button.custom_minimum_size = Vector2(70, 25)
		
		var map_size = map_container.size
		if map_size.x > 0 and map_size.y > 0:
			# Más separación entre estados
			state_button.position = Vector2(
				state_info.position.x * map_size.x - 50,
				state_info.position.y * map_size.y - 18
			)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.4, 0.7, 0.9, 0.8)
		style.border_color = Color.WHITE
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		state_button.add_theme_stylebox_override("normal", style)
		
		var hover_style = style.duplicate()
		hover_style.bg_color.a = 1.0
		hover_style.border_color = Color.YELLOW
		state_button.add_theme_stylebox_override("hover", hover_style)
		
		# Texto más grande
		state_button.add_theme_font_size_override("font_size", 10)
		state_button.add_theme_constant_override("outline_size", 2)
		state_button.mouse_entered.connect(func(): _on_state_mouse_entered(state_code))
		state_button.mouse_exited.connect(func(): _hide_tooltip())
		state_button.pressed.connect(func(): _show_state_missions(state_code))
		
		map_container.add_child(state_button)
	
	# Botón volver
	var back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "← Volver a países"
	back_button.custom_minimum_size = Vector2(120, 30)
	back_button.position = Vector2(10, 10)
	back_button.pressed.connect(func():
		current_view = "countries"
		_draw_countries()
	)
	map_container.add_child(back_button)

func _on_country_mouse_entered(country_code: String):
	"""Maneja hover sobre un país - muestra tooltip"""
	_show_country_tooltip(country_code)

func _show_country_tooltip(country_code: String):
	"""Muestra tooltip con información del país"""
	if not tooltip_panel:
		_setup_tooltip()
	
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
	
	var region_data = countries_by_region.get(region_code, {})
	if region_data.has("countries"):
		var country_info = region_data.countries.get(country_code, {})
		if not country_info.is_empty():
			var title = Label.new()
			title.text = country_info.name
			title.add_theme_font_size_override("font_size", 12)
			container.add_child(title)
			
			# Valores geopolíticos y ecológicos
			var geo_value_system = get_tree().root.find_child("GeopoliticalValueSystem", true, false)
			if geo_value_system and geo_value_system.has_method("get_value_report"):
				var report = geo_value_system.get_value_report(region_code, country_code)
				if report:
					var geo_label = Label.new()
					geo_label.text = "🌍 Geo: " + str(int(report.geopolitical_value)) + "/100"
					geo_label.add_theme_font_size_override("font_size", 10)
					container.add_child(geo_label)
					
					var eco_label = Label.new()
					eco_label.text = "🌿 Eco: " + str(int(report.ecological_value)) + "/100"
					eco_label.add_theme_font_size_override("font_size", 10)
					container.add_child(eco_label)
	
	tooltip_panel.custom_minimum_size = Vector2(180, 100)
	tooltip_panel.position = get_global_mouse_position() + Vector2(20, 20)
	tooltip_panel.visible = true

func _on_state_mouse_entered(state_code: String):
	"""Maneja hover sobre un estado - muestra tooltip"""
	_show_state_tooltip(state_code)

func _show_state_tooltip(state_code: String):
	"""Muestra tooltip con información del estado"""
	if not tooltip_panel:
		_setup_tooltip()
	
	for child in tooltip_panel.get_children():
		child.queue_free()
	
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 10)
	container.add_theme_constant_override("margin_bottom", 10)
	tooltip_panel.add_child(container)
	
	var states_data = usa_states if state_code in usa_states else china_provinces
	var state_info = states_data.get(state_code, {})
	if not state_info.is_empty():
		var title = Label.new()
		title.text = state_info.name
		title.add_theme_font_size_override("font_size", 12)
		container.add_child(title)
		
		# Valores geopolíticos y ecológicos
		var geo_value_system = get_tree().root.find_child("GeopoliticalValueSystem", true, false)
		if geo_value_system:
			var parent_region = "eu" if state_code in usa_states else "ch"
			var report = geo_value_system.get_value_report(parent_region, "", state_code)
			if report:
				var geo_label = Label.new()
				geo_label.text = "🌍 Geo: " + str(int(report.geopolitical_value)) + "/100"
				geo_label.add_theme_font_size_override("font_size", 10)
				container.add_child(geo_label)
				
				var eco_label = Label.new()
				eco_label.text = "🌿 Eco: " + str(int(report.ecological_value)) + "/100"
				eco_label.add_theme_font_size_override("font_size", 10)
				container.add_child(eco_label)
	
	tooltip_panel.custom_minimum_size = Vector2(180, 100)
	tooltip_panel.position = get_global_mouse_position() + Vector2(20, 20)
	tooltip_panel.visible = true

func _hide_tooltip():
	"""Oculta el tooltip"""
	if tooltip_panel:
		tooltip_panel.visible = false

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
	mission_manager = get_tree().root.find_child("MissionManager", true, false)

func _show_country_missions(country_code: String):
	"""Muestra misiones disponibles para un país"""
	if not mission_manager:
		return
	
	var region_data = countries_by_region.get(region_code, {})
	if not region_data.has("countries"):
		return
	var country_info = region_data.countries.get(country_code, {})
	if country_info.is_empty():
		return
	
	var available_missions = mission_manager.get_missions_for_region(region_code)
	# Filtrar por país si es necesario
	var country_missions = []
	for mission in available_missions:
		if mission.country_code == country_code or mission.country_code == "":
			country_missions.append(mission)
	
	_show_mission_selection_window(country_info.name, country_missions)

func _show_state_missions(state_code: String):
	"""Muestra misiones disponibles para un estado"""
	if not mission_manager:
		return
	
	var states_data = usa_states if state_code in usa_states else china_provinces
	var state_info = states_data.get(state_code, {})
	if state_info.is_empty():
		return
	
	var parent_region = "eu" if state_code in usa_states else "ch"
	var available_missions = mission_manager.get_missions_for_region(parent_region)
	# Filtrar por estado
	var state_missions = []
	for mission in available_missions:
		if mission.state_code == state_code:
			state_missions.append(mission)
	
	_show_mission_selection_window(state_info.name, state_missions)

func _show_mission_selection_window(location_name: String, missions: Array):
	"""Muestra ventana de selección de misiones"""
	var mission_window = Window.new()
	mission_window.title = "📋 Misiones: " + location_name
	mission_window.size = Vector2(600, 500)
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	container.add_theme_constant_override("margin_left", 15)
	container.add_theme_constant_override("margin_right", 15)
	container.add_theme_constant_override("margin_top", 15)
	container.add_theme_constant_override("margin_bottom", 15)
	mission_window.add_child(container)
	
	var title = Label.new()
	title.text = "Misiones Disponibles"
	title.add_theme_font_size_override("font_size", 18)
	container.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(scroll)
	
	var mission_list = VBoxContainer.new()
	mission_list.add_theme_constant_override("separation", 5)
	scroll.add_child(mission_list)
	
	if missions.is_empty():
		var no_missions = Label.new()
		no_missions.text = "No hay misiones disponibles en esta ubicación"
		mission_list.add_child(no_missions)
	else:
		for mission in missions:
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
			
			var diff_label = Label.new()
			var stars = ""
			for i in range(mission.difficulty):
				stars += "⭐"
			diff_label.text = "Dificultad: " + stars
			diff_label.add_theme_font_size_override("font_size", 10)
			mission_info.add_child(diff_label)
			
			var start_button = Button.new()
			start_button.text = "Iniciar" if mission.status == Mission.MissionStatus.AVAILABLE else "Continuar"
			start_button.custom_minimum_size = Vector2(80, 30)
			start_button.pressed.connect(func():
				if mission_manager.has_method("start_mission"):
					if mission_manager.start_mission(mission.mission_id):
						mission_window.queue_free()
			)
			mission_info.add_child(start_button)
			
			mission_list.add_child(mission_panel)
	
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.pressed.connect(func(): mission_window.queue_free())
	container.add_child(close_button)
	
	get_tree().root.add_child(mission_window)
	mission_window.popup_centered()

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

func _apply_zoom():
	"""Aplica el zoom al mapa"""
	if not map_container:
		return
	
	map_container.scale = Vector2(zoom_level, zoom_level)
	
	var viewport_size = get_viewport().get_visible_rect().size
	var map_center = map_container.size * 0.5
	var screen_center = viewport_size * 0.5
	map_container.position = screen_center - map_center * zoom_level

func _on_state_clicked(state_code: String):
	"""Maneja click en un estado/provincia"""
	state_selected.emit(state_code)
	_show_state_details(state_code)

func _show_country_details(country_code: String):
	"""Muestra detalles de un país"""
	var region_data = countries_by_region.get(region_code, {})
	if not region_data.has("countries"):
		return
	var country_info = region_data.countries.get(country_code, {})
	if country_info.is_empty():
		return
	
	# Crear panel de detalles
	var detail_panel = PanelContainer.new()
	detail_panel.name = "CountryDetailPanel"
	detail_panel.custom_minimum_size = Vector2(400, 300)
	detail_panel.set_anchors_preset(Control.PRESET_CENTER)
	detail_panel.set_offsets_preset(Control.PRESET_CENTER)
	detail_panel.z_index = 200
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(0.4, 0.4, 0.6)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	detail_panel.add_theme_stylebox_override("panel", style)
	add_child(detail_panel)
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	container.add_theme_constant_override("margin_left", 15)
	container.add_theme_constant_override("margin_right", 15)
	container.add_theme_constant_override("margin_top", 15)
	container.add_theme_constant_override("margin_bottom", 15)
	detail_panel.add_child(container)
	
	var title = Label.new()
	title.text = country_info.name
	title.add_theme_font_size_override("font_size", 18)
	container.add_child(title)
	
	# Obtener reputación si existe
	if game_client and game_client.has_method("get_player_reputation"):
		var reputation = game_client.get_player_reputation()
		var rep_value = reputation.get(region_code, 0)
		var rep_label = Label.new()
		rep_label.text = "⭐ Reputación: " + str(rep_value)
		container.add_child(rep_label)
	
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.pressed.connect(func():
		if detail_panel and is_instance_valid(detail_panel):
			detail_panel.queue_free()
	)
	container.add_child(close_button)

func _show_state_details(state_code: String):
	"""Muestra detalles de un estado/provincia"""
	var states_data = usa_states if state_code in usa_states else china_provinces
	var state_info = states_data.get(state_code, {})
	if state_info.is_empty():
		return
	
	var detail_panel = PanelContainer.new()
	detail_panel.name = "StateDetailPanel"
	detail_panel.custom_minimum_size = Vector2(350, 250)
	detail_panel.set_anchors_preset(Control.PRESET_CENTER)
	detail_panel.set_offsets_preset(Control.PRESET_CENTER)
	detail_panel.z_index = 200
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(0.4, 0.4, 0.6)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	detail_panel.add_theme_stylebox_override("panel", style)
	add_child(detail_panel)
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	container.add_theme_constant_override("margin_left", 15)
	container.add_theme_constant_override("margin_right", 15)
	container.add_theme_constant_override("margin_top", 15)
	container.add_theme_constant_override("margin_bottom", 15)
	detail_panel.add_child(container)
	
	var title = Label.new()
	title.text = state_info.name
	title.add_theme_font_size_override("font_size", 18)
	container.add_child(title)
	
	# Obtener valores geopolíticos y ecológicos
	var geo_value_system = get_tree().root.find_child("GeopoliticalValueSystem", true, false)
	if geo_value_system and geo_value_system.has_method("get_value_report"):
		# Determinar región (eu o ch)
		var parent_region = "eu"  # Por defecto
		if state_code in china_provinces:
			parent_region = "ch"
		
		var report = geo_value_system.get_value_report(parent_region, "", state_code)
		
		var geo_label = Label.new()
		geo_label.text = "🌍 Valor Geopolítico: " + str(int(report.geopolitical_value)) + "/100 (" + report.geopolitical_level + ")"
		container.add_child(geo_label)
		
		var eco_label = Label.new()
		eco_label.text = "🌿 Valor Ecológico: " + str(int(report.ecological_value)) + "/100 (" + report.ecological_level + ")"
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
	
	var close_button = Button.new()
	close_button.text = "Cerrar"
	close_button.pressed.connect(func():
		if detail_panel and is_instance_valid(detail_panel):
			detail_panel.queue_free()
	)
	container.add_child(close_button)

func set_game_client(client: Node):
	"""Establece referencia al GameClient"""
	game_client = client
