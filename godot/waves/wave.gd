extends Node
class_name WaveClass


const MAX_MERGE_CHAIN : int = 8

@export var waveName : String
@export var autoStartTime : float = 0.0
@export var activatePaths : Array[EnemyPathClass]
@export var deactivatePaths : Array[EnemyPathClass]

@export_group("Enemy Stats")
@export var combatLevelBonus : int = 0
@export var healthMultiplier : float = 1.0
@export var speedMultiplier : float = 1.0

#------------------------#

func get_spawn_groups() -> Array[SpawnGroupClass]:
	var groups : Array[SpawnGroupClass] = []
	for child in get_children():
		if child is SpawnGroupClass:
			groups.append(child)
	return groups

func get_portals() -> Array[PortalClass]:
	var portals : Array[PortalClass] = []
	for group in get_spawn_groups():
		if group.portal and not portals.has(group.portal):
			portals.append(group.portal)
	return portals

func get_spawn_paths() -> Array[EnemyPathClass]:
	var spawnPaths : Array[EnemyPathClass] = []
	for portal in get_portals():
		if portal.path and not spawnPaths.has(portal.path):
			spawnPaths.append(portal.path)
	return spawnPaths

func get_enemy_count() -> int:
	var total : int = 0
	for group in get_spawn_groups():
		total += group.get_enemy_count()
	return total

func activate_paths() -> void:
	for path in deactivatePaths:
		path.active = false
	for path in activatePaths:
		path.active = true
	for spawnPath in get_spawn_paths():
		var path : EnemyPathClass = spawnPath
		var chain : int = 0
		while path and chain < MAX_MERGE_CHAIN:
			path.active = true
			path = path.mergeInto
			chain += 1
