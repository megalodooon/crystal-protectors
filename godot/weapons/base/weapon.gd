extends Node2D
class_name WeaponClass


const ENCHANT_SCENE := preload("res://weapons/enchant/enchant.tscn")

@export var rarity : RarityClass
@export var damage : float = 10.0
@export var attackCooldown : float = 0.5
@export var damageType : DamageTypeClass
@export_range(0.0, 1.0) var critChance : float = 0.1
@export var critMultiplier : float = 2.0
@export var effects : Array[WeaponEffectClass]
@export_range(-180.0, 180.0, 1.0, "suffix:°") var holdAngle : float = -100.0
@export var holdSpeed : float = 20.0

@onready var visuals : Node2D = $Visuals

var wielder : Node2D
var canAttack : bool = true
var isSwinging : bool = false
var swingRotation : float = 0.0
var activeEffects : Array[WeaponEffectClass]

#------------------------#

func _ready() -> void:
	for child in get_children():
		if child is AttackClass:
			child.weapon = self
	for effect in effects:
		activeEffects.append(effect.duplicate())
	if rarity:
		for effect in rarity.effects:
			activeEffects.append(effect.duplicate())
	update_flip()
	visuals.rotation = get_hold_rotation()
	add_enchant()
	for effect in activeEffects:
		effect.on_equip(self)

func _process(delta : float) -> void:
	if not isSwinging:
		update_flip()
		visuals.rotation = lerp_angle(visuals.rotation, get_hold_rotation(), minf(holdSpeed * delta, 1.0))

func update_flip() -> void:
	if Vector2.from_angle(global_rotation).x > 0.0:
		scale.y = -1.0
	else:
		scale.y = 1.0

func get_hold_rotation() -> float:
	var angle : float = deg_to_rad(holdAngle)
	if scale.y > 0.0:
		angle = PI - angle
	return wrapf((angle - global_rotation) * scale.y, -PI, PI)

func add_enchant() -> void:
	var sprite : Sprite2D = get_sprite()
	if not rarity or not rarity.enchantStyle or not sprite:
		return
	var enchant : EnchantClass = ENCHANT_SCENE.instantiate()
	enchant.style = rarity.enchantStyle
	enchant.color = rarity.color
	enchant.texture = sprite.texture
	enchant.points = get_pixel_points(sprite.texture)
	sprite.add_child(enchant)

func get_sprite() -> Sprite2D:
	for child in visuals.get_children():
		if child is Sprite2D and child.texture:
			return child
	return null

static func get_pixel_points(texture : Texture2D, bladeOnly : bool = false) -> PackedVector2Array:
	var image : Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	var halfSize : Vector2 = Vector2(image.get_size()) / 2.0
	var points : PackedVector2Array = []
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.5 and (not bladeOnly or x - y >= -1):
				points.append(Vector2(x, y) + Vector2(0.5, 0.5) - halfSize)
	return points

func attack() -> void:
	if not canAttack:
		return
	canAttack = false
	for child in get_children():
		if child is AttackClass:
			child.perform()
	for effect in activeEffects:
		effect.on_attack(self)
	get_tree().create_timer(attackCooldown).timeout.connect(end_cooldown)

func end_cooldown() -> void:
	canAttack = true

func register_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	for effect in activeEffects:
		effect.on_hit(self, hurtbox, hitDamage)

func get_damage() -> float:
	if rarity:
		return damage * rarity.damageMultiplier
	return damage
