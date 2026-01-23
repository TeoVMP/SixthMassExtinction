# Imagen Docker Personalizada - Kali Linux 6ME

Esta imagen Docker personalizada contiene Kali Linux con todas las herramientas preinstaladas y configuradas correctamente.

## Características

- ✅ **Herramientas preinstaladas**: curl, wget, git, python3, nmap, netcat, socat, procps, tree, whatweb, vim, nano, etc.
- ✅ **Java y Maven preinstalados**: Listos para compilar exploits
- ✅ **Marshalsec precompilado**: `/opt/marshalsec/marshalsec.jar` listo para explotación Log4Shell
- ✅ **Exploit Log4Shell precompilado**: Template en `/home/player/exploit_log4shell/` con script `compile-exploit <IP>`
- ✅ **Claves GPG configuradas**: Repositorios firmados correctamente
- ✅ **apt-get funcional**: Configurado para ignorar problemas de tiempo
- ✅ **Control de internet**: Script para activar/desactivar conexión
- ✅ **Listo para usar**: Sin necesidad de actualizar o instalar nada

## Construir la Imagen

### Windows (PowerShell)
```powershell
cd docker
.\build-kali-image.bat
```

### Linux/Mac
```bash
cd docker
chmod +x build-kali-image.sh
./build-kali-image.sh
```

### Manualmente
```bash
docker build -f docker/Dockerfile.kali-6me -t kali-6me:latest .
```

## Verificar la Imagen

```bash
docker images kali-6me
```

## Probar la Imagen

```bash
docker run -it --rm kali-6me:latest bash
```

Dentro del contenedor, verifica las herramientas:
```bash
which curl wget git python3 nmap
curl --version
nmap --version
```

## Control de Internet

Dentro del contenedor, puedes controlar la conexión a internet:

```bash
# Ver estado
internet

# Desactivar internet
internet disable

# Activar internet (requiere reiniciar contenedor)
internet enable
```

## Uso en el Proyecto

El código Go usará automáticamente esta imagen si existe. Si no existe, usará `kalilinux/kali-rolling` como fallback.

Para forzar el uso de la imagen personalizada, el código buscará `kali-6me:latest` primero.
