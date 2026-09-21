extends Node2D


@export var player : PlayerClass
@export var characters : Array[PackedScene]
@export var weapons : Array[PackedScene]
@export var rarities : Array[RarityClass]
@export var waveManager : WaveManagerClass
@export var testElements : Array[WeaponEffectClass]
@export var enemySpriteScales : Dictionary[PackedScene, float]
@export var enemyColors : Dictionary[PackedScene, Color]
@export var labelInterval : float = 0.1

@onready var rarityLabel : Label = $CanvasLayer/HUD/RarityLabel
@onready var upgradeLabel : Label = $CanvasLayer/HUD/UpgradeLabel
@onready var waveLabel : Label = $CanvasLayer/HUD/WaveLabel
@onready var attributePanel : PanelContainer = $CanvasLayer/HUD/AttributePanel
@onready var attributeText : RichTextLabel = $CanvasLayer/HUD/AttributePanel/AttributeText
@onready var towerLabel : Label = $CanvasLayer/HUD/TowerLabel
@onready var hud : Control = $CanvasLayer/HUD
@onready var hoverLabel : Label = $CanvasLayer/HUD/HoverLabel
@onready var minimap : MinimapClass = $CanvasLayer/HUD/Minimap

var characterIndex : int = 0
var wieldable : Dictionary[PackedScene, bool] = {}
var elementIndex : int = -1
var elementWeapon : WeaponClass
var labelTimer : float = 0.0

#------------------------#

func _ready() -> void:
	player.weaponItem.randomize_attributes()
	update_labels()

func _process(delta : float) -> void:
	labelTimer -= delta
	if labelTimer <= 0.0:
		labelTimer = labelInterval
		update_wave_label()
		update_tower_label()
	update_hover_label()
	if player.weapon != elementWeapon:
		elementWeapon = player.weapon
		apply_test_element()
		update_labels()

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var item : WeaponItemClass = player.weaponItem
		if event.keycode == KEY_Q:
			cycle_weapon(item)
		if event.keycode == KEY_TAB:
			switch_character()
			return
		if event.keycode == KEY_E:
			item.level_up()
		if event.keycode == KEY_R:
			item.upgrade_rarity()
		if event.keycode == KEY_C:
			item.upgrade_combat_level()
		if event.keycode == KEY_Z:
			waveManager.combatLevel += 1
		if event.keycode == KEY_T and not testElements.is_empty():
			elementIndex += 1
			if elementIndex >= testElements.size():
				elementIndex = -1
			player.spawn_weapon()
		if event.keycode == KEY_G:
			waveManager.start_next_wave()
		if event.keycode == KEY_V:
			attributePanel.visible = not attributePanel.visible
		if event.keycode == KEY_X:
			item.randomize_attributes()
		if event.keycode == KEY_Y:
			equip_random_synergy()
		if event.keycode == KEY_F1:
			hud.visible = not hud.visible
		use_tower_keys(event.keycode)
		var index : int = event.keycode - KEY_1
		if index >= 0 and index < rarities.size():
			var newItem : WeaponItemClass = WeaponItemClass.new()
			newItem.weaponScene = item.weaponScene
			newItem.rarity = rarities[index]
			newItem.combatLevel = item.combatLevel
			newItem.randomize_attributes()
			player.equip_weapon(newItem)
		update_labels()

func cycle_weapon(item : WeaponItemClass) -> void:
	var options : Array[PackedScene] = []
	for scene in weapons:
		if not wieldable.has(scene):
			wieldable[scene] = player.can_wield(scene)
		if wieldable[scene]:
			options.append(scene)
	if options.is_empty():
		return
	item.weaponScene = options[(options.find(item.weaponScene) + 1) % options.size()]
	player.equip_weapon(item)

func switch_character() -> void:
	if characters.size() < 2:
		return
	characterIndex = (characterIndex + 1) % characters.size()
	var oldPlayer : PlayerClass = player
	var newPlayer : PlayerClass = characters[characterIndex].instantiate()
	newPlayer.position = oldPlayer.position
	(newPlayer.get_node("TowerBuilder") as TowerBuilderClass).waveManager = waveManager
	add_child(newPlayer)
	move_child(newPlayer, oldPlayer.get_index())
	newPlayer.towerBuilder.take_over(oldPlayer.towerBuilder)
	oldPlayer.get_node("Camera2D").reparent(newPlayer)
	oldPlayer.queue_free()
	player = newPlayer
	minimap.player = newPlayer
	minimap.towerBuilder = newPlayer.towerBuilder
	wieldable.clear()
	player.weaponItem.randomize_attributes()
	update_labels()

func use_tower_keys(keycode : int) -> void:
	var builder : TowerBuilderClass = player.towerBuilder
	var hovered : TowerClass = builder.get_hovered()
	if keycode == KEY_B:
		builder.select_next()
	if keycode == KEY_F:
		builder.build()
	if keycode == KEY_U:
		builder.upgrade(hovered)
	if keycode == KEY_H:
		builder.repair(hovered)
	if keycode == KEY_J:
		builder.sell(hovered)
	if keycode == KEY_M:
		builder.add_mana(100)

func update_tower_label() -> void:
	var builder : TowerBuilderClass = player.towerBuilder
	var text : String = "Mana " + str(builder.mana) + "  DU " + str(builder.usedUnits) + "/" + str(builder.defenseUnits) + "  B "
	if builder.selected < 0:
		text += "no tower"
	else:
		var stats : TowerStatsClass = builder.towers[builder.selected]
		text += stats.towerName + " " + str(stats.manaCost) + "  F build"
	towerLabel.text = text

