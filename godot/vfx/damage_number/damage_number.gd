extends Node2D
class_name DamageNumberClass


const DEFAULT_CRIT_COLOR := Color(1.0, 0.85, 0.2)

@export var duration : float = 0.7
@export var riseHeight : float = 8.0
@export var critScale : float = 1.3

@onready var label : Label = $Label

var amount : float = 0.0
var damageType : DamageTypeClass
var isCrit : bool = false

#------------------------#

func _ready() -> void:
	label.text = str(roundi(amount))
	var color : Color = Color.WHITE
	var popScale : float = 1.0
	if damageType:
		color = damageType.color
	if isCrit:
		label.text += "!"
		popScale = critScale
		color = DEFAULT_CRIT_COLOR
		if damageType:
			color = damageType.critColor
	label.modulate = color
	position.x += randf_range(-4.0, 4.0)
	scale = Vector2.ZERO
	var tween : Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * popScale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", position.y - riseHeight, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.tween_callback(queue_free)
