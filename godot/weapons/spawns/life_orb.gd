extends Node2D
class_name LifeOrbClass


@export var speed : float = 45.0
@export var acceleration : float = 300.0
@export var turnSpeed : float = 9.0
@export var arriveDistance : float = 5.0
@export var maxLifetime : float = 1.5
@export var impactScene : PackedScene

@onready var glow : Sprite2D = $Glow
@onready var core : Sprite2D = $Core
@onready var trail : VfxTrailClass = $Trail

var target : Node2D
var velocity : Vector2 = Vector2.ZERO
var age : float = 0.0
var arrived : bool = false

#------------------------#

func _ready() -> void:
	velocity = Vector2.from_angle(randf_range(-PI, 0.0)) * speed

func _physics_process(delta : float) -> void:
	if arrived:
		return
	age += delta
	core.scale = Vector2.ONE * (0.22 + 0.05 * sin(age * 30.0))
	if not is_instance_valid(target) or age > maxLifetime:
		finish(null)
		return
	var toTarget : Vector2 = target.global_position - global_position
	if toTarget.length() <= arriveDistance:
		finish(target)
		return
	var desired : Vector2 = toTarget.normalized() * (speed + acceleration * age)
	velocity = velocity.lerp(desired, minf(turnSpeed * delta, 1.0))
	global_position += velocity * delta

func finish(reachedTarget : Node2D) -> void:
	arrived = true
	glow.visible = false
	core.visible = false
	trail.emitting = false
	if reachedTarget and impactScene:
		var impact : Node2D = impactScene.instantiate()
		reachedTarget.add_child(impact)
	get_tree().create_timer(trail.length + 0.1).timeout.connect(queue_free)
