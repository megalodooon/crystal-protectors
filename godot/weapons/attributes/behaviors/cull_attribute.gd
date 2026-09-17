extends AttributeClass
class_name CullAttributeClass


#------------------------#

func modify_hit_damage(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> float:
	var health : HealthComponentClass = hurtbox.healthComponent
	if not health or health.maxHealth <= 0.0:
		return damage
	if (health.currentHealth - damage) / health.maxHealth > roll.get_value(weapon.get_attribute_level()):
		return damage
	return maxf(damage, health.currentHealth)
