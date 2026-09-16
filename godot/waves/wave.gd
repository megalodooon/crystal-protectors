extends Node
class_name WaveClass


@export var activatePaths : Array[EnemyPathClass]

#------------------------#

func get_spawn_groups() -> Array[SpawnGroupClass]:
	var groups : Array[SpawnGroupClass] = []
	for child in get_children():
		if child is SpawnGroupClass:
			groups.append(child)
	return groups

func activate_paths() -> void:
	for path in activatePaths:
		path.active = true
	for group in get_spawn_groups():
		if group.path:
			group.path.active = true
