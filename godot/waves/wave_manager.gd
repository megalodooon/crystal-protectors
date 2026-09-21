extends Node
class_name WaveManagerClass


signal wave_started(wave : WaveClass)
signal wave_finished(wave : WaveClass)
signal all_waves_finished
signal enemy_spawned(enemy : EnemyClass)

@export var pathNetwork : PathNetworkClass
@export var enemyParent : Node
@export var combatLevel : int = 1

var waves : Array[WaveClass]
var portals : Array[PortalClass]
var enemies : Array[EnemyClass] = []
var waveIndex : int = 0
var isWaveRunning : bool = false
var autoStartTimeLeft : float = 0.0
var pendingSpawns : int = 0
var aliveEnemies : int = 0

#------------------------#

func _ready() -> void:
	for child in get_children():
		if child is WaveClass:
			waves.append(child)
			for portal in child.get_portals():
				if not portals.has(portal):
					portals.append(portal)
	prepare_wave()

func _process(delta : float) -> void:
	if isWaveRunning or autoStartTimeLeft <= 0.0:
		return
	autoStartTimeLeft -= delta
	if autoStartTimeLeft <= 0.0:
		start_next_wave()

func has_next_wave() -> bool:
	return waveIndex < waves.size()

func get_wave() -> WaveClass:
	if has_next_wave():
		return waves[waveIndex]
	return null

func get_enemies_left() -> int:
	return pendingSpawns + aliveEnemies

func prepare_wave() -> void:
	var wave : WaveClass = get_wave()
	var wavePortals : Array[PortalClass] = []
	if wave:
		wavePortals = wave.get_portals()
	for portal in portals:
		portal.set_warning(wavePortals.has(portal))
	if not wave:
		all_waves_finished.emit()
		return
	wave.activate_paths()
	autoStartTimeLeft = wave.autoStartTime
	if pathNetwork:
		pathNetwork.set_spawn_paths(wave.get_spawn_paths())
		pathNetwork.play_preview()

func start_next_wave() -> void:
	if isWaveRunning or not has_next_wave():
		return
	var wave : WaveClass = get_wave()
	isWaveRunning = true
	autoStartTimeLeft = 0.0
	if pathNetwork:
		pathNetwork.stop_preview()
	var groups : Array[SpawnGroupClass] = wave.get_spawn_groups()
	pendingSpawns += wave.get_enemy_count()
	for portal in portals:
		portal.set_warning(false)
	for group in groups:
		if group.portal:
			group.portal.open()
	wave_started.emit(wave)
	var previous : SpawnGroupClass = null
	for group in groups:
		group.run(self, previous)
		previous = group
	check_wave_finished()

func spawn_enemy(group : SpawnGroupClass) -> void:
	pendingSpawns -= 1
	var wave : WaveClass = get_wave()
	if not group.enemyScene or not group.portal or not group.portal.path:
		push_warning("SpawnGroup " + str(group.get_path()) + " needs an enemyScene and a portal inside an EnemyPath.")
		check_wave_finished()
		return
	var enemy : EnemyClass = group.enemyScene.instantiate()
	enemy.combatLevel = maxi(combatLevel + wave.combatLevelBonus + group.combatLevelBonus, 1)
	enemy.healthMultiplier = wave.healthMultiplier * group.healthMultiplier
	enemy.speedMultiplier = wave.speedMultiplier * group.speedMultiplier
	enemy.modifier = group.modifier
	enemy.tree_exited.connect(on_enemy_removed.bind(enemy, group))
	aliveEnemies += 1
	enemies.append(enemy)
	group.on_enemy_added()
	get_enemy_parent().add_child(enemy)
	enemy.pathFollowComponent.start(group.portal.path, enemy)
	group.portal.spawn(enemy)
	enemy_spawned.emit(enemy)

func on_enemy_removed(enemy : EnemyClass, group : SpawnGroupClass) -> void:
	if not enemy.is_queued_for_deletion():
		return
	enemies.erase(enemy)
	aliveEnemies -= 1
	group.on_enemy_removed()
	check_wave_finished()

func check_wave_finished() -> void:
	if not isWaveRunning or pendingSpawns > 0 or aliveEnemies > 0 or not is_inside_tree():
		return
	isWaveRunning = false
	var wave : WaveClass = get_wave()
	waveIndex += 1
	wave_finished.emit(wave)
	prepare_wave()

func get_enemy_parent() -> Node:
	if enemyParent:
		return enemyParent
	return get_tree().current_scene
