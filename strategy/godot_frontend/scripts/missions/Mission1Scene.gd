# Mission1Scene.gd
# Escena de la Misión 1: Refugio en el Hielo
# ACTO I: LOS CIMIENTOS (2028-2030) - Misión 1
extends Control
class_name Mission1Scene

signal tutorial_completed()
signal mission_completed(result: Dictionary)

# Estado de la misión
enum MissionPhase {
	ARRIVAL,           # Llegada con hipotermia
	ELARA_INTRO,       # Diálogo con Dr. Elara Vance
	CIRCLE_INTRO,      # Presentación del Círculo de Prometeo
	KWAME_REVELATION,  # Revelación de Kwame sobre Cartógrafos
	OBJECTIVE_1,       # Información sobre yo de 8 años
	OBJECTIVE_2,       # Información sobre 12 agentes
	OBJECTIVE_3,       # Información sobre La Cosecha de 2030
	ADAPTATION,        # Proceso de adaptación
	COMPLETED          # Misión completada
}

var current_phase: MissionPhase = MissionPhase.ARRIVAL
var tutorial_step: int = 0
var is_tutorial_completed: bool = false
var objectives_revealed: Array = []  # ["child_uppsala", "agents", "harvest"]
var dialogue_history: Array = []

# Referencias UI
var content_label: RichTextLabel = null
var dialogue_container: VBoxContainer = null
var objectives_panel: Panel = null
var continue_button: Button = null
var skip_tutorial_button: Button = null

func _ready():
	print("Mision 1: Refugio en el Hielo iniciada")
	_setup_mission_ui()
	_start_mission()

func _setup_mission_ui():
	"""Configura la UI de la misión"""
	# Fondo oscuro (glaciar)
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Contenedor principal
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 15)
	main_container.add_theme_constant_override("margin_left", 30)
	main_container.add_theme_constant_override("margin_right", 30)
	main_container.add_theme_constant_override("margin_top", 30)
	main_container.add_theme_constant_override("margin_bottom", 30)
	add_child(main_container)
	
	# Título
	var title_container = HBoxContainer.new()
	main_container.add_child(title_container)
	
	var title = Label.new()
	title.text = "MISIÓN 1: REFUGIO EN EL HIELO"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title_container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Islandia - 14 de septiembre de 2028"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title_container.add_child(subtitle)
	
	# Panel de objetivos (lateral derecho)
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(hbox)
	
	# Área de contenido principal
	var content_scroll = ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(content_scroll)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 10)
	content_vbox.add_theme_constant_override("margin_left", 10)
	content_vbox.add_theme_constant_override("margin_right", 10)
	content_vbox.add_theme_constant_override("margin_top", 10)
	content_vbox.add_theme_constant_override("margin_bottom", 10)
	content_scroll.add_child(content_vbox)
	
	# Label de contenido narrativo
	content_label = RichTextLabel.new()
	content_label.bbcode_enabled = true
	content_label.custom_minimum_size = Vector2(0, 400)
	content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_label.scroll_following = true
	content_vbox.add_child(content_label)
	
	# Panel de objetivos (derecha)
	objectives_panel = Panel.new()
	objectives_panel.custom_minimum_size = Vector2(300, 0)
	objectives_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(objectives_panel)
	
	var objectives_vbox = VBoxContainer.new()
	objectives_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	objectives_vbox.add_theme_constant_override("margin_left", 10)
	objectives_vbox.add_theme_constant_override("margin_right", 10)
	objectives_vbox.add_theme_constant_override("margin_top", 10)
	objectives_vbox.add_theme_constant_override("margin_bottom", 10)
	objectives_panel.add_child(objectives_vbox)
	
	var objectives_title = Label.new()
	objectives_title.text = "OBJETIVOS"
	objectives_title.add_theme_font_size_override("font_size", 18)
	objectives_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	objectives_vbox.add_child(objectives_title)
	
	# Contenedor de diálogos (para opciones)
	dialogue_container = VBoxContainer.new()
	dialogue_container.add_theme_constant_override("separation", 5)
	content_vbox.add_child(dialogue_container)
	
	# Botones de control
	var button_container = HBoxContainer.new()
	main_container.add_child(button_container)
	
	continue_button = Button.new()
	continue_button.text = "Continuar"
	continue_button.custom_minimum_size = Vector2(150, 40)
	continue_button.pressed.connect(_on_continue)
	button_container.add_child(continue_button)
	
	skip_tutorial_button = Button.new()
	skip_tutorial_button.text = "Saltar Tutorial"
	skip_tutorial_button.custom_minimum_size = Vector2(150, 40)
	skip_tutorial_button.pressed.connect(_on_skip_tutorial)
	button_container.add_child(skip_tutorial_button)
	
	_update_objectives_panel()

