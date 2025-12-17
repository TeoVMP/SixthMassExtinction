// server/game/state.go
package game

import (
	"time"
)

type Player struct {
	Sanity     int                    `json:"sanity"`
	Needs      map[string]int         `json:"needs"`
	Reputation map[string]int         `json:"reputation"`
	Traumas    []string               `json:"traumas"`
	Skills     map[string]int         `json:"skills"`
	Inventory  []string               `json:"inventory"`
	Currency   int                    `json:"currency"`
}

type World struct {
	ViolenceLevel   int            `json:"violence_level"`
	CartographPower int            `json:"cartograph_power"`
	RegionHealth    map[string]int `json:"region_health"`
	CurrentYear     int            `json:"current_year"`
	CurrentMonth    int            `json:"current_month"`
	CurrentDay      int            `json:"current_day"`
}

type Missions struct {
	Active    string   `json:"active"`
	Completed []string `json:"completed"`
	Failed    []string `json:"failed"`
	Available []string `json:"available"`
}

type NPC struct {
	Trust    int    `json:"trust"`
	Location string `json:"location,omitempty"`
	Status   string `json:"status,omitempty"`
}

type GameState struct {
	Player   Player            `json:"player"`
	World    World             `json:"world"`
	Missions Missions          `json:"missions"`
	NPCs     map[string]NPC    `json:"npcs"`
}

type SaveData struct {
	GameState GameState `json:"game_state"`
	Timestamp int64     `json:"timestamp"`
	Version   string    `json:"version"`
}

func InitializeGameState() GameState {
	return GameState{
		Player: Player{
			Sanity: 85,
			Needs: map[string]int{
				"hunger": 50,
				"thirst": 50,
				"sleep":  70,
				"stress": 30,
			},
			Reputation: map[string]int{
				"pe": 50,  // Pueblos Explotados
				"eo": 0,   // Europa Occidental
				"eu": -20, // Estados Unidos
				"ch": 10,  // China
				"ru": -10, // Rusia
				"as": 30,  // Asia Sur
				"au": 40,  // África Unida
				"la": 45,  // Latinoamérica
			},
			Traumas: []string{},
			Skills: map[string]int{
				"hacking":  60,
				"diplomacy": 50,
				"stealth":   40,
				"survival":  55,
			},
			Inventory: []string{},
			Currency:  1000,
		},
		World: World{
			ViolenceLevel:   45,
			CartographPower: 65,
			RegionHealth: map[string]int{
				"arctic":       40,
				"amazon":       35,
				"africa":       50,
				"asia":         45,
				"europe":       60,
				"north_america": 55,
				"oceania":      30,
				"middle_east":  25,
			},
			CurrentYear:  2028,
			CurrentMonth: 9,
			CurrentDay:   14,
		},
		Missions: Missions{
			Active:    "",
			Completed: []string{},
			Failed:    []string{},
			Available: []string{"m1_islandia"},
		},
		NPCs: map[string]NPC{
			"elara_vance": {
				Trust:    80,
				Location: "islandia",
			},
			"kwame_nkrumah": {
				Trust:    75,
				Location: "islandia",
			},
			"maya": {
				Trust:  90,
				Status: "missing",
			},
		},
	}
}

// GetCurrentGameState retorna el estado actual del juego
func (gs *GameState) GetCurrent() GameState {
	return *gs
}

// UpdatePlayer actualiza el estado del jugador
func (gs *GameState) UpdatePlayer(player Player) {
	gs.Player = player
}

// UpdateWorld actualiza el estado del mundo
func (gs *GameState) UpdateWorld(world World) {
	gs.World = world
}

// UpdateMissions actualiza las misiones
func (gs *GameState) UpdateMissions(missions Missions) {
	gs.Missions = missions
}

// GetSaveData crea datos de guardado
func (gs *GameState) GetSaveData() SaveData {
	return SaveData{
		GameState: *gs,
		Timestamp: time.Now().Unix(),
		Version:   "1.0.0",
	}
}

// LoadFromSaveData carga desde datos guardados
func (gs *GameState) LoadFromSaveData(save SaveData) {
	*gs = save.GameState
}
