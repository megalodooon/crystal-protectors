extends AttributeClass
class_name AreaDamageAttributeClass


const LIGHTNING_SCENE := preload("res://vfx/lightning/lightning.tscn")

@export var radius : float = 20.0
@export var includeTarget : bool = false
@export var damageType : DamageTypeClass
@export var useWeaponColor : bool = true
@export var color : Color = Color.WHITE
@export var skyLightning : bool = false
@export_flags_2d_physics var targetLayer : int = 16

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_AREA or super(usedStat)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	var value : float = roll.get_value(weapon.get_attribute_level())
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
	var effectColor : Color = color
	if useWeaponColor:
		effectColor = weapon.get_color()
	spawn_shockwave(weapon, center, areaRadius, effectColor)
	if skyLightning:
		var lightning : LightningClass = LIGHTNING_SCENE.instantiate()
		lightning.points = PackedVector2Array([center + Vector2(randf_range(-8.0, 8.0), -70.0), center])
		lightning.color = effectColor
		weapon.get_tree().current_scene.add_child(lightning)
