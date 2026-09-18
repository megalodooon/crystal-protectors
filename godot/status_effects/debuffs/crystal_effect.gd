extends StatusEffectClass
class_name CrystalEffectClass


@export var shatterDamage : float = 10.0
@export var shatterRadius : float = 16.0
@export var damageType : DamageTypeClass
@export var shatterScene : PackedScene

#------------------------#

func get_speed_multiplier() -> float:
	return 0.0

func refresh(newEffect : StatusEffectClass) -> void:
	var newCrystal : CrystalEffectClass = newEffect as CrystalEffectClass
	if newCrystal:
		shatterDamage = maxf(shatterDamage, newCrystal.shatterDamage)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherCrystal : CrystalEffectClass = other as CrystalEffectClass
	if otherCrystal:
		shatterDamage += otherCrystal.shatterDamage

func scale_power(multiplier : float) -> void:
	shatterDamage *= multiplier

func set_damage(amount : float) -> void:
	shatterDamage = amount

func on_remove() -> void:
	var hurtbox : HurtboxComponentClass = status.hurtbox
	if not is_instance_valid(hurtbox):
		return
	var shape : CircleShape2D = CircleShape2D.new()
	shape.radius = shatterRadius
	var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, hurtbox.global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = hurtbox.collision_layer
	for result : Dictionary in hurtbox.get_world_2d().direct_space_state.intersect_shape(query):
		var target : HurtboxComponentClass = result["collider"] as HurtboxComponentClass
		if target:
			target.take_damage(shatterDamage, damageType)
	if shatterScene:
		var shatter : Node2D = shatterScene.instantiate()
		shatter.position = hurtbox.global_position
		hurtbox.get_tree().current_scene.add_child(shatter)
