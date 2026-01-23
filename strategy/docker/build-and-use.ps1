# Script PowerShell para construir la imagen Docker personalizada
# Sixth Mass Extinction - Build and Use Custom Kali Image

Write-Host "🔧 Construyendo imagen Docker personalizada de Kali Linux..." -ForegroundColor Cyan
Write-Host ""

# Cambiar al directorio del script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Construir la imagen
Write-Host "📦 Construyendo imagen (esto puede tardar 10-20 minutos)..." -ForegroundColor Yellow
docker build -f Dockerfile.kali-6me -t kali-6me:latest .

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Imagen construida exitosamente: kali-6me:latest" -ForegroundColor Green
    Write-Host ""
    
    # Verificar la imagen
    Write-Host "🔍 Verificando imagen..." -ForegroundColor Cyan
    docker images kali-6me
    
    Write-Host ""
    Write-Host "✅ La imagen está lista para usar." -ForegroundColor Green
    Write-Host ""
    Write-Host "El backend Go detectará automáticamente esta imagen en el próximo reinicio." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para probar la imagen manualmente:" -ForegroundColor Cyan
    Write-Host "  docker run -it --rm kali-6me:latest bash" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error construyendo la imagen" -ForegroundColor Red
    Write-Host "Verifica que Docker esté corriendo y que tengas conexión a internet." -ForegroundColor Yellow
    exit 1
}
