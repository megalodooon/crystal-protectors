extends DebuffAttributeClass
class_name MarkAttributeClass


#------------------------#

func modify_hit_damage(weapon : WeaponClass, _roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> float:
	if not hurtbox.statusComponent:
		return damage
	var mark : MarkEffectClass = hurtbox.statusComponent.activeEffects.get(status.effectName) as MarkEffectClass
	if not mark:
		return damage
	hurtbox.statusComponent.remove_effect(mark)
	spawn_effect(weapon, hurtbox.global_position)
	return damage * (1.0 + mark.bonus)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if hurtbox:
		weapon.add_hit_status(create_status(weapon, roll.get_value(weapon.get_attribute_level()), damage))
