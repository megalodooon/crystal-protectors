extends AttributeClass
class_name ChainLightningAttributeClass


const LIGHTNING_SCENE := preload("res://vfx/lightning/lightning.tscn")

@export var countScaling : AttributeScalingClass
@export var jumpRange : float = 36.0
@export var damageType : DamageTypeClass
@export var color : Color = Color(1.0, 0.9, 0.4)

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["count"] = countScaling.format_value(countScaling.get_value(quality, level))
	return values

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if not hurtbox:
		return
	var level : int = weapon.get_attribute_level()
	var chainDamage : float = damage * roll.get_value(level)
	var targets : Array[HurtboxComponentClass] = [hurtbox]
	var points : PackedVector2Array = [hurtbox.global_position]
	for i in roundi(countScaling.get_value(roll.quality, level)):
		var target : HurtboxComponentClass = find_next_target(weapon, targets)
		if not target:
			break
		targets.append(target)
		points.append(target.global_position)
		target.take_damage(chainDamage, damageType)
	if points.size() < 2:
		return
	var lightning : LightningClass = LIGHTNING_SCENE.instantiate()
	lightning.points = points
	lightning.color = color
	weapon.get_tree().current_scene.add_child(lightning)

func find_next_target(weapon : WeaponClass, targets : Array[HurtboxComponentClass]) -> HurtboxComponentClass:
	var from : HurtboxComponentClass = targets.back()
	var closest : HurtboxComponentClass = null
	for candidate in get_hurtboxes_in_radius(weapon, from.global_position, jumpRange, from.collision_layer):
		if targets.has(candidate):
			continue
		if not closest or from.global_position.distance_squared_to(candidate.global_position) < from.global_position.distance_squared_to(closest.global_position):
			closest = candidate
	return closest
