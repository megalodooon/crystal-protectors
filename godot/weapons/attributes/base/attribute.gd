extends Resource
class_name AttributeClass


enum Stat { NONE, DAMAGE, CRIT_CHANCE, CRIT_DAMAGE, ATTACK_SPEED, KNOCKBACK, ATTACK_SIZE, ATTACK_ARC, EXTRA_TARGETS, STATUS_DAMAGE }

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

func modify_hit_damage(_weapon : WeaponClass, _roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, damage : float) -> float:
	return damage