func _start_mission():
	"""Inicia la secuencia de la misión"""
	_show_phase(MissionPhase.ARRIVAL)

func _show_phase(phase: MissionPhase):
	"""Muestra una fase específica de la misión"""
	current_phase = phase
	
	match phase:
		MissionPhase.ARRIVAL:
			_show_arrival_scene()
		MissionPhase.ELARA_INTRO:
			_show_elara_dialogue()
		MissionPhase.CIRCLE_INTRO:
			_show_circle_intro()
		MissionPhase.KWAME_REVELATION:
			_show_kwame_revelation()
		MissionPhase.OBJECTIVE_1:
			_show_objective_1()
		MissionPhase.OBJECTIVE_2:
			_show_objective_2()
		MissionPhase.OBJECTIVE_3:
			_show_objective_3()
		MissionPhase.ADAPTATION:
			_show_adaptation()
		MissionPhase.COMPLETED:
			_complete_mission()

func _show_arrival_scene():
	"""Escena inicial: llegada con hipotermia"""
	var text = """[color=yellow]═══════════════════════════════════════════════════════[/color]
[color=cyan]ACTO I: LOS CIMIENTOS (2028-2030)[/color]
[color=yellow]═══════════════════════════════════════════════════════[/color]

[color=white]El frío te atraviesa hasta los huesos. Has caminado durante horas
por el glaciar Vatnajökull, siguiendo las coordenadas que encontraste
en los servidores de la NSA.

[color=red]HIPOTERMIA: -5 Cordura[/color]

Tu cuerpo tiembla incontrolablemente. Las extremidades apenas responden.
Pero sabes que estás cerca. Las coordenadas son correctas.

[color=cyan]64.9631°N, 19.0208°W[/color]

De repente, un sonido metálico resuena en el silencio glacial.
Una sección del hielo se desliza, revelando una entrada oculta.

[color=green]>>> La puerta se abre <<<[/color]

Una figura aparece en la entrada, iluminada por la luz cálida del interior.

[color=yellow]>>> CONTINUAR <<<[/color]"""
	
	content_label.text = text
	_clear_dialogue_options()
	_update_objectives_panel()

func _show_elara_dialogue():
	"""Diálogo con Dr. Elara Vance"""
	var text = """[color=yellow]═══════════════════════════════════════════════════════[/color]
[color=cyan]DR. ELARA VANCE[/color]
[color=yellow]═══════════════════════════════════════════════════════[/color]

[color=white]Una mujer de 65 años, con cabello plateado y ojos que reflejan
una sabiduría que trasciende décadas. Te reconoce inmediatamente.

[color=cyan]"Alexei... lo sabía. Los cálculos mostraban un 73.4% de probabilidad."[/color]

Su voz es firme, pero hay una sombra de preocupación.

[color=cyan]"Has visto lo que viene, ¿verdad? El colapso de 2035 no es un accidente.
Está orquestado. Cada línea temporal que observamos termina igual:
la humanidad al borde de la extinción, mientras ellos se enriquecen."[/color]

Te ayuda a entrar. El calor del refugio te devuelve la sensación a tus dedos.

[color=cyan]"Bienvenido al Círculo de Prometeo. Llevamos años esperándote."[/color]

[color=yellow]>>> CONTINUAR <<<[/color]"""
	
	content_label.text = text
	_clear_dialogue_options()
	objectives_revealed.append("elara_met")
	_update_objectives_panel()

