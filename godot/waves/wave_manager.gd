extends Node
class_name WaveManagerClass


signal wave_started(wave : WaveClass)
signal wave_finished(wave : WaveClass)
signal enemy_spawned(enemy : EnemyClass)

@export var pathNetwork : PathNetworkClass
@export var enemyParent : Node
@export var combatLevel : int = 1

var waves : Array[WaveClass]
var waveIndex : int = 0
var isWaveRunning : bool = false
var pendingSpawns : int = 0
var aliveEnemies : int = 0

#------------------------#

func _ready() -> void:
	for child in get_children():
		if child is WaveClass:
			waves.append(child)
	prepare_wave()

func has_next_wave() -> bool:
	return waveIndex < waves.size()

func prepare_wave() -> void:
	if not has_next_wave():
		return
	waves[waveIndex].activate_paths()
	if pathNetwork:
		pathNetwork.set_spawn_paths(waves[waveIndex].get_spawn_paths())
		pathNetwork.play_preview()

func start_next_wave() -> void:
	if isWaveRunning or not has_next_wave():
		return
	var wave : WaveClass = waves[waveIndex]
	isWaveRunning = true
	if pathNetwork:
		pathNetwork.stop_preview()
	var groups : Array[SpawnGroupClass] = wave.get_spawn_groups()
	for group in groups:
		pendingSpawns += maxi(group.count, 0)
	for group in groups:
		group.start(self)
	wave_started.emit(wave)
	check_wave_finished()

func spawn_enemy(enemyScene : PackedScene, path : EnemyPathClass) -> void:
	pendingSpawns -= 1
	if not enemyScene or not path:
		check_wave_finished()
		return
	var enemy : EnemyClass = enemyScene.instantiate()
	enemy.combatLevel = combatLevel
	enemy.tree_exited.connect(on_enemy_removed)
	aliveEnemies += 1
	get_enemy_parent().add_child(enemy)
	enemy.pathFollowComponent.start(path, enemy)
	enemy_spawned.emit(enemy)

func on_enemy_removed() -> void:
	aliveEnemies -= 1
	check_wave_finished()

func check_wave_finished() -> void:
	if not isWaveRunning or pendingSpawns > 0 or aliveEnemies > 0 or not is_inside_tree():
		return
	isWaveRunning = false
	var wave : WaveClass = waves[waveIndex]
	waveIndex += 1
	wave_finished.emit(wave)
	prepare_wave()

func get_enemy_parent() -> Node:
	if enemyParent:
		return enemyParent
	return get_tree().current_scene
