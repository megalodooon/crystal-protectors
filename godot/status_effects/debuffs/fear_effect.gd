extends StatusEffectClass
class_name FearEffectClass


@export var fleeSpeed : float = 0.6

#------------------------#

func get_speed_multiplier() -> float:
	return -fleeSpeed
