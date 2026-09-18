extends Node2D
class_name PathDotClass


@export var breatheSpeed : float = 4.0

@onready var glow : Sprite2D = $Glow
@onready var core : Sprite2D = $Core
@onready var ring : Sprite2D = $Ring

var glowColor : Color = Color.WHITE
var coreColor : Color = Color.WHITE
var ringScale : Vector2

#------------------------#

func _ready() -> void:
	ringScale = ring.scale
	visible = false

static func get_gray_color(color : Color, gray : float) -> Color:
	var luminance : float = color.get_luminance()
	return color.lerp(Color(luminance, luminance, luminance, color.a), gray)

func set_colors(newGlowColor : Color, newCoreColor : Color) -> void:
	glowColor = newGlowColor
	coreColor = newCoreColor

func update_dot(age : float, opacity : float, gray : float, style : PathPulseStyleClass) -> void:
	visible = age >= 0.0 and opacity > 0.0
	if not visible:
		return
	var pop : float = minf(age / style.dotPopTime, 1.0)
	var ringProgress : float = minf(age / style.dotRingTime, 1.0)
	scale = Vector2.ONE * Tween.interpolate_value(0.0, 1.0, pop, 1.0, Tween.TRANS_BACK, Tween.EASE_OUT)
	modulate.a = opacity
	glow.self_modulate = get_gray_color(glowColor, gray)
	ring.self_modulate = get_gray_color(glowColor.lightened(0.4), gray)
	core.self_modulate = get_gray_color(coreColor, gray)
	glow.modulate.a = 0.8 + 0.2 * cos(age * breatheSpeed)
	ring.scale = ringScale * Tween.interpolate_value(0.3, 0.7, ringProgress, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ring.modulate.a = 1.0 - ringProgress
