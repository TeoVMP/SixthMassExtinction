# CyberpunkTheme.gd
# Sistema de tema global futurista/post-apocalíptico/hacker profesional
extends RefCounted
class_name CyberpunkTheme

# ============================================
# PALETA DE COLORES CYBERPUNK/POST-APOCALÍPTICA
# ============================================

# Colores base - Fondos oscuros
static var COLOR_BG_PRIMARY = Color(0.02, 0.02, 0.03, 1.0)      # Negro casi puro
static var COLOR_BG_SECONDARY = Color(0.05, 0.05, 0.08, 1.0)    # Gris muy oscuro azulado
static var COLOR_BG_TERTIARY = Color(0.08, 0.08, 0.12, 1.0)     # Gris oscuro
static var COLOR_BG_PANEL = Color(0.03, 0.03, 0.05, 0.95)       # Panel semi-transparente

# Colores neón - Acentos brillantes
static var COLOR_NEON_CYAN = Color(0.0, 1.0, 1.0, 1.0)          # Cian brillante
static var COLOR_NEON_GREEN = Color(0.0, 1.0, 0.4, 1.0)         # Verde neón
static var COLOR_NEON_MAGENTA = Color(1.0, 0.0, 0.8, 1.0)       # Magenta neón
static var COLOR_NEON_BLUE = Color(0.2, 0.6, 1.0, 1.0)         # Azul eléctrico
static var COLOR_NEON_ORANGE = Color(1.0, 0.4, 0.0, 1.0)        # Naranja neón
static var COLOR_NEON_RED = Color(1.0, 0.0, 0.2, 1.0)           # Rojo neón

# Colores de texto
static var COLOR_TEXT_PRIMARY = Color(0.9, 0.95, 1.0, 1.0)      # Blanco azulado
static var COLOR_TEXT_SECONDARY = Color(0.6, 0.7, 0.8, 1.0)    # Gris claro
static var COLOR_TEXT_DIM = Color(0.4, 0.5, 0.6, 1.0)          # Gris medio
static var COLOR_TEXT_TERMINAL = Color(0.0, 1.0, 0.4, 1.0)     # Verde terminal

# Colores de estado
static var COLOR_SUCCESS = Color(0.0, 1.0, 0.4, 1.0)           # Verde éxito
static var COLOR_WARNING = Color(1.0, 0.6, 0.0, 1.0)          # Naranja advertencia
static var COLOR_ERROR = Color(1.0, 0.0, 0.3, 1.0)            # Rojo error
static var COLOR_INFO = Color(0.2, 0.6, 1.0, 1.0)              # Azul información

# Colores de borde con glow
static var COLOR_BORDER_NEON = Color(0.0, 1.0, 0.6, 0.8)        # Borde neón verde
static var COLOR_BORDER_DIM = Color(0.2, 0.3, 0.4, 0.5)        # Borde tenue

# ============================================
# ESTILOS DE BOTONES
# ============================================

static func create_button_style_normal() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_SECONDARY
	style.border_color = COLOR_NEON_CYAN
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 0  # Bordes rectos estilo tech
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.shadow_color = Color(0.0, 1.0, 0.6, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	return style

static func create_button_style_hover() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 1.0)
	style.border_color = COLOR_NEON_CYAN
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.shadow_color = Color(0.0, 1.0, 1.0, 0.4)
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 2)
	return style

static func create_button_style_pressed() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 1.0)
	style.border_color = COLOR_NEON_BLUE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.shadow_color = Color(0.2, 0.6, 1.0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 0)
	return style

# ============================================
# ESTILOS DE PANELES
# ============================================

static func create_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_PANEL
	style.border_color = COLOR_BORDER_NEON
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.shadow_color = Color(0.0, 0.5, 1.0, 0.2)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 0)
	return style

static func create_terminal_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.98)  # Negro terminal profesional
	style.border_color = COLOR_NEON_CYAN
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.shadow_color = Color(0.0, 1.0, 1.0, 0.3)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 0)
	return style

# ============================================
# ESTILOS DE BARRAS DE PROGRESO
# ============================================

static func create_progress_bar_bg_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 1.0)
	style.border_color = COLOR_BORDER_DIM
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	return style

static func create_progress_bar_fill_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.3)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	style.shadow_color = Color(color.r, color.g, color.b, 0.5)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 0)
	return style

# ============================================
# APLICAR TEMA A NODOS
# ============================================

static func apply_theme_to_node(node: Node):
	"""Aplica el tema cyberpunk a un nodo y sus hijos recursivamente"""
	if node is Button:
		var button = node as Button
		button.add_theme_stylebox_override("normal", create_button_style_normal())
		button.add_theme_stylebox_override("hover", create_button_style_hover())
		button.add_theme_stylebox_override("pressed", create_button_style_pressed())
		button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		button.add_theme_color_override("font_hover_color", COLOR_NEON_CYAN)
		button.add_theme_color_override("font_pressed_color", COLOR_NEON_MAGENTA)
		button.add_theme_font_size_override("font_size", 14)
	
	elif node is Panel:
		var panel = node as Panel
		panel.add_theme_stylebox_override("panel", create_panel_style())
	
	elif node is Label:
		var label = node as Label
		label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		label.add_theme_font_size_override("font_size", 14)
	
	elif node is ProgressBar:
		var progress = node as ProgressBar
		progress.add_theme_stylebox_override("background", create_progress_bar_bg_style())
		# El fill se actualiza dinámicamente según el valor
	
	# Aplicar recursivamente a los hijos
	for child in node.get_children():
		apply_theme_to_node(child)

