extends Node


@export var cullMargin : float = 32.0
@export var crowdRadius : float = 8.0
@export var crowdTime : float = 0.15
@export var effectCrowdTime : float = 0.3
@export var statusCrowdRadius : float = 16.0
@export var updateInterval : float = 0.1

@export_group("Budget")
@export var effectsPerCrowd : int = 1
@export var sparksPerCrowd : int = 2
@export var numbersPerCrowd : int = 4
@export var boltsPerCrowd : int = 2
@export var statusVisualsPerCrowd : int = 1
@export var maxEffects : int = 16
@export var maxEffectsPerScene : int = 4
@export var maxStatusVisuals : int = 24

@export_group("Warmup")
@export var warmupFolders : PackedStringArray = ["res://vfx/effects/", "res://vfx/buffs/", "res://status_effects/"]
@export var warmupFrames : int = 3

@onready var damageNumbers : DamageNumbersClass = $DamageNumbers
@onready var hitSparks : HitSparksClass = $HitSparks
@onready var pool : Node2D = $Pool
@onready var warmup : Node2D = $Warmup

var time : float = 0.0
var updateTimer : float = 0.0
var viewRect : Rect2
var viewFrame : int = -1
var recentSpawns : Dictionary = {}
var aliveEffects : Dictionary = {}
var aliveTotal : int = 0
var shakes : Dictionary = {}
var pools : Dictionary = {}
var notPoolable : Dictionary = {}
var statusGroups : Dictionary[String, Array] = {}
var shownStatusVisuals : int = 0
var cullables : Array[Node2D] = []
var warmupLeft : int = 0
var warmedEffects : Array[VfxEffectClass] = []
var warmedScenes : Array[PackedScene] = []

#------------------------#

func _ready() -> void:
	warmupLeft = warmupFrames + 1

func _process(delta : float) -> void:
	time += delta
	update_warmup()
	updateTimer += delta
	if updateTimer < updateInterval:
		return
	updateTimer = 0.0
	forget_old_spawns()
	update_status_visuals()
	update_cullables()

func get_view_rect() -> Rect2:
	var frame : int = Engine.get_process_frames()
	if frame != viewFrame:
		viewFrame = frame
		var viewport : Viewport = get_viewport()
		viewRect = (viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()).grow(cullMargin)
	return viewRect

func is_on_screen(position : Vector2) -> bool:
	return get_view_rect().has_point(position)

func can_spawn(key : Object, position : Vector2, perCrowd : int, radius : float = 0.0, window : float = 0.0) -> bool:
	if not is_on_screen(position):
		return false
	var spawns : PackedVector3Array = recentSpawns.get(key, PackedVector3Array())
	var distance : float = maxf(crowdRadius, radius * 0.5)
	var duration : float = maxf(crowdTime, window)
	var nearby : int = 0
	for spawn in spawns:
		if time - spawn.z < duration and position.distance_squared_to(Vector2(spawn.x, spawn.y)) < distance * distance:
			nearby += 1
	if nearby >= perCrowd:
		return false
	spawns.append(Vector3(position.x, position.y, time))
	recentSpawns[key] = spawns
	return true

func forget_old_spawns() -> void:
	for key : Object in recentSpawns.keys():
		var kept : PackedVector3Array = []
		for spawn in recentSpawns[key]:
			if time - spawn.z < maxf(crowdTime, effectCrowdTime):
				kept.append(spawn)
		if kept.is_empty():
			recentSpawns.erase(key)
		else:
			recentSpawns[key] = kept

func show_damage_number(position : Vector2, amount : float, damageType : DamageTypeClass, isCrit : bool) -> void:
	if can_spawn(damageNumbers, position, numbersPerCrowd):
		damageNumbers.add(position, amount, damageType, isCrit)

