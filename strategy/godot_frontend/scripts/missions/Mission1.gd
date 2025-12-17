# godot_frontend/scripts/missions/Mission1.gd
extends Node2D

class_name MissionIslandia

@onready var player = $Player
@onready var npc_elara = $NPCs/ElaraVance
@onready var npc_kwame = $NPCs/KwameNkrumah
@onready var glacier = $Environment/Glacier
@onready var secret_door = $Environment/SecretDoor
@onready var puzzle_ui = $UI/PuzzleUI
@onready var dialogue_ui = $UI/DialogueUI

enum MissionState { EXPLORING, PUZZLE, DIALOGUE, COMPLETED }
var current_state: MissionState = MissionState.EXPLORING
var puzzle_solved: bool = false
var dialogue_completed: bool = false

func _ready():
    setup_mission()
    GameClient.sanity_updated.connect(_on_sanity_updated)

func setup_mission():
    # Configurar NPCs
    npc_elara.setup_dialogue("elara_intro", [
        "Alexei... lo sabía. Las probabilidades eran del 73.4%.",
        "Has visto lo que viene, ¿verdad? El colapso de 2035 no es natural.",
        "Está orquestado por quienes llamamos 'Los Cartógrafos'."
    ])
    
    npc_kwame.setup_dialogue("kwame_intro", [
        "Tu línea temporal es la número 37 que observamos.",
        "Los Cartógrafos mapean realidades para explotarlas.",
        "Necesitamos tu ayuda para cambiar este futuro."
    ])
    
    # Ocultar puerta secreta inicialmente
    secret_door.hide()
    
    # Iniciar música ambiental
    SoundManager.play_music("glacier_ambient", 0.5)

func _process(delta):
    match current_state:
        MissionState.EXPLORING:
            handle_exploration()
        MissionState.PUZZLE:
            handle_puzzle()
        MissionState.DIALOGUE:
            handle_dialogue()

func handle_exploration():
    # Verificar si jugador está cerca de coordenadas secretas
    var player_pos = player.global_position
    var secret_area = $Environment/SecretArea
    
    if secret_area.overlaps_body(player) and not puzzle_solved:
        start_puzzle()
    
    # Verificar interacción con NPCs
    if Input.is_action_just_pressed("interact"):
        var nearest_npc = get_nearest_npc()
        if nearest_npc:
            start_dialogue(nearest_npc)

func start_puzzle():
    current_state = MissionState.PUZZLE
    puzzle_ui.show()
    puzzle_ui.start_coordinate_puzzle(
        Vector2(64.9631, -19.0208),  # Coordenadas correctas
        [
            Vector2(64.1234, -19.5678),  # Fake 1
            Vector2(64.9500, -19.1000),  # Fake 2
            Vector2(65.1000, -19.0500),  # Fake 3
        ]
    )

func _on_puzzle_completed(success: bool, selected_coords: Vector2):
    if success:
        puzzle_solved = true
        reveal_secret_door()
        GameClient.perform_action("stress", {"amount": -10})  # Alivio por éxito
    else:
        # Penalidad por fallo
        GameClient.perform_action("stress", {"amount": 15})
        show_hint("Las coordenadas correctas están en Islandia. Busca 64.9°N, 19.0°W")
    
    current_state = MissionState.EXPLORING

func reveal_secret_door():
    secret_door.show()
    
    # Animación de puerta abriéndose
    var tween = create_tween()
    tween.tween_property(secret_door, "position", secret_door.position + Vector2(0, -200), 2.0)
    tween.tween_callback(func(): 
        show_notification("¡Entrada secreta descubierta!")
        current_state = MissionState.DIALOGUE
        start_dialogue(npc_elara)
    )

func start_dialogue(npc):
    current_state = MissionState.DIALOGUE
    dialogue_ui.show()
    dialogue_ui.start_dialogue(npc.get_dialogue())

func _on_dialogue_completed():
    dialogue_completed = true
    current_state = MissionState.EXPLORING
    check_mission_completion()

func check_mission_completion():
    if puzzle_solved and dialogue_completed:
        complete_mission()

func complete_mission():
    var choices = {
        "violence_used": false,
        "saved_scientist": true,
        "method": "puzzle_solution"
    }
    
    var time_spent = $MissionTimer.time_elapsed
    
    GameClient.complete_mission(
        "m1_islandia",
        choices,
        time_spent
    )
    
    # Transición a siguiente escena
    transition_to_base_interior()

func transition_to_base_interior():
    var transition = preload("res://scenes/effects/SceneTransition.tscn").instantiate()
    add_child(transition)
    transition.fade_out()
    await transition.fade_finished
    
    get_tree().change_scene_to_file("res://scenes/missions/m1_interior.tscn")

func _on_sanity_updated(value: int):
    # Efectos de cordura baja en la misión
    if value < 30 and randf() < 0.01:
        trigger_mission_flashback()

func trigger_mission_flashback():
    var flashback = preload("res://scenes/effects/MissionFlashback.tscn").instantiate()
    flashback.setup_flashback("2055_glitch", [
        "Recuerdo... el servidor de la NSA...",
        "Maya... ¿dónde estás?",
        "Los datos... tengo que llevarlos a Islandia..."
    ])
    add_child(flashback)
