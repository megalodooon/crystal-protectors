extends WeaponAuraClass
class_name EnchantClass


@onready var glow : Sprite2D = $Glow

var style : EnchantStyleClass
var color : Color = Color.WHITE

#------------------------#

func _ready() -> void:
	var shader : ShaderMaterial = glow.material
	shader.set_shader_parameter("glowColor", color)
	shader.set_shader_parameter("strength", style.glowStrength)
	shader.set_shader_parameter("pulseSpeed", style.pulseSpeed)
	shader.set_shader_parameter("glowSize", style.glowSize)
	if style.particleAmount <= 0:
		points = PackedVector2Array()
	for child in get_children():
		if child is CPUParticles2D:
			child.color = color.lerp(Color.WHITE, 0.25)
			child.amount = maxi(roundi(style.particleAmount * child.amount / 4.0), 1)
	super()
