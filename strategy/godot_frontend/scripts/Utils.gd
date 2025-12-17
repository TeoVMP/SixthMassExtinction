# godot_frontend/scripts/Utils.gd
class_name GameUtils

static func format_time(seconds: float) -> String:
    var hours = int(seconds / 3600)
    var minutes = int((seconds - hours * 3600) / 60)
    var secs = int(seconds - hours * 3600 - minutes * 60)
    
    if hours > 0:
        return "%02d:%02d:%02d" % [hours, minutes, secs]
    else:
        return "%02d:%02d" % [minutes, secs]

static func calculate_sanity_color(sanity: int) -> Color:
    if sanity >= 70:
        return Color.GREEN
    elif sanity >= 50:
        return Color.YELLOW
    elif sanity >= 30:
        return Color.ORANGE
    else:
        return Color.RED

static func get_region_name(region_code: String) -> String:
    var regions = {
        "pe": "Pueblos Explotados",
        "eo": "Europa Occidental",
        "eu": "Estados Unidos",
        "ch": "China",
        "ru": "Rusia",
        "as": "Asia Sur",
        "au": "África Unida",
        "la": "Latinoamérica"
    }
    return regions.get(region_code, "Desconocido")

static func save_screenshot() -> void:
    var image = get_viewport().get_texture().get_image()
    var timestamp = Time.get_datetime_string_from_system().replace(":", "_")
    var path = "user://screenshots/screenshot_%s.png" % timestamp
    
    # Crear directorio si no existe
    var dir = DirAccess.open("user://")
    dir.make_dir("screenshots")
    
    image.save_png(path)
    print("Screenshot guardado: ", path)

static func lerp_color(a: Color, b: Color, t: float) -> Color:
    return Color(
        lerp(a.r, b.r, t),
        lerp(a.g, b.g, t),
        lerp(a.b, b.b, t),
        lerp(a.a, b.a, t)
    )
