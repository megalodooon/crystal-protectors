extends Resource
class_name WeaponItemClass


const UPGRADES := preload("res://weapons/upgrades/weapon_upgrades.tres")
const COMBAT_SCALING := preload("res://combat_level/combat_scaling.tres")
const ATTRIBUTE_POOL := preload("res://weapons/attributes/pool/attribute_pool.tres")

@export var weaponScene : PackedScene
@export var rarity : RarityClass
@export var level : int = 0
@export var combatLevel : int = 1
@export var rarityUpgraded : bool = false
@export var attributes : Array[AttributeRollClass]

#------------------------#

func create_weapon() -> WeaponClass:
	var weapon : WeaponClass = weaponScene.instantiate()
	weapon.item = self
	for roll in attributes:
		if roll and roll.attribute:
			weapon.attributes.append(roll)
	if rarity:
		weapon.rarity = rarity
	return weapon

func is_max_level() -> bool:
	return level >= UPGRADES.maxLevel

func can_level_up() -> bool:
	return not is_max_level()

func level_up() -> void:
	if not can_level_up():
		return
	level += 1
	emit_changed()

func can_upgrade_rarity() -> bool:
	return is_max_level() and not rarityUpgraded and rarity != null and rarity.nextRarity != null

func upgrade_rarity() -> void:
	if not can_upgrade_rarity():
		return
	rarity = rarity.nextRarity
	rarityUpgraded = true
	level = 0
	attributes = ATTRIBUTE_POOL.roll_attributes(self, attributes)
	emit_changed()

func upgrade_combat_level(amount : int = 1) -> void:
	combatLevel = maxi(combatLevel + amount, 1)
	emit_changed()

func randomize_attributes() -> void:
	attributes = ATTRIBUTE_POOL.roll_attributes(self)
	emit_changed()

func get_damage_multiplier() -> float:
	return UPGRADES.get_damage_multiplier(level) * COMBAT_SCALING.get_multiplier(combatLevel)

func get_attribute_level() -> int:
	var attributeLevel : int = level
	if rarityUpgraded or (rarity != null and rarity.nextRarity == null):
		attributeLevel += UPGRADES.maxLevel
	return mini(attributeLevel, get_max_attribute_level())

func get_max_attribute_level() -> int:
	return UPGRADES.maxLevel * 2
