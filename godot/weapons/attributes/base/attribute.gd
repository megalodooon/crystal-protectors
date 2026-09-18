extends Resource
class_name AttributeClass


enum Stat { NONE, DAMAGE, CRIT_CHANCE, CRIT_DAMAGE, ATTACK_SPEED, KNOCKBACK, ATTACK_SIZE, ATTACK_ARC, EXTRA_TARGETS, STATUS_DAMAGE, MOVE_SPEED, STATUS_DURATION, EFFECT_CHANCE, EFFECT_AREA, EFFECT_DAMAGE, PIERCE, EXTRA_PROJECTILES }
enum Trigger { NONE, ATTACK, HIT, CRIT, KILL, PROC }

@export var attributeName : String
@export var description : String = "+{value} {name}"
@export var stat : Stat = Stat.NONE
@export var scaling : AttributeScalingClass
@export var trigger : Trigger = Trigger.NONE
@export var chanceScaling : AttributeScalingClass
@export var effectScene : PackedScene
@export var auraScene : PackedScene
@export var attackTypes : Array[AttackTypeClass]
@export var special : bool = false
@export var inRandomPool : bool = true
@export var weight : float = 1.0
@export var requiredAttributes : Array[Resource]
@export var procSource : Resource

#------------------------#

static func is_stat_used(weapon : WeaponClass, chosen : Array[AttributeClass], usedStat : Stat) -> bool:
	for effect in weapon.get_all_effects():
		if effect.uses_stat(usedStat):
			return true
	for attribute in chosen:
		if attribute.uses_stat(usedStat):
			return true
	return false

static func get_statuses(weapon : WeaponClass, chosen : Array[AttributeClass]) -> Array[StatusEffectClass]:
	var statuses : Array[StatusEffectClass] = []
	for effect in weapon.get_all_effects():
		if effect.get_status():
			statuses.append(effect.get_status())
	for attribute in chosen:
		if attribute.get_status():
			statuses.append(attribute.get_status())
	return statuses

static func cancels(status : StatusEffectClass, other : StatusEffectClass) -> bool:
	for interaction in status.interactions:
		if interaction.triggerEffects.has(other.effectName):
			return true
	return false

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	var status : StatusEffectClass = get_status()
	if status:
		for other in get_statuses(weapon, chosen):
			if cancels(other, status) or cancels(status, other):
				return false
	for attackNode in weapon.get_attacks():
		if can_use_attack(attackNode):
			return true
	return false

func can_use_attack(attackNode : AttackClass) -> bool:
	return attackTypes.is_empty() or attackTypes.has(attackNode.get_attack_type())

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_CHANCE and chanceScaling != null

func get_status() -> StatusEffectClass:
	return null

func get_value(quality : float, level : int) -> float:
	if not scaling:
		return 0.0
	return scaling.get_value(quality, level)

func get_chance(quality : float, level : int) -> float:
	if not chanceScaling:
		return 1.0
	return chanceScaling.get_value(quality, level)

func get_stat_bonus(bonusStat : Stat, quality : float, level : int) -> float:
	if bonusStat == Stat.NONE or bonusStat != stat:
		return 0.0
	return get_value(quality, level)

func get_description(quality : float, level : int) -> String:
	return description.format(get_description_values(quality, level))

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = {"name": attributeName}
	if scaling:
		values["value"] = scaling.format_value(get_value(quality, level))
	if chanceScaling:
		values["chance"] = chanceScaling.format_value(get_chance(quality, level))
	return values

func get_aura_scene() -> PackedScene:
	return auraScene

func on_equip(weapon : WeaponClass, _roll : AttributeRollClass) -> void:
	weapon.add_aura(get_aura_scene())

func on_attack(weapon : WeaponClass, roll : AttributeRollClass) -> void:
	try_proc(Trigger.ATTACK, weapon, roll, null, 0.0)

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	try_proc(Trigger.HIT, weapon, roll, hurtbox, damage)

func on_crit(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	try_proc(Trigger.CRIT, weapon, roll, hurtbox, damage)

func on_kill(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	try_proc(Trigger.KILL, weapon, roll, hurtbox, damage)

func try_proc(event : Trigger, weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if trigger == event and weapon.roll_chance(roll.get_chance(weapon.get_attribute_level())):
		on_proc(weapon, roll, hurtbox, damage)
		weapon.on_attribute_proc(roll, hurtbox, damage)

func on_proc(_weapon : WeaponClass, _roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	pass

func modify_attack_damage(_weapon : WeaponClass, _roll : AttributeRollClass, damage : float) -> float:
	return damage

func modify_hit_damage(_weapon : WeaponClass, _roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, damage : float) -> float:
	return damage

func get_hurtboxes_in_radius(weapon : WeaponClass, center : Vector2, radius : float, layer : int) -> Array[HurtboxComponentClass]:
	return HurtboxComponentClass.find_in_radius(weapon.get_world_2d(), center, radius, layer)

func get_hurtboxes_in_shape(weapon : WeaponClass, shape : Shape2D, shapeTransform : Transform2D, layer : int) -> Array[HurtboxComponentClass]:
	return HurtboxComponentClass.find_in_shape(weapon.get_world_2d(), shape, shapeTransform, layer)

func spawn_effect(weapon : WeaponClass, position : Vector2, radius : float = 0.0, parent : Node = null) -> Node2D:
	if not effectScene:
		return null
	var effect : Node2D = effectScene.instantiate()
	var vfx : VfxEffectClass = effect as VfxEffectClass
	if vfx:
		vfx.radius = radius
		vfx.color = weapon.get_color()
	if parent:
		parent.add_child(effect)
		effect.global_position = position
	else:
		effect.position = position
		weapon.get_tree().current_scene.add_child(effect)
	return effect
