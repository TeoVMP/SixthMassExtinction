# Prompt de Contexto: Resolución de Problemas con apt-get update en Contenedores Kali Linux

## 📋 CONTEXTO DEL PROYECTO

### Descripción General
Este es un proyecto de juego educativo de hacking llamado "Sixth Mass Extinction" (6ME). El proyecto consiste en:

- **Backend Go**: Servidor RPC que gestiona el estado del juego, misiones, y contenedores Docker
- **Frontend Godot**: Interfaz gráfica del juego
- **Sistema de Terminales**: Los jugadores interactúan con terminales Kali Linux ejecutándose en contenedores Docker

### Arquitectura del Sistema de Terminales

El sistema utiliza contenedores Docker basados en `kalilinux/kali-rolling` para proporcionar terminales interactivas a los jugadores. Cada sesión de terminal tiene:

- **TerminalSession**: Estructura Go que representa una sesión de terminal con:
  - `ContainerID`: ID del contenedor Docker asociado
  - `Scenario`: Escenario del juego (ej: "nsa_breach" para Misión 0)
  - `WorkingDir`: Directorio de trabajo actual
  - Sistema de streaming de comandos en tiempo real

- **Funciones clave**:
  - `initKaliContainerForSession()`: Crea e inicializa un contenedor Kali Linux para una sesión
  - `setupDefaultFilesystem()`: Configura el sistema de archivos base en contenedores default
  - `executeTerminalCommand()`: Ejecuta comandos en el contenedor Docker
  - `EnsureMission0ScriptsForAllTerminals()`: Crea scripts de hacking para la Misión 0

### Ubicación del Código
- **Archivo principal**: `go_backend/handlers/terminal.go` (3969 líneas)
- **Funciones relacionadas con apt**: Líneas 190-250, 756-825, 1990-2010

---

## 🐛 PROBLEMA ACTUAL

### Error Principal
Los contenedores Kali Linux no pueden ejecutar `apt-get update` correctamente debido a errores de verificación de firmas GPG:

```
W: The key(s) in the keyring /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg are ignored as the file has an unsupported filetype.
W: OpenPGP signature verification failed: http://kali.download/kali kali-rolling InRelease: Sub-process /usr/bin/sqv returned an error code (1), error message is: Missing key 827C8569F2518CC677FECA1AED65462EC8D5E4C5, which is needed to verify signature.
W: The repository 'http://http.kali.org/kali kali-rolling InRelease' is not signed.
```

### Consecuencias
1. **No se pueden actualizar listas de paquetes**: `apt-get update` falla o muestra warnings que impiden la actualización completa
2. **No se pueden instalar herramientas**: `apt-get install` falla con "E: Unable to locate package"
3. **Herramientas no disponibles**: `nmap`, `curl`, `wget`, etc. no están instaladas en los contenedores
4. **Scripts de hacking no funcionan**: Los scripts de la Misión 0 requieren herramientas que no están disponibles

### Requisitos del Usuario
- **CRÍTICO**: Las herramientas de Kali Linux deben estar **preinstaladas** o instalarse automáticamente durante la inicialización del contenedor
- El repositorio debe estar correctamente firmado (sin warnings de "not signed")
- `apt-get update` debe ejecutarse sin errores
- `apt-get install` debe poder instalar paquetes correctamente

---

## 🔍 ESTADO ACTUAL DEL CÓDIGO

### Implementación Actual de Importación de Claves GPG

**Ubicación**: `initKaliContainerForSession()` (líneas 756-771) y `setupDefaultFilesystem()` (líneas 196-199)

**Código actual**:
```go
// Limpiar archivos de claves mal formateados si existen
cleanKeyCmd := exec.CommandContext(ctx, "docker", "exec", session.ContainerID, "sh", "-c", 
    "rm -f /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg /etc/apt/keyrings/kali-archive-keyring.gpg 2>&1 || true")

// Importar claves GPG de Kali Linux
gpgKeyCmd := exec.CommandContext(ctx, "docker", "exec", session.ContainerID, "sh", "-c", 
    "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys ED444FF07D8D0BF6 827C8569F2518CC677FECA1AED65462EC8D5E4C5 2>&1 || apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys ED444FF07D8D0BF6 827C8569F2518CC677FECA1AED65462EC8D5E4C5 2>&1 || true")
```

### Configuración de APT

**Ubicación**: Líneas 773-785 (`initKaliContainerForSession`) y 200-202 (`setupDefaultFilesystem`)

**Archivo de configuración**: `/etc/apt/apt.conf.d/99no-verify`

**Contenido actual**:
```
Acquire::Check-Valid-Until "0";
Acquire::AllowInsecureRepositories "true";
APT::Get::AllowUnauthenticated "true";
Acquire::AllowReleaseInfoChange::Suite "true";
Acquire::http::AllowRedirect "true";
Acquire::gpgv::Options "--ignore-time-conflict --ignore-valid-from";
```

