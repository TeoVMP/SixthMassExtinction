# Instrucciones para Construir la Imagen Docker Personalizada

## ⚠️ Problema Conocido

Durante la construcción de la imagen, `apt-get update` puede fallar debido a problemas de sincronización de tiempo con los repositorios de Kali Linux. Esto es un problema conocido de Kali Linux cuando se construye en contenedores Docker.

## Solución Temporal

Si la imagen se construye pero las herramientas no están instaladas, puedes:

### Opción 1: Construir con acceso a red del host (recomendado)

```powershell
cd docker
docker build --network=host -f Dockerfile.kali-6me -t kali-6me:latest .
```

Esto permite que el contenedor use el reloj del host directamente.

### Opción 2: Instalar herramientas después del build

Si la imagen se construye pero sin herramientas, puedes crear un contenedor temporal e instalar las herramientas manualmente:

```powershell
# Crear contenedor temporal
docker run -d --name kali-temp kali-6me:latest tail -f /dev/null

# Entrar al contenedor
docker exec -it kali-temp bash

# Dentro del contenedor, instalar herramientas
apt-get update
apt-get install -y curl wget git python3 python3-pip nmap netcat-traditional netcat-openbsd iproute2 iputils-ping whatweb

# Salir del contenedor
exit

# Hacer commit de los cambios a la imagen
docker commit kali-temp kali-6me:latest

# Limpiar contenedor temporal
docker rm -f kali-temp
```

### Opción 3: Usar imagen base diferente

Puedes modificar el Dockerfile para usar una imagen base que ya tenga herramientas:

```dockerfile
FROM kalilinux/kali-last-snapshot
```

O usar una imagen de Kali con herramientas preinstaladas si está disponible.

## Verificar la Imagen

Después de construir, verifica que las herramientas estén instaladas:

```powershell
docker run --rm kali-6me:latest which curl wget git python3 nmap
```

Si todas las herramientas están disponibles, la imagen está lista para usar.

## Uso

Una vez que la imagen esté construida correctamente, el backend Go la detectará automáticamente y la usará en lugar de `kalilinux/kali-rolling`.
