extends ProjectileClass
class_name SpiritOrbClass


const HIT_SPARK_SCENE := preload("res://vfx/hit_spark/hit_spark.tscn")

@export var turnSpeed : float = 7.0
@export var seekRange : float = 70.0
@export var fadeTime : float = 0.15

@onready var glow : Sprite2D = $Glow
@onready var core : Sprite2D = $Core

var age : float = 0.0
var seekQuery : PhysicsShapeQueryParameters2D

#------------------------#

func _ready() -> void:
	super()
	glow.self_modulate = color
	for particles : CPUParticles2D in [$Wake, $Trail, $Wisps]:
		particles.color = color
		particles.emitting = true
	var shape : CircleShape2D = CircleShape2D.new()
	shape.radius = seekRange
	seekQuery = PhysicsShapeQueryParameters2D.new()
	seekQuery.shape = shape
	seekQuery.collide_with_areas = true
	seekQuery.collide_with_bodies = false
	seekQuery.collision_mask = collision_mask

func _process(delta : float) -> void:
	age += delta
	modulate.a = clampf((lifetime - age) / fadeTime, 0.0, 1.0)
	var pulse : float = 0.5 + 0.5 * sin(age * 18.0)
	glow.scale = Vector2.ONE * (0.45 + 0.1 * pulse)
	core.scale = Vector2.ONE * (0.25 + 0.06 * pulse)

func _physics_process(delta : float) -> void:
	var target : HurtboxComponentClass = find_target()
	if target:
		rotation = rotate_toward(rotation, global_position.angle_to_point(target.global_position), turnSpeed * delta)
	super(delta)

func find_target() -> HurtboxComponentClass:
	seekQuery.transform = Transform2D(0.0, global_position)
	var closest : HurtboxComponentClass = null
	for result : Dictionary in get_world_2d().direct_space_state.intersect_shape(seekQuery):
		var hurtbox : HurtboxComponentClass = result["collider"] as HurtboxComponentClass
		if hurtbox and (not closest or global_position.distance_squared_to(hurtbox.global_position) < global_position.distance_squared_to(closest.global_position)):
			closest = hurtbox
	return closest

func on_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	var hitSpark : HitSparkClass = HIT_SPARK_SCENE.instantiate()
	hitSpark.position = hurtbox.global_position
	hitSpark.color = color
	hitSpark.strength = 0.8
	hitSpark.sparkAmount = 8
	hitSpark.orbAmount = 5
	hitSpark.angle = rotation + PI / 2.0
	get_tree().current_scene.add_child(hitSpark)
	super(hurtbox, hitDamage)