### Instalación de Herramientas en Background

**Ubicación**: Líneas 787-824 (`initKaliContainerForSession`) y 217-250 (`setupDefaultFilesystem`)

**Proceso actual**:
1. Ejecuta `apt-get update` con opciones de bypass
2. Ejecuta `apt-get install` con herramientas básicas (curl, wget, git, python3, nmap, etc.)
3. Verifica que las herramientas se instalaron correctamente

**Comando de actualización**:
```bash
apt-get -o Acquire::Check-Valid-Until=0 -o Acquire::AllowInsecureRepositories=true -o APT::Get::AllowUnauthenticated=true --allow-unauthenticated --allow-insecure-repositories update
```

**Comando de instalación**:
```bash
apt-get -o Acquire::Check-Valid-Until=0 -o Acquire::AllowInsecureRepositories=true -o APT::Get::AllowUnauthenticated=true --allow-unauthenticated --allow-insecure-repositories install -y curl wget git python3 python3-pip nmap netcat-traditional netcat-openbsd iproute2 iputils-ping tree whatweb
```

### Manejo de Comandos apt-get en executeTerminalCommand

**Ubicación**: Líneas 1990-2010

**Lógica actual**:
- Detecta comandos `apt-get update` y `apt-get install`
- Aplica automáticamente la configuración de apt si no existe
- Modifica los comandos para incluir opciones de bypass
- Filtra errores de "Not live until" y "not signed" del output

---

## 🔧 SOLUCIONES INTENTADAS

### 1. Configuración de APT con opciones de bypass
- ✅ **Implementado**: Archivo `/etc/apt/apt.conf.d/99no-verify` con opciones para desactivar verificación
- ❌ **Resultado**: Aún muestra warnings de "not signed"

### 2. Importación de claves GPG con apt-key
- ✅ **Implementado**: Importación de claves `ED444FF07D8D0BF6` y `827C8569F2518CC677FECA1AED65462EC8D5E4C5`
- ❌ **Resultado**: Error "unsupported filetype" en el archivo de claves

### 3. Limpieza de archivos de claves mal formateados
- ✅ **Implementado**: Eliminación de archivos de claves antes de importar nuevas
- ❌ **Resultado**: El problema persiste, posiblemente porque `apt-key` crea archivos en formato incorrecto

### 4. Opciones de bypass en línea de comandos
- ✅ **Implementado**: `--allow-unauthenticated --allow-insecure-repositories` en comandos apt-get
- ⚠️ **Resultado**: `apt-get update` ejecuta (exit code 0) pero muestra warnings que pueden impedir la actualización completa

---

## 🎯 OBJETIVO FINAL

### Estado Deseado
1. **Claves GPG correctamente importadas**: Sin errores de "unsupported filetype" o "Missing key"
2. **Repositorio firmado**: Sin warnings de "The repository ... is not signed"
3. **apt-get update funciona**: Actualiza las listas de paquetes sin errores
4. **apt-get install funciona**: Puede instalar paquetes correctamente
5. **Herramientas preinstaladas**: `nmap`, `curl`, `wget`, `git`, `python3`, etc. disponibles inmediatamente después de crear el contenedor

### Métricas de Éxito
- ✅ `apt-get update` ejecuta sin warnings de "not signed"
- ✅ `apt-get install nmap` instala correctamente
- ✅ `which nmap` retorna `/usr/bin/nmap` (o ruta válida)
- ✅ Los scripts de hacking pueden ejecutarse sin errores de "comando no encontrado"

---

## 🔬 ANÁLISIS TÉCNICO

### Problema Raíz Identificado
El error "unsupported filetype" sugiere que:
1. El formato del archivo de claves GPG no es compatible con la versión de apt en el contenedor
2. `apt-key` (deprecated) puede estar creando archivos en formato antiguo
3. Las versiones modernas de apt requieren claves en formato específico (`.gpg` vs `.asc`)

### Posibles Soluciones a Investigar

#### Opción 1: Usar método moderno de importación de claves
- Descargar la clave en formato ASCII (`.asc`)
- Convertir a formato binario con `gpg --dearmor`
- Guardar en `/etc/apt/keyrings/` (directorio moderno)
- Actualizar `sources.list` para usar `signed-by=/etc/apt/keyrings/kali-archive-keyring.gpg`

#### Opción 2: Usar el paquete oficial de Kali
- Instalar `kali-archive-keyring` package directamente
- Este paquete incluye las claves en el formato correcto

#### Opción 3: Configurar sources.list correctamente
- Asegurar que `sources.list` apunta al repositorio correcto
- Usar `signed-by` para especificar explícitamente el keyring

