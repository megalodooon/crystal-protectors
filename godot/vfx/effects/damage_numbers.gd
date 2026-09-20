extends Node2D
class_name DamageNumbersClass


const DEFAULT_CRIT_COLOR := Color(1.0, 0.85, 0.2)

@export var duration : float = 0.7
@export var riseHeight : float = 8.0
@export var critScale : float = 1.3
@export var popTime : float = 0.12
@export var randomOffset : float = 1.0
@export var fontSize : int = 4
@export var outlineSize : int = 2
@export var outlineColor : Color = Color.BLACK
@export var boxSize : Vector2 = Vector2(40.0, 6.0)
@export var maxNumbers : int = 80

@export_group("Stacking")
@export var mergeRadius : float = 7.0
@export var mergeTime : float = 0.35
@export var stackHeight : float = 6.0
@export var maxStack : int = 3

var font : Font
var positions : PackedVector2Array = []
var stacks : PackedFloat32Array = []
var amounts : PackedFloat32Array = []
var offsets : PackedVector2Array = []
var ages : PackedFloat32Array = []
var fadeLeads : PackedFloat32Array = []
var popScales : PackedFloat32Array = []
var colors : PackedColorArray = []
var texts : PackedStringArray = []
var freshCount : int = 0

#------------------------#

func _ready() -> void:
	font = ThemeDB.fallback_font
	set_process(false)

func _process(delta : float) -> void:
	var expired : int = 0
	var count : int = ages.size()
	for i in count - freshCount:
		ages[i] += delta
		if ages[i] >= duration:
			expired = i + 1
	for i in range(count - freshCount, count):
		fadeLeads[i] = delta
	freshCount = 0
	if expired > 0:
		remove_oldest(expired)
	if ages.is_empty():
		set_process(false)
	queue_redraw()

func _draw() -> void:
	for i in ages.size():
		var age : float = ages[i]
		var popScale : float = Tween.interpolate_value(0.0, popScales[i], minf(age, popTime), popTime, Tween.TRANS_BACK, Tween.EASE_OUT)
		var rise : float = Tween.interpolate_value(0.0, -riseHeight, age, duration, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		var alpha : float = 1.0 - clampf((age + fadeLeads[i] - duration * 0.6) / (duration * 0.4), 0.0, 1.0)
		draw_set_transform(positions[i] + Vector2(0.0, rise - stacks[i]), 0.0, Vector2.ONE * popScale)
		draw_string_outline(font, offsets[i], texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, fontSize, outlineSize, Color(outlineColor, outlineColor.a * alpha))
		draw_string(font, offsets[i], texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, fontSize, Color(colors[i], colors[i].a * alpha))
	draw_set_transform(Vector2.ZERO)

func add(spot : Vector2, amount : float, damageType : DamageTypeClass, isCrit : bool) -> void:
	var color : Color = Color.WHITE
	var popScale : float = 1.0
	if damageType:
		color = damageType.color
	if isCrit:
		popScale = critScale
		color = DEFAULT_CRIT_COLOR
		if damageType:
			color = damageType.critColor
	if merge_into(spot, amount, color, isCrit, popScale):
		return
	if ages.size() >= maxNumbers:
		remove_oldest(1)
	var text : String = get_text(amount, isCrit)
	positions.append(spot + Vector2(randf_range(-randomOffset, randomOffset), 0.0))
	stacks.append(get_stack_offset(spot))
	amounts.append(amount)
	offsets.append(get_text_offset(text))
	ages.append(0.0)
	fadeLeads.append(0.0)
	popScales.append(popScale)
	colors.append(color)
	texts.append(text)
	freshCount = mini(freshCount + 1, ages.size())
	set_process(true)

func merge_into(spot : Vector2, amount : float, color : Color, isCrit : bool, popScale : float) -> bool:
	for i in range(ages.size() - 1, -1, -1):
		if ages[i] > mergeTime:
			return false
		if colors[i] != color or is_far(i, spot):
			continue
		amounts[i] += amount
		texts[i] = get_text(amounts[i], isCrit)
		offsets[i] = get_text_offset(texts[i])
		ages[i] = 0.0
		popScales[i] = popScale
		return true
	return false

func get_stack_offset(spot : Vector2) -> float:
	var nearby : int = 0
	for i in ages.size():
		if ages[i] < duration * 0.7 and not is_far(i, spot):
			nearby += 1
	return stackHeight * float(mini(nearby, maxStack))

func is_far(index : int, spot : Vector2) -> bool:
	return positions[index].distance_squared_to(spot) > mergeRadius * mergeRadius

func get_text(amount : float, isCrit : bool) -> String:
	if isCrit:
		return NumberFormatClass.format(amount) + "!"
	return NumberFormatClass.format(amount)

func get_text_offset(text : String) -> Vector2:
	var ascent : float = font.get_ascent(fontSize)
	var descent : float = font.get_descent(fontSize)
	var fontHeight : int = int(font.get_height(fontSize))
	if ascent + descent < fontHeight:
		var gap : float = fontHeight - (ascent + descent)
		ascent += gap / 2.0
		descent += gap - gap / 2.0
	var top : int = int((boxSize.y - (ascent + descent)) / 2.0)
	var width : float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fontSize).x
	var left : int = floori(int(boxSize.x - width) / 2.0)
	return Vector2(left - boxSize.x / 2.0, top + ascent - boxSize.y)

func remove_oldest(count : int) -> void:
	positions = positions.slice(count)
	stacks = stacks.slice(count)
	amounts = amounts.slice(count)
	offsets = offsets.slice(count)
	ages = ages.slice(count)
	fadeLeads = fadeLeads.slice(count)
	popScales = popScales.slice(count)
	colors = colors.slice(count)
	texts = texts.slice(count)
