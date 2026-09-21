extends ProjectileClass
class_name SpellBoltClass


@export var motion : SpellMotionClass
@export var size : float = 1.0
@export var fadeTime : float = 0.16
@export var bounceRange : float = 70.0
@export var bounceTurnSpeed : float = 14.0
@export var pulseSpeed : float = 22.0

@onready var trail : VfxTrailClass = $Trail
@onready var glow : Sprite2D = $Glow
@onready var core : Sprite2D = $Core
@onready var flare : Sprite2D = $Flare
@onready var shape : CollisionShape2D = $CollisionShape2D

var attack : AttackClass
var style : SpellStyleClass
var colors : Array[Color] = []
var trailMaterial : ShaderMaterial
var side : float = 1.0
var phase : float = 0.0
var holdTime : float = 0.0
var castOrigin : Vector2
var speedScale : float = 1.0
var distanceScale : float = 1.0
var homing : float = 0.0
var bounces : int = 0
var stretch : float = 0.0

var age : float = 0.0
var flightAge : float = 0.0
var progress : float = 0.0
var start : Vector2
var carrier : Vector2
var heading : float = 0.0
var travelled : float = 0.0
var flightDistance : float = 0.0
var flightTime : float = 0.0
var speed2D : float = 0.0
var launched : bool = false
var bounced : bool = false
var ended : bool = false
var endAge : float = 0.0
var target : HurtboxComponentClass
var seekTimer : float = 0.0
var hitTargets : Array[HurtboxComponentClass] = []
var glowScale : Vector2
var coreScale : Vector2
var flareScale : Vector2

#------------------------#

func _ready() -> void:
	if not motion:
		motion = SpellMotionClass.new()
	if not style:
		style = get_weapon_style()
	if colors.is_empty():
		colors = [color.darkened(0.45), color, color.lerp(Color.WHITE, 0.6)]
	if not trailMaterial:
		trailMaterial = SpellAttackClass.make_trail_material(style, colors)
	flightDistance = motion.distance * distanceScale
	flightTime = maxf(motion.flightTime / speedScale, 0.05)
	speed2D = flightDistance / flightTime
	lifetime = holdTime + flightTime + fadeTime + style.trailLength + bounces * 0.6 + 1.5
	super()
	start = global_position
	carrier = start
	heading = rotation
	if castOrigin == Vector2.ZERO:
		castOrigin = start
	(shape.shape as CircleShape2D).radius *= size
	setup_visuals()
	if holdTime > 0.0:
		monitoring = false
		trail.emitting = false
		global_position = castOrigin
	Vfx.add_cullable(self)

func get_weapon_style() -> SpellStyleClass:
	if is_instance_valid(weapon):
		for attackNode in weapon.get_attacks():
			var spell : SpellAttackClass = attackNode as SpellAttackClass
			if spell:
				var spellStyle : SpellStyleClass = spell.get_style()
				colors = spell.get_spell_colors()
				trailMaterial = spell.get_trail_material(spellStyle)
				return spellStyle
		if weapon.rarity and weapon.rarity.spellStyle:
			return weapon.rarity.spellStyle
	return SpellStyleClass.new()

func setup_visuals() -> void:
	var headSize : float = size * style.headSize
	glowScale = glow.scale * headSize * Vector2(1.0 + stretch, 1.0)
	coreScale = core.scale * headSize * Vector2(1.0 + stretch * 1.5, 1.0)
	flareScale = flare.scale * headSize * style.flare
	glow.self_modulate = Color(colors[1], glow.self_modulate.a)
	core.self_modulate = Color(colors[2], core.self_modulate.a)
	flare.self_modulate = Color(colors[2], flare.self_modulate.a)
	flare.visible = style.flare > 0.0
	trail.material = trailMaterial
	trail.length = style.trailLength
	trail.width = style.trailWidth * size * SpellAttackClass.TRAIL_PADDING
	update_head()

func _process(_delta : float) -> void:
	update_head()

