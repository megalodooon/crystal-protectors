extends Node
class_name SpawnGroupClass


signal finished_spawning
signal cleared

enum StartAfter { WAVE_START, PREVIOUS_SPAWNED, PREVIOUS_CLEARED }

@export var enemyScene : PackedScene
@export var portal : PortalClass
@export var count : int = 5
@export var burst : int = 1
@export var interval : float = 1.0
@export_range(0.0, 1.0) var intervalRandomness : float = 0.0

@export_group("Start")
@export var startAfter : StartAfter = StartAfter.WAVE_START
@export var delay : float = 0.0

@export_group("Enemy Stats")
@export var combatLevelBonus : int = 0
@export var healthMultiplier : float = 1.0
@export var speedMultiplier : float = 1.0
@export var modifier : StatusEffectClass

var isSpawning : bool = false
var spawnedCount : int = 0
var aliveCount : int = 0

#------------------------#

func run(waveManager : WaveManagerClass, previous : SpawnGroupClass) -> void:
	isSpawning = true
	spawnedCount = 0
	aliveCount = 0
	if previous and startAfter == StartAfter.PREVIOUS_SPAWNED and previous.isSpawning:
		await previous.finished_spawning
	if previous and startAfter == StartAfter.PREVIOUS_CLEARED and not previous.is_cleared():
		await previous.cleared
	await wait(delay)
	while spawnedCount < count:
		for i in mini(maxi(burst, 1), count - spawnedCount):
			spawnedCount += 1
			waveManager.spawn_enemy(self)
		if spawnedCount < count:
			await wait(interval * randf_range(1.0 - intervalRandomness, 1.0 + intervalRandomness))
	isSpawning = false
	if portal:
		portal.release()
	finished_spawning.emit()
	check_cleared()

func wait(seconds : float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout

func get_enemy_count() -> int:
	return maxi(count, 0)

func is_cleared() -> bool:
	return not isSpawning and aliveCount <= 0

func on_enemy_added() -> void:
	aliveCount += 1

func on_enemy_removed() -> void:
	aliveCount -= 1
	check_cleared()

func check_cleared() -> void:
	if is_cleared():
		cleared.emit()
