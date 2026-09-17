extends AttributeClass
class_name AreaDamageAttributeClass


const LIGHTNING_SCENE := preload("res://vfx/lightning/lightning.tscn")

@export var radius : float = 20.0
@export var includeTarget : bool = false
@export var damageType : DamageTypeClass
@export var status : StatusEffectClass
@export var statusStrength : float = 0.0
@export var skyLightning : bool = false
@export var lightningColor : Color = Color(1.0, 0.9, 0.4)
@export_flags_2d_physics var targetLayer : int = 16

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	if usedStat == Stat.EFFECT_AREA or usedStat == Stat.EFFECT_DAMAGE:
		return true
	if usedStat == Stat.STATUS_DURATION:
		return status != null
	return super(usedStat)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	var value : float = roll.get_value(weapon.get_attribute_level()) * weapon.get_effect_damage_multiplier()
	var center : Vector2 = weapon.get_origin()
	var layer : int = targetLayer
	var areaDamage : float = weapon.get_damage() * value
	if hurtbox:
		center = hurtbox.global_position
		layer = hurtbox.collision_layer
		areaDamage = damage * value
	var areaRadius : float = radius * weapon.get_area_multiplier()
	var areaDamageType : DamageTypeClass = damageType
	if not areaDamageType:
		areaDamageType = weapon.damageType
	for target in get_hurtboxes_in_radius(weapon, center, areaRadius, layer):
		if target != hurtbox or includeTarget:
			target.take_damage(areaDamage, areaDamageType)
			if status:
				var newStatus : StatusEffectClass = status.duplicate()
				newStatus.set_strength(statusStrength)
				weapon.apply_status(target, newStatus)
	spawn_effect(weapon, center, areaRadius)
	if skyLightning:
		var lightning : LightningClass = LIGHTNING_SCENE.instantiate()
		lightning.points = PackedVector2Array([center + Vector2(randf_range(-10.0, 10.0), -80.0), center])
		lightning.color = lightningColor
		lightning.width = 2.0
		weapon.get_tree().current_scene.add_child(lightning)
