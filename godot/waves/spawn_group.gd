extends Node
class_name SpawnGroupClass


@export var enemyScene : PackedScene
@export var path : EnemyPathClass
@export var count : int = 5
@export var interval : float = 1.0
@export var delay : float = 0.0

#------------------------#

func start(waveManager : WaveManagerClass) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	for i in count:
		waveManager.spawn_enemy(enemyScene, path)
		if i < count - 1:
			await get_tree().create_timer(interval).timeout
