extends AttributeClass
class_name ContagionAttributeClass


@export var radius : float = 32.0
@export var color : Color = Color.WHITE

#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	return super(weapon, chosen) and is_stat_used(weapon, chosen, Stat.STATUS_DURATION)

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_AREA or super(usedStat)

func on_proc(weapon : WeaponClass, _roll : AttributeRollClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not hurtbox or not hurtbox.statusComponent or hurtbox.statusComponent.activeEffects.is_empty():
		return
	var areaRadius : float = radius * weapon.get_area_multiplier()
	for target in get_hurtboxes_in_radius(weapon, hurtbox.global_position, areaRadius, hurtbox.collision_layer):
		if target == hurtbox:
			continue
		for effect : StatusEffectClass in hurtbox.statusComponent.activeEffects.values():
			target.apply_status(effect.duplicate())
	spawn_shockwave(weapon, hurtbox.global_position, areaRadius, color)
