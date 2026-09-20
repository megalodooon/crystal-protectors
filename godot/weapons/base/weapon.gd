extends Node2D
class_name WeaponClass


const ENCHANT_SCENE := preload("res://weapons/enchant/enchant.tscn")
const MAX_AURAS : int = 1

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
var synergies : Array[AttributeRollClass]
var canAttack : bool = true
var isSwinging : bool = false
var swingRotation : float = 0.0
var aimRotation : float = 0.0
var activeEffects : Array[WeaponEffectClass]
var hitStatuses : Dictionary[String, StatusEffectClass] = {}
var buffs : Dictionary[AttributeRollClass, AttributeBuffClass] = {}
var attackCount : int = 0
var cooldownId : int = 0
var lastAttackTime : int = -100000
var attackIdleTime : float = 100.0
var auraScenes : Array[PackedScene] = []
var statCache : Dictionary[AttributeClass.Stat, float] = {}
var statCacheFrame : int = -1

#------------------------#

func _ready() -> void:
	for attackNode in get_attacks():
		attackNode.weapon = self
	for effect in get_all_effects():
		activeEffects.append(effect.duplicate())
	update_flip()
	visuals.rotation = get_hold_rotation()
	add_enchant()
	for effect in activeEffects:
		effect.on_equip(self)
	for roll in get_rolls():
		roll.attribute.on_equip(self, roll)

func _exit_tree() -> void:
	for buff : AttributeBuffClass in buffs.values():
		if is_instance_valid(buff.visual):
			buff.visual.stop()
	buffs.clear()

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

func get_rolls() -> Array[AttributeRollClass]:
	var rolls : Array[AttributeRollClass] = attributes.duplicate()
	rolls.append_array(synergies)
	return rolls

func get_all_effects() -> Array[WeaponEffectClass]:
	var allEffects : Array[WeaponEffectClass] = effects.duplicate()
	if rarity:
		allEffects.append_array(rarity.effects)
	return allEffects

func get_origin() -> Vector2:
	if wielder:
		return wielder.global_position
	return global_position

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
	var now : int = Time.get_ticks_msec()
	attackIdleTime = (now - lastAttackTime) / 1000.0
	lastAttackTime = now
	aimRotation = global_rotation - swingRotation
	for attackNode in get_attacks():
		attackNode.perform()
	for effect in activeEffects:
		effect.on_attack(self)
	for roll in get_rolls():
		roll.attribute.on_attack(self, roll)
	cooldownId += 1
	get_tree().create_timer(get_attack_cooldown(), true, false, true).timeout.connect(end_cooldown.bind(cooldownId))

func end_cooldown(id : int) -> void:
	if id == cooldownId:
		canAttack = true

func reset_cooldown() -> void:
	cooldownId += 1
	canAttack = true

