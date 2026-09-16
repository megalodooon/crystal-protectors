extends Resource
class_name WeaponUpgradesClass


@export var maxLevel : int = 15
@export var damagePerLevel : float = 0.05

#------------------------#

func get_damage_multiplier(level : int) -> float:
	return 1.0 + damagePerLevel * level
