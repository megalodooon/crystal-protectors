extends StatBoostAttributeClass
class_name StatusTargetDamageAttributeClass


#------------------------#

func modify_hit_damage(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> float:
	if not hurtbox.statusComponent or hurtbox.statusComponent.get_harmful_effects().is_empty():
		return damage
	return damage * (1.0 + roll.get_value(weapon.get_attribute_level()))
