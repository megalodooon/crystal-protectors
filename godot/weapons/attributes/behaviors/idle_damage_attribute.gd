extends AttributeClass
class_name IdleDamageAttributeClass


@export var idleTime : float = 1.5

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["idle"] = AttributeScalingClass.format_number(idleTime)
	return values

func modify_attack_damage(weapon : WeaponClass, roll : AttributeRollClass, damage : float) -> float:
	if weapon.attackIdleTime < idleTime:
		return damage
	return damage * (1.0 + roll.get_value(weapon.get_attribute_level()))

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	super(weapon, roll, hurtbox, damage)
	if weapon.attackIdleTime >= idleTime:
		spawn_effect(weapon, hurtbox.global_position)
