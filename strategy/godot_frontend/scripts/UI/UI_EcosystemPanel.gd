# UI_EcosystemPanel.gd (nuevo panel para la UI)
extends Control

@onready var ecosystem_grid = $EcosystemGrid
@onready var world_map = $WorldMap
@onready var timeline_graph = $TimelineGraph

func _ready():
	connect_to_ecosystem_manager()
	setup_world_map_overlay()

func update_ecosystem_display(eco_id: String, state: EcosystemState):
	# Actualizar item en grid
	var item = ecosystem_grid.get_node(eco_id)
	if item:
		item.update_display(state)
	
	# Actualizar mapa mundial
	update_map_overlay(eco_id, state.health)
	
	# Actualizar gráfico temporal
	timeline_graph.add_data_point(eco_id, state.health)

func update_map_overlay(eco_id: String, health: float):
	var color: Color
	if health >= 70: color = Color.GREEN
	elif health >= 40: color = Color.YELLOW
	elif health >= 20: color = Color.ORANGE
	else: color = Color.RED
	
	world_map.set_region_color(eco_id, color)

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
