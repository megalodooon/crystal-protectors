extends Node2D
class_name WeaponAuraClass


var texture : Texture2D
var points : PackedVector2Array
var space : Node2D
var particles : Array[CPUParticles2D] = []

#------------------------#

func _ready() -> void:
	process_physics_priority = 100
	for child in get_children():
		if child is Sprite2D:
			child.texture = texture
		elif child is CPUParticles2D and not points.is_empty():
			particles.append(child)
	for emitter in particles:
		if space:
			emitter.top_level = true
			emitter.local_coords = true
		emitter.emission_points = points
		emitter.emitting = true
	update_particles()
	for emitter in particles:
		emitter.reset_physics_interpolation()

func _physics_process(_delta : float) -> void:
	update_particles()

func update_particles() -> void:
	if not is_instance_valid(space):
		return
	var spacePoints : PackedVector2Array = space.global_transform.affine_inverse() * global_transform * points
	for emitter in particles:
		emitter.global_position = space.global_position
		emitter.emission_points = spacePoints
