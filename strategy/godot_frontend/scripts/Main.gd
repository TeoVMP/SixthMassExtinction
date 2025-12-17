# godot_frontend/scripts/Main.gd
extends Node2D

@onready var sanity_bar = $UI/SanityBar
@onready var needs_panel = $UI/NeedsPanel
@onready var world_map = $UI/WorldMap
@onready var mission_ui = $UI/MissionUI

func _ready():
	# Conectar a GameClient (autoload)
	GameClient.sanity_updated.connect(_on_sanity_updated)
	GameClient.needs_updated.connect(_on_needs_updated)
	GameClient.mission_received.connect(_on_mission_received)
	
	# Inicializar UI
	sanity_bar.initialize()
	needs_panel.initialize()
	
	# Cargar estado inicial
	GameClient.request_game_state()

func _on_sanity_updated(value: int):
	sanity_bar.update_value(value)
	
	# Efectos visuales según cordura
	match value:
		> 70:
			$Camera2D.add_shader("high_sanity")
		30..70:
			$Camera2D.remove_shader()
		< 30:
			$Camera2D.add_shader("low_sanity")
			# Flashbacks aleatorios
			if randf() < 0.05:
				trigger_flashback()

func trigger_flashback():
	var flashback_scene = preload("res://scenes/effects/Flashback.tscn")
	var flashback = flashback_scene.instantiate()
	add_child(flashback)
	flashback.play_flashback()

func _on_needs_updated(needs: Dictionary):
	needs_panel.update_needs(needs)
	
	# Alertas si necesidades están críticas
	for need in needs:
		if needs[need] > 80:
			show_warning(need.capitalize() + " crítica!")
		elif needs[need] < 20:
			show_status(need.capitalize() + " satisfecha")

func show_warning(message: String):
	var warning = preload("res://scenes/ui/WarningMessage.tscn").instantiate()
	warning.set_message(message, Color.RED)
	$UI.add_child(warning)

func show_status(message: String):
	var status = preload("res://scenes/ui/StatusMessage.tscn").instantiate()
	status.set_message(message, Color.GREEN)
	$UI.add_child(status)

func _on_mission_received(mission_data: Dictionary):
	mission_ui.show_mission(mission_data)

func _input(event):
	# Debug keys para desarrollo
	if event.is_action_pressed("sanity_debug_increase"):
		GameClient.perform_action("debug", {"action": "increase_sanity", "amount": 10})
	elif event.is_action_pressed("sanity_debug_decrease"):
		GameClient.perform_action("debug", {"action": "decrease_sanity", "amount": 10})
