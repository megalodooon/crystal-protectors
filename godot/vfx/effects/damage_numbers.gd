extends Node2D
class_name DamageNumbersClass


const DEFAULT_CRIT_COLOR := Color(1.0, 0.85, 0.2)

@export var duration : float = 0.7
@export var riseHeight : float = 8.0
@export var critScale : float = 1.3
@export var popTime : float = 0.12
@export var randomOffset : float = 4.0
@export var fontSize : int = 4
@export var outlineSize : int = 2
@export var outlineColor : Color = Color.BLACK
@export var boxSize : Vector2 = Vector2(40.0, 6.0)
@export var maxNumbers : int = 80

var font : Font
var positions : PackedVector2Array = []
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
		draw_set_transform(positions[i] + Vector2(0.0, rise), 0.0, Vector2.ONE * popScale)
		draw_string_outline(font, offsets[i], texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, fontSize, outlineSize, Color(outlineColor, outlineColor.a * alpha))
		draw_string(font, offsets[i], texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, fontSize, Color(colors[i], colors[i].a * alpha))
	draw_set_transform(Vector2.ZERO)

func add(spot : Vector2, amount : float, damageType : DamageTypeClass, isCrit : bool) -> void:
	var text : String = NumberFormatClass.format(amount)
	var color : Color = Color.WHITE
	var popScale : float = 1.0
	if damageType:
		color = damageType.color
	if isCrit:
		text += "!"
		popScale = critScale
		color = DEFAULT_CRIT_COLOR
		if damageType:
			color = damageType.critColor
	if ages.size() >= maxNumbers:
		remove_oldest(1)
	positions.append(spot + Vector2(randf_range(-randomOffset, randomOffset), 0.0))
	offsets.append(get_text_offset(text))
	ages.append(0.0)
	fadeLeads.append(0.0)
	popScales.append(popScale)
	colors.append(color)
	texts.append(text)
	freshCount = mini(freshCount + 1, ages.size())
	set_process(true)

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
	offsets = offsets.slice(count)
	ages = ages.slice(count)
	fadeLeads = fadeLeads.slice(count)
	popScales = popScales.slice(count)
	colors = colors.slice(count)
	texts = texts.slice(count)
