package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gorilla/mux"
)

type VPNConfig struct {
	MissionID        string
	ServerIP         string
	ClientIP         string
	ServerPort       int
	ServerPublicKey  string
	ServerPrivateKey string
	ClientPublicKey  string
	ClientPrivateKey string
	PresharedKey     string
	ContainerID      string
}

func StartVPN(missionID string) error {
	// Obtener configuración de red
	networkConfig, err := getMissionNetworkConfig(missionID)
	if err != nil {
		return fmt.Errorf("error obteniendo configuración de red: %v", err)
	}

	// Generar configuración VPN
	config := &VPNConfig{
		MissionID:  missionID,
		ServerIP:   "10.10.0.2", // IP del servidor WireGuard en la red Docker
		ClientIP:   "10.10.0.10", // IP del cliente VPN
		ServerPort: 51820,
	}

	// Generar claves WireGuard
	if err := generateWireGuardKeys(config); err != nil {
		return fmt.Errorf("error generando claves WireGuard: %v", err)
	}

	// Crear contenedor WireGuard
	if err := createWireGuardContainer(config, networkConfig); err != nil {
		return fmt.Errorf("error creando contenedor WireGuard: %v", err)
	}

	// Generar configuración del cliente
	if err := generateClientConfig(config, networkConfig); err != nil {
		return fmt.Errorf("error generando configuración del cliente: %v", err)
	}

	fmt.Printf("✅ [StartVPN] VPN WireGuard iniciada para misión %s\n", missionID)
	return nil
}

func generateWireGuardKeys(config *VPNConfig) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Usar un contenedor temporal para generar claves reales de WireGuard
	tempContainer := "sme-wg-keygen-temp"
	
	// Limpiar contenedor temporal si existe
	dockerCommandContext(ctx, "rm", "-f", tempContainer).Run()

	// Crear contenedor temporal con alpine/wireguard
	createCmd := dockerCommandContext(ctx, "run", "--name", tempContainer, "alpine/wireguard:latest", "sh", "-c", 
		"wg genkey | tee /tmp/privatekey && wg pubkey < /tmp/privatekey | tee /tmp/publickey && cat /tmp/privatekey")
	
	serverPrivateKeyOutput, err := createCmd.Output()
	if err != nil {
		return fmt.Errorf("error generando clave privada del servidor: %v", err)
	}
	config.ServerPrivateKey = strings.TrimSpace(string(serverPrivateKeyOutput))

	// Obtener clave pública del servidor
	pubkeyCmd := dockerCommandContext(ctx, "exec", tempContainer, "sh", "-c", "wg pubkey < /tmp/privatekey")
	serverPublicKeyOutput, err := pubkeyCmd.Output()
	if err != nil {
		return fmt.Errorf("error generando clave pública del servidor: %v", err)
	}
	config.ServerPublicKey = strings.TrimSpace(string(serverPublicKeyOutput))

	// Generar clave privada del cliente
	clientPrivateCmd := dockerCommandContext(ctx, "exec", tempContainer, "sh", "-c", "wg genkey")
	clientPrivateKeyOutput, err := clientPrivateCmd.Output()
	if err != nil {
		return fmt.Errorf("error generando clave privada del cliente: %v", err)
	}
	config.ClientPrivateKey = strings.TrimSpace(string(clientPrivateKeyOutput))

	// Obtener clave pública del cliente
	clientPubkeyCmd := dockerCommandContext(ctx, "exec", tempContainer, "sh", "-c", fmt.Sprintf("echo '%s' | wg pubkey", config.ClientPrivateKey))
	clientPublicKeyOutput, err := clientPubkeyCmd.Output()
	if err != nil {
		return fmt.Errorf("error generando clave pública del cliente: %v", err)
	}
	config.ClientPublicKey = strings.TrimSpace(string(clientPublicKeyOutput))

	// Generar preshared key
	presharedCmd := dockerCommandContext(ctx, "exec", tempContainer, "sh", "-c", "wg genpsk")
	presharedKeyOutput, err := presharedCmd.Output()
	if err != nil {
		return fmt.Errorf("error generando preshared key: %v", err)
	}
	config.PresharedKey = strings.TrimSpace(string(presharedKeyOutput))

	// Limpiar contenedor temporal
	dockerCommandContext(ctx, "rm", "-f", tempContainer).Run()

	return nil
}

