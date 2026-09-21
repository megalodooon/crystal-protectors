extends AttackClass
class_name SpellAttackClass


const ATTACK_TYPE := preload("res://weapons/attacks/spell_type.tres")
const TRAIL_MATERIAL := preload("res://weapons/attacks/spell_trail.tres")
const TRAIL_PADDING : float = 3.0

@export var boltScene : PackedScene
@export var motion : SpellMotionClass
@export var count : int = 1
@export_range(0.0, 360.0, 1.0, "suffix:°") var spread : float = 0.0
@export var volleyDelay : float = 0.0
@export var size : float = 1.0
@export var pierce : int = 1
@export var raritySizeGrowth : float = 1.0
@export var headStretch : float = 0.0
@export var boltColor : Color = Color(0.0, 0.0, 0.0, 0.0)
@export var colorTexture : Texture2D
@export var styleOverride : SpellStyleClass

@export_group("Cast")
@export var pointsWeapon : bool = true
@export var recoil : float = 1.5
@export var flashTexture : Texture2D
@export var starTexture : Texture2D
@export var flashSize : float = 14.0
@export var flashTime : float = 0.18

var castSide : float = 1.0
var castTween : Tween
var flash : float = 0.0
var pending : Array[Vector4] = []
var defaultStyle : SpellStyleClass
var trailMaterial : ShaderMaterial
var trailStyle : SpellStyleClass
var spellColors : Array[Color] = []

#------------------------#

func _ready() -> void:
	set_process(false)

func _process(delta : float) -> void:
	flash = move_toward(flash, 0.0, delta / maxf(flashTime, 0.01))
	queue_redraw()
	if flash <= 0.0:
		set_process(false)

func _physics_process(delta : float) -> void:
	for i in range(pending.size() - 1, -1, -1):
		pending[i].x -= delta
		if pending[i].x <= 0.0:
			var entry : Vector4 = pending[i]
			pending.remove_at(i)
			spawn_bolt(int(entry.y), int(entry.z), entry.w)

func _draw() -> void:
	if flash <= 0.0:
		return
	var style : SpellStyleClass = get_style()
	var colors : Array[Color] = get_spell_colors()
	var strength : float = flash * style.castFlash
	if flashTexture:
		var glowSize : float = flashSize * (0.6 + (1.0 - flash) * 0.6) * style.castFlash
		draw_texture_rect(flashTexture, Rect2(-Vector2.ONE * glowSize / 2.0, Vector2.ONE * glowSize), false, Color(colors[1], strength * 0.8))
	if starTexture:
		var starSize : float = flashSize * flash * style.castFlash
		draw_set_transform(Vector2.ZERO, (1.0 - flash) * 1.2)
		draw_texture_rect(starTexture, Rect2(-Vector2.ONE * starSize / 2.0, Vector2.ONE * starSize), false, Color(colors[2], strength))
		draw_set_transform(Vector2.ZERO)

func perform() -> void:
	var total : int = maxi(count + roundi(weapon.get_stat(AttributeClass.Stat.EXTRA_PROJECTILES)), 1)
	for i in total:
		if volleyDelay * i <= 0.0:
			spawn_bolt(i, total, castSide)
		else:
			pending.append(Vector4(volleyDelay * i, i, total, castSide))
	castSide *= -1.0
	flash = 1.0
	set_process(true)
	queue_redraw()
	if pointsWeapon:
		point_weapon()

func spawn_bolt(index : int, total : int, side : float) -> void:
	if not boltScene:
		return
	var style : SpellStyleClass = get_style()
	var aim : float = global_rotation - weapon.swingRotation
	var heading : float = aim
	if total > 1:
		heading += deg_to_rad(lerpf(-spread / 2.0, spread / 2.0, float(index) / (total - 1)))
	var start : Vector2 = global_position + motion.get_spawn_offset(index, total).rotated(aim)
	if motion.convergeDistance > 0.0:
		heading = start.angle_to_point(global_position + Vector2.from_angle(aim) * motion.convergeDistance)
	var bolt : SpellBoltClass = boltScene.instantiate()
	bolt.attack = self
	bolt.weapon = weapon
	bolt.motion = motion
	bolt.style = style
	bolt.colors = get_spell_colors()
	bolt.color = bolt.colors[1]
	bolt.trailMaterial = get_trail_material(style)
	bolt.size = get_bolt_size(style)
	bolt.stretch = headStretch
	bolt.side = side * (lerpf(-1.0, 1.0, float(index) / (total - 1)) if total > 1 else 1.0)
	bolt.phase = TAU * index / total
	bolt.holdTime = motion.get_hold_time(index)
	bolt.castOrigin = global_position
	bolt.speedScale = 1.0 + weapon.get_stat(AttributeClass.Stat.PROJECTILE_SPEED)
	bolt.distanceScale = 1.0 + weapon.get_stat(AttributeClass.Stat.PROJECTILE_RANGE)
	bolt.homing = weapon.get_stat(AttributeClass.Stat.HOMING)
	bolt.bounces = roundi(weapon.get_stat(AttributeClass.Stat.BOUNCES))
	setup_hitbox(bolt)
	bolt.maxHits = maxi(pierce, 1) + roundi(weapon.get_stat(AttributeClass.Stat.PIERCE))
	bolt.position = start
	bolt.rotation = heading
	get_tree().current_scene.add_child(bolt)

