extends Node2D
class_name ShockwaveClass


@export var duration : float = 0.3

@onready var ring : Sprite2D = $Ring
@onready var flash : Sprite2D = $Flash

var radius : float = 20.0
var color : Color = Color.WHITE
var shrink : bool = false
var elapsed : float = 0.0

#------------------------#

func _ready() -> void:
	ring.self_modulate = Color(color.lerp(Color.WHITE, 0.2), 0.6)
	flash.self_modulate = Color(color, 0.35)
	update_shockwave()

func _process(delta : float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	update_shockwave()

func update_shockwave() -> void:
	var progress : float = elapsed / duration
	var grow : float = 1.0 - pow(1.0 - progress, 3.0)
	var ringSize : float = lerpf(0.25, 1.0, grow)
	if shrink:
		ringSize = lerpf(1.0, 0.2, grow)
	ring.scale = Vector2.ONE * radius / (ring.texture.get_width() * 0.5 * 0.85) * ringSize
	ring.modulate.a = 1.0 - progress
	flash.scale = Vector2.ONE * radius / (flash.texture.get_width() * 0.5) * lerpf(0.3, 0.6, grow)
	flash.modulate.a = pow(1.0 - progress, 2.0)
