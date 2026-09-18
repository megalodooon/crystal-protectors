extends AttributeClass
class_name BeamAttributeClass


@export var length : float = 90.0
@export var width : float = 8.0
@export var countScaling : AttributeScalingClass
@export var spreadAngle : float = 30.0
@export var maxTargets : int = 6
@export var damageType : DamageTypeClass
@export var colors : Array[Color]
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
	var origin : Vector2 = weapon.get_origin()
	var baseAngle : float = weapon.aimRotation
	var beamDamage : float = weapon.get_damage() * roll.get_value(level) * weapon.get_effect_damage_multiplier()
	if hurtbox:
		baseAngle = origin.angle_to_point(hurtbox.global_position)
		beamDamage = damage * roll.get_value(level) * weapon.get_effect_damage_multiplier()
	var beamLength : float = length * weapon.get_area_multiplier()
	var beamType : DamageTypeClass = damageType
	if not beamType:
		beamType = weapon.damageType
	var count : int = get_count(roll.quality, level)
	var shape : RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(beamLength, width * weapon.get_area_multiplier())
	for i in count:
		var angle : float = baseAngle
		if count > 1:
			angle += deg_to_rad(lerpf(-spreadAngle / 2.0, spreadAngle / 2.0, float(i) / (count - 1)))
		var direction : Vector2 = Vector2.from_angle(angle)
		var targets : Array[HurtboxComponentClass] = get_hurtboxes_in_shape(weapon, shape, Transform2D(angle, origin + direction * beamLength / 2.0), targetLayer)
		for target in HurtboxComponentClass.keep_nearest(targets, origin, maxTargets):
			target.take_damage(beamDamage, beamType)
		spawn_beam(weapon, origin, angle, beamLength, i)

func spawn_beam(weapon : WeaponClass, origin : Vector2, angle : float, beamLength : float, index : int) -> void:
	var color : Color = weapon.get_color()
	if not colors.is_empty():
		color = colors[index % colors.size()]
	Vfx.spawn_effect(effectScene, origin, beamLength, color, null, angle, false)
