extends AttributeClass
class_name AreaDamageAttributeClass


const SHOCKWAVE_SCENE := preload("res://vfx/shockwave/shockwave.tscn")

@export var radius : float = 20.0

#------------------------#

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	var areaDamage : float = damage * roll.get_value(weapon.get_attribute_level())
	var shape : CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, hurtbox.global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = hurtbox.collision_layer
	for result : Dictionary in weapon.get_world_2d().direct_space_state.intersect_shape(query):
		var target : HurtboxComponentClass = result["collider"] as HurtboxComponentClass
		if target and target != hurtbox:
			target.take_damage(areaDamage, weapon.damageType)
	var shockwave : ShockwaveClass = SHOCKWAVE_SCENE.instantiate()
	shockwave.position = hurtbox.global_position
	shockwave.radius = radius
	shockwave.color = weapon.get_color()
	weapon.get_tree().current_scene.add_child(shockwave)
