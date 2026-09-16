extends Node2D
class_name EnchantClass


@onready var glow : Sprite2D = $Glow
@onready var particles : CPUParticles2D = $Particles

var style : EnchantStyleClass
var color : Color = Color.WHITE
var texture : Texture2D
var points : PackedVector2Array

#------------------------#

func _ready() -> void:
	glow.texture = texture
	var shader : ShaderMaterial = glow.material
	shader.set_shader_parameter("glowColor", color)
	shader.set_shader_parameter("strength", style.glowStrength)
	shader.set_shader_parameter("glowSize", style.glowSize)
	shader.set_shader_parameter("pulseSpeed", style.pulseSpeed)
	if style.particleAmount > 0 and not points.is_empty():
		particles.color = color.lerp(Color.WHITE, 0.3)
		particles.amount = style.particleAmount
		particles.emission_points = points
		particles.emitting = true
