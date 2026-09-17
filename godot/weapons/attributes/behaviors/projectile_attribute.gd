extends AttributeClass
class_name ProjectileAttributeClass


@export var projectileScene : PackedScene
@export var countScaling : AttributeScalingClass
@export var spreadAngle : float = 24.0
@export var spawnDistance : float = 8.0

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_DAMAGE or usedStat == Stat.PIERCE or usedStat == Stat.EXTRA_PROJECTILES or super(usedStat)

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["count"] = countScaling.format_value(countScaling.get_value(quality, level))
	return values

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	var level : int = weapon.get_attribute_level()
	var count : int = roundi(countScaling.get_value(roll.quality, level) + weapon.get_stat(Stat.EXTRA_PROJECTILES))
	var pierce : int = roundi(weapon.get_stat(Stat.PIERCE))
	var damageMultiplier : float = roll.get_value(level) * weapon.get_effect_damage_multiplier()
	var origin : Vector2 = weapon.get_origin()
	var burstAngle : float = randf() * TAU
	if hurtbox:
		origin = hurtbox.global_position
	for i in count:
		var angle : float = weapon.aimRotation
		if hurtbox:
			angle = burstAngle + TAU * i / count
		elif count > 1:
			angle += deg_to_rad(lerpf(-spreadAngle / 2.0, spreadAngle / 2.0, float(i) / (count - 1)))
		var projectile : ProjectileClass = projectileScene.instantiate()
		weapon.setup_hitbox(projectile, damageMultiplier)
		if projectile.maxHits > 0:
			projectile.maxHits += pierce
		projectile.position = origin + Vector2.from_angle(angle) * spawnDistance
		projectile.rotation = angle
		projectile.color = weapon.get_color()
		projectile.hit.connect(weapon.register_hit)
		weapon.get_tree().current_scene.add_child(projectile)
	spawn_effect(weapon, origin)
