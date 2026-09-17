extends AttributeClass
class_name BuffAttributeClass


enum Trigger { HIT, KILL }

@export var trigger : Trigger = Trigger.KILL
@export var buffStat : Stat = Stat.NONE
@export var duration : float = 3.0
@export var maxStacks : int = 1

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["duration"] = AttributeScalingClass.format_number(duration)
	values["stacks"] = str(maxStacks)
	return values

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if trigger == Trigger.HIT:
		weapon.add_buff(roll, buffStat, duration, maxStacks)

func on_kill(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if trigger == Trigger.KILL:
		weapon.add_buff(roll, buffStat, duration, maxStacks)
