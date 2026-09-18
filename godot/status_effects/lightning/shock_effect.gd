extends StatusEffectClass
class_name ShockEffectClass


@export var damagePerTick : float = 2.0
@export var damageType : DamageTypeClass
@export var jumpRange : float = 30.0
@export var jumpDamage : float = 0.5
@export var boltScene : PackedScene
@export var boltColor : Color = Color(1.0, 0.92, 0.45)

#------------------------#

func on_tick() -> void:
	var hurtbox : HurtboxComponentClass = status.hurtbox
	if not hurtbox:
		return
	pulse_visual()
	var target : HurtboxComponentClass = find_jump_target(hurtbox)
	if target:
		target.take_damage(damagePerTick * jumpDamage, damageType)
		spawn_bolt(hurtbox.global_position, target.global_position)
	hurtbox.take_damage(damagePerTick, damageType)

func find_jump_target(hurtbox : HurtboxComponentClass) -> HurtboxComponentClass:
	var closest : HurtboxComponentClass = null
	for candidate in HurtboxComponentClass.find_in_radius(hurtbox.get_world_2d(), hurtbox.global_position, jumpRange, hurtbox.collision_layer):
		if candidate == hurtbox or candidate.is_dead():
			continue
		if not closest or hurtbox.global_position.distance_squared_to(candidate.global_position) < hurtbox.global_position.distance_squared_to(closest.global_position):
			closest = candidate
	return closest

func spawn_bolt(from : Vector2, to : Vector2) -> void:
	if not boltScene:
		return
	var bolt : LightningClass = boltScene.instantiate()
	bolt.points = PackedVector2Array([from, to])
	bolt.color = boltColor
	status.get_tree().current_scene.add_child(bolt)

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newShock : ShockEffectClass = newEffect as ShockEffectClass
	if newShock:
		damagePerTick = maxf(damagePerTick, newShock.damagePerTick)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherShock : ShockEffectClass = other as ShockEffectClass
	if otherShock:
		damagePerTick += otherShock.damagePerTick

func scale_power(multiplier : float) -> void:
	damagePerTick *= multiplier

func set_damage(amount : float) -> void:
	damagePerTick = amount
