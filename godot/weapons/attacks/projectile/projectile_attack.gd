extends AttackClass
class_name ProjectileAttackClass


@export var projectileScene : PackedScene
@export var projectileCount : int = 1
@export var spreadAngle : float = 0.0

#------------------------#

func perform() -> void:
	for i in projectileCount:
		var projectile : ProjectileClass = projectileScene.instantiate()
		setup_hitbox(projectile)
		projectile.global_position = global_position
		projectile.rotation = global_rotation + get_spread_offset(i)
		projectile.hit.connect(register_hit)
		get_tree().current_scene.add_child(projectile)

func get_spread_offset(index : int) -> float:
	if projectileCount <= 1:
		return 0.0
	return deg_to_rad(-spreadAngle / 2.0 + spreadAngle * index / (projectileCount - 1))
