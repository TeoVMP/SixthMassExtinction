package handlers

import (
	"context"
	"fmt"
	"strings"
	"time"
)

type MissionNetworkConfig struct {
	NetworkName string
	Subnet      string
	Gateway     string
}

func createMissionNetwork(missionID string) (*MissionNetworkConfig, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	networkName := "sme-mission-network"
	subnet := "10.10.0.0/24"
	gateway := "10.10.0.1"

	// Verificar si la red ya existe
	checkCmd := dockerCommandContext(ctx, "network", "inspect", networkName)
	output, err := checkCmd.CombinedOutput()
	if err == nil {
		// La red existe, verificar que tenga el subnet correcto
		outputStr := string(output)
		if strings.Contains(outputStr, subnet) {
			fmt.Printf("✅ [createMissionNetwork] Red %s ya existe con subnet correcto\n", networkName)
			return &MissionNetworkConfig{
				NetworkName: networkName,
				Subnet:      subnet,
				Gateway:     gateway,
			}, nil
		}
		// Si existe pero con subnet diferente, eliminarla
		fmt.Printf("⚠️ [createMissionNetwork] Red existe con subnet diferente, eliminando...\n")
		removeCmd := dockerCommandContext(ctx, "network", "rm", networkName)
		removeCmd.Run() // Ignorar errores
	}

	// Crear la red
	createCmd := dockerCommandContext(ctx, "network", "create",
		"--driver", "bridge",
		"--subnet", subnet,
		"--gateway", gateway,
		networkName)

	output, err = createCmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("error creando red: %v, output: %s", err, string(output))
	}

	fmt.Printf("✅ [createMissionNetwork] Red %s creada exitosamente\n", networkName)

	return &MissionNetworkConfig{
		NetworkName: networkName,
		Subnet:      subnet,
		Gateway:     gateway,
	}, nil
}

func getMissionNetworkConfig(missionID string) (*MissionNetworkConfig, error) {
	return createMissionNetwork(missionID)
}
