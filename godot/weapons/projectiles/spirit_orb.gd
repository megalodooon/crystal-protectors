extends ProjectileClass
class_name SpiritOrbClass


@export var turnSpeed : float = 7.0
@export var seekRange : float = 70.0
@export var fadeTime : float = 0.15
@export var seekInterval : float = 0.1

@onready var glow : Sprite2D = $Glow
@onready var core : Sprite2D = $Core
@onready var wake : VfxTrailClass = $Wake
@onready var trail : VfxTrailClass = $Trail
@onready var wisps : CPUParticles2D = $Wisps

var age : float = 0.0
var seekQuery : PhysicsShapeQueryParameters2D
var seekTimer : float = 0.0
var target : HurtboxComponentClass

#------------------------#

func _ready() -> void:
	super()
	glow.self_modulate = color
	wake.color = Color(color, wake.color.a)
	trail.color = Color(color.lerp(Color.WHITE, 0.35), trail.color.a)
	wisps.color = color
	wisps.emitting = true
	var shape : CircleShape2D = CircleShape2D.new()
	shape.radius = seekRange
	seekQuery = PhysicsShapeQueryParameters2D.new()
	seekQuery.shape = shape
	seekQuery.collide_with_areas = true
	seekQuery.collide_with_bodies = false
	seekQuery.collision_mask = collision_mask
	Vfx.add_cullable(self)

func _process(delta : float) -> void:
	age += delta
	modulate.a = clampf((lifetime - age) / fadeTime, 0.0, 1.0)
	var pulse : float = 0.5 + 0.5 * sin(age * 18.0)
	glow.scale = Vector2.ONE * (0.45 + 0.1 * pulse)
	core.scale = Vector2.ONE * (0.25 + 0.06 * pulse)

func _physics_process(delta : float) -> void:
	seekTimer -= delta
	if seekTimer <= 0.0 or not is_instance_valid(target):
		seekTimer = seekInterval
		target = find_target()
	if is_instance_valid(target):
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
	Vfx.show_hit_spark(hurtbox.global_position, color, 0.8, 5, rotation + PI / 2.0)
	super(hurtbox, hitDamage)
