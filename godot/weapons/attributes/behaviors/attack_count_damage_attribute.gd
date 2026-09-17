extends AttributeClass
class_name AttackCountDamageAttributeClass


@export var everyAttacks : int = 3

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["attacks"] = str(everyAttacks)
	return values

func is_empowered(weapon : WeaponClass) -> bool:
	return weapon.attackCount % maxi(everyAttacks, 1) == 0

func modify_attack_damage(weapon : WeaponClass, roll : AttributeRollClass, damage : float) -> float:
	if not is_empowered(weapon):
		return damage
	return damage * (1.0 + roll.get_value(weapon.get_attribute_level()))

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	super(weapon, roll, hurtbox, damage)
	if is_empowered(weapon):
		spawn_effect(weapon, hurtbox.global_position)