#### Opción 4: Usar imagen de Kali con herramientas preinstaladas
- Cambiar a una imagen de Kali que incluya herramientas por defecto
- O crear una imagen personalizada con herramientas preinstaladas

---

## 📝 INSTRUCCIONES PARA EL AGENTE DE IA

### Tareas Prioritarias
1. **Diagnosticar el problema exacto**: Revisar los logs del backend para ver el output completo de la importación de claves GPG
2. **Implementar solución robusta**: Usar el método más moderno y compatible para importar claves GPG
3. **Verificar instalación de herramientas**: Asegurar que las herramientas se instalan correctamente en background
4. **Probar la solución**: Verificar que `apt-get update` y `apt-get install` funcionan sin errores

### Restricciones y Consideraciones
- **NO eliminar funcionalidad existente**: Mantener el sistema de archivos, scripts de misión, etc.
- **Mantener compatibilidad**: El código debe funcionar en Windows (donde se ejecuta Docker)
- **Logging detallado**: Mantener los logs de debug para diagnosticar problemas futuros
- **Timeout apropiados**: Los comandos de instalación pueden tardar varios minutos

### Archivos a Modificar
- **PRINCIPAL**: `go_backend/handlers/terminal.go`
  - Función `initKaliContainerForSession()` (líneas 674-838)
  - Función `setupDefaultFilesystem()` (líneas 183-250)
  - Función `executeTerminalCommand()` (líneas 1990-2010)

### Comandos de Prueba
Después de implementar la solución, probar en un contenedor nuevo:
```bash
# En el contenedor Docker
apt-get update
apt-get install -y nmap
which nmap
nmap --version
```

### Logs a Revisar
- Output de `gpgKeyCmd.CombinedOutput()` (línea 765)
- Output de `updateExec.CombinedOutput()` (línea 800)
- Output de `installExec.CombinedOutput()` (línea 812)
- Output de `verifyCmd.Output()` (línea 822)

---

## 🔗 REFERENCIAS Y CONTEXTO ADICIONAL

### Estructura del Proyecto
```
strategy/
├── go_backend/
│   ├── handlers/
│   │   ├── terminal.go      # ← ARCHIVO PRINCIPAL A MODIFICAR
│   │   ├── rpc.go           # Handlers RPC
│   │   └── victim_os.go     # Gestión de servidores víctima
│   └── main.go              # Punto de entrada
├── godot_frontend/          # Frontend del juego
└── shared_protocols/        # Protocolos compartidos
```

### Misiones del Juego
- **Misión 0**: Explotar Log4Shell en servidor NSA
- Requiere herramientas: `nmap`, `curl`, `whatweb`, `netcat`, `python3`
- Scripts automatizados en `/home/player/scripts/`

### Sistema de Archivos
- Contenedores pueden ser **persistentes** (con volumen Docker) o **temporales** (sin persistencia)
- Sistema de archivos se configura según el escenario de la misión
- Directorio home del jugador: `/home/<nombre_jugador>`

---

## ✅ CHECKLIST DE VERIFICACIÓN

Antes de considerar el problema resuelto, verificar:

- [ ] `apt-get update` ejecuta sin warnings de "not signed"
- [ ] `apt-get update` ejecuta sin errores de "Missing key"
- [ ] `apt-get update` ejecuta sin errores de "unsupported filetype"
- [ ] `apt-get install -y nmap` instala correctamente
- [ ] `which nmap` retorna una ruta válida
- [ ] `nmap --version` muestra la versión instalada
- [ ] Las herramientas se instalan automáticamente en background durante la inicialización
- [ ] Los logs del backend muestran "✅ Claves GPG importadas" sin errores
- [ ] Los logs del backend muestran "✅ Listas de paquetes actualizadas" sin errores
- [ ] Los logs del backend muestran "✅ Herramientas básicas instaladas correctamente"

---

## 🚀 PRÓXIMOS PASOS SUGERIDOS

1. **Revisar logs actuales**: Analizar el output completo de la importación de claves GPG
2. **Investigar formato correcto**: Determinar el formato exacto que requiere apt moderno
3. **Implementar solución moderna**: Usar `gpg --dearmor` y `/etc/apt/keyrings/` en lugar de `apt-key`
4. **Actualizar sources.list**: Asegurar que usa `signed-by` correctamente
5. **Probar exhaustivamente**: Crear contenedores nuevos y verificar que todo funciona
6. **Documentar solución**: Actualizar este prompt con la solución final implementada

---

**Última actualización**: Basado en el estado del código al momento de crear este prompt. El problema persiste: las claves GPG no se importan correctamente, causando que el repositorio no esté firmado y las herramientas no se puedan instalar.
