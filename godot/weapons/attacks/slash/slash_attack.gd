extends AttackClass
class_name SlashAttackClass


const SLASH_SCENE := preload("res://weapons/attacks/slash/slash.tscn")

@export var radius : float = 17.0
@export var size : float = 14.0
@export_range(10.0, 360.0, 1.0, "suffix:°") var curve : float = 160.0
@export var styleOverride : SlashStyleClass

static var colorCache : Dictionary = {}

var swingDirection : float = 1.0
var swingTween : Tween

#------------------------#

func perform() -> void:
	var style : SlashStyleClass = get_style()
	var totalCurve : float = minf(curve + style.curveBonus, 360.0)
	var slash : SlashClass = SLASH_SCENE.instantiate()
	slash.attack = self
	slash.style = style
	slash.colors = get_blade_colors()
	slash.radius = radius * style.sizeMultiplier
	slash.size = size * style.sizeMultiplier
	slash.curve = totalCurve
	slash.swingDirection = swingDirection
	slash.rotation = global_rotation
	if weapon.wielder:
		weapon.wielder.add_child(slash)
	else:
		slash.position = global_position
		get_tree().current_scene.add_child(slash)
	swing_weapon(style.duration * 0.7, totalCurve)
	swingDirection *= -1.0

func swing_weapon(duration : float, totalCurve : float) -> void:
	if swingTween:
		swingTween.kill()
	var halfCurve : float = deg_to_rad(totalCurve) / 2.0 * swingDirection
	weapon.visuals.rotation = -halfCurve
	swingTween = create_tween()
	swingTween.tween_property(weapon.visuals, "rotation", halfCurve, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	swingTween.tween_property(weapon.visuals, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func get_style() -> SlashStyleClass:
	if styleOverride:
		return styleOverride
	if weapon.rarity and weapon.rarity.slashStyle:
		return weapon.rarity.slashStyle
	return SlashStyleClass.new()

func get_blade_colors() -> Array[Color]:
	for child in weapon.visuals.get_children():
		if child is Sprite2D and child.texture:
			if not colorCache.has(child.texture):
				colorCache[child.texture] = extract_colors(child.texture)
			return colorCache[child.texture]
	return [Color.WHITE, Color.WHITE, Color.WHITE]

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
