extends AttributeClass
class_name RandomDamageAttributeClass


@export var secondScaling : AttributeScalingClass
@export_range(0.0, 1.0) var effectThreshold : float = 0.8

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["second"] = secondScaling.format_value(secondScaling.get_value(quality, level))
	return values

func modify_hit_damage(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> float:
	var level : int = weapon.get_attribute_level()
	var bonus : float = roll.get_value(level)
	var penalty : float = secondScaling.get_value(roll.quality, level)
	if chanceScaling:
		if weapon.roll_chance(roll.get_chance(level)):
			spawn_effect(weapon, hurtbox.global_position)
			return damage * (1.0 + bonus)
		return damage * (1.0 + penalty)
	var luck : float = randf()
	if luck >= effectThreshold:
		spawn_effect(weapon, hurtbox.global_position)
	return damage * (1.0 + lerpf(penalty, bonus, luck))
