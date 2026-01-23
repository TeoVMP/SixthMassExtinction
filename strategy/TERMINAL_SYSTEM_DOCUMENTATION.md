# 🖥️ Sistema de Terminales Kali Linux - Documentación

## 📋 Resumen

Se ha implementado un sistema completo de terminales Kali Linux integrado en el juego "Sixth Mass Extinction: Insurgencia Temporal". El sistema permite abrir múltiples terminales simultáneas, cada una ejecutándose en su propio contenedor Docker con Kali Linux real.

## 🎮 Características Principales

### ✅ Funcionalidades Implementadas

1. **Múltiples Terminales Simultáneas**
   - Puedes abrir varias terminales a la vez
   - Cada terminal tiene su propio contenedor Docker
   - Cada terminal mantiene su propio estado y historial

2. **Gestión de Ventanas**
   - **Abrir**: Crea una nueva terminal con un botón en la UI
   - **Minimizar**: Oculta la ventana temporalmente
   - **Maximizar**: Expande la ventana a pantalla completa
   - **Cerrar**: Cierra la terminal y elimina el contenedor Docker

3. **Herramientas de Kali Linux**
   - Todas las herramientas estándar de Kali Linux están disponibles
   - `nmap`, `metasploit`, `wireshark`, `aircrack-ng`, `hydra`, `sqlmap`, etc.
   - Comandos de Linux estándar: `ls`, `cd`, `cat`, `find`, `grep`, etc.

4. **Escenarios Integrados con la Historia**
   - Cada terminal puede tener un escenario específico del juego
   - Los escenarios incluyen sistemas de archivos simulados relevantes
   - Integrado con las misiones del juego

## 🚀 Cómo Usar

### Abrir una Terminal

1. En la UI principal del juego, busca el botón **"🖥️ Abrir Terminal Kali"**
2. Haz clic en el botón
3. Se abrirá una nueva ventana de terminal

### Usar la Terminal

- **Escribir comandos**: Escribe comandos de Linux en la línea de entrada
- **Historial**: Usa las flechas ↑↓ para navegar por el historial de comandos
- **Limpiar**: Escribe `clear` para limpiar la pantalla
- **Ayuda**: Escribe `help` para ver comandos disponibles

### Gestión de Ventanas

- **Minimizar**: Haz clic en el botón "─" en la barra de título
- **Maximizar**: Haz clic en el botón "□" en la barra de título
- **Cerrar**: Haz clic en el botón "✕" en la barra de título

## 🎯 Escenarios Disponibles

### 1. `nsa_breach` / `m0_brecha_nsa`
**Misión 0: La Brecha de la NSA**

Estructura de archivos:
```
/root/nsa-server/
├── logs/
│   └── server_logs.txt          # Logs del servidor NSA
├── classified/
│   └── classified_data.enc      # Datos clasificados
├── protocols/
│   └── protocol_cronos.enc     # Protocolo Cronos (objetivo)
└── backups/
```

**Objetivo**: Encontrar el Protocolo Cronos que revela la verdad sobre el colapso de 2035.

### 2. `cartographer_network` / `cartographers`
**Red de los Cartógrafos**

Estructura de archivos:
```
/root/cartographer-network/
├── agents/
│   └── agent_list.txt           # Lista de los 12 agentes infiltrados
├── operations/
│   └── harvest_2030.txt         # Plan de extracción de recursos
└── intel/
```

**Objetivo**: Infiltrar la red de los Cartógrafos y descubrir sus planes.

### 3. `circle_prometheus` / `prometheus`
**Círculo de Prometeo (Islandia)**

Estructura de archivos:
```
/root/prometheus-lab/
├── research/
│   └── timeline_analysis.txt    # Análisis de líneas temporales
└── timeline-data/
    └── cronos_data.txt          # Datos del dispositivo Cronos
```

**Objetivo**: Analizar datos temporales y entender las múltiples líneas temporales.

### 4. Escenario Genérico
Si no se especifica un escenario, se crea una terminal genérica con:
```
/root/hacking-lab/
├── tools/
└── data/
```

## 🐳 Requisitos Técnicos

### Docker

- **Docker Desktop** debe estar instalado y ejecutándose
- El sistema descargará automáticamente la imagen `kalilinux/kali-rolling` la primera vez
- Cada terminal crea su propio contenedor Docker

### Backend

- El backend en Go gestiona los contenedores Docker
- Cada terminal tiene un ID único
- Los contenedores se crean automáticamente cuando se abre una terminal

## 🔧 Arquitectura del Sistema

### Backend (Go)

**Archivo**: `go_backend/handlers/terminal.go`

