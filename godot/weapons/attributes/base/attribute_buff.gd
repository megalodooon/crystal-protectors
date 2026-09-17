extends RefCounted
class_name AttributeBuffClass


var roll : AttributeRollClass
var stat : AttributeClass.Stat = AttributeClass.Stat.NONE
var stacks : int = 0
var timeLeft : float = 0.0

#------------------------#

func get_value(level : int) -> float:
	return roll.get_value(level) * stacks
