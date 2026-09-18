extends Node2D
class_name WeaponSpawnClass


@export var tickInterval : float = 0.5
@export var fadeTime : float = 0.3
@export var lingerTime : float = 0.8
@export_flags_2d_physics var targetLayer : int = 16

var radius : float = 24.0
var duration : float = 2.0
var value : float = 0.0
var damage : float = 0.0
var damageType : DamageTypeClass
var critChance : float = 0.0
var critMultiplier : float = 2.0
var color : Color = Color.WHITE
var target : HurtboxComponentClass
var age : float = 0.0
var tickTimer : float = 0.0
var ended : bool = false

#------------------------#

func _process(delta : float) -> void:
	age += delta
	modulate.a = minf(clampf(age / fadeTime, 0.0, 1.0), clampf((duration + fadeTime - age) / fadeTime, 0.0, 1.0))
	if age >= duration and not ended:
		ended = true
		on_end()
	if age >= duration + fadeTime + lingerTime:
		queue_free()

func _physics_process(delta : float) -> void:
	if not is_active():
		return
	tickTimer += delta
	if tickTimer >= tickInterval:
		tickTimer -= tickInterval
		on_tick()

func is_active() -> bool:
	return age < duration

func refresh(newDuration : float) -> void:
	duration = maxf(duration, age + newDuration)

func on_tick() -> void:
	pass

func on_end() -> void:
	for particles : CPUParticles2D in find_children("*", "CPUParticles2D", true, false):
		particles.emitting = false

func get_targets(center : Vector2, searchRadius : float) -> Array[HurtboxComponentClass]:
	var shape : CircleShape2D = CircleShape2D.new()
	shape.radius = searchRadius
	var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = targetLayer
	var hurtboxes : Array[HurtboxComponentClass] = []
	for result : Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var hurtbox : HurtboxComponentClass = result["collider"] as HurtboxComponentClass
		if hurtbox:
			hurtboxes.append(hurtbox)
	return hurtboxes

func get_closest_target(center : Vector2, searchRadius : float) -> HurtboxComponentClass:
	var closest : HurtboxComponentClass = null
	for hurtbox in get_targets(center, searchRadius):
		if not closest or center.distance_squared_to(hurtbox.global_position) < center.distance_squared_to(closest.global_position):
			closest = hurtbox
	return closest

func hit(hurtbox : HurtboxComponentClass, amount : float) -> void:
	var isCrit : bool = randf() < critChance
	if isCrit:
		amount *= critMultiplier
	hurtbox.take_damage(amount, damageType, isCrit)

func spawn_vfx(scene : PackedScene, at : Vector2, vfxRadius : float = 0.0) -> void:
	if not scene:
		return
	var effect : Node2D = scene.instantiate()
	var vfx : VfxEffectClass = effect as VfxEffectClass
	if vfx:
		vfx.radius = vfxRadius
		vfx.color = color
	effect.position = at
	get_tree().current_scene.add_child(effect)
