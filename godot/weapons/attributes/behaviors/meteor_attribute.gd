extends AttributeClass
class_name MeteorAttributeClass


@export var meteorScene : PackedScene
@export var radius : float = 22.0
@export var searchRange : float = 80.0
@export var maxTargets : int = 6
@export var damageType : DamageTypeClass
@export var countScaling : AttributeScalingClass
@export var scatter : float = 28.0
@export var dropDelay : float = 0.12
@export_flags_2d_physics var targetLayer : int = 16

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_AREA or usedStat == Stat.EFFECT_DAMAGE or super(usedStat)

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["count"] = str(get_count(quality, level))
	return values

func get_count(quality : float, level : int) -> int:
	if not countScaling:
		return 1
	return maxi(roundi(countScaling.get_value(quality, level)), 1)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	var level : int = weapon.get_attribute_level()
	var value : float = roll.get_value(level) * weapon.get_effect_damage_multiplier()
	var center : Vector2 = find_target(weapon)
	var areaDamage : float = weapon.get_damage() * value
	if hurtbox:
		center = hurtbox.global_position
		areaDamage = damage * value
	var areaRadius : float = radius * weapon.get_area_multiplier()
	var targets : Array[Vector2] = get_drop_points(weapon, center, get_count(roll.quality, level))
	for i in targets.size():
		var meteor : MeteorClass = meteorScene.instantiate()
		meteor.position = targets[i]
		meteor.radius = areaRadius
		meteor.delay = dropDelay * i
		meteor.onImpact = impact.bind(weakref(weapon), areaDamage, areaRadius)
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

func get_drop_points(weapon : WeaponClass, center : Vector2, count : int) -> Array[Vector2]:
	var dropPoints : Array[Vector2] = [center]
	var nearby : Array[HurtboxComponentClass] = get_hurtboxes_in_radius(weapon, center, scatter, targetLayer)
	nearby.shuffle()
	for hurtbox in nearby:
		if dropPoints.size() >= count:
			break
		if hurtbox.global_position.distance_to(center) > 4.0:
			dropPoints.append(hurtbox.global_position)
	while dropPoints.size() < count:
		dropPoints.append(center + Vector2.from_angle(randf() * TAU) * randf_range(scatter * 0.4, scatter))
	return dropPoints

func impact(center : Vector2, weaponRef : WeakRef, areaDamage : float, areaRadius : float) -> void:
	var weapon : WeaponClass = weaponRef.get_ref() as WeaponClass
	if not weapon:
		return
	var impactDamageType : DamageTypeClass = damageType
	if not impactDamageType:
		impactDamageType = weapon.damageType
	for target in get_hurtboxes_in_radius(weapon, center, areaRadius, targetLayer, maxTargets):
		target.take_damage(areaDamage, impactDamageType)
