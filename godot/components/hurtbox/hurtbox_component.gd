extends Area2D
class_name HurtboxComponentClass


const DAMAGE_NUMBER_SCENE := preload("res://vfx/damage_number/damage_number.tscn")

@export var healthComponent : HealthComponentClass
@export var statusComponent : StatusComponentClass
@export var showDamageNumbers : bool = true

var lastHitKilled : bool = false
var lastHitCrit : bool = false

#------------------------#

func apply_status(effect : StatusEffectClass) -> void:
	if statusComponent:
		statusComponent.apply_effect(effect)

func take_damage(amount : float, damageType : DamageTypeClass = null, isCrit : bool = false) -> void:
	if statusComponent:
		amount *= statusComponent.get_damage_taken_multiplier()
	var wasAlive : bool = not is_dead()
	healthComponent.take_damage(amount)
	lastHitKilled = wasAlive and is_dead()
	lastHitCrit = isCrit
	if statusComponent:
		statusComponent.on_damage_taken(damageType)
	if showDamageNumbers:
		spawn_damage_number(amount, damageType, isCrit)

func is_dead() -> bool:
	return healthComponent.currentHealth <= 0.0

func knockback(impulse : Vector2) -> void:
	var body : CharacterBody2D = get_parent() as CharacterBody2D
	if body:
		body.velocity += impulse

func spawn_damage_number(amount : float, damageType : DamageTypeClass, isCrit : bool) -> void:
	var damageNumber : DamageNumberClass = DAMAGE_NUMBER_SCENE.instantiate()
	damageNumber.amount = amount
	damageNumber.damageType = damageType
	damageNumber.isCrit = isCrit
	damageNumber.position = global_position
	get_tree().current_scene.add_child.call_deferred(damageNumber)
