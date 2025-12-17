// server/handlers/rpc.go
package handlers

import (
	"math/rand"
	"time"

	"sixth-mass-extinction/game"
)

// Variables globales
var (
	gameState *game.GameState
	saveSlots = make(map[int]game.SaveData)
)

func init() {
	gameState = &game.GameState{}
	*gameState = game.InitializeGameState()
	rand.Seed(time.Now().UnixNano())
}

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
	if needType == "hunger" && contains(item, "meat") {
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
		"success": true,
		"mission_id": missionID,
	}
}

func getMissionDetails(params map[string]interface{}) map[string]interface{} {
	missionID, ok := params["mission_id"].(string)
	if !ok {
		return errorResponse("Invalid mission_id")
	}
	
	// Datos de misión mock (luego se implementaría base de datos)
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
		"success":           true,
		"mission_id":        missionID,
		"sanity_impact":     sanityImpact,
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
	// En producción, aquí se integraría con un LLM
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
		"success":           true,
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
	
	saveData, ok := params["save_data"].(map[string]interface{})
	if !ok {
		return errorResponse("Invalid save_data parameter")
	}
	
	// Guardar en slot (mock - en producción sería en base de datos)
	slotInt := int(slot)
	saveSlots[slotInt] = gameState.GetSaveData()
	
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
	gameState.LoadFromSaveData(saveData)
	
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

// Funciones auxiliares
func errorResponse(message string) map[string]interface{} {
	return map[string]interface{}{
		"success": false,
		"error":   message,
	}
}

func checkSanityThresholds(oldSanity, newSanity int) {
	// Implementar lógica de umbrales
}

func calculateSanityImpact(choices map[string]interface{}) int {
	// Lógica basada en elecciones
	return rand.Intn(21) - 10 // -10 a +10
}

func calculateReputationChanges(choices map[string]interface{}, missionID string) map[string]int {
	// Lógica basada en misión y elecciones
	return map[string]int{
		"pe": rand.Intn(21) - 5, // -5 a +15
		"eo": rand.Intn(11) - 10, // -10 a 0
	}
}

func analyzeSentiment(text string) float64 {
	// Análisis de sentimiento simple (mock)
	positiveWords := []string{"esperanza", "libertad", "justicia", "revolución", "futuro"}
	negativeWords := []string{"muerte", "destrucción", "odio", "sufrimiento", "caos"}
	
	score := 0.0
	for _, word := range positiveWords {
		if contains(text, word) {
			score += 0.1
		}
	}
	for _, word := range negativeWords {
		if contains(text, word) {
			score -= 0.1
		}
	}
	
	return score
}

func extractThemes(text string) []string {
	themes := []string{}
	possibleThemes := []string{"ecología", "política", "tecnología", "sociedad", "economía"}
	
	for _, theme := range possibleThemes {
		if contains(text, theme) {
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

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && (s[0:len(substr)] == substr || contains(s[1:], substr)))
}
