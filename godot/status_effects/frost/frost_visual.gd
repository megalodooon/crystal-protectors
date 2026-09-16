extends Node2D
class_name FrostVisualClass


@export var fadeSpeed : float = 10.0

@onready var overlay : Sprite2D = $Overlay

var targetSprite : Sprite2D
var buildUp : float = 0.0
var shownBuildUp : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	shownBuildUp = lerpf(shownBuildUp, buildUp, minf(fadeSpeed * delta, 1.0))
	var shader : ShaderMaterial = overlay.material
	shader.set_shader_parameter("buildUp", shownBuildUp)
	overlay.visible = is_instance_valid(targetSprite)
	if overlay.visible:
		copy_sprite()

func copy_sprite() -> void:
	overlay.texture = targetSprite.texture
	overlay.centered = targetSprite.centered
	overlay.offset = targetSprite.offset
	overlay.flip_h = targetSprite.flip_h
	overlay.flip_v = targetSprite.flip_v
	overlay.hframes = targetSprite.hframes
	overlay.vframes = targetSprite.vframes
	overlay.frame = targetSprite.frame
	overlay.global_transform = targetSprite.global_transform

func shatter() -> void:
	buildUp = 0.0
	shownBuildUp = 0.0
