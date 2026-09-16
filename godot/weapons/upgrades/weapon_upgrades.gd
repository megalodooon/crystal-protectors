extends Resource
class_name WeaponUpgradesClass


@export var maxLevel : int = 15
@export var damagePerLevel : float = 0.05
@export var attributesPerLevel : float = 0.05
@export var resetLevelOnRarityUpgrade : bool = false

#------------------------#

func get_damage_multiplier(level : int) -> float:
	return 1.0 + damagePerLevel * level

func get_attribute_multiplier(level : int) -> float:
	return 1.0 + attributesPerLevel * level
