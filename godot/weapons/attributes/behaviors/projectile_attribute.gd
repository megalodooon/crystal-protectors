extends AttributeClass
class_name ProjectileAttributeClass


@export var projectileScene : PackedScene
@export var countScaling : AttributeScalingClass
@export var spreadAngle : float = 24.0
@export var spawnDistance : float = 8.0

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["count"] = countScaling.format_value(countScaling.get_value(quality, level))
	return values

func on_attack(weapon : WeaponClass, roll : AttributeRollClass) -> void:
	var level : int = weapon.get_attribute_level()
	var count : int = roundi(countScaling.get_value(roll.quality, level))
	var origin : Vector2 = weapon.global_position
	if weapon.wielder:
		origin = weapon.wielder.global_position
	for i in count:
		var angle : float = weapon.aimRotation
		if count > 1:
			angle += deg_to_rad(lerpf(-spreadAngle / 2.0, spreadAngle / 2.0, float(i) / (count - 1)))
		var projectile : ProjectileClass = projectileScene.instantiate()
		weapon.setup_hitbox(projectile, roll.get_value(level))
		projectile.position = origin + Vector2.from_angle(angle) * spawnDistance
		projectile.rotation = angle
		projectile.color = weapon.get_color()
		projectile.hit.connect(weapon.register_hit)
		weapon.get_tree().current_scene.add_child(projectile)