func show_hit_spark(position : Vector2, color : Color, strength : float, sparkAmount : int, orbAmount : int, angle : float) -> void:
	if can_spawn(hitSparks, position, sparksPerCrowd):
		hitSparks.add(position, color, strength, sparkAmount, orbAmount, angle)

func spawn_effect(scene : PackedScene, position : Vector2, radius : float = 0.0, color : Color = Color.WHITE, parent : Node = null, angle : float = 0.0, crowded : bool = true) -> Node2D:
	if not scene:
		return null
	var allowed : bool = aliveTotal < maxEffects and is_on_screen(position)
	if crowded:
		allowed = allowed and aliveEffects.get(scene, 0) < maxEffectsPerScene and can_spawn(scene, position, effectsPerCrowd, radius, effectCrowdTime)
	if not allowed:
		GameFeel.shake(get_shake(scene))
		return null
	aliveEffects[scene] = aliveEffects.get(scene, 0) + 1
	aliveTotal += 1
	if not parent and not notPoolable.has(scene):
		var pooled : VfxEffectClass = take_from_pool(scene)
		if pooled:
			pooled.radius = radius
			pooled.color = color
			pooled.position = position
			pooled.rotation = angle
			pooled.visible = true
			pooled.process_mode = Node.PROCESS_MODE_INHERIT
			pooled.play()
			return pooled
	var effect : Node2D = scene.instantiate()
	var vfx : VfxEffectClass = effect as VfxEffectClass
	if vfx:
		vfx.radius = radius
		vfx.color = color
	effect.tree_exiting.connect(on_effect_exiting.bind(scene))
	if parent:
		parent.add_child(effect)
		effect.global_position = position
	else:
		effect.position = position
		get_tree().current_scene.add_child(effect)
	effect.rotation = angle
	return effect

func take_from_pool(scene : PackedScene) -> VfxEffectClass:
	var idle : Array = pools.get(scene, [])
	if not idle.is_empty():
		return idle.pop_back()
	var node : Node = scene.instantiate()
	var effect : VfxEffectClass = node as VfxEffectClass
	if not effect:
		notPoolable[scene] = true
		node.free()
		return null
	add_to_pool(effect, scene)
	return effect

func add_to_pool(effect : VfxEffectClass, scene : PackedScene) -> void:
	effect.pooled = true
	effect.finished.connect(on_pooled_finished.bind(scene))
	pool.add_child(effect)

func on_pooled_finished(effect : VfxEffectClass, scene : PackedScene) -> void:
	return_to_pool(effect, scene)
	on_effect_exiting(scene)

func return_to_pool(effect : VfxEffectClass, scene : PackedScene) -> void:
	effect.visible = false
	effect.process_mode = Node.PROCESS_MODE_DISABLED
	if not pools.has(scene):
		pools[scene] = []
	pools[scene].append(effect)

func spawn_lightning(scene : PackedScene, points : PackedVector2Array, color : Color, width : float = 0.0) -> void:
	if not scene or points.size() < 2 or not can_spawn(scene, points[points.size() - 1], boltsPerCrowd):
		return
	var lightning : LightningClass = scene.instantiate()
	lightning.points = points
	lightning.color = color
	if width > 0.0:
		lightning.width = width
	get_tree().current_scene.add_child(lightning)

func on_effect_exiting(scene : PackedScene) -> void:
	aliveEffects[scene] = maxi(aliveEffects.get(scene, 1) - 1, 0)
	aliveTotal = maxi(aliveTotal - 1, 0)

func get_shake(scene : PackedScene) -> float:
	if not shakes.has(scene):
		var shake : float = 0.0
		var state : SceneState = scene.get_state()
		for i in state.get_node_property_count(0):
			if state.get_node_property_name(0, i) == &"shake":
				shake = state.get_node_property_value(0, i)
		shakes[scene] = shake
	return shakes[scene]

