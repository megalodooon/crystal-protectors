extends Node2D


@export var player : PlayerClass
@export var weapons : Array[PackedScene]
@export var rarities : Array[RarityClass]

@onready var rarityLabel : Label = $CanvasLayer/RarityLabel
@onready var upgradeLabel : Label = $CanvasLayer/UpgradeLabel

var weaponIndex : int = 0

#------------------------#

func _ready() -> void:
	update_labels()

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var item : WeaponItemClass = player.weaponItem
		if event.keycode == KEY_Q and not weapons.is_empty():
			weaponIndex = (weaponIndex + 1) % weapons.size()
			item.weaponScene = weapons[weaponIndex]
			player.equip_weapon(item)
		if event.keycode == KEY_E:
			item.level_up()
		if event.keycode == KEY_R:
			item.upgrade_rarity()
		if event.keycode == KEY_C:
			item.upgrade_combat_level()
		var index : int = event.keycode - KEY_1
		if index >= 0 and index < rarities.size():
			var newItem : WeaponItemClass = WeaponItemClass.new()
			newItem.weaponScene = item.weaponScene
			newItem.rarity = rarities[index]
			newItem.combatLevel = item.combatLevel
			player.equip_weapon(newItem)
		update_labels()

func update_labels() -> void:
	var item : WeaponItemClass = player.weaponItem
	if not item or not item.rarity:
		return
	var weaponName : String = item.weaponScene.resource_path.get_file().get_basename().capitalize()
	rarityLabel.text = "Q " + weaponName + "  1-" + str(rarities.size()) + " " + item.rarity.rarityName
	rarityLabel.modulate = item.rarity.color
	var rarityText : String = "R Rarity up at max level"
	if item.can_upgrade_rarity():
		rarityText = "R Upgrade to " + item.rarity.nextRarity.rarityName
	elif item.rarityUpgraded or not item.rarity.nextRarity:
		rarityText = "Rarity cannot upgrade"
	upgradeLabel.text = "E Level " + str(item.level) + "/" + str(item.UPGRADES.maxLevel) + "  C Combat " + str(item.combatLevel)
	upgradeLabel.text += "  Damage " + NumberFormatClass.format(player.weapon.get_damage())
	upgradeLabel.text += "\n" + rarityText
