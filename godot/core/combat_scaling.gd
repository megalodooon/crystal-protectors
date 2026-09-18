extends Resource
class_name CombatScalingClass


@export var growthPerLevel : float = 0.1

#------------------------#

func get_multiplier(combatLevel : int) -> float:
	return pow(1.0 + growthPerLevel, combatLevel - 1)
