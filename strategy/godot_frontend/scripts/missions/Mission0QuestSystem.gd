# Mission0QuestSystem.gd
# Sistema de quests/tareas para la Misión 0: La Brecha de la NSA
# Muestra progreso y comandos sugeridos conforme el jugador avanza
extends Node
class_name Mission0QuestSystem

signal quest_completed(quest_id: String)
signal all_quests_completed()

# Estados de las quests
enum QuestStatus {
	LOCKED,      # Bloqueada (requisitos no cumplidos)
	AVAILABLE,   # Disponible para empezar
	IN_PROGRESS, # En progreso
	COMPLETED    # Completada
}

# Definición de una quest
class Quest:
	var quest_id: String
	var title: String
	var description: String
	var status: QuestStatus = QuestStatus.AVAILABLE
	var required_quests: Array[String] = []  # IDs de quests que deben completarse antes
	var commands_suggested: Array[String] = []  # Comandos sugeridos para resolver
	var completion_conditions: Dictionary = {}  # Condiciones para completar
	var progress: float = 0.0  # Progreso 0.0-1.0
	
	func _init(id: String, title: String, desc: String):
		quest_id = id
		self.title = title
		description = desc

# Quests de la Misión 0
var quests: Dictionary = {}  # {quest_id: Quest}
var quest_order: Array[String] = []  # Orden de las quests

# Referencias
var quest_panel: Panel = null
var quest_container: VBoxContainer = null

func _ready():
	_initialize_quests()
	# Verificar si ya existe un panel antes de crear uno nuevo
	if not quest_panel or not is_instance_valid(quest_panel):
		_create_quest_ui()
	else:
		# Si ya existe, solo actualizar la UI
		_update_quest_ui()

func _initialize_quests():
	"""Inicializa las quests de la Misión 0"""
	
	# Quest 1: Enumeración inicial
	var q1 = Quest.new("enum_network", "Enumeración de Red", 
		"Identifica el objetivo y enumera los servicios disponibles")
	q1.commands_suggested = [
		"nmap -sV -p- <target_ip>",
		"gobuster dir -u http://<target_ip> -w /usr/share/wordlists/dirb/common.txt",
		"nikto -h http://<target_ip>"
	]
	q1.completion_conditions = {
		"nmap_scan": false,
		"service_discovered": false
	}
	quests[q1.quest_id] = q1
	quest_order.append(q1.quest_id)
	
	# Quest 2: Conexión al servidor
	var q2 = Quest.new("connect_server", "Conectar al Servidor NSA", 
		"Establece conexión con el servidor objetivo")
	q2.required_quests = ["enum_network"]
	q2.commands_suggested = [
		"connect",
		"ssh user@<target_ip",
		"nc <target_ip> <port>"
	]
	q2.completion_conditions = {
		"connected": false
	}
	quests[q2.quest_id] = q2
	quest_order.append(q2.quest_id)
	
	# Quest 3: Exploración del sistema de archivos
	var q3 = Quest.new("explore_filesystem", "Explorar Sistema de Archivos", 
		"Explora la estructura del servidor para encontrar archivos críticos")
	q3.required_quests = ["connect_server"]
	q3.commands_suggested = [
		"ls -la /",
		"ls -la /opt",
		"ls -la /etc",
		"find / -name '*.enc' 2>/dev/null",
		"find / -name '*protocol*' 2>/dev/null"
	]
	q3.completion_conditions = {
		"filesystem_explored": false,
		"critical_paths_found": false
	}
	quests[q3.quest_id] = q3
	quest_order.append(q3.quest_id)
	
	# Quest 4: Encontrar archivos de configuración
	var q4 = Quest.new("find_config", "Localizar Archivos de Configuración", 
		"Encuentra los archivos de configuración del sistema NSA")
	q4.required_quests = ["explore_filesystem"]
	q4.commands_suggested = [
		"cat /etc/nsa/config.conf",
		"cat /etc/os-release",
		"ls -la /opt/nsa-server/",
		"cat /var/log/nsa/protocol.log"
	]
	q4.completion_conditions = {
		"config_found": false,
		"log_read": false
	}
	quests[q4.quest_id] = q4
	quest_order.append(q4.quest_id)
	
	# Quest 5: Acceder a archivos clasificados
	var q5 = Quest.new("access_classified", "Acceder a Archivos Clasificados", 
		"Encuentra y accede a los archivos clasificados del Protocolo Cronos")
	q5.required_quests = ["find_config"]
	q5.commands_suggested = [
		"ls -la /opt/nsa-server/protocols/",
		"cat /opt/nsa-server/protocols/protocol_cronos.enc",
		"ls -la /opt/nsa-server/classified/",
		"cat /opt/nsa-server/classified/classified_data.enc",
		"ls -la /opt/nsa-server/.hidden/",
		"cat /opt/nsa-server/.hidden/.access_key"
	]
	q5.completion_conditions = {
		"protocol_found": false,
		"classified_accessed": false
	}
	quests[q5.quest_id] = q5
	quest_order.append(q5.quest_id)
	
	# Quest 6: Post-explotación y extracción
	var q6 = Quest.new("post_exploit", "Post-Explotación", 
		"Extrae toda la información crítica y completa la misión")
	q6.required_quests = ["access_classified"]
	q6.commands_suggested = [
		"cat /opt/nsa-server/.hidden/server_info.txt",
		"cat /etc/systemd/system/nsa-protocol.service",
		"cat /opt/nsa-server/protocols/cronos-daemon.sh",
		"history",
		"exit"
	]
	q6.completion_conditions = {
		"all_files_read": false,
		"mission_complete": false
	}
	quests[q6.quest_id] = q6
	quest_order.append(q6.quest_id)
	
	# Marcar primera quest como disponible
	if quests.has("enum_network"):
		quests["enum_network"].status = QuestStatus.AVAILABLE

