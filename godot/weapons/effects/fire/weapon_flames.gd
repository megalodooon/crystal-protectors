extends Node2D
class_name WeaponFlamesClass


@onready var glow : Sprite2D = $Glow
@onready var flames : CPUParticles2D = $Flames
@onready var embers : CPUParticles2D = $Embers

var texture : Texture2D
var points : PackedVector2Array

#------------------------#

func _ready() -> void:
	glow.texture = texture
	if points.is_empty():
		return
	flames.emission_points = points
	embers.emission_points = points
	flames.emitting = true
	embers.emitting = true
