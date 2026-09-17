extends AttributeClass
class_name MeteorAttributeClass


@export var meteorScene : PackedScene
@export var radius : float = 22.0
@export var searchRange : float = 80.0
@export var damageType : DamageTypeClass
@export_flags_2d_physics var targetLayer : int = 16

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_AREA or usedStat == Stat.EFFECT_DAMAGE or super(usedStat)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	var value : float = roll.get_value(weapon.get_attribute_level()) * weapon.get_effect_damage_multiplier()
	var target : Vector2 = find_target(weapon)
	var areaDamage : float = weapon.get_damage() * value
	if hurtbox:
		target = hurtbox.global_position
		areaDamage = damage * value
	var meteor : MeteorClass = meteorScene.instantiate()
	meteor.position = target
	meteor.radius = radius * weapon.get_area_multiplier()
	meteor.onImpact = impact.bind(weakref(weapon), areaDamage, meteor.radius)
	weapon.get_tree().current_scene.add_child(meteor)

func find_target(weapon : WeaponClass) -> Vector2:
	var origin : Vector2 = weapon.get_origin()
	var aimPoint : Vector2 = origin + Vector2.from_angle(weapon.aimRotation) * 30.0
	var best : Vector2 = aimPoint
	var bestDistance : float = INF
	for hurtbox in get_hurtboxes_in_radius(weapon, origin, searchRange, targetLayer):
		var distance : float = hurtbox.global_position.distance_squared_to(aimPoint)
		if distance < bestDistance:
			bestDistance = distance
			best = hurtbox.global_position
	return best

func impact(center : Vector2, weaponRef : WeakRef, areaDamage : float, areaRadius : float) -> void:
	var weapon : WeaponClass = weaponRef.get_ref() as WeaponClass
	if not weapon:
		return
	var impactDamageType : DamageTypeClass = damageType
	if not impactDamageType:
		impactDamageType = weapon.damageType
	for target in get_hurtboxes_in_radius(weapon, center, areaRadius, targetLayer):
		target.take_damage(areaDamage, impactDamageType)
