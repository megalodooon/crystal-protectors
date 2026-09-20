extends Node2D
class_name TowerBuilderClass


signal changed

@export var towers : Array[TowerStatsClass]
@export var waveManager : WaveManagerClass
@export var towerParent : Node
@export var startMana : int = 250
@export var defenseUnits : int = 120
@export var reachDistance : float = 26.0
@export var spacing : float = 13.0

var mana : int = 0
var usedUnits : int = 0
var selected : int = -1
var ghost : TowerClass
var built : Array[TowerClass] = []

#------------------------#

func _ready() -> void:
	mana = startMana
	if waveManager:
		waveManager.enemy_spawned.connect(on_enemy_spawned)

func _process(_delta : float) -> void:
	if not is_instance_valid(ghost):
		return
	var spot : Vector2 = get_build_spot()
	ghost.global_position = spot
	ghost.set_valid(can_build(spot))

func get_build_spot() -> Vector2:
	return get_global_mouse_position().round()

func select_next() -> void:
	select(selected + 1 if selected + 1 < towers.size() else -1)

func select(index : int) -> void:
	selected = index if index >= 0 and index < towers.size() else -1
	if is_instance_valid(ghost):
		ghost.queue_free()
		ghost = null
	if selected >= 0:
		ghost = make_tower(towers[selected], true)
	changed.emit()

func make_tower(stats : TowerStatsClass, preview : bool) -> TowerClass:
	var tower : TowerClass = stats.towerScene.instantiate()
	tower.stats = stats
	tower.isPreview = preview
	get_tower_parent().add_child(tower)
	tower.global_position = get_build_spot()
	return tower

func build() -> bool:
	return build_at(get_build_spot())

func build_at(spot : Vector2) -> bool:
	if not can_build(spot):
		return false
	var stats : TowerStatsClass = towers[selected]
	mana -= stats.manaCost
	usedUnits += stats.manaCost
	var tower : TowerClass = make_tower(stats, false)
	tower.global_position = spot
	tower.tree_exited.connect(on_tower_removed.bind(tower, stats))
	built.append(tower)
	changed.emit()
	return true

func can_build(spot : Vector2) -> bool:
	if selected < 0:
		return false
	var stats : TowerStatsClass = towers[selected]
	if mana < stats.manaCost or usedUnits + stats.manaCost > defenseUnits:
		return false
	for tower in built:
		if tower.global_position.distance_to(spot) < spacing:
			return false
	return true

func get_nearest(spot : Vector2) -> TowerClass:
	var nearest : TowerClass = null
	var bestDistance : float = reachDistance
	for tower in built:
		var distance : float = tower.global_position.distance_to(spot)
		if distance <= bestDistance:
			bestDistance = distance
			nearest = tower
	return nearest

func upgrade(tower : TowerClass) -> bool:
	if not tower or tower.tier >= tower.stats.maxTier:
		return false
	var cost : int = tower.stats.get_upgrade_cost(tower.tier)
	if mana < cost:
		return false
	mana -= cost
	tower.upgrade()
	changed.emit()
	return true

func repair(tower : TowerClass) -> bool:
	if not tower or tower.get_missing_health() <= 0.0:
		return false
	var cost : int = tower.stats.get_repair_cost(tower.get_missing_health())
	if mana < cost:
		return false
	mana -= cost
	tower.repair()
	changed.emit()
	return true

func sell(tower : TowerClass) -> bool:
	if not tower:
		return false
	mana += tower.stats.get_sell_refund(tower.tier)
	tower.queue_free()
	changed.emit()
	return true

func add_mana(amount : int) -> void:
	mana += amount
	changed.emit()

func on_enemy_spawned(enemy : EnemyClass) -> void:
	enemy.healthComponent.died.connect(add_mana.bind(enemy.manaReward))

func on_tower_removed(tower : TowerClass, stats : TowerStatsClass) -> void:
	built.erase(tower)
	usedUnits = maxi(usedUnits - stats.manaCost, 0)
	changed.emit()

func get_tower_parent() -> Node:
	if towerParent:
		return towerParent
	return get_tree().current_scene
