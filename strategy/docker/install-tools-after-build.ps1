# Script para instalar herramientas en la imagen después del build
# Esto es necesario porque apt-get update falla durante el build debido a problemas de tiempo

Write-Host "🔧 Instalando herramientas en imagen kali-6me..." -ForegroundColor Cyan
Write-Host ""

# Verificar que la imagen existe
$imageExists = docker images kali-6me --format "{{.Repository}}" 2>&1
if (-not $imageExists) {
    Write-Host "❌ La imagen kali-6me:latest no existe. Construye la imagen primero." -ForegroundColor Red
    exit 1
}

Write-Host "📦 Creando contenedor temporal..." -ForegroundColor Yellow
docker run -d --name kali-temp-tools kali-6me:latest tail -f /dev/null

Write-Host "⏳ Esperando 5 minutos para que el Release file sea válido..." -ForegroundColor Yellow
Write-Host "   (El Release file de Kali tiene una fecha de validez futura)" -ForegroundColor Gray
Start-Sleep -Seconds 300

Write-Host "🔄 Actualizando listas de paquetes..." -ForegroundColor Yellow
docker exec kali-temp-tools bash -c "apt-get update -o Acquire::Check-Valid-Until=false -o APT::Get::AllowUnauthenticated=true --allow-unauthenticated 2>&1 | tail -3"

Write-Host "📥 Instalando herramientas..." -ForegroundColor Yellow
docker exec kali-temp-tools bash -c "apt-get install -y -o Acquire::Check-Valid-Until=false -o APT::Get::AllowUnauthenticated=true --allow-unauthenticated curl wget git python3 python3-pip nmap netcat-traditional netcat-openbsd iproute2 iputils-ping whatweb 2>&1 | tail -5"

Write-Host "✅ Verificando herramientas instaladas..." -ForegroundColor Yellow
docker exec kali-temp-tools which curl wget git python3 nmap

Write-Host "💾 Haciendo commit de los cambios..." -ForegroundColor Yellow
docker commit kali-temp-tools kali-6me:latest

Write-Host "🧹 Limpiando contenedor temporal..." -ForegroundColor Yellow
docker rm -f kali-temp-tools

Write-Host ""
Write-Host "✅ Imagen kali-6me:latest actualizada con herramientas instaladas" -ForegroundColor Green
Write-Host ""
Write-Host "Verifica la imagen:" -ForegroundColor Cyan
Write-Host "  docker run --rm kali-6me:latest which curl wget git python3 nmap" -ForegroundColor White