func _create_quest_ui():
	"""Crea el panel de UI para mostrar las quests"""
	quest_panel = Panel.new()
	quest_panel.name = "QuestPanel"
	quest_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	quest_panel.set_offsets_preset(Control.PRESET_TOP_LEFT)
	quest_panel.offset_left = 10
	quest_panel.offset_top = 10
	quest_panel.offset_right = 400
	quest_panel.offset_bottom = 600
	
	# Estilo cyberpunk
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var panel_style = StyleBoxFlat.new()
	if CyberpunkThemeClass:
		panel_style.bg_color = CyberpunkThemeClass.COLOR_BG_PRIMARY
		panel_style.border_color = CyberpunkThemeClass.COLOR_NEON_CYAN
	else:
		panel_style.bg_color = Color(0.02, 0.02, 0.03, 0.95)
		panel_style.border_color = Color(0.0, 1.0, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	quest_panel.add_theme_stylebox_override("panel", panel_style)
	
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.set_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 5)
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 10)
	container.add_theme_constant_override("margin_bottom", 10)
	quest_panel.add_child(container)
	
	# Título
	var title = Label.new()
	title.text = "┌─ QUESTS ─────────────────────────────"
	var title_color = CyberpunkThemeClass.COLOR_NEON_CYAN if CyberpunkThemeClass else Color(0.0, 1.0, 1.0)
	title.add_theme_color_override("font_color", title_color)
	title.add_theme_font_size_override("font_size", 14)
	container.add_child(title)
	
	# Scroll container para las quests
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(scroll)
	
	quest_container = VBoxContainer.new()
	quest_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	quest_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(quest_container)
	
	# Actualizar UI
	_update_quest_ui()

func _update_quest_ui():
	"""Actualiza la UI de las quests"""
	if not quest_container:
		return
	
	# Limpiar quests anteriores
	for child in quest_container.get_children():
		child.queue_free()
	
	# Mostrar cada quest
	for quest_id in quest_order:
		if not quests.has(quest_id):
			continue
		
		var quest = quests[quest_id]
		_create_quest_item_ui(quest)

