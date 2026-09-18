extends AttributeClass
class_name DebuffAttributeClass


@export var status : StatusEffectClass
@export var damageFromHit : bool = false
@export var radius : float = 0.0
@export_flags_2d_physics var targetLayer : int = 16

#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	return status and super(weapon, chosen)

func get_status() -> StatusEffectClass:
	return status

func uses_stat(usedStat : Stat) -> bool:
	if usedStat == Stat.STATUS_DURATION:
		return true
	if usedStat == Stat.STATUS_DAMAGE:
		return damageFromHit
	if usedStat == Stat.EFFECT_AREA:
		return radius > 0.0
	return super(usedStat)

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["duration"] = AttributeScalingClass.format_number(status.duration)
	return values

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	var value : float = roll.get_value(weapon.get_attribute_level())
	if radius <= 0.0:
		if hurtbox:
			weapon.add_hit_status(create_status(weapon, value, damage))
			spawn_effect(weapon, hurtbox.global_position)
		return
	var center : Vector2 = weapon.get_origin()
	var layer : int = targetLayer
	var hitDamage : float = weapon.get_damage()
	if hurtbox:
		center = hurtbox.global_position
		layer = hurtbox.collision_layer
		hitDamage = damage
	var areaRadius : float = radius * weapon.get_area_multiplier()
	for target in get_hurtboxes_in_radius(weapon, center, areaRadius, layer):
		weapon.apply_status(target, create_status(weapon, value, hitDamage))
	spawn_effect(weapon, center, areaRadius)

func create_status(weapon : WeaponClass, value : float, damage : float) -> StatusEffectClass:
	var newStatus : StatusEffectClass = status.duplicate()
	if damageFromHit:
		newStatus.set_damage(damage * value * (1.0 + weapon.get_stat(Stat.STATUS_DAMAGE)))
	elif scaling:
		newStatus.set_strength(value)
	return newStatus
