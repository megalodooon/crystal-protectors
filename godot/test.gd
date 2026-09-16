extends Node2D


@export var player : PlayerClass
@export var weapons : Array[PackedScene]
@export var rarities : Array[RarityClass]

@onready var rarityLabel : Label = $CanvasLayer/RarityLabel

var weaponIndex : int = 0

#------------------------#

func _ready() -> void:
	update_label()

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q and not weapons.is_empty():
			weaponIndex = (weaponIndex + 1) % weapons.size()
			player.weaponScene = weapons[weaponIndex]
			player.equip_weapon(player.weaponScene, player.weapon.rarity)
			update_label()
		var index : int = event.keycode - KEY_1
		if index >= 0 and index < rarities.size():
			player.equip_weapon(player.weaponScene, rarities[index])
			update_label()

func update_label() -> void:
	if not player.weapon or not player.weapon.rarity:
		return
	var weaponName : String = player.weaponScene.resource_path.get_file().get_basename().capitalize()
	rarityLabel.text = "Q " + weaponName + "  1-" + str(rarities.size()) + " " + player.weapon.rarity.rarityName
	rarityLabel.modulate = player.weapon.rarity.color
