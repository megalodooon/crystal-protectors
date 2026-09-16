extends Node2D
class_name EnchantClass


@onready var glow : Sprite2D = $Glow
@onready var particles : CPUParticles2D = $Particles

var style : EnchantStyleClass
var color : Color = Color.WHITE
var texture : Texture2D

#------------------------#

func _ready() -> void:
	glow.texture = texture
	var shader : ShaderMaterial = glow.material
	shader.set_shader_parameter("glowColor", color)
	shader.set_shader_parameter("strength", style.glowStrength)
	shader.set_shader_parameter("glowSize", style.glowSize)
	shader.set_shader_parameter("pulseSpeed", style.pulseSpeed)
	if style.particleAmount > 0:
		particles.color = color.lerp(Color.WHITE, 0.3)
		particles.amount = style.particleAmount
		particles.emission_points = get_pixel_points()
		particles.emitting = true

func get_pixel_points() -> PackedVector2Array:
	var image : Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	var halfSize : Vector2 = Vector2(image.get_size()) / 2.0
	var points : PackedVector2Array = []
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.5:
				points.append(Vector2(x, y) + Vector2(0.5, 0.5) - halfSize)
	return points
