extends AttributeClass
class_name AttackCountDamageAttributeClass


@export var everyAttacks : int = 4

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["attacks"] = str(everyAttacks)
	return values

func modify_attack_damage(weapon : WeaponClass, roll : AttributeRollClass, damage : float) -> float:
	if weapon.attackCount % maxi(everyAttacks, 1) != 0:
		return damage
	return damage * (1.0 + roll.get_value(weapon.get_attribute_level()))
