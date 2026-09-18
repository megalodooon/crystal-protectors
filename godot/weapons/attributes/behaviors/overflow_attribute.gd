extends AttributeClass
class_name OverflowAttributeClass


@export var projectileScene : PackedScene
@export var searchRange : float = 60.0

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_DAMAGE or super(usedStat)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not hurtbox or hurtbox.lastHitOverkill <= 0.0:
		return
	var target : HurtboxComponentClass = find_target(weapon, hurtbox)
	if not target:
		return
	var angle : float = hurtbox.global_position.angle_to_point(target.global_position)
	var orb : ProjectileClass = projectileScene.instantiate()
	weapon.setup_hitbox(orb)
	orb.damage = hurtbox.lastHitOverkill * roll.get_value(weapon.get_attribute_level()) * weapon.get_effect_damage_multiplier()
	orb.critChance = 0.0
	orb.damageModifier = Callable()
	orb.maxHits = 1
	orb.weapon = weapon
	orb.position = hurtbox.global_position + Vector2.from_angle(angle) * 8.0
	orb.rotation = angle
	orb.color = weapon.get_color()
	orb.hit.connect(weapon.register_hit)
	weapon.get_tree().current_scene.add_child(orb)
	spawn_effect(weapon, hurtbox.global_position)

func find_target(weapon : WeaponClass, from : HurtboxComponentClass) -> HurtboxComponentClass:
	var closest : HurtboxComponentClass = null
	for candidate in get_hurtboxes_in_radius(weapon, from.global_position, searchRange, from.collision_layer):
		if candidate == from or candidate.is_dead():
			continue
		if not closest or from.global_position.distance_squared_to(candidate.global_position) < from.global_position.distance_squared_to(closest.global_position):
			closest = candidate
	return closest