func _show_circle_intro():
	"""Presentación del Círculo de Prometeo"""
	var text = """[color=yellow]═══════════════════════════════════════════════════════[/color]
[color=cyan]EL CÍRCULO DE PROMETEO[/color]
[color=yellow]═══════════════════════════════════════════════════════[/color]

[color=white]El refugio es más grande de lo que imaginabas. Un laboratorio
subterráneo con tecnología avanzada, pero discreta. Nueve personas
te observan desde diferentes estaciones de trabajo.

[color=green]Científicos de 9 nacionalidades:[/color]
  • Dr. Elara Vance (EE.UU.) - Física cuántica
  • Kwame Nkrumah Jr. (Ghana) - Física teórica, líder
  • Dr. Mei Chen (China) - Climatología
  • Dr. Priya Sharma (India) - Ciencias de datos
  • Dr. Elena Volkov (Rusia) - Tu hermana, ingeniería
  • Dr. Hassan Al-Mansouri (Emiratos) - Energía renovable
  • Dr. Sofia Martinez (Brasil) - Biología marina
  • Dr. James Okafor (Nigeria) - Inteligencia artificial
  • Dr. Yuki Tanaka (Japón) - Robótica

[color=cyan]Kwame Nkrumah Jr.[/color] se acerca. Es un hombre alto, con una presencia
imponente y una sonrisa cálida.

[color=yellow]>>> CONTINUAR <<<[/color]"""
	
	content_label.text = text
	_clear_dialogue_options()
	objectives_revealed.append("circle_met")
	_update_objectives_panel()

func _show_kwame_revelation():
	"""Revelación de Kwame sobre los Cartógrafos"""
	var text = """[color=yellow]═══════════════════════════════════════════════════════[/color]
[color=cyan]KWAME NKRUMAH JR. - LA REVELACIÓN[/color]
[color=yellow]═══════════════════════════════════════════════════════[/color]

[color=white][color=cyan]"La oligarquía, que llamamos 'Los Cartógrafos', mapea realidades
para explotarlas."[/color]

Kwame proyecta un holograma en el centro de la sala. Múltiples líneas
temporales se entrelazan, cada una marcada con un número.

[color=cyan]"Tu línea temporal es la número 37 que observamos. En todas,
el patrón es el mismo:[/color]

[color=red]1. Infiltración en gobiernos clave (2028-2030)
2. La Cosecha de 2030 - extracción masiva de recursos
3. Colapso climático acelerado (2030-2035)
4. Control total de los recursos restantes (2035+)[/color]

[color=cyan]"Los Cartógrafos no son una organización tradicional. Son un
consorcio transnacional que manipula realidades económicas y políticas
para maximizar su beneficio antes del colapso inevitable."[/color]

[color=yellow]>>> CONTINUAR <<<[/color]"""
	
	content_label.text = text
	_clear_dialogue_options()
	objectives_revealed.append("cartographers_revealed")
	_update_objectives_panel()

