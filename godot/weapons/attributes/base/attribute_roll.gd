extends Resource
class_name AttributeRollClass


@export var attribute : AttributeClass
@export_range(0.0, 1.0) var quality : float = 0.5

#------------------------#

func get_value(level : int) -> float:
	return attribute.get_value(quality, level)

func get_chance(level : int) -> float:
	return attribute.get_chance(quality, level)

func get_description(level : int) -> String:
	return attribute.get_description(quality, level)
