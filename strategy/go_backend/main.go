// server/main.go
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/mux"
)

// ============================================
// ESTRUCTURAS DE DATOS
// ============================================

type RPCMethod struct {
	JSONRPC string                 `json:"jsonrpc"`
	Method  string                 `json:"method"`
	Params  map[string]interface{} `json:"params"`
	ID      int                    `json:"id"`
}

type RPCResponse struct {
	JSONRPC string      `json:"jsonrpc"`
	Result  interface{} `json:"result,omitempty"`
	Error   *RPCError   `json:"error,omitempty"`
	ID      int         `json:"id"`
}

type RPCError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

type Player struct {
	Sanity     int            `json:"sanity"`
	Needs      map[string]int `json:"needs"`
	Reputation map[string]int `json:"reputation"`
	Traumas    []string       `json:"traumas"`
	Skills     map[string]int `json:"skills"`
	Inventory  []string       `json:"inventory"`
	Currency   int            `json:"currency"`
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
	Player   Player         `json:"player"`
	World    World          `json:"world"`
	Missions Missions       `json:"missions"`
	NPCs     map[string]NPC `json:"npcs"`
}

type SaveData struct {
	GameState GameState `json:"game_state"`
	Timestamp int64     `json:"timestamp"`
	Version   string    `json:"version"`
}

// ============================================
// VARIABLES GLOBALES
// ============================================

var (
	gameState = GameState{}
	mu        sync.RWMutex
	saveSlots = make(map[int]SaveData)
)

// ============================================
// FUNCIONES DE INICIALIZACIÓN
// ============================================

func initializeGameState() {
	gameState = GameState{
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
				"hacking":   60,
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
				"arctic":        40,
				"amazon":        35,
				"africa":        50,
				"asia":          45,
				"europe":        60,
				"north_america": 55,
				"oceania":       30,
				"middle_east":   25,
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

// ============================================
// FUNCIONES PRINCIPALES DEL SERVIDOR
// ============================================

func main() {
	// Inicializar estado del juego
	initializeGameState()
	rand.Seed(time.Now().UnixNano())

	r := mux.NewRouter()
	r.HandleFunc("/rpc", handleRPC).Methods("POST")
	r.HandleFunc("/health", handleHealth).Methods("GET")

	// Configurar CORS para desarrollo
	corsMiddleware := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}

			next.ServeHTTP(w, r)
		})
	}

	server := &http.Server{
		Addr:         ":8080",
		Handler:      corsMiddleware(r),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	log.Println("Sixth Mass Extinction - Backend Go")
	log.Println("Servidor iniciado en http://localhost:8080")
	log.Println("Usa /rpc para las peticiones JSON-RPC")

	if err := server.ListenAndServe(); err != nil {
		log.Fatal("Error iniciando servidor:", err)
	}
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":  "online",
		"game":    "Sixth Mass Extinction",
		"version": "1.0.0",
		"players": 1,
		"uptime":  time.Now().Format(time.RFC3339),
	}

	jsonResponse(w, response)
}