func point_weapon() -> void:
	if castTween:
		castTween.kill()
	var visuals : Node2D = weapon.visuals
	weapon.update_flip()
	weapon.isSwinging = true
	castTween = create_tween()
	castTween.tween_property(visuals, "rotation", 0.0, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	castTween.parallel().tween_property(visuals, "position:x", -recoil, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	castTween.tween_property(visuals, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	castTween.tween_interval(maxf(weapon.get_attack_cooldown() - 0.1, 0.05))
	castTween.tween_callback(func() -> void: weapon.isSwinging = false)

func get_attack_type() -> AttackTypeClass:
	return ATTACK_TYPE

func uses_stat(stat : AttributeClass.Stat) -> bool:
	return stat in [AttributeClass.Stat.ATTACK_SIZE, AttributeClass.Stat.EXTRA_PROJECTILES, AttributeClass.Stat.PIERCE, AttributeClass.Stat.PROJECTILE_SPEED, AttributeClass.Stat.PROJECTILE_RANGE, AttributeClass.Stat.HOMING, AttributeClass.Stat.BOUNCES]

func get_color() -> Color:
	return get_spell_colors()[1]

func get_style() -> SpellStyleClass:
	if styleOverride:
		return styleOverride
	if weapon.rarity and weapon.rarity.spellStyle:
		return weapon.rarity.spellStyle
	if not defaultStyle:
		defaultStyle = SpellStyleClass.new()
	return defaultStyle

func get_bolt_size(style : SpellStyleClass) -> float:
	return size * (1.0 + (style.sizeMultiplier - 1.0) * raritySizeGrowth) * (1.0 + weapon.get_stat(AttributeClass.Stat.ATTACK_SIZE))

func get_trail_material(style : SpellStyleClass) -> ShaderMaterial:
	if not trailMaterial or trailStyle != style:
		trailStyle = style
		trailMaterial = make_trail_material(style, get_spell_colors())
	return trailMaterial

static func make_trail_material(style : SpellStyleClass, colors : Array[Color]) -> ShaderMaterial:
	var newMaterial : ShaderMaterial = TRAIL_MATERIAL.duplicate()
	newMaterial.set_shader_parameter("darkColor", colors[0])
	newMaterial.set_shader_parameter("mainColor", colors[1])
	newMaterial.set_shader_parameter("lightColor", colors[2])
	newMaterial.set_shader_parameter("padding", TRAIL_PADDING)
	newMaterial.set_shader_parameter("glow", style.glow)
	newMaterial.set_shader_parameter("core", style.core)
	newMaterial.set_shader_parameter("streaks", style.streaks)
	newMaterial.set_shader_parameter("helix", style.helix)
	newMaterial.set_shader_parameter("sparkles", style.sparkles)
	newMaterial.set_shader_parameter("chromatic", style.chromaticAberration)
	return newMaterial

func get_spell_colors() -> Array[Color]:
	if spellColors.is_empty():
		spellColors = get_color_set(find_bolt_color())
	return spellColors

func find_bolt_color() -> Color:
	if boltColor.a > 0.0:
		return boltColor
	var texture : Texture2D = colorTexture
	if not texture and weapon.get_sprite():
		texture = weapon.get_sprite().texture
	if not texture:
		return Color(0.6, 0.5, 1.0)
	return extract_color(texture)

static func get_color_set(main : Color) -> Array[Color]:
	return [
		Color.from_hsv(main.h, minf(main.s * 1.1, 1.0), clampf(main.v * 0.5, 0.3, 0.6)),
		Color.from_hsv(main.h, minf(main.s * 1.05, 1.0), maxf(main.v, 0.85)),
		Color.from_hsv(main.h, main.s * 0.35, 1.0),
	]

static func extract_color(texture : Texture2D) -> Color:
	var image : Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	var best : Color = Color(0.6, 0.5, 1.0)
	var bestScore : float = -1.0
	for y in image.get_height():
		for x in image.get_width():
			var pixel : Color = image.get_pixel(x, y)
			var score : float = pixel.s * pixel.v
			if pixel.a > 0.5 and score > bestScore:
				best = pixel
				bestScore = score
	return best
