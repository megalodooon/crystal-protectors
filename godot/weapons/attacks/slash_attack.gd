extends AttackClass
class_name SlashAttackClass


const SLASH_SCENE := preload("res://weapons/attacks/slash.tscn")
const ATTACK_TYPE := preload("res://weapons/attacks/slash_type.tres")

@export var radius : float = 17.0
@export var size : float = 14.0
@export_range(10.0, 360.0, 1.0, "suffix:°") var curve : float = 160.0
@export var maxTargets : int = 3
@export var raritySizeGrowth : float = 1.0
@export var swingsWeapon : bool = true
@export var colorTexture : Texture2D
@export var styleOverride : SlashStyleClass

static var colorCache : Dictionary = {}

var swingDirection : float = 1.0
var swingTween : Tween

#------------------------#

func perform() -> void:
	var style : SlashStyleClass = get_style()
	var totalCurve : float = minf(curve + style.curveBonus + weapon.get_stat(AttributeClass.Stat.ATTACK_ARC), 360.0)
	var sizeMultiplier : float = (1.0 + (style.sizeMultiplier - 1.0) * raritySizeGrowth) * (1.0 + weapon.get_stat(AttributeClass.Stat.ATTACK_SIZE))
	var centerAngle : float = 0.0
	if totalCurve >= 360.0:
		centerAngle = PI
	var slash : SlashClass = SLASH_SCENE.instantiate()
	slash.attack = self
	slash.style = style
	slash.colors = get_blade_colors()
	slash.radius = radius * sizeMultiplier
	slash.size = size * sizeMultiplier
	slash.curve = totalCurve
	slash.maxTargets = maxTargets + roundi(weapon.get_stat(AttributeClass.Stat.EXTRA_TARGETS))
	slash.swingDirection = swingDirection
	slash.rotation = global_rotation - weapon.swingRotation + centerAngle
	if weapon.wielder:
		weapon.wielder.add_child(slash)
	else:
		slash.position = global_position
		get_tree().current_scene.add_child(slash)
	if swingsWeapon:
		swing_weapon(style.duration * 0.7, totalCurve, centerAngle)
	swingDirection *= -1.0

func swing_weapon(duration : float, totalCurve : float, centerAngle : float) -> void:
	if swingTween:
		swingTween.kill()
	var halfCurve : float = deg_to_rad(totalCurve) / 2.0 * swingDirection
	var endRotation : float = centerAngle + halfCurve
	weapon.isSwinging = true
	weapon.swingRotation = centerAngle - halfCurve
	weapon.visuals.rotation = 0.0
	swingTween = create_tween()
	swingTween.tween_property(weapon, "swingRotation", endRotation, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	swingTween.tween_property(weapon, "swingRotation", 0.0, 0.2).from(wrapf(endRotation, -PI, PI)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swingTween.parallel().tween_property(weapon.visuals, "rotation", weapon.get_hold_rotation(), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swingTween.tween_callback(func() -> void: weapon.isSwinging = false)

func get_attack_type() -> AttackTypeClass:
	return ATTACK_TYPE

func get_color() -> Color:
	return get_blade_colors()[1]

func get_style() -> SlashStyleClass:
	if styleOverride:
		return styleOverride
	if weapon.rarity and weapon.rarity.slashStyle:
		return weapon.rarity.slashStyle
	return SlashStyleClass.new()

func get_blade_colors() -> Array[Color]:
	var texture : Texture2D = colorTexture
	if not texture:
		for child in weapon.visuals.get_children():
			if child is Sprite2D and child.texture:
				texture = child.texture
				break
	if not texture:
		return [Color.WHITE, Color.WHITE, Color.WHITE]
	if not colorCache.has(texture):
		colorCache[texture] = extract_colors(texture)
	return colorCache[texture]

func extract_colors(texture : Texture2D) -> Array[Color]:
	var image : Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	var pixels : Array[Color] = []
	for y in image.get_height():
		for x in image.get_width():
			var pixel : Color = image.get_pixel(x, y)
			if pixel.a > 0.5:
				pixels.append(pixel)
	if pixels.is_empty():
		return [Color.WHITE, Color.WHITE, Color.WHITE]
	pixels.sort_custom(func(a : Color, b : Color) -> bool: return a.get_luminance() < b.get_luminance())
	var dark : Color = pixels[int(pixels.size() * 0.35)]
	var main : Color = pixels[int(pixels.size() * 0.7)]
	var light : Color = pixels[pixels.size() - 1]
	return [
		Color.from_hsv(dark.h, dark.s, maxf(dark.v, 0.35)),
		Color.from_hsv(main.h, minf(main.s * 1.2, 1.0), maxf(main.v, 0.75)),
		Color.from_hsv(light.h, light.s * 0.6, 1.0),
	]
