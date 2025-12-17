# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Sistema central completo con 12 zonas geopolíticas
- GameManager como Autoload con timer de actualización automática
- Interfaz de diagnóstico con 4 botones funcionales (rojo, verde, cyan, amarillo)
- Conexión con Temporal Server v2.0-simple para simulación de biomas
- Mapa geopolítico visual interactivo con panel de detalles
- Sistema de logging a `game_log.txt`
- 12 zonas geopolíticas con reputación dinámica:
  1. América Latina (+5 rep automática)
  2. África Subsahariana
  3. Sudeste Asiático
  4. Sur de Asia
  5. Medio Oriente (+3 rep automática)
  6. Europa Oriental
  7. Islas del Pacífico
  8. Cuenca Amazónica (-5% deforestación)
  9. Ártico
  10. Cuenca del Congo
  11. Asia Central
  12. Caribe

### Changed
- Reestructuración completa del proyecto: separación Godot/Go en carpetas
- Actualización a Godot Engine 4.5.1
- Sistema de configuración optimizado
- .gitignore específico para proyecto Godot/Go

### Fixed
- Problemas de sincronización Git (index.lock)
- Configuración correcta de .gitignore para excluir archivos temporales
- Organización de carpetas scripts/ y scenes/

## [0.1.0] - 2025-12-09
### Added
- Proyecto inicial "Insurgencia Temporal"
- Estructura básica del juego estratégico
- Servidor temporal en Go (Temporal Server v2.0)
- Documentación inicial
- Sistema básico de zonas geopolíticas
