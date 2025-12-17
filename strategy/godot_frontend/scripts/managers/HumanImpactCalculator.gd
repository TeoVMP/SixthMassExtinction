# res://scripts/managers/HumanImpactCalculator.gd
extends Node
class_name HumanImpactCalculator

var impact_factors = {
	"mining": 2.5,
	"deforestation": 3.0,
	"pollution": 2.0,
	"overfishing": 2.2,
	"urbanization": 1.8,
	"agriculture": 1.5,
	"tourism": 0.8,
	"climate_change": 3.5,
}

func calculate_region_impact(region: String, activities: Dictionary) -> float:
	var total_impact = 0.0
	
	for activity in activities:
		var intensity = activities[activity]
		var factor = impact_factors.get(activity, 1.0)
		total_impact += intensity * factor
	
	var regional_modifiers = {
		"pe": 1.2,
		"eo": 0.8,
		"ch": 1.5,
		"as": 1.1,
		"au": 1.3,
	}
	
	return total_impact * regional_modifiers.get(region, 1.0)

func calculate_ecosystem_impact(ecosystem_type: int, human_impact: float) -> Dictionary:
	var effects = {}
	
	# Usar constantes numéricas en lugar del enum
	if ecosystem_type == 0:  # FOREST
		effects = {
			"health_loss": human_impact * 1.2,
			"biodiversity_loss": human_impact * 1.5,
			"carbon_loss": human_impact * 2.0,
		}
	elif ecosystem_type == 1:  # CORAL
		effects = {
			"health_loss": human_impact * 1.8,
			"biodiversity_loss": human_impact * 2.0,
			"bleaching_risk": human_impact * 1.5,
		}
	elif ecosystem_type == 2:  # WETLAND
		effects = {
			"health_loss": human_impact * 1.0,
			"water_purification_loss": human_impact * 1.3,
			"flood_control_loss": human_impact * 1.2,
		}
	
	return effects
