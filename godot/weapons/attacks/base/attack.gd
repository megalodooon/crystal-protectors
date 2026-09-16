extends Node2D
class_name AttackClass


@export var damageMultiplier : float = 1.0

var weapon : WeaponClass

#------------------------#

func perform() -> void:
	pass

func get_damage() -> float:
	return weapon.get_damage() * damageMultiplier

func register_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	weapon.register_hit(hurtbox, hitDamage)

func setup_hitbox(hitbox : HitboxComponentClass) -> void:
	hitbox.damage = get_damage()
	hitbox.damageType = weapon.damageType
	hitbox.critChance = weapon.critChance
	hitbox.critMultiplier = weapon.critMultiplier
