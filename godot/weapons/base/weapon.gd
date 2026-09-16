extends Node2D
class_name WeaponClass


@export var rarity : RarityClass
@export var damage : float = 10.0
@export var attackCooldown : float = 0.5
@export var damageType : DamageTypeClass
@export_range(0.0, 1.0) var critChance : float = 0.1
@export var critMultiplier : float = 2.0
@export var effects : Array[WeaponEffectClass]

@onready var visuals : Node2D = $Visuals

var wielder : Node2D
var canAttack : bool = true
var activeEffects : Array[WeaponEffectClass]

#------------------------#

func _ready() -> void:
	for child in get_children():
		if child is AttackClass:
			child.weapon = self
	for effect in effects:
		activeEffects.append(effect.duplicate())
	if rarity:
		for effect in rarity.effects:
			activeEffects.append(effect.duplicate())

func attack() -> void:
	if not canAttack:
		return
	canAttack = false
	for child in get_children():
		if child is AttackClass:
			child.perform()
	for effect in activeEffects:
		effect.on_attack(self)
	get_tree().create_timer(attackCooldown).timeout.connect(end_cooldown)

func end_cooldown() -> void:
	canAttack = true

func register_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	for effect in activeEffects:
		effect.on_hit(self, hurtbox, hitDamage)

func get_damage() -> float:
	if rarity:
		return damage * rarity.damageMultiplier
	return damage
