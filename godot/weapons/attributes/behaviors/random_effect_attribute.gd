extends AttributeClass
class_name RandomEffectAttributeClass


@export var options : Array[AttributeClass]

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	for option in options:
		if option.uses_stat(usedStat):
			return true
	return super(usedStat)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if options.is_empty():
		return
	var optionRoll : AttributeRollClass = AttributeRollClass.new()
	optionRoll.attribute = options.pick_random()
	optionRoll.quality = roll.quality
	optionRoll.attribute.on_proc(weapon, optionRoll, hurtbox, damage)
	if hurtbox:
		spawn_effect(weapon, hurtbox.global_position)
	else:
		spawn_effect(weapon, weapon.get_origin())
