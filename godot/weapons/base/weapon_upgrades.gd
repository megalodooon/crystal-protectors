extends Resource
class_name WeaponUpgradesClass


@export var maxLevel : int = 30
@export var rarityUpgradeLevel : int = 15
@export var damagePerLevel : float = 0.08

#------------------------#

func get_damage_multiplier(level : int) -> float:
	return 1.0 + damagePerLevel * level