func _show_objective_1():
	"""OBJETIVO 1: Información sobre tu yo de 8 años"""
	var text = """[color=yellow]═══════════════════════════════════════════════════════[/color]
[color=cyan]OBJETIVO 1: ADAPTACIÓN A 2028[/color]
[color=yellow]═══════════════════════════════════════════════════════[/color]

[color=white]Elena, tu hermana, se acerca. Sus ojos reflejan una mezcla de
alegría y preocupación.

[color=cyan]"Alexei... hay algo que debes saber."[/color]

Ella muestra una pantalla con información de un orfanato en Uppsala, Suecia.

[color=red]ORFANATO ST. ERIK'S - UPPSALA, SUECIA[/color]

[color=white]En la pantalla aparece la foto de un niño de 8 años. Es... tú.

[color=cyan]"Tu yo de 8 años está en un orfanato en Uppsala. Tus padres
murieron en un 'accidente' en 2020. Los Cartógrafos los eliminaron
porque descubrieron parte de la verdad."[/color]

[color=yellow]INFORMACIÓN REVELADA:[/color]
  • Tu yo pasado está en peligro
  • Los Cartógrafos ya estaban activos en 2020
  • Tienes una conexión temporal contigo mismo
  • Cualquier acción puede afectar tu propia línea temporal

[color=cyan]"No puedes contactarlo directamente. Sería demasiado peligroso.
Pero saber dónde está te da una ventaja: puedes protegerlo indirectamente."[/color]

[color=yellow]>>> CONTINUAR <<<[/color]"""
	
	content_label.text = text
	_clear_dialogue_options()
	objectives_revealed.append("child_uppsala")
	_update_objectives_panel()

func _show_objective_2():
	"""OBJETIVO 2: Los 12 agentes Cartógrafos infiltrados"""
	var text = """[color=yellow]═══════════════════════════════════════════════════════[/color]
[color=cyan]OBJETIVO 2: LOS 12 AGENTES INFILTRADOS[/color]
[color=yellow]═══════════════════════════════════════════════════════[/color]

[color=white]Dr. Priya Sharma activa un mapa mundial interactivo. Puntos rojos
parpadean en diferentes capitales.

[color=cyan]"Hemos identificado 12 agentes de los Cartógrafos infiltrados
en gobiernos clave. Cada uno tiene acceso a decisiones críticas."[/color]

[color=red]AGENTES IDENTIFICADOS:[/color]

[color=white]1. [color=yellow]EE.UU.[/color] - Asesor de Seguridad Nacional
2. [color=yellow]China[/color] - Ministro de Recursos Energéticos
3. [color=yellow]Rusia[/color] - Director de Política Exterior
4. [color=yellow]UE[/color] - Comisionado de Comercio
5. [color=yellow]Brasil[/color] - Secretario de Medio Ambiente
6. [color=yellow]India[/color] - Asesor del Primer Ministro
7. [color=yellow]Japón[/color] - Director de Tecnología
8. [color=yellow]Arabia Saudí[/color] - Ministro de Petróleo
9. [color=yellow]Nigeria[/color] - Director de Recursos Naturales
10. [color=yellow]Australia[/color] - Ministro de Minería
11. [color=yellow]Canadá[/color] - Director de Política Climática
12. [color=yellow]México[/color] - Secretario de Economía

[color=cyan]"No tenemos sus nombres reales. Operan bajo identidades falsas.
Pero sabemos sus posiciones y su influencia. Cada uno puede bloquear
o acelerar políticas climáticas críticas."[/color]

[color=yellow]>>> CONTINUAR <<<[/color]"""
	
	content_label.text = text
	_clear_dialogue_options()
	objectives_revealed.append("agents")
	_update_objectives_panel()