func createWireGuardContainer(config *VPNConfig, networkConfig *MissionNetworkConfig) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	containerName := fmt.Sprintf("sme-wireguard-%s", config.MissionID)

	// Verificar si el contenedor ya existe
	checkCmd := dockerCommandContext(ctx, "ps", "-a", "--filter", fmt.Sprintf("name=%s", containerName), "--format", "{{.ID}}")
	output, err := checkCmd.Output()
	if err == nil && len(strings.TrimSpace(string(output))) > 0 {
		// El contenedor existe, intentar iniciarlo
		startCmd := dockerCommandContext(ctx, "start", containerName)
		if _, startErr := startCmd.CombinedOutput(); startErr == nil {
			// Obtener ID del contenedor
			idCmd := dockerCommandContext(ctx, "ps", "-a", "--filter", fmt.Sprintf("name=%s", containerName), "--format", "{{.ID}}")
			if idOutput, idErr := idCmd.Output(); idErr == nil {
				config.ContainerID = strings.TrimSpace(string(idOutput))
				fmt.Printf("✅ [createWireGuardContainer] Contenedor WireGuard existente iniciado: %s\n", config.ContainerID)
				// Configurar reenvío de tráfico
				return configureTrafficForwarding(config, networkConfig)
			}
		}
		// Si no se pudo iniciar, eliminar y recrear
		fmt.Printf("⚠️ [createWireGuardContainer] No se pudo iniciar contenedor existente, eliminando...\n")
		dockerCommandContext(ctx, "rm", "-f", containerName).Run()
	}

	// Obtener IP del host para el endpoint
	hostIP, err := getHostIP()
	if err != nil {
		return fmt.Errorf("error obteniendo IP del host: %v", err)
	}

	// Crear contenedor con WireGuard
	dockerArgs := []string{
		"run", "-d",
		"--name", containerName,
		"--cap-add", "NET_ADMIN",
		"--cap-add", "SYS_MODULE",
		"--sysctl", "net.ipv4.ip_forward=1",
		"--network", networkConfig.NetworkName,
		"--ip", config.ServerIP,
		"-p", fmt.Sprintf("%d:%d/udp", config.ServerPort, config.ServerPort),
		"-e", "PUID=1000",
		"-e", "PGID=1000",
		"-e", "TZ=Etc/UTC",
		"-e", fmt.Sprintf("SERVERURL=%s", hostIP),
		"-e", fmt.Sprintf("SERVERPORT=%d", config.ServerPort),
		"-e", "PEERS=1",
		"-e", "PEERDNS=8.8.8.8",
		"-e", fmt.Sprintf("INTERNAL_SUBNET=%s", networkConfig.Subnet),
		"linuxserver/wireguard:latest",
	}

	createCmd := dockerCommandContext(ctx, dockerArgs...)
	output, err = createCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("error creando contenedor: %v, output: %s", err, string(output))
	}

	containerID := strings.TrimSpace(string(output))
	config.ContainerID = containerID

	fmt.Printf("✅ [createWireGuardContainer] Contenedor WireGuard creado: %s\n", containerID)

	// Esperar a que WireGuard se configure
	fmt.Printf("⏳ [createWireGuardContainer] Esperando a que WireGuard se configure automáticamente...\n")
	time.Sleep(15 * time.Second)

	// Leer las claves generadas por linuxserver/wireguard
	if err := readWireGuardKeysFromContainer(config); err != nil {
		fmt.Printf("⚠️ [createWireGuardContainer] No se pudieron leer las claves del contenedor: %v\n", err)
	}

	// Configurar el peer con la IP correcta del cliente
	if err := configureWireGuardPeer(config); err != nil {
		fmt.Printf("⚠️ [createWireGuardContainer] No se pudo configurar el peer automáticamente: %v\n", err)
	}

	// Configurar reenvío de tráfico
	return configureTrafficForwarding(config, networkConfig)
}

func readWireGuardKeysFromContainer(config *VPNConfig) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Leer clave privada del cliente desde el contenedor
	readPrivateCmd := dockerCommandContext(ctx, "exec", config.ContainerID, "cat", "/config/peer1/privatekey-peer1")
	privateKeyOutput, err := readPrivateCmd.Output()
	if err == nil {
		config.ClientPrivateKey = strings.TrimSpace(string(privateKeyOutput))
	}

	// Leer preshared key desde el contenedor
	readPresharedCmd := dockerCommandContext(ctx, "exec", config.ContainerID, "cat", "/config/peer1/presharedkey-peer1")
	presharedKeyOutput, err := readPresharedCmd.Output()
	if err == nil {
		config.PresharedKey = strings.TrimSpace(string(presharedKeyOutput))
	}

	// Generar clave pública del cliente desde su clave privada
	if config.ClientPrivateKey != "" {
		pubkeyCmd := dockerCommandContext(ctx, "exec", config.ContainerID, "sh", "-c", fmt.Sprintf("echo '%s' | wg pubkey", config.ClientPrivateKey))
		pubkeyOutput, err := pubkeyCmd.Output()
		if err == nil {
			config.ClientPublicKey = strings.TrimSpace(string(pubkeyOutput))
		}
	}

	return nil
}

