extends Node2D
class_name GameManager

# Temporal Paradox System
var temporal_contamination: float = 0.0
var past_self_proximity: float = 0.0
var reality_branch: String = "alpha"

# Sanity System
var sanity: float = 100.0
var sanity_effects: Dictionary = {}

# Reputation System
var global_reputation: Dictionary = {
	"global_south": 0.0,
	"activists": 0.0,
	"oligarchs": -100.0,
	"scientists": 50.0
}

func _ready():
	print("Sixth Mass Extinction - Temporal Insurgency Loaded")
	print("Reality Branch: ", reality_branch)
	
func apply_sanity_effect(effect: String, magnitude: float):
	sanity = clamp(sanity + magnitude, 0.0, 100.0)
	print("Sanity: ", sanity, " (", effect, ": ", magnitude, ")")
	
func calculate_paradox_risk():
	return temporal_contamination * past_self_proximity
