extends Node2D
class_name PathNetworkClass


signal pulses_rebuilt

const PULSE_SCENE := preload("res://paths/path_pulse.tscn")
const MAX_CHAIN : int = 8

@export var style : PathPulseStyleClass = preload("res://paths/path_pulse_style.tres")
@export var playOnStart : bool = true

var paths : Array[EnemyPathClass]
var spawnPaths : Array[EnemyPathClass]
var isPlaying : bool = false
var needsRebuild : bool = true
var time : float = 0.0
var travelTime : float = 0.0
var gray : float = 0.0

#------------------------#

func _ready() -> void:
	for child in get_children():
		if child is EnemyPathClass:
			paths.append(child)
	for path in paths:
		path.connect_paths()
	for path in paths:
		path.pulse = PULSE_SCENE.instantiate()
		path.add_child(path.pulse)
		path.pulse.build(path, style)
		path.active_changed.connect(on_path_active_changed)
	if playOnStart:
		play_preview()

func _process(delta : float) -> void:
	if needsRebuild:
		rebuild_pulses()
	var cycleFade : float = 1.0
	if isPlaying:
		time += delta
		if time >= get_cycle_time():
			time = 0.0
		cycleFade = 1.0 - clampf((time - travelTime - style.holdTime) / style.fadeTime, 0.0, 1.0)
	else:
		var settledTime : float = travelTime + style.trailLength / style.speed
		if gray >= 1.0 and time >= settledTime:
			return
		gray = move_toward(gray, 1.0, delta / style.stopFadeTime)
		time = minf(time + delta, settledTime)
	var opacity : float = lerpf(1.0, style.waveOpacity, gray) * cycleFade
	for path in paths:
		path.pulse.visible = not path.pulse.sources.is_empty()
		if path.pulse.visible:
			path.pulse.update_pulse(time, opacity, gray)

func play_preview() -> void:
	isPlaying = true
	gray = 0.0
	time = 0.0

func stop_preview() -> void:
	isPlaying = false

func set_spawn_paths(newSpawnPaths : Array[EnemyPathClass]) -> void:
	spawnPaths = newSpawnPaths
	needsRebuild = true
	time = 0.0

func on_path_active_changed() -> void:
	needsRebuild = true
	time = 0.0

func rebuild_pulses() -> void:
	needsRebuild = false
	travelTime = 0.0
	for path in paths:
		path.pulse.sources.clear()
		path.pulse.isSpawn = is_spawn(path)
	for path in paths:
		if path.pulse.isSpawn:
			add_pulse(path, 0.0, 0.0, 0)
	pulses_rebuilt.emit()

func is_spawn(path : EnemyPathClass) -> bool:
	if not path.active:
		return false
	if spawnPaths.is_empty():
		return not path.is_fed()
	return spawnPaths.has(path)

func add_pulse(path : EnemyPathClass, fromDistance : float, startTime : float, chain : int) -> void:
	if chain >= MAX_CHAIN or path.pulse.sources.size() >= PathPulseClass.MAX_PULSES:
		return
	path.pulse.sources.append(Vector2(fromDistance, startTime))
	var endTime : float = startTime + (path.get_length() - fromDistance) / style.speed
	travelTime = maxf(travelTime, endTime)
	for branch in path.branches:
		if branch.active and branch.branchDistance >= fromDistance:
			add_pulse(branch, 0.0, startTime + (branch.branchDistance - fromDistance) / style.speed, chain + 1)
	if path.can_merge():
		add_pulse(path.mergeInto, path.mergeDistance, endTime, chain + 1)

func get_cycle_time() -> float:
	return travelTime + style.holdTime + style.fadeTime + style.pauseTime