func configureWireGuardPeer(config *VPNConfig) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if config.ClientPublicKey == "" {
		return fmt.Errorf("clave pública del cliente no disponible")
	}

	// Eliminar peer existente si lo hay
	removePeerCmd := dockerCommandContext(ctx, "exec", config.ContainerID, "wg", "set", "wg0",
		fmt.Sprintf("peer=%s", config.ClientPublicKey), "remove")
	removePeerCmd.Run() // Ignorar errores si no existe

	// Agregar el peer con la IP correcta del cliente
	// Usar un archivo temporal para el preshared key
	updatePeerCmd := dockerCommandContext(ctx, "exec", config.ContainerID, "sh", "-c",
		fmt.Sprintf("echo '%s' > /tmp/preshared.tmp && wg set wg0 peer=%s allowed-ips=%s/32 preshared-key=/tmp/preshared.tmp && rm /tmp/preshared.tmp",
			config.PresharedKey, config.ClientPublicKey, config.ClientIP))
	
	if err := updatePeerCmd.Run(); err != nil {
		return fmt.Errorf("error configurando peer: %v", err)
	}

	fmt.Printf("✅ [configureWireGuardPeer] Peer configurado con IP correcta: %s/32\n", config.ClientIP)
	return nil
}

func configureTrafficForwarding(config *VPNConfig, networkConfig *MissionNetworkConfig) error {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	fmt.Printf("🔧 [configureTrafficForwarding] Configurando reenvío de tráfico...\n")

	// Habilitar IP forwarding
	dockerCommandContext(ctx, "exec", config.ContainerID, "sysctl", "-w", "net.ipv4.ip_forward=1").Run()
	dockerCommandContext(ctx, "exec", config.ContainerID, "sysctl", "-w", "net.ipv4.conf.all.forwarding=1").Run()
	dockerCommandContext(ctx, "exec", config.ContainerID, "sysctl", "-w", "net.ipv4.conf.all.rp_filter=0").Run()

	// Limpiar reglas FORWARD existentes
	dockerCommandContext(ctx, "exec", config.ContainerID, "iptables", "-F", "FORWARD").Run()

	// Reglas específicas para tráfico del cliente hacia la red Docker (prioritarias)
	dockerCommandContext(ctx, "exec", config.ContainerID, "iptables", "-A", "FORWARD",
		"-i", "wg0", "-o", "eth0",
		"-s", config.ClientIP+"/32", "-d", networkConfig.Subnet,
		"-j", "ACCEPT", "-m", "comment", "--comment", "Client to Docker network").Run()

	dockerCommandContext(ctx, "exec", config.ContainerID, "iptables", "-A", "FORWARD",
		"-i", "eth0", "-o", "wg0",
		"-s", networkConfig.Subnet, "-d", config.ClientIP+"/32",
		"-j", "ACCEPT", "-m", "comment", "--comment", "Docker network to client").Run()

	// Reglas generales de FORWARD (menos específicas)
	dockerCommandContext(ctx, "exec", config.ContainerID, "iptables", "-A", "FORWARD",
		"-i", "wg0", "-j", "ACCEPT").Run()
	dockerCommandContext(ctx, "exec", config.ContainerID, "iptables", "-A", "FORWARD",
		"-o", "wg0", "-j", "ACCEPT").Run()

	// Limpiar reglas POSTROUTING existentes
	dockerCommandContext(ctx, "exec", config.ContainerID, "iptables", "-t", "nat", "-F", "POSTROUTING").Run()

	// Regla NAT específica para el cliente (prioritaria)
	dockerCommandContext(ctx, "exec", config.ContainerID, "iptables", "-t", "nat", "-A", "POSTROUTING",
		"-s", config.ClientIP+"/32", "-o", "eth0",
		"-j", "MASQUERADE", "-m", "comment", "--comment", "Client to Docker network NAT").Run()

	// Regla NAT general para el contenedor
	dockerCommandContext(ctx, "exec", config.ContainerID, "iptables", "-t", "nat", "-A", "POSTROUTING",
		"-o", "eth+", "-j", "MASQUERADE").Run()

	fmt.Printf("✅ [configureTrafficForwarding] Reenvío de tráfico configurado\n")
	return nil
}

