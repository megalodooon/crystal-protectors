extends CharacterBody2D
class_name EnemyClass


const PLACEHOLDER_IMAGE := preload("res://player/player_placeholder.png")
const COMBAT_SCALING := preload("res://core/combat_scaling.tres")
const MODIFIERS := preload("res://enemies/enemy_modifiers.tres")

@export var image : Texture2D
@export var flipSpeed : float = 10.0
@export var healthComponent : HealthComponentClass
@export var movementComponent : MovementComponentClass
@export var pathFollowComponent : PathFollowComponentClass
@export var statusComponent : StatusComponentClass

@onready var visuals : Node2D = $Visuals
@onready var sprite : Sprite2D = $Visuals/Sprite2D

var combatLevel : int = 1
var healthMultiplier : float = 1.0
var speedMultiplier : float = 1.0
var modifier : StatusEffectClass
var facing : float = 1.0

#------------------------#

func _ready() -> void:
	if image:
		sprite.texture = image
	else:
		sprite.texture = PLACEHOLDER_IMAGE
	healthComponent.maxHealth *= COMBAT_SCALING.get_multiplier(combatLevel) * healthMultiplier
	healthComponent.currentHealth = healthComponent.maxHealth
	movementComponent.speedMultiplier = speedMultiplier
	if not modifier:
		modifier = MODIFIERS.roll_modifier(combatLevel)
	if modifier and statusComponent:
		statusComponent.apply_effect.call_deferred(modifier)

func _physics_process(delta : float) -> void:
	var direction : Vector2 = pathFollowComponent.get_direction(self)
	movementComponent.move(self, direction, delta)
	update_facing(delta)

func update_facing(delta : float) -> void:
	if absf(velocity.x) > movementComponent.speed * 0.25:
		facing = signf(velocity.x)
	visuals.scale.x = move_toward(visuals.scale.x, facing, flipSpeed * delta)

func die() -> void:
	queue_free()

func on_reached_end() -> void:
	queue_free()