func _show_objective_3():
	"""OBJETIVO 3: La Cosecha de 2030"""
	var text = """[color=yellow]═══════════════════════════════════════════════════════[/color]
[color=cyan]OBJETIVO 3: LA COSECHA DE 2030[/color]
[color=yellow]═══════════════════════════════════════════════════════[/color]

[color=white]Dr. Mei Chen muestra gráficos de proyecciones climáticas.
Una línea roja se dispara en 2030.

[color=cyan]"La Cosecha de 2030 no es metafórica. Es un plan real, documentado
en los servidores que hackeaste. Los Cartógrafos planean una extracción
masiva de recursos antes del colapso climático total."[/color]

[color=red]LA COSECHA DE 2030 - PUNTO DE INFLEXIÓN:[/color]

[color=white]• [color=yellow]Extracción acelerada de combustibles fósiles[/color]
  - Petróleo, gas, carbón sin regulación
  - Operaciones en áreas protegidas
  - Ignorando límites de emisiones

• [color=yellow]Deforestación masiva[/color]
  - Amazonas, Congo, Indonesia
  - "Operación Arca Verde" - nombre en clave
  - Compensaciones falsas de carbono

• [color=yellow]Minería de tierras raras[/color]
  - China, Groenlandia, África
  - Sin consideración ambiental
  - Contaminación masiva de acuíferos

• [color=yellow]Acaparamiento de agua dulce[/color]
  - Glaciares, acuíferos, ríos
  - Privatización de recursos hídricos
  - Control de suministros críticos

[color=cyan]"Si La Cosecha de 2030 se completa, el colapso será inevitable.
Tenemos menos de dos años para detenerla. Es el punto de no retorno."[/color]

[color=yellow]>>> CONTINUAR <<<[/color]"""
	
	content_label.text = text
	_clear_dialogue_options()
	objectives_revealed.append("harvest")
	_update_objectives_panel()

func _show_adaptation():
	"""Fase final: Adaptación completada"""
	var text = """[color=yellow]═══════════════════════════════════════════════════════[/color]
[color=cyan]ADAPTACIÓN COMPLETADA[/color]
[color=yellow]═══════════════════════════════════════════════════════[/color]

[color=white]Has aprendido todo lo necesario para operar en 2028:

[color=green][OK] Conoces al Circulo de Prometeo[/color]
[color=green][OK] Sabes sobre tu yo de 8 anos en Uppsala[/color]
[color=green][OK] Identificaste a los 12 agentes Cartografos[/color]
[color=green][OK] Entiendes La Cosecha de 2030[/color]

[color=cyan]Dr. Elara Vance:[/color] "Ahora eres parte de nosotros, Alexei.
El Círculo de Prometeo te respalda. Tienes acceso a nuestros recursos,
nuestra red de contactos y nuestra tecnología."

[color=cyan]Kwame Nkrumah Jr.:[/color] "El tiempo es tu aliado y tu enemigo.
Cada día que pasa, los Cartógrafos avanzan. Pero ahora tienes el conocimiento
y el apoyo necesario para enfrentarlos."

[color=yellow]REcompensas:[/color]
  • +10 Cordura (alivio por encontrar aliados)
  • +5 Reputación en todas las regiones (red del Círculo)
  • Acceso a tecnología avanzada
  • Desbloqueo de misiones del Acto I

[color=green]>>> COMPLETAR MISIÓN <<<[/color]"""
	
	content_label.text = text
	_clear_dialogue_options()
	_update_objectives_panel()

func _update_objectives_panel():
	"""Actualiza el panel de objetivos"""
	if not objectives_panel:
		return
	
	# Limpiar panel
	var vbox = objectives_panel.get_child(0)
	for i in range(1, vbox.get_child_count()):
		vbox.get_child(i).queue_free()
	
	# Agregar objetivos
	var objectives = [
		{"id": "elara_met", "text": "Conocer a Dr. Elara Vance", "completed": objectives_revealed.has("elara_met")},
		{"id": "circle_met", "text": "Conocer el Círculo de Prometeo", "completed": objectives_revealed.has("circle_met")},
		{"id": "cartographers_revealed", "text": "Aprender sobre los Cartógrafos", "completed": objectives_revealed.has("cartographers_revealed")},
		{"id": "child_uppsala", "text": "Descubrir tu yo de 8 años", "completed": objectives_revealed.has("child_uppsala")},
		{"id": "agents", "text": "Identificar 12 agentes Cartógrafos", "completed": objectives_revealed.has("agents")},
		{"id": "harvest", "text": "Entender La Cosecha de 2030", "completed": objectives_revealed.has("harvest")}
	]
	
	for obj in objectives:
		var obj_label = Label.new()
		var status = "[OK]" if obj.completed else "[ ]"
		var color = "[color=green]" if obj.completed else "[color=gray]"
		obj_label.bbcode_enabled = true
		obj_label.text = color + status + "[/color] " + obj.text
		vbox.add_child(obj_label)