func on_attribute_proc(source : AttributeRollClass, hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	for roll in synergies:
		if roll.attribute.procSource == source.attribute:
			roll.attribute.try_proc(AttributeClass.Trigger.PROC, self, roll, hurtbox, hitDamage)

func roll_chance(chance : float) -> bool:
	return randf() < chance * (1.0 + get_stat(AttributeClass.Stat.EFFECT_CHANCE))

func setup_hitbox(hitbox : HitboxComponentClass, damageMultiplier : float = 1.0) -> void:
	var attackDamage : float = get_damage() * damageMultiplier
	for roll in get_rolls():
		attackDamage = roll.attribute.modify_attack_damage(self, roll, attackDamage)
	hitbox.damage = attackDamage
	hitbox.damageType = damageType
	hitbox.critChance = get_crit_chance()
	hitbox.critMultiplier = get_crit_multiplier()
	hitbox.damageModifier = modify_hit_damage

func modify_hit_damage(hurtbox : HurtboxComponentClass, hitDamage : float) -> float:
	for roll in get_rolls():
		hitDamage = roll.attribute.modify_hit_damage(self, roll, hurtbox, hitDamage)
	return hitDamage

func register_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	if not is_instance_valid(hurtbox):
		return
	var killed : bool = hurtbox.lastHitKilled
	var crit : bool = hurtbox.lastHitCrit
	for effect in activeEffects:
		effect.on_hit(self, hurtbox, hitDamage)
	var rolls : Array[AttributeRollClass] = get_rolls()
	for roll in rolls:
		roll.attribute.on_hit(self, roll, hurtbox, hitDamage)
	if crit:
		for roll in rolls:
			roll.attribute.on_crit(self, roll, hurtbox, hitDamage)
	if killed:
		for roll in rolls:
			roll.attribute.on_kill(self, roll, hurtbox, hitDamage)
	apply_knockback(hurtbox)
	for status : StatusEffectClass in hitStatuses.values():
		apply_status(hurtbox, status)
	hitStatuses.clear()

func apply_status(hurtbox : HurtboxComponentClass, status : StatusEffectClass) -> void:
	status.duration *= 1.0 + get_stat(AttributeClass.Stat.STATUS_DURATION)
	hurtbox.apply_status(status)

func add_hit_status(status : StatusEffectClass) -> void:
	if hitStatuses.has(status.effectName):
		hitStatuses[status.effectName].combine(status)
	else:
		hitStatuses[status.effectName] = status

func add_buff(roll : AttributeRollClass, stat : AttributeClass.Stat, duration : float, maxStacks : int, visualScene : PackedScene = null) -> void:
	if not buffs.has(roll):
		var newBuff : AttributeBuffClass = AttributeBuffClass.new()
		newBuff.roll = roll
		buffs[roll] = newBuff
		if visualScene:
			newBuff.visual = visualScene.instantiate()
			get_visual_holder().add_child(newBuff.visual)
	var buff : AttributeBuffClass = buffs[roll]
	buff.stat = stat
	buff.stacks = mini(buff.stacks + 1, maxi(maxStacks, 1))
	buff.timeLeft = duration
	statCacheFrame = -1
	if is_instance_valid(buff.visual):
		buff.visual.set_stacks(buff.stacks, maxStacks)

func update_buffs(delta : float) -> void:
	for roll : AttributeRollClass in buffs.keys():
		buffs[roll].timeLeft -= delta
		if buffs[roll].timeLeft <= 0.0:
			remove_buff(roll)

func remove_buff(roll : AttributeRollClass) -> void:
	if not buffs.has(roll):
		return
	if is_instance_valid(buffs[roll].visual):
		buffs[roll].visual.stop()
	buffs.erase(roll)
	statCacheFrame = -1

func add_aura(scene : PackedScene) -> void:
	var sprite : Sprite2D = get_sprite()
	if not scene or not sprite or auraScenes.has(scene) or auraScenes.size() >= MAX_AURAS:
		return
	auraScenes.append(scene)
	var aura : WeaponAuraClass = scene.instantiate()
	aura.texture = sprite.texture
	aura.points = get_pixel_points(sprite.texture, true)
	sprite.add_child(aura)

func get_visual_holder() -> Node2D:
	if wielder:
		return wielder
	return self

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
	var frame : int = Engine.get_process_frames()
	if frame != statCacheFrame:
		statCacheFrame = frame
		statCache.clear()
	if statCache.has(stat):
		return statCache[stat]
	var total : float = 0.0
	var level : int = get_attribute_level()
	for roll in get_rolls():
		total += roll.attribute.get_stat_bonus(stat, roll.quality, level)
	for buff : AttributeBuffClass in buffs.values():
		if buff.stat == stat:
			total += buff.get_value(level)
	statCache[stat] = total
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

func get_area_multiplier() -> float:
	return 1.0 + get_stat(AttributeClass.Stat.EFFECT_AREA)

func get_effect_damage_multiplier() -> float:
	return 1.0 + get_stat(AttributeClass.Stat.EFFECT_DAMAGE)