func add_status_visual(effect : Resource) -> bool:
	if not statusGroups.has(effect.effectName):
		statusGroups[effect.effectName] = []
	var group : Array = statusGroups[effect.effectName]
	group.append(effect)
	var position : Vector2 = get_status_position(effect)
	if not is_on_screen(position) or shownStatusVisuals >= maxStatusVisuals:
		return false
	var cell : Vector2i = get_cell(position)
	var nearby : int = 0
	for other : Resource in group:
		if other != effect and is_status_active(other) and is_visual_shown(other) and get_cell(get_status_position(other)) == cell:
			nearby += 1
	if nearby >= statusVisualsPerCrowd:
		return false
	shownStatusVisuals += 1
	return true

func update_status_visuals() -> void:
	var rect : Rect2 = get_view_rect()
	shownStatusVisuals = 0
	for effectName : String in statusGroups.keys():
		var group : Array = []
		for effect : Resource in statusGroups[effectName]:
			if is_status_active(effect):
				group.append(effect)
		if group.is_empty():
			statusGroups.erase(effectName)
			continue
		group.sort_custom(func(a : Resource, b : Resource) -> bool: return is_visual_shown(a) and not is_visual_shown(b))
		statusGroups[effectName] = group
		var cells : Dictionary[Vector2i, int] = {}
		for effect : Resource in group:
			var position : Vector2 = get_status_position(effect)
			var cell : Vector2i = get_cell(position)
			var shown : bool = rect.has_point(position) and cells.get(cell, 0) < statusVisualsPerCrowd and shownStatusVisuals < maxStatusVisuals
			if shown:
				cells[cell] = cells.get(cell, 0) + 1
				shownStatusVisuals += 1
			effect.status.set_visual_shown(effect, shown)

func is_status_active(effect : Resource) -> bool:
	var status : Variant = effect.status
	return is_instance_valid(status) and status.is_inside_tree() and status.activeEffects.get(effect.effectName) == effect

func get_status_position(effect : Resource) -> Vector2:
	return effect.status.get_visual_parent().global_position

func is_visual_shown(effect : Resource) -> bool:
	var visual : Variant = effect.visual
	return is_instance_valid(visual) and visual.visible

func get_cell(position : Vector2) -> Vector2i:
	return Vector2i((position / statusCrowdRadius).floor())

func add_cullable(node : Node2D) -> void:
	cullables.append(node)

func update_cullables() -> void:
	var rect : Rect2 = get_view_rect()
	for i in range(cullables.size() - 1, -1, -1):
		var node : Node2D = cullables[i]
		if not is_instance_valid(node) or not node.is_inside_tree():
			cullables.remove_at(i)
			continue
		node.visible = rect.has_point(node.global_position)

func update_warmup() -> void:
	if warmupLeft <= 0:
		return
	warmupLeft -= 1
	if warmupLeft == warmupFrames:
		var center : Vector2 = get_view_rect().get_center()
		warmup.global_position = center
		for path in find_scenes(warmupFolders):
			var scene : PackedScene = load(path)
			var node : Node = scene.instantiate()
			var effect : VfxEffectClass = node as VfxEffectClass
			if effect:
				effect.position = center
				effect.modulate.a = warmup.modulate.a
				add_to_pool(effect, scene)
				warmedEffects.append(effect)
				warmedScenes.append(scene)
			else:
				warmup.add_child(node)
	elif warmupLeft == 0:
		warmup.queue_free()
		for i in warmedEffects.size():
			warmedEffects[i].modulate.a = 1.0
			return_to_pool(warmedEffects[i], warmedScenes[i])
		warmedEffects.clear()
		warmedScenes.clear()

func find_scenes(folders : PackedStringArray) -> PackedStringArray:
	var scenes : PackedStringArray = []
	for folder in folders:
		for file in ResourceLoader.list_directory(folder):
			if file.ends_with("/"):
				scenes.append_array(find_scenes([folder + file]))
			elif file.ends_with(".tscn"):
				scenes.append(folder + file)
	return scenes
