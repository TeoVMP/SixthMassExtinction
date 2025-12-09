@tool
extends EditorScript

func _run():
	print("=" . repeat(70))
	print("🔧 TESTEO DIRECTO DE GameManager.gd")
	print("=" . repeat(70))
	
	# 1. Cargar script
	var gm_path = "res://scripts/GameManager.gd"
	
	if not ResourceLoader.exists(gm_path):
		print("❌ ERROR: No existe:", gm_path)
		return
	
	print("✅ Archivo existe:", gm_path)
	
	# 2. Cargarlo
	var script = load(gm_path)
	if not script:
		print("❌ ERROR: No se pudo cargar el script")
		return
	
	print("✅ Script cargado")
	print("   Base type:", script.get_instance_base_type())
	print("   ¿Extiende Node?:", script.get_instance_base_type() == "Node")
	
	# 3. Crear instancia
	var instance = Node.new()
	instance.set_script(script)
	
	print("✅ Instancia creada")
	print("   Nombre:", instance.name)
	print("   ¿Tiene _ready()?:", "_ready" in instance)
	print("   ¿Tiene geopolitical_zones?:", "geopolitical_zones" in instance)
	
	if "geopolitical_zones" in instance:
		print("   geopolitical_zones tamaño:", instance.geopolitical_zones.size())
	
	# 4. Ejecutar _ready()
	print("\n🎯 Ejecutando _ready()...")
	instance._ready()
	
	print("=" . repeat(70))