func handleRPC(w http.ResponseWriter, r *http.Request) {
	var req RPCMethod

	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(&req); err != nil {
		sendError(w, -32700, "Parse error", 0)
		return
	}

	log.Printf("📨 RPC Request: %s (ID: %d)", req.Method, req.ID)

	// Procesar método
	mu.Lock()
	result, err := processRPCMethod(req)
	mu.Unlock()

	response := RPCResponse{
		JSONRPC: "2.0",
		ID:      req.ID,
	}

	if err != nil {
		response.Error = err
	} else {
		response.Result = result
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func processRPCMethod(req RPCMethod) (interface{}, *RPCError) {
	switch req.Method {
	case "ping":
		return map[string]string{"status": "pong", "message": "Backend Go activo"}, nil

	case "get_game_state":
		return getGameState(), nil

	case "modify_sanity":
		return modifySanity(req.Params), nil

	case "decay_needs":
		return decayNeeds(req.Params), nil

	case "satisfy_need":
		return satisfyNeed(req.Params), nil

	case "start_mission":
		return startMission(req.Params), nil

	case "get_mission_details":
		return getMissionDetails(req.Params), nil

	case "complete_mission":
		return completeMission(req.Params), nil

	case "analyze_manifesto":
		return analyzeManifesto(req.Params), nil

	case "save_game":
		return saveGame(req.Params), nil

	case "load_game":
		return loadGame(req.Params), nil

	case "get_last_save":
		return getLastSave(), nil

	default:
		return nil, &RPCError{
			Code:    -32601,
			Message: fmt.Sprintf("Method '%s' not found", req.Method),
		}
	}
}

// ============================================
// MÉTODOS RPC IMPLEMENTACIÓN
// ============================================

func getGameState() map[string]interface{} {
	return map[string]interface{}{
		"player":   gameState.Player,
		"world":    gameState.World,
		"missions": gameState.Missions,
		"npcs":     gameState.NPCs,
	}
}

func modifySanity(params map[string]interface{}) map[string]interface{} {
	amount, ok := params["amount"].(float64)
	if !ok {
		return errorResponse("Invalid amount parameter")
	}

	currentSanity, ok := params["current_sanity"].(float64)
	if !ok {
		currentSanity = float64(gameState.Player.Sanity)
	}

	// Aplicar cambio con límites
	newSanity := int(currentSanity) + int(amount)
	if newSanity < 0 {
		newSanity = 0
	} else if newSanity > 100 {
		newSanity = 100
	}

	gameState.Player.Sanity = newSanity

	// Verificar umbrales de cordura
	checkSanityThresholds(int(currentSanity), newSanity)

	return map[string]interface{}{
		"success":    true,
		"new_sanity": newSanity,
		"reason":     params["reason"],
	}
}

func decayNeeds(params map[string]interface{}) map[string]interface{} {
	currentNeeds, ok := params["current_needs"].(map[string]interface{})
	if !ok {
		return errorResponse("Invalid needs parameter")
	}

	// Degradar cada necesidad (1-5 puntos por día)
	newNeeds := make(map[string]int)
	for need, value := range currentNeeds {
		if val, ok := value.(float64); ok {
			decay := rand.Intn(5) + 1 // 1-5 puntos de degradación
			newValue := int(val) - decay
			if newValue < 0 {
				newValue = 0
			}
			newNeeds[need] = newValue
		}
	}

	// Actualizar estado
	gameState.Player.Needs = newNeeds

	return map[string]interface{}{
		"success":   true,
		"new_needs": newNeeds,
	}
}

func satisfyNeed(params map[string]interface{}) map[string]interface{} {
	needType, ok1 := params["need_type"].(string)
	amount, ok2 := params["amount"].(float64)

	if !ok1 || !ok2 {
		return errorResponse("Invalid parameters")
	}

	// Satisfacer necesidad
	currentValue := gameState.Player.Needs[needType]
	newValue := currentValue + int(amount)
	if newValue > 100 {
		newValue = 100
	}

	gameState.Player.Needs[needType] = newValue

	// Verificar si es comida de carne para vegano
	item, _ := params["item"].(string)
	isVeganTrauma := false
	if needType == "hunger" && strings.Contains(strings.ToLower(item), "meat") {
		isVeganTrauma = true
	}

	return map[string]interface{}{
		"success":     true,
		"new_needs":   gameState.Player.Needs,
		"vegan_check": isVeganTrauma,
	}
}

func startMission(params map[string]interface{}) map[string]interface{} {
	missionID, ok := params["mission_id"].(string)
	if !ok {
		return errorResponse("Invalid mission_id")
	}

	// Verificar si ya hay misión activa
	if gameState.Missions.Active != "" {
		return map[string]interface{}{
			"success": false,
			"error":   "Ya hay una misión activa",
		}
	}

	// Verificar si la misión está disponible
	available := false
	for _, m := range gameState.Missions.Available {
		if m == missionID {
			available = true
			break
		}
	}

	if !available {
		return map[string]interface{}{
			"success": false,
			"error":   "Misión no disponible",
		}
	}

	// Iniciar misión
	gameState.Missions.Active = missionID

	return map[string]interface{}{
		"success":    true,
		"mission_id": missionID,
	}
}

func getMissionDetails(params map[string]interface{}) map[string]interface{} {
	missionID, ok := params["mission_id"].(string)
	if !ok {
		return errorResponse("Invalid mission_id")
	}

	// Datos de misión mock
	missionData := getMockMissionData(missionID)

	return map[string]interface{}{
		"success":      true,
		"mission_data": missionData,
	}
}

func completeMission(params map[string]interface{}) map[string]interface{} {
	missionID, ok1 := params["mission_id"].(string)
	choices, ok2 := params["choices"].(map[string]interface{})

	if !ok1 || !ok2 {
		return errorResponse("Invalid parameters")
	}

	// Verificar que la misión activa coincida
	if gameState.Missions.Active != missionID {
		return map[string]interface{}{
			"success": false,
			"error":   "Misión no activa",
		}
	}

	// Calcular resultados basados en elecciones
	sanityImpact := calculateSanityImpact(choices)
	reputationChanges := calculateReputationChanges(choices, missionID)

	// Actualizar estado
	gameState.Missions.Active = ""
	gameState.Missions.Completed = append(gameState.Missions.Completed, missionID)
	gameState.Player.Sanity += sanityImpact

	// Aplicar cambios de reputación
	for region, change := range reputationChanges {
		gameState.Player.Reputation[region] += change
	}

	return map[string]interface{}{
		"success":            true,
		"mission_id":         missionID,
		"sanity_impact":      sanityImpact,
		"reputation_changes": reputationChanges,
		"rewards": map[string]interface{}{
			"currency": 500,
			"items":    []string{"encrypted_data", "elara_trust_token"},
		},
	}
}

func analyzeManifesto(params map[string]interface{}) map[string]interface{} {
	text, ok := params["text"].(string)
	if !ok {
		return errorResponse("Invalid text parameter")
	}

	// Análisis simple del manifiesto (mock)
	wordCount := len(text)
	sentiment := analyzeSentiment(text)

	// Calcular impacto basado en sentimiento y reputación actual
	reputationImpact := make(map[string]int)
	for region := range gameState.Player.Reputation {
		impact := 0
		if sentiment > 0.5 {
			impact = rand.Intn(10) + 5 // Positivo
		} else if sentiment < -0.5 {
			impact = -(rand.Intn(10) + 5) // Negativo
		}
		reputationImpact[region] = impact
	}

	sanityImpact := 0
	if wordCount > 500 {
		sanityImpact = 5 // Escribir mucho cansa
	}

	// Aplicar cambios
	for region, impact := range reputationImpact {
		gameState.Player.Reputation[region] += impact
	}
	gameState.Player.Sanity += sanityImpact

	return map[string]interface{}{
		"success": true,
		"analysis": map[string]interface{}{
			"word_count": wordCount,
			"sentiment":  sentiment,
			"themes":     extractThemes(text),
		},
		"reputation_impact": reputationImpact,
		"sanity_impact":     sanityImpact,
		"world_reaction":    generateWorldReaction(text, sentiment),
	}
}

func saveGame(params map[string]interface{}) map[string]interface{} {
	slot, ok := params["slot"].(float64)
	if !ok {
		return errorResponse("Invalid slot parameter")
	}

	saveData := SaveData{
		GameState: gameState,
		Timestamp: time.Now().Unix(),
		Version:   "1.0.0",
	}

	// Guardar en slot
	slotInt := int(slot)
	saveSlots[slotInt] = saveData

	return map[string]interface{}{
		"success": true,
		"slot":    slotInt,
		"message": "Juego guardado exitosamente",
	}
}

func loadGame(params map[string]interface{}) map[string]interface{} {
	slot, ok := params["slot"].(float64)
	if !ok {
		return errorResponse("Invalid slot parameter")
	}

	slotInt := int(slot)
	saveData, exists := saveSlots[slotInt]

	if !exists {
		return map[string]interface{}{
			"success": false,
			"error":   "No hay partida guardada en este slot",
		}
	}

	// Cargar estado
	gameState = saveData.GameState

	return map[string]interface{}{
		"success":    true,
		"slot":       slotInt,
		"game_state": getGameState(),
		"timestamp":  saveData.Timestamp,
	}
}

func getLastSave() map[string]interface{} {
	// Encontrar el slot más reciente
	var lastSlot int = -1
	var lastTimestamp int64 = 0

	for slot, save := range saveSlots {
		if save.Timestamp > lastTimestamp {
			lastTimestamp = save.Timestamp
			lastSlot = slot
		}
	}

	return map[string]interface{}{
		"success": lastSlot >= 0,
		"slot":    lastSlot,
		"exists":  lastSlot >= 0,
	}
}

// ============================================
// FUNCIONES AUXILIARES
// ============================================

func sendError(w http.ResponseWriter, code int, message string, id int) {
	response := RPCResponse{
		JSONRPC: "2.0",
		Error: &RPCError{
			Code:    code,
			Message: message,
		},
		ID: id,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(400)
	json.NewEncoder(w).Encode(response)
}

func jsonResponse(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

func errorResponse(message string) map[string]interface{} {
	return map[string]interface{}{
		"success": false,
		"error":   message,
	}
}

func checkSanityThresholds(oldSanity, newSanity int) {
	// Umbrales de cordura
	const critical = 15
	const low = 30
	const high = 70

	// Verificar si cruzó umbral crítico (< 15)
	if oldSanity >= critical && newSanity < critical {
		log.Println("¡CORDURA CRÍTICA! Riesgo de suicidio")
	} else if oldSanity >= low && newSanity < low {
		// Verificar si cruzó umbral bajo (< 30)
		log.Println("Cordura baja - Flashbacks activados")
	} else if oldSanity < high && newSanity >= high {
		// Verificar si subió a nivel alto (> 70)
		log.Println("Cordura alta - Bonus a diplomacia")
	}
}

func calculateSanityImpact(choices map[string]interface{}) int {
	// Lógica basada en elecciones
	return rand.Intn(21) - 10 // -10 a +10
}

func calculateReputationChanges(choices map[string]interface{}, missionID string) map[string]int {
	// Lógica basada en misión y elecciones
	return map[string]int{
		"pe": rand.Intn(21) - 5,  // -5 a +15
		"eo": rand.Intn(11) - 10, // -10 a 0
	}
}

func analyzeSentiment(text string) float64 {
	// Análisis de sentimiento simple (mock)
	positiveWords := []string{"esperanza", "libertad", "justicia", "revolución", "futuro"}
	negativeWords := []string{"muerte", "destrucción", "odio", "sufrimiento", "caos"}

	score := 0.0
	lowerText := strings.ToLower(text)

	for _, word := range positiveWords {
		if strings.Contains(lowerText, word) {
			score += 0.1
		}
	}
	for _, word := range negativeWords {
		if strings.Contains(lowerText, word) {
			score -= 0.1
		}
	}

	return score
}

func extractThemes(text string) []string {
	themes := []string{}
	possibleThemes := []string{"ecología", "política", "tecnología", "sociedad", "economía"}
	lowerText := strings.ToLower(text)

	for _, theme := range possibleThemes {
		if strings.Contains(lowerText, theme) {
			themes = append(themes, theme)
		}
	}

	return themes
}

func generateWorldReaction(text string, sentiment float64) map[string]interface{} {
	return map[string]interface{}{
		"violence_change": rand.Intn(11) - 5,
		"power_change":    rand.Intn(11) - 5,
		"headlines":       []string{"Manifiesto publicado", "Reacciones mixtas", "Impacto global"},
	}
}

func getMockMissionData(missionID string) map[string]interface{} {
	if missionID == "m1_islandia" {
		return map[string]interface{}{
			"id":          "m1_islandia",
			"title":       "Refugio en Islandia",
			"description": "Has llegado al refugio hacktivista en Islandia. Elara Vance te espera con información crucial sobre los Cartógrafos.",
			"objectives": []string{
				"Hablar con Elara Vance",
				"Acceder al servidor seguro",
				"Descargar los datos de los Cartógrafos",
			},
			"choices": []map[string]interface{}{
				{
					"id":      "approach",
					"text":    "Cómo abordar a Elara",
					"options": []string{"Directo", "Cauteloso", "Apasionado"},
				},
				{
					"id":      "data_access",
					"text":    "Método de acceso al servidor",
					"options": []string{"Hackeo directo", "Infiltración", "Diplomacia"},
				},
			},
			"rewards": map[string]interface{}{
				"currency":   500,
				"reputation": map[string]int{"pe": 20, "eo": -10},
				"items":      []string{"cartograph_data", "encryption_key"},
			},
			"duration": 3, // días en juego
		}
	}

	return map[string]interface{}{
		"error": "Misión no encontrada",
	}
}
