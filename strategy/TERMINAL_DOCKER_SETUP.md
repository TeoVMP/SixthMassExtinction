# Configuración de Terminal Docker/Kali Linux

## 📋 Resumen

La Misión 0 ahora se conecta a un contenedor Docker de Kali Linux que simula un sistema de archivos real del servidor NSA. Esto proporciona una experiencia de hacking más auténtica con herramientas reales de Linux.

## 🐳 Requisitos

- Docker Desktop instalado y ejecutándose
- Conexión a internet (para descargar la imagen de Kali Linux la primera vez)

## 🚀 Configuración Automática

El sistema intentará configurar automáticamente el contenedor cuando inicies la Misión 0:

1. **Verifica Docker**: Comprueba si Docker está disponible
2. **Crea contenedor**: Si no existe, crea un contenedor llamado `sme-kali-terminal`
3. **Configura sistema de archivos**: Crea la estructura de directorios y archivos del servidor NSA
4. **Inicia contenedor**: Pone en marcha el contenedor si está detenido

## 📁 Estructura del Sistema de Archivos

El contenedor simula un servidor NSA con la siguiente estructura:

```
/root/nsa-server/
├── logs/
│   └── server_logs.txt          # Logs del servidor
├── classified/
│   └── classified_data.enc      # Datos clasificados
├── protocols/
│   └── protocol_cronos.enc     # Protocolo Cronos (objetivo)
└── backups/
```

## 🛠️ Comandos Disponibles

Todos los comandos estándar de Linux funcionan:

- `ls`, `list`, `dir` - Listar archivos
- `cat <archivo>` - Leer archivo
- `find <patrón>` - Buscar archivos
- `pwd` - Directorio actual
- `whoami` - Usuario actual
- `cd <directorio>` - Cambiar directorio
- `grep`, `awk`, `sed` - Herramientas de procesamiento de texto
- Y cualquier otro comando de Linux

## ⚙️ Modo Simulado

Si Docker no está disponible, el sistema automáticamente usa un modo simulado que:
- Funciona sin Docker
- Simula comandos básicos
- Mantiene la funcionalidad de la misión

## 🔧 Solución de Problemas

### Docker no se inicia

1. Verifica que Docker Desktop esté ejecutándose
2. Asegúrate de que Docker tenga permisos suficientes
3. Reinicia Docker Desktop si es necesario

### Contenedor no se crea

El sistema intentará crear el contenedor automáticamente. Si falla:
1. Verifica que tengas conexión a internet (para descargar la imagen)
2. Asegúrate de tener espacio en disco suficiente
3. Revisa los logs del backend de Go

### Comandos no funcionan

1. Verifica que el contenedor esté ejecutándose: `docker ps`
2. Verifica los logs: `docker logs sme-kali-terminal`
3. Reinicia el contenedor si es necesario

## 📝 Comandos Docker Útiles

```bash
# Ver contenedores
docker ps -a

# Ver logs del contenedor
docker logs sme-kali-terminal

# Reiniciar contenedor
docker restart sme-kali-terminal

# Eliminar contenedor (si necesitas empezar de nuevo)
docker rm -f sme-kali-terminal

# Entrar al contenedor manualmente
docker exec -it sme-kali-terminal /bin/bash
```

## 🎯 Flujo de la Misión

1. **Conectar**: `connect` - Establece conexión con el servidor
2. **Escanear**: `scan` - Busca vulnerabilidades
3. **Explorar**: `ls /root/nsa-server` - Lista archivos
4. **Leer logs**: `cat /root/nsa-server/logs/server_logs.txt`
5. **Buscar protocolo**: `find cronos` o `find protocol`
6. **Leer protocolo**: `cat /root/nsa-server/protocols/protocol_cronos.enc`
7. **Misión completada**: Al encontrar el Protocolo Cronos

## 🔒 Seguridad

- El contenedor está aislado del sistema host
- No tiene acceso a archivos del sistema
- Se ejecuta con permisos limitados
- Se puede eliminar sin afectar el sistema

## 📊 Estado del Terminal

El terminal muestra el estado de conexión:
- **✓ Conectado a Kali Linux (Docker)**: Docker está funcionando
- **⚠ Modo simulado**: Docker no disponible, usando simulación

## 🐛 Debugging

Si encuentras problemas:

1. Revisa los logs del backend de Go
2. Verifica el estado del contenedor: `docker ps`
3. Revisa los logs del contenedor: `docker logs sme-kali-terminal`
4. Intenta reiniciar el contenedor

## 📚 Recursos

- [Docker Documentation](https://docs.docker.com/)
- [Kali Linux Documentation](https://www.kali.org/docs/)
- [Docker API Go Client](https://pkg.go.dev/github.com/docker/docker/client)











