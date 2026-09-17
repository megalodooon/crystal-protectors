extends Node2D
class_name WeaponClass


const ENCHANT_SCENE := preload("res://weapons/enchant/enchant.tscn")

@export var rarity : RarityClass
@export var damage : float = 10.0
@export var attackCooldown : float = 0.5
@export var damageType : DamageTypeClass
@export_range(0.0, 1.0) var critChance : float = 0.1
@export var critMultiplier : float = 2.0
@export var knockback : float = 0.0
@export var effects : Array[WeaponEffectClass]
@export var fixedAttributes : Array[AttributeRollClass]
@export_range(-180.0, 180.0, 1.0, "suffix:°") var holdAngle : float = -100.0
@export var holdSpeed : float = 20.0

@onready var visuals : Node2D = $Visuals

var wielder : Node2D
var item : WeaponItemClass
var attributes : Array[AttributeRollClass]
var canAttack : bool = true
var isSwinging : bool = false
var swingRotation : float = 0.0
var aimRotation : float = 0.0
var activeEffects : Array[WeaponEffectClass]
var hitStatuses : Dictionary[String, StatusEffectClass] = {}
var buffs : Dictionary[AttributeRollClass, AttributeBuffClass] = {}
var attackCount : int = 0

#------------------------#

func _ready() -> void:
	for attackNode in get_attacks():
		attackNode.weapon = self
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
	for roll in attributes:
		roll.attribute.on_equip(self, roll)

func _process(delta : float) -> void:
	update_buffs(delta)
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

func get_attacks() -> Array[AttackClass]:
	var attacks : Array[AttackClass] = []
	for child in get_children():
		if child is AttackClass:
			attacks.append(child)
	return attacks

func get_color() -> Color:
	var attacks : Array[AttackClass] = get_attacks()
	if not attacks.is_empty():
		return attacks[0].get_color()
	if rarity:
		return rarity.color
	return Color.WHITE

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
	attackCount += 1
	aimRotation = global_rotation - swingRotation
	for attackNode in get_attacks():
		attackNode.perform()
	for effect in activeEffects:
		effect.on_attack(self)
	for roll in attributes:
		roll.attribute.on_attack(self, roll)
	get_tree().create_timer(get_attack_cooldown(), true, false, true).timeout.connect(end_cooldown)

func end_cooldown() -> void:
	canAttack = true

func setup_hitbox(hitbox : HitboxComponentClass, damageMultiplier : float = 1.0) -> void:
	var attackDamage : float = get_damage() * damageMultiplier
	for roll in attributes:
		attackDamage = roll.attribute.modify_attack_damage(self, roll, attackDamage)
	hitbox.damage = attackDamage
	hitbox.damageType = damageType
	hitbox.critChance = get_crit_chance()
	hitbox.critMultiplier = get_crit_multiplier()
	hitbox.damageModifier = modify_hit_damage

func modify_hit_damage(hurtbox : HurtboxComponentClass, hitDamage : float) -> float:
	for roll in attributes:
		hitDamage = roll.attribute.modify_hit_damage(self, roll, hurtbox, hitDamage)
	return hitDamage

func register_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	if not is_instance_valid(hurtbox):
		return
	var killed : bool = hurtbox.is_dead()
	for effect in activeEffects:
		effect.on_hit(self, hurtbox, hitDamage)
	for roll in attributes:
		roll.attribute.on_hit(self, roll, hurtbox, hitDamage)
	if killed:
		for roll in attributes:
			roll.attribute.on_kill(self, roll, hurtbox, hitDamage)
	apply_knockback(hurtbox)
	var durationMultiplier : float = 1.0 + get_stat(AttributeClass.Stat.STATUS_DURATION)
	for status : StatusEffectClass in hitStatuses.values():
		status.duration *= durationMultiplier
		hurtbox.apply_status(status)
	hitStatuses.clear()

func add_hit_status(status : StatusEffectClass) -> void:
	if hitStatuses.has(status.effectName):
		hitStatuses[status.effectName].combine(status)
	else:
		hitStatuses[status.effectName] = status

func add_buff(roll : AttributeRollClass, stat : AttributeClass.Stat, duration : float, maxStacks : int) -> void:
	if not buffs.has(roll):
		var newBuff : AttributeBuffClass = AttributeBuffClass.new()
		newBuff.roll = roll
		buffs[roll] = newBuff
	var buff : AttributeBuffClass = buffs[roll]
	buff.stat = stat
	buff.stacks = mini(buff.stacks + 1, maxi(maxStacks, 1))
	buff.timeLeft = duration

func update_buffs(delta : float) -> void:
	for roll : AttributeRollClass in buffs.keys():
		buffs[roll].timeLeft -= delta
		if buffs[roll].timeLeft <= 0.0:
			buffs.erase(roll)

func apply_knockback(hurtbox : HurtboxComponentClass) -> void:
	var force : float = get_knockback()
	if force <= 0.0 or not wielder:
		return
	hurtbox.knockback(wielder.global_position.direction_to(hurtbox.global_position) * force)

func get_attribute_level() -> int:
	if item:
		return item.get_attribute_level()
	return 0

func get_stat(stat : AttributeClass.Stat) -> float:
	var total : float = 0.0
	var level : int = get_attribute_level()
	for roll in attributes:
		if roll.attribute.stat == stat:
			total += roll.get_value(level)
	for buff : AttributeBuffClass in buffs.values():
		if buff.stat == stat:
			total += buff.get_value(level)
	return total

func get_damage() -> float:
	return damage * get_power_multiplier()

func get_power_multiplier() -> float:
	var multiplier : float = 1.0 + get_stat(AttributeClass.Stat.DAMAGE)
	if rarity:
		multiplier *= rarity.damageMultiplier
	if item:
		multiplier *= item.get_damage_multiplier()
	return multiplier

func get_status_power() -> float:
	return get_power_multiplier() * (1.0 + get_stat(AttributeClass.Stat.STATUS_DAMAGE))

func get_crit_chance() -> float:
	return critChance + get_stat(AttributeClass.Stat.CRIT_CHANCE)

func get_crit_multiplier() -> float:
	return critMultiplier + get_stat(AttributeClass.Stat.CRIT_DAMAGE)

func get_attack_cooldown() -> float:
	return attackCooldown / (1.0 + get_stat(AttributeClass.Stat.ATTACK_SPEED))

func get_knockback() -> float:
	return knockback + get_stat(AttributeClass.Stat.KNOCKBACK)
