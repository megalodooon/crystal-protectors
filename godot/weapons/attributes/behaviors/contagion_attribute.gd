extends AttributeClass
class_name ContagionAttributeClass


@export var radius : float = 32.0

#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	return super(weapon, chosen) and is_stat_used(weapon, chosen, Stat.STATUS_DURATION)

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_AREA or super(usedStat)

func on_proc(weapon : WeaponClass, _roll : AttributeRollClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not hurtbox or not hurtbox.statusComponent:
		return
	var harmful : Array[StatusEffectClass] = hurtbox.statusComponent.get_harmful_effects()
	if harmful.is_empty():
		return
	var areaRadius : float = radius * weapon.get_area_multiplier()
	for target in get_hurtboxes_in_radius(weapon, hurtbox.global_position, areaRadius, hurtbox.collision_layer):
		if target == hurtbox:
			continue
		for effect in harmful:
			target.apply_status(effect.duplicate())
	spawn_effect(weapon, hurtbox.global_position, areaRadius)
