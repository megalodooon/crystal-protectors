extends Node2D


@export var player : PlayerClass
@export var weapons : Array[PackedScene]
@export var rarities : Array[RarityClass]
@export var waveManager : WaveManagerClass
@export var enemySpriteScales : Dictionary[PackedScene, float]
@export var enemyColors : Dictionary[PackedScene, Color]

@onready var rarityLabel : Label = $CanvasLayer/RarityLabel
@onready var upgradeLabel : Label = $CanvasLayer/UpgradeLabel
@onready var waveLabel : Label = $CanvasLayer/WaveLabel
@onready var attributePanel : PanelContainer = $CanvasLayer/AttributePanel
@onready var attributeText : RichTextLabel = $CanvasLayer/AttributePanel/AttributeText

var weaponIndex : int = 0

#------------------------#

func _ready() -> void:
	player.weaponItem.randomize_attributes()
	update_labels()

func _process(_delta : float) -> void:
	update_wave_label()

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
		if event.keycode == KEY_G:
			waveManager.start_next_wave()
		if event.keycode == KEY_V:
			attributePanel.visible = not attributePanel.visible
		if event.keycode == KEY_X:
			item.randomize_attributes()
		var index : int = event.keycode - KEY_1
		if index >= 0 and index < rarities.size():
			var newItem : WeaponItemClass = WeaponItemClass.new()
			newItem.weaponScene = item.weaponScene
			newItem.rarity = rarities[index]
			newItem.combatLevel = item.combatLevel
			newItem.randomize_attributes()
			player.equip_weapon(newItem)
		update_labels()

func on_enemy_spawned(enemy : EnemyClass) -> void:
	for scene : PackedScene in enemySpriteScales:
		if scene.resource_path == enemy.scene_file_path:
			enemy.sprite.scale = Vector2.ONE * enemySpriteScales[scene]
	for scene : PackedScene in enemyColors:
		if scene.resource_path == enemy.scene_file_path:
			enemy.sprite.modulate = enemyColors[scene]

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
	upgradeLabel.text += "\n" + rarityText + "  V Attributes"
	update_attribute_panel()

func update_attribute_panel() -> void:
	var item : WeaponItemClass = player.weaponItem
	var level : int = item.get_attribute_level()
	var panelStyle : StyleBoxFlat = attributePanel.get_theme_stylebox("panel")
	panelStyle.border_color = item.rarity.color
	var text : String = "[color=#%s]%s Attributes[/color]  Lv %d/%d  X Reroll" % [item.rarity.color.to_html(false), item.rarity.rarityName, level, item.get_max_attribute_level()]
	for roll in item.attributes:
		var color : Color = Color.WHITE
		if roll.attribute.special:
			color = item.rarity.color
		text += "\n%s [color=#%s]%s[/color]" % [get_quality_bar(roll.quality), color.to_html(false), roll.get_description(level)]
	attributeText.text = text

func get_quality_bar(quality : float) -> String:
	var filled : int = roundi(quality * 5.0)
	return "[color=#bbbbbb]%s[/color][color=#444444]%s[/color]" % ["|".repeat(filled), "|".repeat(5 - filled)]

func update_wave_label() -> void:
	var waveText : String = str(waveManager.waveIndex + 1) + "/" + str(waveManager.waves.size())
	if waveManager.isWaveRunning:
		waveLabel.text = "Wave " + waveText + "  Enemies " + str(waveManager.aliveEnemies + waveManager.pendingSpawns)
	elif waveManager.has_next_wave():
		waveLabel.text = "G Start wave " + waveText
	else:
		waveLabel.text = "All waves cleared"
