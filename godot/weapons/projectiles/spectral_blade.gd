extends ProjectileClass
class_name SpectralBladeClass


@export var outTime : float = 0.32
@export var returnSpeed : float = 220.0
@export var returnAcceleration : float = 700.0
@export var spinSpeed : float = 22.0
@export var catchDistance : float = 6.0

@onready var visuals : Node2D = $Visuals
@onready var blade : Sprite2D = $Visuals/Blade
@onready var ghost : Sprite2D = $Visuals/Ghost
@onready var afterimages : CPUParticles2D = $Afterimages

var age : float = 0.0
var direction : Vector2
var currentSpeed : float = 0.0
var owner2D : Node2D

#------------------------#

func _ready() -> void:
	super()
	direction = Vector2.from_angle(rotation)
	rotation = 0.0
	if is_instance_valid(weapon):
		owner2D = weapon.wielder
		var sprite : Sprite2D = weapon.get_sprite()
		if sprite:
			blade.texture = sprite.texture
			ghost.texture = sprite.texture
			afterimages.texture = sprite.texture
	var shader : ShaderMaterial = ghost.material as ShaderMaterial
	if shader:
		shader.set_shader_parameter("glowColor", color)
	for particles : CPUParticles2D in find_children("*", "CPUParticles2D", true, false):
		particles.color = color.lerp(Color.WHITE, 0.3)
	var trail : VfxTrailClass = $Trail
	trail.color = Color(color.lerp(Color.WHITE, 0.3), trail.color.a)

func _process(delta : float) -> void:
	visuals.rotation += spinSpeed * delta

func _physics_process(delta : float) -> void:
	age += delta
	afterimages.angle_min = rad_to_deg(visuals.rotation) - 20.0
	afterimages.angle_max = rad_to_deg(visuals.rotation) + 20.0
	if age < outTime:
		var progress : float = age / outTime
		position += direction * speed * 2.0 * (1.0 - progress) * delta
		return
	if not is_instance_valid(owner2D):
		queue_free()
		return
	var toOwner : Vector2 = owner2D.global_position - global_position
	currentSpeed = minf(currentSpeed + returnAcceleration * delta, returnSpeed)
	if toOwner.length() <= maxf(catchDistance, currentSpeed * delta):
		queue_free()
		return
	position += toOwner.normalized() * currentSpeed * delta

func on_hit(_hurtbox : HurtboxComponentClass, _hitDamage : float) -> void:
	pass

func on_body_entered(_body : Node2D) -> void:
	pass
