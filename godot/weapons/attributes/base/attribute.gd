extends Resource
class_name AttributeClass


enum Stat { NONE, DAMAGE, CRIT_CHANCE, CRIT_DAMAGE, ATTACK_SPEED, KNOCKBACK, ATTACK_SIZE, ATTACK_ARC, EXTRA_TARGETS, STATUS_DAMAGE, MOVE_SPEED, STATUS_DURATION }

@export var attributeName : String
@export var description : String = "+{value} {name}"
@export var stat : Stat = Stat.NONE
@export var scaling : AttributeScalingClass
@export var attackTypes : Array[AttackTypeClass]
@export var special : bool = false
@export var weight : float = 1.0

#------------------------#

func can_roll(weapon : WeaponClass, _chosen : Array[AttributeClass]) -> bool:
	for attackNode in weapon.get_attacks():
		if can_use_attack(attackNode):
			return true
	return false

func can_use_attack(attackNode : AttackClass) -> bool:
	return attackTypes.is_empty() or attackTypes.has(attackNode.get_attack_type())

func get_value(quality : float, level : int) -> float:
	if not scaling:
		return 0.0
	return scaling.get_value(quality, level)

func get_description(quality : float, level : int) -> String:
	return description.format(get_description_values(quality, level))

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = {"name": attributeName}
	if scaling:
		values["value"] = scaling.format_value(get_value(quality, level))
	return values

func on_equip(_weapon : WeaponClass, _roll : AttributeRollClass) -> void:
	pass

func on_attack(_weapon : WeaponClass, _roll : AttributeRollClass) -> void:
	pass

func on_hit(_weapon : WeaponClass, _roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	pass

func on_kill(_weapon : WeaponClass, _roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	pass

func modify_attack_damage(_weapon : WeaponClass, _roll : AttributeRollClass, damage : float) -> float:
	return damage

func modify_hit_damage(_weapon : WeaponClass, _roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, damage : float) -> float:
	return damage

func get_hurtboxes_in_radius(weapon : WeaponClass, center : Vector2, radius : float, layer : int) -> Array[HurtboxComponentClass]:
	var shape : CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = layer
	var hurtboxes : Array[HurtboxComponentClass] = []
	for result : Dictionary in weapon.get_world_2d().direct_space_state.intersect_shape(query):
		var hurtbox : HurtboxComponentClass = result["collider"] as HurtboxComponentClass
		if hurtbox and not hurtbox.is_dead():
			hurtboxes.append(hurtbox)
	return hurtboxes
