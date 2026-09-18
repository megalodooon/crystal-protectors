extends Resource
class_name EnemyModifiersClass


@export var modifiers : Array[StatusEffectClass]
@export var startLevel : int = 3
@export var chancePerLevel : float = 0.012
@export var maxChance : float = 0.3

#------------------------#

func get_chance(combatLevel : int) -> float:
	if combatLevel < startLevel:
		return 0.0
	return minf((combatLevel - startLevel + 1) * chancePerLevel, maxChance)

func roll_modifier(combatLevel : int) -> StatusEffectClass:
	if modifiers.is_empty() or randf() >= get_chance(combatLevel):
		return null
	return modifiers.pick_random().duplicate()
