// handlers/java_installer.go
// Gestión de instalador de Java incluido en el juego
package handlers

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// installJavaFromLocalInstaller instala Java desde un instalador local incluido en el juego
// Busca el instalador en varios directorios posibles
func installJavaFromLocalInstaller(containerID string, ctx context.Context) error {
	// Directorios donde buscar el instalador de Java
	// 1. Directorio de recursos del backend
	// 2. Directorio de assets del frontend
	// 3. Directorio raíz del proyecto
	possiblePaths := []string{
		"./go_backend/resources/java/",
		"./resources/java/",
		"./java/",
		"../resources/java/",
		"../java/",
		"./godot_frontend/assets/java/",
	}

	// Nombres posibles del instalador
	installerNames := []string{
		"openjdk-11-jdk.deb",           // Debian package (recomendado)
		"openjdk-11.tar.gz",            // Tarball
		"jdk-11_linux-x64_bin.tar.gz",  // Oracle JDK (si tienes licencia)
		"openjdk-17-jdk.deb",           // OpenJDK 17 (alternativa)
		"openjdk-17.tar.gz",
	}

	var installerPath string
	var installerName string

	// Buscar el instalador
	for _, basePath := range possiblePaths {
		for _, name := range installerNames {
			fullPath := filepath.Join(basePath, name)
			if _, err := os.Stat(fullPath); err == nil {
				installerPath = fullPath
				installerName = name
				fmt.Printf("✅ [installJavaFromLocalInstaller] Instalador encontrado: %s\n", fullPath)
				break
			}
		}
		if installerPath != "" {
			break
		}
	}

	if installerPath == "" {
		return fmt.Errorf("instalador de Java no encontrado en los directorios de recursos")
	}

	// Copiar el instalador al contenedor
	fmt.Printf("🔧 [installJavaFromLocalInstaller] Copiando instalador al contenedor...\n")
	copyCmd := exec.CommandContext(ctx, "docker", "cp", installerPath, fmt.Sprintf("%s:/tmp/%s", containerID, installerName))
	if err := copyCmd.Run(); err != nil {
		return fmt.Errorf("error copiando instalador al contenedor: %v", err)
	}

	// Instalar según el tipo de archivo
	if strings.HasSuffix(installerName, ".deb") {
		// Instalar paquete .deb
		fmt.Printf("🔧 [installJavaFromLocalInstaller] Instalando paquete .deb...\n")
		installCmd := exec.CommandContext(ctx, "docker", "exec", containerID,
			"sh", "-c", fmt.Sprintf("dpkg -i /tmp/%s || apt-get install -f -y", installerName))
		if err := installCmd.Run(); err != nil {
			return fmt.Errorf("error instalando paquete .deb: %v", err)
		}
	} else if strings.HasSuffix(installerName, ".tar.gz") {
		// Extraer y configurar tarball
		fmt.Printf("🔧 [installJavaFromLocalInstaller] Extrayendo tarball...\n")
		extractCmd := exec.CommandContext(ctx, "docker", "exec", containerID,
			"sh", "-c", fmt.Sprintf("cd /opt && tar -xzf /tmp/%s && mv jdk-* java", installerName))
		if err := extractCmd.Run(); err != nil {
			return fmt.Errorf("error extrayendo tarball: %v", err)
		}

		// Configurar variables de entorno
		setupCmd := exec.CommandContext(ctx, "docker", "exec", containerID,
			"sh", "-c", `echo 'export JAVA_HOME=/opt/java' >> /etc/profile && echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile`)
		setupCmd.Run()
	}

	// Verificar instalación
	verifyCmd := exec.CommandContext(ctx, "docker", "exec", containerID,
		"sh", "-c", "java -version 2>&1 | head -1")
	verifyOutput, _ := verifyCmd.Output()
	if len(verifyOutput) > 0 && !strings.Contains(string(verifyOutput), "not found") {
		fmt.Printf("✅ [installJavaFromLocalInstaller] Java instalado: %s\n", strings.TrimSpace(string(verifyOutput)))
		return nil
	}

	return fmt.Errorf("Java no se instaló correctamente")
}
