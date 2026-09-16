extends AttributeClass
class_name LifeStealAttributeClass


#------------------------#

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, damage : float) -> void:
	if not weapon.wielder:
		return
	var health : HealthComponentClass = weapon.wielder.get("healthComponent") as HealthComponentClass
	if health:
		health.heal(damage * roll.get_value(weapon.get_attribute_level()))
