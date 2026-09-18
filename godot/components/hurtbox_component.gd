extends Area2D
class_name HurtboxComponentClass


@export var healthComponent : HealthComponentClass
@export var statusComponent : StatusComponentClass
@export var showDamageNumbers : bool = true

var lastHitKilled : bool = false
var lastHitCrit : bool = false
var lastHitOverkill : float = 0.0

#------------------------#

static func find_in_radius(world : World2D, center : Vector2, radius : float, layer : int, maxTargets : int = 0) -> Array[HurtboxComponentClass]:
	var shape : CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	return find_in_shape(world, shape, Transform2D(0.0, center), layer, maxTargets)

static func find_in_shape(world : World2D, shape : Shape2D, shapeTransform : Transform2D, layer : int, maxTargets : int = 0) -> Array[HurtboxComponentClass]:
	var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = shapeTransform
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = layer
	var hurtboxes : Array[HurtboxComponentClass] = []
	for result : Dictionary in world.direct_space_state.intersect_shape(query, 64):
		var hurtbox : HurtboxComponentClass = result["collider"] as HurtboxComponentClass
		if hurtbox:
			hurtboxes.append(hurtbox)
	return keep_nearest(hurtboxes, shapeTransform.origin, maxTargets)

static func find_overlapping(area : Area2D, maxTargets : int = 0) -> Array[HurtboxComponentClass]:
	var hurtboxes : Array[HurtboxComponentClass] = []
	for overlapping in area.get_overlapping_areas():
		var hurtbox : HurtboxComponentClass = overlapping as HurtboxComponentClass
		if hurtbox:
			hurtboxes.append(hurtbox)
	return keep_nearest(hurtboxes, area.global_position, maxTargets)

static func keep_nearest(hurtboxes : Array[HurtboxComponentClass], center : Vector2, maxTargets : int) -> Array[HurtboxComponentClass]:
	if maxTargets <= 0 or hurtboxes.size() <= maxTargets:
		return hurtboxes
	hurtboxes.sort_custom(func(a : HurtboxComponentClass, b : HurtboxComponentClass) -> bool: return a.global_position.distance_squared_to(center) < b.global_position.distance_squared_to(center))
	hurtboxes.resize(maxTargets)
	return hurtboxes

func apply_status(effect : StatusEffectClass) -> void:
	if statusComponent:
		statusComponent.apply_effect(effect)

func take_damage(amount : float, damageType : DamageTypeClass = null, isCrit : bool = false) -> void:
	if statusComponent:
		amount *= statusComponent.get_damage_taken_multiplier(damageType)
	var healthBefore : float = healthComponent.currentHealth
	healthComponent.take_damage(amount)
	lastHitKilled = healthBefore > 0.0 and is_dead()
	lastHitOverkill = maxf(amount - healthBefore, 0.0) if lastHitKilled else 0.0
	lastHitCrit = isCrit
	if statusComponent:
		statusComponent.on_damage_taken(amount, damageType)
	if showDamageNumbers:
		spawn_damage_number(amount, damageType, isCrit)

func is_dead() -> bool:
	return healthComponent.currentHealth <= 0.0

func knockback(impulse : Vector2) -> void:
	var body : CharacterBody2D = get_parent() as CharacterBody2D
	if body:
		body.velocity += impulse

func displace(motion : Vector2) -> void:
	var body : CharacterBody2D = get_parent() as CharacterBody2D
	if body:
		body.move_and_collide(motion)

func spawn_damage_number(amount : float, damageType : DamageTypeClass, isCrit : bool) -> void:
	Vfx.show_damage_number(global_position, amount, damageType, isCrit)
