extends Resource
class_name AttributeScalingClass


@export var minBase : float = 0.0
@export var maxBase : float = 0.0
@export var perStep : float = 0.0
@export var levelsPerStep : int = 1
@export var maxValue : float = 0.0
@export var percent : bool = false
@export var wholeNumber : bool = false

#------------------------#

func get_value(quality : float, level : int) -> float:
	var steps : int = floori(float(level) / maxi(levelsPerStep, 1))
	var value : float = snap_value(lerpf(minBase, maxBase, quality)) + perStep * steps
	if maxValue > 0.0:
		value = minf(value, maxValue)
	return value

func snap_value(value : float) -> float:
	if wholeNumber:
		return roundf(value)
	if percent:
		return snappedf(value, 0.001)
	return snappedf(value, 0.1)

func format_value(value : float) -> String:
	if wholeNumber:
		return str(roundi(value))
	if percent:
		value *= 100.0
	return String.num(snappedf(value, 0.1), 1).trim_suffix(".0")
