# 🤖 INSTRUCCIONES: Sistema de IA para Manifiestos

## 📋 RESUMEN

Se ha implementado un sistema completo de análisis de manifiestos con efectos de gameplay reales. El sistema puede usar Ollama (IA local) o un modo simulado como fallback.

## 🚀 INSTALACIÓN DE OLLAMA (OPCIONAL PERO RECOMENDADO)

### Paso 1: Descargar Ollama
1. Ve a: https://ollama.com/download
2. Descarga la versión para Windows
3. Instala ejecutando el instalador

### Paso 2: Descargar Modelo Recomendado
Abre PowerShell o CMD y ejecuta:

```bash
ollama pull phi3:mini
```

**Modelos alternativos recomendados:**
- `phi3:mini` (3.8GB) - **RECOMENDADO**: Rápido, ligero, buen español
- `gemma:2b` (1.4GB) - Muy ligero pero menos preciso
- `llama3.2:1b` (1.3GB) - Ultra ligero
- `mistral:7b` (4.1GB) - Mejor calidad pero más pesado

### Paso 3: Verificar Instalación
```bash
ollama list
```

Deberías ver el modelo descargado.

### Paso 4: Probar Ollama
```bash
ollama run phi3:mini "Hola, ¿funcionas?"
```

## ⚙️ CONFIGURACIÓN EN GODOT

El sistema está configurado para:
- **URL de Ollama**: `http://localhost:11434` (puerto por defecto)
- **Modelo por defecto**: `phi3:mini`
- **Timeout**: 10 segundos

Si Ollama no está disponible, el sistema automáticamente usa modo simulado.

## 🎮 CÓMO FUNCIONA

### 1. Análisis de IA
Cuando escribes un manifiesto:
- Si Ollama está disponible → Usa IA real
- Si no → Usa análisis simulado (basado en palabras clave)

### 2. Efectos de Gameplay
El sistema calcula efectos basados en:
- **Calidad retórica** (0-10)
- **Poder de persuasión** (0-10)
- **Temas detectados** (anti_cartographer, revolution, ecology, justice)
- **Riesgo de represión** (low/medium/high/extreme)

### 3. Efectos Aplicados

**EFECTOS POSITIVOS:**
- ✅ **Poder Político**: +5 a +30 (nuevo recurso)
- ✅ **Cordura**: +0 a +8 (si tono es esperanza/determinación)
- ✅ **Reputación**: Varía por región según temas

**EFECTOS NEGATIVOS:**
- ⚠️ **Cordura**: -0 a -5 (si tono es ira/miedo)
- ⚠️ **Atención Cartógrafos**: Aumenta si mencionas "Cartógrafos"
- ⚠️ **Reputación negativa**: En regiones conservadoras (EO, EU, CH)

**RIESGOS:**
- 🔴 **Infiltración**: Si atención Cartógrafos > 50%
- 🔴 **Censura**: Si riesgo de represión es high/extreme

## 📁 ARCHIVOS CREADOS

1. **`scripts/systems/OllamaManifestoProcessor.gd`**
   - Procesador de IA con Ollama
   - Fallback a modo simulado

2. **`scripts/systems/ManifestoImpactSystem.gd`**
   - Sistema de efectos de gameplay
   - Calcula y aplica consecuencias

3. **Actualizado `scripts/GameClient.gd`**
   - Integración con sistemas de IA y efectos

4. **Actualizado `scenes/UI_Main.gd`**
   - UI mejorada para mostrar análisis y efectos

## 🔧 TROUBLESHOOTING

### Ollama no responde
1. Verifica que Ollama esté corriendo: `ollama list`
2. Verifica el puerto: `http://localhost:11434`
3. El sistema usará modo simulado automáticamente

### Análisis vacío
- Verifica que el archivo `AIManifestoProcesssor.gd` exista
- Revisa los logs en la consola de Godot
- El sistema debería usar el procesador simulado como fallback

### Efectos no se aplican
- Verifica que `ManifestoImpactSystem` esté inicializado
- Revisa que `GameClient` tenga los métodos `modify_sanity` y `modify_reputation`

## 🎯 PRÓXIMOS PASOS

1. **Mejorar prompt de IA**: Ajustar el prompt en `OllamaManifestoProcessor._build_analysis_prompt()`
2. **Balancear efectos**: Ajustar valores en `ManifestoImpactSystem._calculate_effects()`
3. **Añadir más métricas**: Poder político, aliados, eventos especiales
4. **Integrar con backend**: Enviar efectos al servidor Go

## 📊 ESTRUCTURA DE DATOS

### Análisis de IA
```gdscript
{
  "analysis": {
    "emotional_tone": "ira|esperanza|miedo|determinacion",
    "primary_themes": ["anti_cartographer", "ecology"],
    "rhetorical_quality": 7.5,
    "persuasion_power": 8.0,
    "risk_of_repression": "high",
    "target_audience": ["workers", "youth"],
    "potential_virality": 7.0,
    "summary": "Manifiesto apasionado...",
    "strengths": ["Tono motivacional"],
    "weaknesses": ["Falta propuestas concretas"]
  },
  "game_effects": {
    "immediate": [...],
    "delayed": [...],
    "risks": [...]
  }
}
```

## 💡 CONSEJOS

- **Manifiestos efectivos**: Combina temas (ecology + revolution) para máximo impacto
- **Cuidado con Cartógrafos**: Mencionarlos aumenta atención pero da más poder político
- **Balance emocional**: Esperanza/determinación dan cordura, ira/miedo la quitan
- **Regiones**: PE y LA son más receptivas, EO y EU son más conservadoras
















