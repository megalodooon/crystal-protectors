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
@export var attackDamage : float = 10.0
@export var attackCooldown : float = 0.8
@export var manaReward : int = 8

@onready var visuals : Node2D = $Visuals
@onready var sprite : Sprite2D = $Visuals/Sprite2D

var combatLevel : int = 1
var healthMultiplier : float = 1.0
var speedMultiplier : float = 1.0
var modifier : StatusEffectClass
var facing : float = 1.0
var attackTimer : float = 0.0

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
	attackTimer -= delta
	var direction : Vector2 = pathFollowComponent.get_direction(self)
	movementComponent.move(self, direction, delta)
	attack_blocker()
	update_facing(delta)

func attack_blocker() -> void:
	if attackTimer > 0.0:
		return
	for i in get_slide_collision_count():
		var tower : TowerClass = get_slide_collision(i).get_collider() as TowerClass
		if not tower:
			continue
		attackTimer = attackCooldown
		tower.take_damage(attackDamage * COMBAT_SCALING.get_multiplier(combatLevel))
		Vfx.show_hit_spark(global_position.lerp(tower.global_position, 0.6), Color(1.0, 0.5, 0.35), 0.7, 4, 0, global_position.angle_to_point(tower.global_position))
		return

func update_facing(delta : float) -> void:
	if absf(velocity.x) > movementComponent.speed * 0.25:
		facing = signf(velocity.x)
	visuals.scale.x = move_toward(visuals.scale.x, facing, flipSpeed * delta)

func die() -> void:
	queue_free()

func on_reached_end() -> void:
	queue_free()
