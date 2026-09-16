extends AttributeClass
class_name HealthDamageAttributeClass


@export_range(0.0, 1.0) var minHealth : float = 0.0
@export_range(0.0, 1.0) var maxHealth : float = 1.0

#------------------------#

func modify_hit_damage(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> float:
	var health : HealthComponentClass = hurtbox.healthComponent
	if not health or health.maxHealth <= 0.0:
		return damage
	var healthPart : float = health.currentHealth / health.maxHealth
	if healthPart < minHealth or healthPart > maxHealth:
		return damage
	return damage * (1.0 + roll.get_value(weapon.get_attribute_level()))
