extends AttributeClass
class_name RendAttributeClass


@export var maxHitMultiplier : float = 3.0
@export var damageType : DamageTypeClass

#------------------------#

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if not hurtbox or hurtbox.is_dead():
		return
	var rendDamage : float = minf(hurtbox.healthComponent.currentHealth * roll.get_value(weapon.get_attribute_level()), damage * maxHitMultiplier)
	var rendType : DamageTypeClass = damageType
	if not rendType:
		rendType = weapon.damageType
	hurtbox.take_damage(rendDamage, rendType)
	spawn_effect(weapon, hurtbox.global_position)
