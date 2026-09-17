extends AttributeClass
class_name CooldownResetAttributeClass


#------------------------#

func on_proc(weapon : WeaponClass, _roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	weapon.reset_cooldown()
	spawn_effect(weapon, weapon.get_origin(), 0.0, weapon.get_visual_holder())