func update_hover_label() -> void:
	var builder : TowerBuilderClass = player.towerBuilder
	var tower : TowerClass = builder.get_hovered()
	hoverLabel.visible = tower != null
	if not tower:
		return
	var text : String = tower.stats.towerName + " T" + str(tower.tier) + "/" + str(tower.stats.maxTier)
	if not builder.can_reach(tower):
		text += "\nmove closer"
	else:
		if tower.get_missing_health() > 0.0:
			text += "\nH to repair  " + str(tower.stats.get_repair_cost(tower.get_missing_health()))
		if tower.tier < tower.stats.maxTier:
			text += "\nU to upgrade  " + str(tower.stats.get_upgrade_cost(tower.tier))
		text += "\nJ to sell  " + str(tower.stats.get_sell_refund(tower.tier))
	hoverLabel.text = text
	hoverLabel.position = get_hover_spot(tower)

func get_hover_spot(tower : TowerClass) -> Vector2:
	var labelSize : Vector2 = hoverLabel.get_minimum_size()
	var rect : Rect2 = tower.get_hover_rect()
	var screen : Transform2D = get_viewport().get_canvas_transform()
	var spot : Vector2 = screen * Vector2(rect.end.x + 2.0, rect.position.y)
	if hits_minimap(spot, labelSize):
		spot.x = (screen * rect.position).x - labelSize.x - 2.0
	var limit : Vector2 = hud.size - labelSize - Vector2.ONE * 2.0
	return Vector2(clampf(spot.x, 2.0, limit.x), clampf(spot.y, 2.0, limit.y)).round()

func hits_minimap(spot : Vector2, labelSize : Vector2) -> bool:
	return minimap.visible and Rect2(spot, labelSize).intersects(minimap.get_canvas_rect())

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
	rarityLabel.text = "Tab " + player.characterName + "  Q " + weaponName + "  1-" + str(rarities.size()) + " " + item.rarity.rarityName + "  F1 hide"
	rarityLabel.modulate = item.rarity.color
	var rarityText : String = "R Rarity up at level " + str(item.UPGRADES.rarityUpgradeLevel)
	if item.can_upgrade_rarity():
		rarityText = "R Upgrade to " + item.rarity.nextRarity.rarityName
	elif item.rarityUpgraded or not item.rarity.nextRarity:
		rarityText = "Rarity cannot upgrade"
	upgradeLabel.text = "E Level " + str(item.level) + "/" + str(item.UPGRADES.maxLevel) + "  C Combat " + str(item.combatLevel)
	upgradeLabel.text += "  Damage " + NumberFormatClass.format(player.weapon.get_damage())
	upgradeLabel.text += "\n" + rarityText + "  V Attributes  Y Synergy  T Element " + get_element_name()
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
	for roll in item.get_synergy_rolls():
		text += "\n[color=#ffd966]+ %s[/color]" % roll.get_description(level)
	attributeText.text = text

func equip_random_synergy() -> void:
	var synergies : Array[AttributeClass] = WeaponItemClass.ATTRIBUTE_POOL.synergies
	if synergies.is_empty() or rarities.is_empty():
		return
	var synergy : AttributeClass = synergies.pick_random()
	var newItem : WeaponItemClass = WeaponItemClass.new()
	newItem.weaponScene = player.weaponItem.weaponScene
	newItem.rarity = rarities.back()
	newItem.level = player.weaponItem.level
	newItem.combatLevel = player.weaponItem.combatLevel
	var kept : Array[AttributeRollClass] = []
	for required in synergy.requiredAttributes:
		var roll : AttributeRollClass = AttributeRollClass.new()
		roll.attribute = required as AttributeClass
		roll.quality = randf()
		kept.append(roll)
	newItem.attributes = WeaponItemClass.ATTRIBUTE_POOL.roll_attributes(newItem, kept)
	player.equip_weapon(newItem)

func apply_test_element() -> void:
	if elementIndex < 0 or not player.weapon:
		return
	var effect : WeaponEffectClass = testElements[elementIndex].duplicate()
	player.weapon.activeEffects.append(effect)
	effect.on_equip(player.weapon)

func get_element_name() -> String:
	if elementIndex < 0:
		return "None"
	return testElements[elementIndex].resource_path.get_file().get_basename().capitalize()

func get_quality_bar(quality : float) -> String:
	var filled : int = roundi(quality * 5.0)
	return "[color=#bbbbbb]%s[/color][color=#444444]%s[/color]" % ["|".repeat(filled), "|".repeat(5 - filled)]

func update_wave_label() -> void:
	var modifierChance : float = EnemyClass.MODIFIERS.get_chance(waveManager.combatLevel)
	var enemyText : String = "  Z Lv" + str(waveManager.combatLevel) + " " + AttributeScalingClass.format_number(modifierChance * 100.0) + "%"
	var wave : WaveClass = waveManager.get_wave()
	if not wave:
		waveLabel.text = "All cleared" + enemyText
		return
	var waveText : String = "Wave " + str(waveManager.waveIndex + 1) + "/" + str(waveManager.waves.size())
	if not wave.waveName.is_empty():
		waveText += " " + wave.waveName
	if waveManager.isWaveRunning:
		waveLabel.text = waveText + "  " + str(waveManager.get_enemies_left()) + " left"
	elif waveManager.autoStartTimeLeft > 0.0:
		waveLabel.text = "G " + waveText + " in " + str(ceili(waveManager.autoStartTimeLeft)) + "s"
	else:
		waveLabel.text = "G Start " + waveText
	waveLabel.text += enemyText