- `TerminalSession`: Estructura que representa una sesión de terminal
- `getOrCreateTerminalSession()`: Obtiene o crea una sesión
- `initKaliContainerForSession()`: Inicializa un contenedor Docker para una sesión
- `executeTerminalCommand()`: Ejecuta comandos en un contenedor
- `setupScenarioFilesystem()`: Configura el sistema de archivos según el escenario

**Métodos RPC**:
- `create_terminal`: Crea una nueva terminal
- `execute_terminal_command`: Ejecuta un comando en una terminal
- `close_terminal`: Cierra una terminal
- `list_terminals`: Lista todas las terminales activas
- `get_terminal_status`: Obtiene el estado de una terminal

### Frontend (Godot)

**Archivos**:
- `scripts/UI/TerminalWindow.gd`: Ventana individual de terminal
- `scripts/UI/TerminalManager.gd`: Gestor de múltiples terminales
- `scenes/UI_Main.gd`: Integración con la UI principal

**TerminalWindow**:
- Gestiona la UI de una terminal individual
- Se comunica con el backend mediante HTTP/RPC
- Maneja comandos, historial y gestión de ventana

**TerminalManager**:
- Gestiona múltiples terminales simultáneas
- Mantiene referencias a todas las terminales activas
- Maneja la creación y cierre de terminales

## 📝 Ejemplos de Uso

### Ejemplo 1: Explorar el servidor NSA

```bash
# Conectar y explorar
ls /root/nsa-server
cd /root/nsa-server/logs
cat server_logs.txt
find /root -name "*cronos*"
cat /root/nsa-server/protocols/protocol_cronos.enc
```

### Ejemplo 2: Escanear la red de los Cartógrafos

```bash
# Usar herramientas de Kali
nmap -sS 192.168.1.0/24
cd /root/cartographer-network
cat agents/agent_list.txt
grep "Agent" operations/harvest_2030.txt
```

### Ejemplo 3: Análisis temporal

```bash
# Analizar datos del Círculo de Prometeo
cd /root/prometheus-lab
cat research/timeline_analysis.txt
ls timeline-data/
grep "collapse" research/timeline_analysis.txt
```

## 🔒 Seguridad

- Cada contenedor está aislado del sistema host
- No tiene acceso a archivos del sistema
- Se ejecuta con permisos limitados
- Se puede eliminar sin afectar el sistema

## 🐛 Solución de Problemas

### Docker no está disponible

Si Docker no está disponible, el sistema automáticamente usa un modo simulado que:
- Funciona sin Docker
- Simula comandos básicos
- Mantiene la funcionalidad básica

### Contenedor no se crea

1. Verifica que Docker Desktop esté ejecutándose
2. Verifica que tengas conexión a internet (para descargar la imagen)
3. Revisa los logs del backend de Go

### Comandos no funcionan

1. Verifica que el contenedor esté ejecutándose: `docker ps`
2. Verifica los logs: `docker logs sme-kali-terminal-<ID>`
3. Reinicia el contenedor si es necesario

## 📚 Comandos Docker Útiles

```bash
# Ver todas las terminales activas
docker ps -a | grep sme-kali-terminal

# Ver logs de una terminal específica
docker logs sme-kali-terminal-<ID>

# Reiniciar una terminal
docker restart sme-kali-terminal-<ID>

# Eliminar una terminal manualmente
docker rm -f sme-kali-terminal-<ID>

# Entrar a una terminal manualmente
docker exec -it sme-kali-terminal-<ID> /bin/bash
```

## 🎯 Integración con el Juego

### Misiones

Las terminales se integran automáticamente con las misiones:
- **Misión 0**: Abre terminal con escenario `nsa_breach`
- **Misión 1**: Abre terminal con escenario `circle_prometheus`
- Otras misiones: Pueden tener sus propios escenarios

### Narrativa

Los escenarios están diseñados para integrarse con la historia del juego:
- Los archivos contienen información relevante para la trama
- Los objetivos de las misiones se pueden completar usando las terminales
- Las herramientas de hacking son necesarias para progresar

## 🚀 Próximas Mejoras

- [ ] Más escenarios integrados con misiones
- [ ] Sistema de progreso basado en comandos ejecutados
- [ ] Desafíos CTF integrados en la narrativa
- [ ] Sistema de logros por uso de herramientas
- [ ] Integración con sistema de habilidades del jugador

## 📖 Referencias

- [Docker Documentation](https://docs.docker.com/)
- [Kali Linux Documentation](https://www.kali.org/docs/)
- [Godot Window API](https://docs.godotengine.org/en/stable/classes/class_window.html)









