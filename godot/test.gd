extends Node2D


@export var player : PlayerClass
@export var rarities : Array[RarityClass]

@onready var rarityLabel : Label = $CanvasLayer/RarityLabel

#------------------------#

func _ready() -> void:
	update_label()

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index : int = event.keycode - KEY_1
		if index >= 0 and index < rarities.size():
			player.equip_weapon(player.weaponScene, rarities[index])
			update_label()

func update_label() -> void:
	if not player.weapon or not player.weapon.rarity:
		return
	rarityLabel.text = "1-" + str(rarities.size()) + "  " + player.weapon.rarity.rarityName
	rarityLabel.modulate = player.weapon.rarity.color
