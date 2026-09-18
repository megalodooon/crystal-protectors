extends Sprite2D
class_name VfxFlashClass


@export var duration : float = 0.2
@export var delay : float = 0.0
@export var startScale : float = 0.4
@export var endScale : float = 1.0
@export var startAlpha : float = 1.0
@export var loop : bool = false

var baseScale : Vector2
var elapsed : float = 0.0

#------------------------#

func _ready() -> void:
	baseScale = scale
	update_flash()

func restart() -> void:
	elapsed = 0.0
	update_flash()

func _process(delta : float) -> void:
	elapsed += delta
	if loop and elapsed > delay + duration:
		elapsed -= duration
	update_flash()

func update_flash() -> void:
	var progress : float = clampf((elapsed - delay) / duration, 0.0, 1.0)
	var grow : float = 1.0 - pow(1.0 - progress, 3.0)
	scale = baseScale * lerpf(startScale, endScale, grow)
	self_modulate.a = 0.0 if elapsed < delay else startAlpha * pow(1.0 - progress, 2.0)