func _clear_dialogue_options():
	"""Limpia las opciones de diálogo"""
	if dialogue_container:
		for child in dialogue_container.get_children():
			child.queue_free()

func _on_continue():
	"""Avanza a la siguiente fase"""
	match current_phase:
		MissionPhase.ARRIVAL:
			_show_phase(MissionPhase.ELARA_INTRO)
		MissionPhase.ELARA_INTRO:
			_show_phase(MissionPhase.CIRCLE_INTRO)
		MissionPhase.CIRCLE_INTRO:
			_show_phase(MissionPhase.KWAME_REVELATION)
		MissionPhase.KWAME_REVELATION:
			_show_phase(MissionPhase.OBJECTIVE_1)
		MissionPhase.OBJECTIVE_1:
			_show_phase(MissionPhase.OBJECTIVE_2)
		MissionPhase.OBJECTIVE_2:
			_show_phase(MissionPhase.OBJECTIVE_3)
		MissionPhase.OBJECTIVE_3:
			_show_phase(MissionPhase.ADAPTATION)
		MissionPhase.ADAPTATION:
			_show_phase(MissionPhase.COMPLETED)

func _on_skip_tutorial():
	"""Salta directamente a la fase de adaptación"""
	if current_phase < MissionPhase.ADAPTATION:
		# Marcar todos los objetivos como completados
		objectives_revealed = ["elara_met", "circle_met", "cartographers_revealed", 
		                       "child_uppsala", "agents", "harvest"]
		_show_phase(MissionPhase.ADAPTATION)

func _complete_mission():
	"""Completa la misión y emite señales"""
	is_tutorial_completed = true
	tutorial_completed.emit()
	
	# Aplicar recompensas
	var game_client = get_tree().root.find_child("GameClient", true, false)
	if game_client:
		if game_client.has_method("modify_sanity"):
			game_client.modify_sanity(10, "mission_reward")
		if game_client.has_method("modify_reputation"):
			# +5 reputación en todas las regiones
			var regions = ["pe", "eo", "eu", "ch", "la", "as", "au"]
			for region in regions:
				game_client.modify_reputation(region, 5)
	
	# Resultado de la misión
	var result = {
		"mission_id": "m1_refugio_hielo",
		"success": true,
		"tutorial_completed": is_tutorial_completed,
		"objectives_completed": objectives_revealed.size(),
		"reputation_rewards": {"all": 5},
		"sanity_reward": 10,
		"climate_action_reward": 10.0
	}
	
	mission_completed.emit(result)
	
	# Mostrar mensaje final
	content_label.text = """[color=green]═══════════════════════════════════════════════════════[/color]
[color=cyan]MISIÓN COMPLETADA[/color]
[color=green]═══════════════════════════════════════════════════════[/color]

[color=white]Has completado la Misión 1: Refugio en el Hielo.

Ahora tienes acceso a:
  • El mapa del mundo completo
  • Misiones del Acto I desbloqueadas
  • Red de contactos del Círculo de Prometeo
  • Tecnología avanzada

[color=yellow]Misiones desbloqueadas:[/color]
  • Misión 2: Huérfanos del Deshielo
  • Misión 3: El Latido del Amazonas

[color=green]¡La lucha por el futuro ha comenzado![/color]

[color=cyan]>>> CERRAR <<<[/color]"""
	
	continue_button.text = "Cerrar"
	continue_button.pressed.disconnect(_on_continue)
	continue_button.pressed.connect(func(): 
		var window = get_parent()
		if window is Window:
			window.queue_free()
	)
