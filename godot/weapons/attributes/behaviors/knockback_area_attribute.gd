extends AttributeClass
class_name KnockbackAreaAttributeClass


@export var radius : float = 32.0
@export var force : float = 120.0
@export var pull : bool = false
@export var maxTargets : int = 6

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_AREA or super(usedStat)

func on_proc(weapon : WeaponClass, _roll : AttributeRollClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not hurtbox:
		return
	var center : Vector2 = hurtbox.global_position
	var areaRadius : float = radius * weapon.get_area_multiplier()
	for target in get_hurtboxes_in_radius(weapon, center, areaRadius, hurtbox.collision_layer, maxTargets + 1):
		if target == hurtbox:
			continue
		var direction : Vector2 = center.direction_to(target.global_position)
		if pull:
			direction = -direction
		target.knockback(direction * force)
	spawn_effect(weapon, center, areaRadius)
