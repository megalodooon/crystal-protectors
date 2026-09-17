extends AttributeClass
class_name ChanceDamageAttributeClass


#------------------------#

func modify_hit_damage(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> float:
	var level : int = weapon.get_attribute_level()
	if not weapon.roll_chance(roll.get_chance(level)):
		return damage
	spawn_effect(weapon, hurtbox.global_position)
	return damage * (1.0 + roll.get_value(level))
