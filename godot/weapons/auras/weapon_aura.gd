extends Node2D
class_name WeaponAuraClass


var texture : Texture2D
var points : PackedVector2Array

#------------------------#

func _ready() -> void:
	show_behind_parent = true
	z_index = 0
	for child in get_children():
		if child is Sprite2D:
			child.texture = texture
		elif child is CPUParticles2D:
			child.z_index = 1
			if not points.is_empty():
				child.emission_points = points
				child.emitting = true
