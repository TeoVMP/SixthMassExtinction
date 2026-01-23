package handlers

import (
	"context"
	"fmt"
	"os/exec"
	"runtime"
	"sync"
	"time"
)

var (
	dockerCmdCache   string
	dockerCmdOnce    sync.Once
	dockerCmdChecked bool
	nerdctlAddress   string // Socket address para nerdctl si es necesario
)

func detectDockerCommand() string {
	dockerCmdOnce.Do(func() {
		if checkCommandAvailable("nerdctl", "version") {
			dockerCmdCache = "nerdctl"
			dockerCmdChecked = true
			fmt.Println("✅ Usando Nerdctl CLI (Rancher Desktop)")
			return
		}
		
		if checkCommandAvailable("nerdctl", "--address", "/var/run/docker/containerd/containerd.sock", "version") {
			dockerCmdCache = "nerdctl"
			nerdctlAddress = "/var/run/docker/containerd/containerd.sock"
			dockerCmdChecked = true
			fmt.Println("✅ Usando Nerdctl CLI con socket Docker (Rancher Desktop)")
			return
		}
		
		if checkCommandAvailable("docker", "version") {
			dockerCmdCache = "docker"
			dockerCmdChecked = true
			fmt.Println("✅ Usando Docker CLI")
			return
		}
		
		dockerCmdCache = ""
		dockerCmdChecked = true
		fmt.Println("❌ Ni Docker ni Nerdctl CLI encontrados. Ejecutando en modo simulado.")
	})
	
	return dockerCmdCache
}

func checkCommandAvailable(cmd string, args ...string) bool {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	
	allArgs := append([]string{cmd}, args...)
	checkCmd := exec.CommandContext(ctx, allArgs[0], allArgs[1:]...)
	err := checkCmd.Run()
	return err == nil
}

func getDockerCommand() string {
	if !dockerCmdChecked {
		return detectDockerCommand()
	}
	return dockerCmdCache
}

func isDockerAvailable() bool {
	cmd := getDockerCommand()
	if cmd == "" {
		return false
	}
	
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	
	var checkCmd *exec.Cmd
	if cmd == "nerdctl" && nerdctlAddress != "" {
		checkCmd = exec.CommandContext(ctx, cmd, "--address", nerdctlAddress, "version")
	} else {
		checkCmd = exec.CommandContext(ctx, cmd, "version")
	}
	
	err := checkCmd.Run()
	return err == nil
}

func dockerCommand(args ...string) *exec.Cmd {
	cmd := getDockerCommand()
	if cmd == "" {
		if runtime.GOOS == "windows" {
			return exec.Command("powershell.exe", "-Command", fmt.Sprintf("Write-Error \"Error: docker/nerdctl no disponible. Args: %v\"", args))
		}
		return exec.Command("sh", "-c", fmt.Sprintf("echo \"Error: docker/nerdctl no disponible. Args: %v\" && exit 1", args))
	}
	
	if cmd == "nerdctl" && nerdctlAddress != "" {
		allArgs := append([]string{"--address", nerdctlAddress}, args...)
		return exec.Command(cmd, allArgs...)
	}
	
	return exec.Command(cmd, args...)
}

func dockerCommandContext(ctx context.Context, args ...string) *exec.Cmd {
	cmd := getDockerCommand()
	if cmd == "" {
		if runtime.GOOS == "windows" {
			return exec.CommandContext(ctx, "powershell.exe", "-Command", fmt.Sprintf("Write-Error \"Error: docker/nerdctl no disponible. Args: %v\"", args))
		}
		return exec.CommandContext(ctx, "sh", "-c", fmt.Sprintf("echo \"Error: docker/nerdctl no disponible. Args: %v\" && exit 1", args))
	}
	
	if cmd == "nerdctl" && nerdctlAddress != "" {
		allArgs := append([]string{"--address", nerdctlAddress}, args...)
		return exec.CommandContext(ctx, cmd, allArgs...)
	}
	
	return exec.CommandContext(ctx, cmd, args...)
}