func _physics_process(delta : float) -> void:
	age += delta
	if ended:
		if age - endAge >= maxf(fadeTime, trail.length):
			queue_free()
		return
	if age < holdTime:
		hover()
		return
	if not launched:
		launched = true
		monitoring = true
		carrier = start
		if not trail.emitting:
			trail.clear()
			trail.emitting = true
	flightAge += delta
	var newProgress : float = minf(flightAge / flightTime, 1.0)
	steer(delta, newProgress)
	var travel : float = motion.get_travel(newProgress) * flightDistance
	carrier += Vector2.from_angle(heading) * (travel - travelled)
	travelled = travel
	var next : Vector2 = carrier
	if not bounced:
		next += motion.get_offset(newProgress, side, phase).rotated(heading)
	if next.distance_squared_to(global_position) > 0.0001:
		rotation = global_position.angle_to_point(next)
	global_position = next
	progress = newProgress
	if progress >= 1.0:
		finish(false)

func hover() -> void:
	var settleTime : float = maxf(motion.holdTime * 0.7, 0.05)
	var settle : float = Tween.interpolate_value(0.0, 1.0, minf(age, settleTime), settleTime, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	global_position = castOrigin.lerp(start, settle) + Vector2(0.0, sin(age * 9.0 + phase) * 0.7 * settle)

func steer(delta : float, newProgress : float) -> void:
	var turnSpeed : float = bounceTurnSpeed if bounced else motion.homing + homing
	if turnSpeed <= 0.0 or (newProgress < motion.homingStart and not bounced):
		return
	seekTimer -= delta
	if seekTimer <= 0.0 or not is_instance_valid(target) or target.is_dead():
		seekTimer = 0.1
		target = find_target(bounceRange if bounced else motion.homingRange)
	if is_instance_valid(target):
		heading = rotate_toward(heading, carrier.angle_to_point(target.global_position), turnSpeed * delta)

func find_target(radius : float) -> HurtboxComponentClass:
	var closest : HurtboxComponentClass = null
	for hurtbox in HurtboxComponentClass.find_in_radius(get_world_2d(), global_position, radius, collision_mask, 8):
		if hitTargets.has(hurtbox) or hurtbox.is_dead():
			continue
		if not closest or global_position.distance_squared_to(hurtbox.global_position) < global_position.distance_squared_to(closest.global_position):
			closest = hurtbox
	return closest

func on_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	hitTargets.append(hurtbox)
	if is_instance_valid(attack):
		attack.register_hit(hurtbox, hitDamage)
	play_impact(hurtbox.global_position)
	if ended or maxHits <= 0 or hitCount < maxHits:
		return
	if bounces > 0 and bounce():
		return
	finish(true)

func on_body_entered(_body : Node2D) -> void:
	if ended:
		return
	play_impact(global_position)
	finish(true)

func bounce() -> bool:
	var next : HurtboxComponentClass = find_target(bounceRange)
	if not next:
		return false
	bounces -= 1
	maxHits += 1
	bounced = true
	target = next
	seekTimer = 0.1
	carrier = global_position
	heading = carrier.angle_to_point(next.global_position)
	travelled = 0.0
	flightAge = 0.0
	flightDistance = carrier.distance_to(next.global_position) + 12.0
	flightTime = maxf(flightDistance / maxf(speed2D, 1.0), 0.08)
	Vfx.show_hit_spark(global_position, colors[2], 0.5 * size, 2, heading)
	return true

func play_impact(spot : Vector2) -> void:
	Vfx.show_hit_spark(spot, colors[1], style.hitSparkSize * size, style.hitSparkAmount, rotation + PI / 2.0)
	if style.impactScene:
		Vfx.spawn_effect(style.impactScene, spot, 10.0 * size * style.impactSize, colors[1], null, rotation)
	GameFeel.hit_stop(style.hitStop)
	GameFeel.shake(style.screenShake)

func finish(impact : bool) -> void:
	ended = true
	endAge = age
	trail.emitting = false
	set_deferred("monitoring", false)
	if not impact:
		Vfx.show_hit_spark(global_position, colors[1], 0.35 * size, 2, rotation + PI / 2.0)

func update_head() -> void:
	var grow : float = 1.0
	if age < holdTime:
		grow = Tween.interpolate_value(0.0, 0.8, minf(age, 0.14), 0.14, Tween.TRANS_BACK, Tween.EASE_OUT)
	if ended:
		grow = 1.0 - clampf((age - endAge) / fadeTime, 0.0, 1.0)
	var pulse : float = 1.0 + sin(age * pulseSpeed + phase) * 0.08
	if age < holdTime:
		pulse *= 0.75
	glow.scale = glowScale * grow * pulse
	core.scale = coreScale * grow
	flare.scale = flareScale * grow * (1.0 + sin(age * 13.0 + phase) * 0.18)
	flare.rotation = age * 5.0 + phase
