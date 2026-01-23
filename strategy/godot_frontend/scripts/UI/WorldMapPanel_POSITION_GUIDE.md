# Guía para Ajustar Posiciones de Puntos en el Mapa

## Ubicación del Archivo
Las posiciones se encuentran en: `godot_frontend/scripts/UI/WorldMapPanel.gd`

## Cómo Funcionan las Coordenadas

Las coordenadas están **normalizadas de 0 a 1**:
- **X (horizontal)**: 
  - `0.0` = Borde izquierdo del mapa
  - `0.5` = Centro horizontal
  - `1.0` = Borde derecho del mapa
- **Y (vertical)**:
  - `0.0` = Borde superior (Norte)
  - `0.5` = Centro vertical
  - `1.0` = Borde inferior (Sur)

## Dónde Editar las Posiciones

### Regiones
Edita el diccionario `region_data` (líneas 43-156):

```gdscript
var region_data = {
    "eu": {
        "name": "Estados Unidos", 
        "position": Vector2(0.20, 0.32),  // <-- Ajusta estos valores
        ...
    },
    ...
}
```

### Ecosistemas
Edita el diccionario `ecosystem_data` (líneas 160-168):

```gdscript
var ecosystem_data = {
    "amazon": {
        "name": "Amazonas", 
        "position_override": Vector2(0.32, 0.55),  // <-- Ajusta estos valores
        ...
    },
    ...
}
```

## Códigos de Regiones

- `"eu"` - Estados Unidos
- `"ca"` - América Central
- `"sa"` - Sudamérica
- `"eo"` - Europa Occidental
- `"ee"` - Europa Oriental
- `"ru"` - Rusia
- `"ch"` - China
- `"as"` - Asia Sur
- `"seasia"` - Sudeste Asiático
- `"mena"` - Medio Oriente
- `"africa_norte"` - África del Norte
- `"africa_central"` - África Central
- `"africa_oriental"` - África Oriental
- `"africa_occidental"` - África Occidental
- `"sudafrica"` - Sudáfrica
- `"oceania"` - Oceanía

## Pasos para Ajustar

1. Abre `WorldMapPanel.gd` en tu editor
2. Busca la región que quieres ajustar (por ejemplo, `"eu"` para Estados Unidos)
3. Modifica los valores de `position: Vector2(X, Y)`
4. Guarda el archivo
5. En Godot, recarga el script o reinicia la escena
6. Abre el mapa del mundo para ver los cambios

## Ejemplo de Ajuste

Si quieres mover "Estados Unidos" más al este y más al sur:

**Antes:**
```gdscript
"eu": {
    "name": "Estados Unidos", 
    "position": Vector2(0.20, 0.32),
    ...
}
```

**Después:**
```gdscript
"eu": {
    "name": "Estados Unidos", 
    "position": Vector2(0.25, 0.38),  // Más al este (0.20 → 0.25) y más al sur (0.32 → 0.38)
    ...
}
```

## Consejos

- **Incrementos pequeños**: Usa cambios de 0.01-0.05 para ajustes finos
- **Prueba y ajusta**: Haz cambios pequeños, prueba, y ajusta según necesites
- **Coordenadas relativas**: Recuerda que son relativas al tamaño del mapa, no píxeles absolutos
- **Ecosistemas**: Si un ecosistema tiene `position_override`, usa esa posición. Si no, se calcula relativo a su región.

## Función de Debug

Puedes usar la función `_print_region_positions()` para ver todas las posiciones actuales en la consola.







