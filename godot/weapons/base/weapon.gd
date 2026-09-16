extends Node2D
class_name WeaponClass


@export var rarity : RarityClass
@export var damage : float = 10.0
@export var attackCooldown : float = 0.5
@export var damageType : DamageTypeClass
@export_range(0.0, 1.0) var critChance : float = 0.1
@export var critMultiplier : float = 2.0
@export var effects : Array[WeaponEffectClass]
@export_range(-180.0, 180.0, 1.0, "suffix:°") var holdAngle : float = -100.0
@export var holdSpeed : float = 20.0

@onready var visuals : Node2D = $Visuals

var wielder : Node2D
var canAttack : bool = true
var isSwinging : bool = false
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
	update_flip()
	visuals.rotation = get_hold_rotation()

func _process(delta : float) -> void:
	update_flip()
	if not isSwinging:
		visuals.rotation = lerp_angle(visuals.rotation, get_hold_rotation(), minf(holdSpeed * delta, 1.0))

func update_flip() -> void:
	if Vector2.from_angle(global_rotation).x > 0.0:
		scale.y = -1.0
	else:
		scale.y = 1.0

func get_hold_rotation() -> float:
	var angle : float = deg_to_rad(holdAngle)
	if scale.y > 0.0:
		angle = PI - angle
	return wrapf((angle - global_rotation) * scale.y, -PI, PI)

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