func _create_quest_item_ui(quest: Quest):
	"""Crea el UI para un item de quest"""
	var quest_item = VBoxContainer.new()
	quest_item.add_theme_constant_override("separation", 3)
	quest_container.add_child(quest_item)
	
	# Título y estado
	var title_container = HBoxContainer.new()
	quest_item.add_child(title_container)
	
	var status_icon = Label.new()
	match quest.status:
		QuestStatus.LOCKED:
			status_icon.text = "[LOCKED]"
		QuestStatus.AVAILABLE:
			status_icon.text = "[ ]"
		QuestStatus.IN_PROGRESS:
			status_icon.text = "[>]"
		QuestStatus.COMPLETED:
			status_icon.text = "[OK]"
	title_container.add_child(status_icon)
	
	var title_label = Label.new()
	title_label.text = quest.title
	var CyberpunkThemeClass = load("res://scripts/UI/CyberpunkTheme.gd")
	var title_color = CyberpunkThemeClass.COLOR_NEON_GREEN if CyberpunkThemeClass else Color(0.0, 1.0, 0.4)
	if quest.status == QuestStatus.COMPLETED:
		title_color = Color(0.5, 0.5, 0.5)
	elif quest.status == QuestStatus.LOCKED:
		title_color = Color(0.3, 0.3, 0.3)
	title_label.add_theme_color_override("font_color", title_color)
	title_label.add_theme_font_size_override("font_size", 12)
	title_container.add_child(title_label)
	
	# Descripción
	if quest.status != QuestStatus.LOCKED:
		var desc_label = Label.new()
		desc_label.text = quest.description
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quest_item.add_child(desc_label)
		
		# Comandos sugeridos (solo si está en progreso o disponible)
		if quest.status == QuestStatus.IN_PROGRESS or quest.status == QuestStatus.AVAILABLE:
			var commands_label = Label.new()
			commands_label.text = "Comandos sugeridos:"
			commands_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
			commands_label.add_theme_font_size_override("font_size", 9)
			quest_item.add_child(commands_label)
			
			for cmd in quest.commands_suggested:
				var cmd_label = Label.new()
				cmd_label.text = "  • " + cmd
				cmd_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
				cmd_label.add_theme_font_size_override("font_size", 9)
				cmd_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				quest_item.add_child(cmd_label)
		
		# Barra de progreso
		if quest.progress > 0.0:
			var progress_bar = ProgressBar.new()
			progress_bar.value = quest.progress * 100
			progress_bar.max_value = 100
			progress_bar.custom_minimum_size = Vector2(0, 8)
			quest_item.add_child(progress_bar)
	
	# Separador
	var separator = HSeparator.new()
	quest_item.add_child(separator)

func update_quest_progress(quest_id: String, condition: String, value: bool):
	"""Actualiza el progreso de una quest"""
	if not quests.has(quest_id):
		return
	
	var quest = quests[quest_id]
	
	# Verificar si la quest puede iniciarse
	if quest.status == QuestStatus.AVAILABLE:
		# Verificar requisitos
		var can_start = true
		for req_id in quest.required_quests:
			if not quests.has(req_id) or quests[req_id].status != QuestStatus.COMPLETED:
				can_start = false
				break
		
		if can_start:
			quest.status = QuestStatus.IN_PROGRESS
	
	if quest.status == QuestStatus.IN_PROGRESS:
		# Actualizar condición
		if quest.completion_conditions.has(condition):
			quest.completion_conditions[condition] = value
		
		# Calcular progreso
		var total = quest.completion_conditions.size()
		var completed = 0
		for key in quest.completion_conditions:
			if quest.completion_conditions[key]:
				completed += 1
		quest.progress = float(completed) / float(total) if total > 0 else 0.0
		
		# Verificar si está completa
		if quest.progress >= 1.0:
			quest.status = QuestStatus.COMPLETED
			quest_completed.emit(quest_id)
			
			# Desbloquear siguiente quest
			_unlock_next_quests(quest_id)
			
			# Verificar si todas están completas
			_check_all_quests_completed()
	
	_update_quest_ui()

func _unlock_next_quests(completed_quest_id: String):
	"""Desbloquea las quests que dependen de la quest completada"""
	for quest_id in quests:
		var quest = quests[quest_id]
		if quest.status == QuestStatus.LOCKED:
			if completed_quest_id in quest.required_quests:
				# Verificar si todos los requisitos están completos
				var all_required_complete = true
				for req_id in quest.required_quests:
					if not quests.has(req_id) or quests[req_id].status != QuestStatus.COMPLETED:
						all_required_complete = false
						break
				
				if all_required_complete:
					quest.status = QuestStatus.AVAILABLE

func _check_all_quests_completed():
	"""Verifica si todas las quests están completas"""
	for quest_id in quests:
		if quests[quest_id].status != QuestStatus.COMPLETED:
			return
	all_quests_completed.emit()

func get_current_quest() -> Quest:
	"""Obtiene la quest actual en progreso"""
	for quest_id in quest_order:
		if quests.has(quest_id):
			var quest = quests[quest_id]
			if quest.status == QuestStatus.IN_PROGRESS:
				return quest
	return null

func get_panel() -> Panel:
	"""Retorna el panel de quests"""
	return quest_panel

