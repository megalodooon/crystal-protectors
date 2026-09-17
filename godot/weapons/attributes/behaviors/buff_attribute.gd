extends AttributeClass
class_name BuffAttributeClass


@export var buffStat : Stat = Stat.NONE
@export var duration : float = 3.0
@export var maxStacks : int = 1
@export var buffScene : PackedScene

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["duration"] = AttributeScalingClass.format_number(duration)
	values["stacks"] = str(maxStacks)
	return values

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	weapon.add_buff(roll, buffStat, duration, maxStacks, buffScene)
