extends AttributeClass
class_name CooldownResetAttributeClass


#------------------------#

func on_proc(weapon : WeaponClass, _roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	weapon.reset_cooldown()
