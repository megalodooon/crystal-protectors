extends AttributeClass
class_name BladeStormAttributeClass


@export var stormScene : PackedScene
@export var duration : float = 2.5

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_AREA or usedStat == Stat.EFFECT_DAMAGE or super(usedStat)

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["duration"] = AttributeScalingClass.format_number(duration)
	return values

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	var holder : Node2D = weapon.get_visual_holder()
	for child in holder.get_children():
		var existing : BladeStormClass = child as BladeStormClass
		if existing:
			existing.refresh(duration)
			return
	var storm : BladeStormClass = stormScene.instantiate()
	storm.duration = duration
	storm.damage = weapon.get_damage() * roll.get_value(weapon.get_attribute_level()) * weapon.get_effect_damage_multiplier()
	storm.damageType = weapon.damageType
	storm.critChance = weapon.get_crit_chance()
	storm.critMultiplier = weapon.get_crit_multiplier()
	storm.color = weapon.get_color()
	storm.radius *= weapon.get_area_multiplier()
	holder.add_child(storm)