func generateClientConfig(config *VPNConfig, networkConfig *MissionNetworkConfig) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Obtener clave pública del servidor desde el contenedor
	readServerPubCmd := dockerCommandContext(ctx, "exec", config.ContainerID, "cat", "/config/wg0.conf")
	serverConfigOutput, err := readServerPubCmd.Output()
	if err != nil {
		return fmt.Errorf("error leyendo configuración del servidor: %v", err)
	}

	// Extraer clave pública del servidor
	serverConfig := string(serverConfigOutput)
	lines := strings.Split(serverConfig, "\n")
	for _, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "PrivateKey =") {
			parts := strings.Split(line, "=")
			if len(parts) > 1 {
				serverPrivateKey := strings.TrimSpace(parts[1])
				// Generar clave pública desde la privada
				pubkeyCmd := dockerCommandContext(ctx, "exec", config.ContainerID, "sh", "-c",
					fmt.Sprintf("echo '%s' | wg pubkey", serverPrivateKey))
				pubkeyOutput, err := pubkeyCmd.Output()
				if err == nil {
					config.ServerPublicKey = strings.TrimSpace(string(pubkeyOutput))
					break
				}
			}
		}
	}

	if config.ServerPublicKey == "" {
		return fmt.Errorf("no se pudo obtener la clave pública del servidor")
	}

	// Obtener IP del host para el endpoint
	hostIP, err := getHostIP()
	if err != nil {
		return fmt.Errorf("error obteniendo IP del host: %v", err)
	}

	// Construir configuración del cliente
	clientConfig := fmt.Sprintf(`[Interface]
PrivateKey = %s
Address = %s/24
DNS = 8.8.8.8

[Peer]
PublicKey = %s
PresharedKey = %s
Endpoint = %s:%d
AllowedIPs = %s
PersistentKeepalive = 25
`, config.ClientPrivateKey, config.ClientIP, config.ServerPublicKey, config.PresharedKey, hostIP, config.ServerPort, networkConfig.Subnet)

	// Guardar configuración del cliente
	configDir := "vpn_configs"
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return fmt.Errorf("error creando directorio de configuraciones: %v", err)
	}

	configPath := filepath.Join(configDir, fmt.Sprintf("%s.conf", config.MissionID))
	if err := ioutil.WriteFile(configPath, []byte(clientConfig), 0600); err != nil {
		return fmt.Errorf("error guardando configuración del cliente: %v", err)
	}

	fmt.Printf("✅ [generateClientConfig] Configuración del cliente guardada en: %s\n", configPath)
	return nil
}

func getHostIP() (string, error) {
	// Intentar obtener IP desde variable de entorno
	if hostIP := os.Getenv("HOST_IP"); hostIP != "" {
		return hostIP, nil
	}

	// Intentar obtener IP conectando a un servidor externo
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "", fmt.Errorf("error obteniendo IP local: %v", err)
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String(), nil
}

func GetVPNConfig(missionID string) (string, error) {
	configPath := filepath.Join("vpn_configs", fmt.Sprintf("%s.conf", missionID))
	
	// Verificar si el archivo existe
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		// Intentar iniciar la VPN si no está activa
		if err := StartVPN(missionID); err != nil {
			return "", fmt.Errorf("error iniciando VPN: %v", err)
		}
	}

	// Leer configuración
	configContent, err := ioutil.ReadFile(configPath)
	if err != nil {
		return "", fmt.Errorf("error leyendo configuración: %v", err)
	}

	// Validar que sea una configuración válida
	if !strings.HasPrefix(string(configContent), "[Interface]") {
		return "", fmt.Errorf("configuración inválida")
	}

	return string(configContent), nil
}

// Handlers HTTP

func StartVPNHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	missionID := vars["mission_id"]

	if err := StartVPN(missionID); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error":   "Error iniciando VPN",
			"details": err.Error(),
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":   true,
		"mission_id": missionID,
		"message":   "VPN iniciada exitosamente",
	})
}

func StopVPNHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	missionID := vars["mission_id"]

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	containerName := fmt.Sprintf("sme-wireguard-%s", missionID)
	stopCmd := dockerCommandContext(ctx, "stop", containerName)
	if err := stopCmd.Run(); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error":   "Error deteniendo VPN",
			"details": err.Error(),
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":   true,
		"mission_id": missionID,
		"message":   "VPN detenida exitosamente",
	})
}

func GetVPNConfigHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	missionID := vars["mission_id"]

	config, err := GetVPNConfig(missionID)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error":   "Error obteniendo configuración VPN",
			"details": err.Error(),
		})
		return
	}

	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte(config))
}
