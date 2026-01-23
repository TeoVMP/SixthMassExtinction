@echo off
REM Script para construir la imagen Docker personalizada de Kali Linux (Windows)
REM Sixth Mass Extinction - Build Custom Kali Image

echo 🔧 Construyendo imagen Docker personalizada de Kali Linux...
echo.

REM Cambiar al directorio del script
cd /d "%~dp0"

REM Construir la imagen
docker build -f Dockerfile.kali-6me -t kali-6me:latest .

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Imagen construida exitosamente: kali-6me:latest
    echo.
    echo Para verificar la imagen:
    echo   docker images kali-6me
    echo.
    echo Para probar la imagen:
    echo   docker run -it --rm kali-6me:latest bash
    echo.
    echo Herramientas preinstaladas:
    echo   - curl, wget, git
    echo   - python3, python3-pip
    echo   - nmap, netcat, whatweb
    echo   - iproute2, iputils-ping, tree
    echo.
) else (
    echo.
    echo ❌ Error construyendo la imagen
    exit /b 1
)
