#!/bin/bash
# 1. Guarda el original
cp scenes/UI_Main.tscn scenes/UI_Main_ORIGINAL.tscn

# 2. Extrae el UID funcional de tu archivo que SÍ funciona
UID_FUNCIONAL="uid://c034euokbmhay"
UID_SCRIPT="uid://cotbqrr6al32p"

# 3. Crea nuevo archivo fusionado
echo '[gd_scene load_steps=7 format=3 uid="'"$UID_FUNCIONAL"'"]' > scenes/UI_Main_NEW.tscn
echo '' >> scenes/UI_Main_NEW.tscn
echo '[ext_resource type="Script" uid="'"$UID_SCRIPT"'" path="res://scenes/UI_Main.gd" id="1"]' >> scenes/UI_Main_NEW.tscn
echo '' >> scenes/UI_Main_NEW.tscn

# 4. Añade todos los nodos del original (saltando las primeras 4 líneas)
tail -n +5 scenes/UI_Main_ORIGINAL.tscn >> scenes/UI_Main_NEW.tscn

# 5. Reemplaza
mv scenes/UI_Main_NEW.tscn scenes/UI_Main.tscn

echo "✅ Archivo fusionado creado"
