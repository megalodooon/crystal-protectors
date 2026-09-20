extends Control
class_name MinimapClass


@export var pathNetwork : PathNetworkClass
@export var waveManager : WaveManagerClass
@export var towerBuilder : TowerBuilderClass
@export var player : Node2D
@export var mapSize : Vector2 = Vector2(512.0, 288.0)
@export var minimapSize : Vector2 = Vector2(64.0, 36.0)
@export var margin : float = 2.0
@export var groundTexture : Texture2D
@export var playerIcon : Texture2D
@export var updateInterval : float = 0.05
@export var detailScale : int = 0
@export_range(0.125, 1.0) var pixelScale : float = 0.5

@export_group("Look")
@export var shadeColor : Color = Color(0.0, 0.0, 0.05, 0.35)
@export var outlineColor : Color = Color(0.03, 0.02, 0.05, 0.95)
@export var playerColor : Color = Color(1.0, 1.0, 1.0)
@export var lockedFade : float = 0.35
@export var laneOutline : int = 5
@export var laneBody : int = 3
@export var laneCore : int = 1
@export var portalRadius : Vector2i = Vector2i(3, 4)
@export var towerBlock : int = 3
@export var enemyBlock : int = 2
@export var playerIconSize : float = 6.0

var unit : float = 1.0
var pixel : float = 1.0
var timer : float = 0.0
var laneCells : Dictionary[EnemyPathClass, PackedVector2Array] = {}

#------------------------#

func _ready() -> void:
	get_viewport().size_changed.connect(apply_scale)
	apply_scale()

func _process(delta : float) -> void:
	timer += delta
	if timer < updateInterval:
		return
	timer = 0.0
	queue_redraw()

func apply_scale() -> void:
	unit = float(get_detail_scale())
	pixel = maxf(roundf(unit * pixelScale), 1.0)
	size = minimapSize * unit
	scale = Vector2.ONE / unit
	position = Vector2(get_canvas_size().x - minimapSize.x - margin, margin)
	laneCells.clear()
	queue_redraw()

func get_detail_scale() -> int:
	if detailScale > 0:
		return detailScale
	var window : Vector2 = Vector2(get_window().size)
	var canvas : Vector2 = get_canvas_size()
	return maxi(int(minf(window.x / canvas.x, window.y / canvas.y)), 1)

func get_canvas_size() -> Vector2:
	var width : int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height : int = ProjectSettings.get_setting("display/window/size/viewport_height")
	return Vector2(float(width), float(height))

func get_canvas_rect() -> Rect2:
	return Rect2(position, minimapSize)

func _draw() -> void:
	if groundTexture:
		draw_texture_rect_region(groundTexture, Rect2(Vector2.ZERO, size), Rect2(Vector2.ZERO, mapSize))
	draw_rect(Rect2(Vector2.ZERO, size), shadeColor)
	draw_lanes()
	draw_portals()
	draw_towers()
	draw_enemies()
	draw_player()
	draw_rect(Rect2(Vector2.ZERO, size), Color(get_path_color(), 0.5), false, pixel)

func draw_lanes() -> void:
	if not pathNetwork:
		return
	var ordered : Array[EnemyPathClass] = get_ordered_paths()
	for path in ordered:
		draw_lane(path, laneOutline, outlineColor)
	for path in ordered:
		draw_lane(path, laneBody, fade(get_path_color(), path.active))
	for path in ordered:
		draw_lane(path, laneCore, fade(get_core_color(), path.active))

func get_ordered_paths() -> Array[EnemyPathClass]:
	var ordered : Array[EnemyPathClass] = []
	for path in pathNetwork.paths:
		if not path.active:
			ordered.append(path)
	for path in pathNetwork.paths:
		if path.active:
			ordered.append(path)
	return ordered

func draw_lane(path : EnemyPathClass, thickness : int, color : Color) -> void:
	for cell in get_lane_cells(path):
		draw_block(cell, thickness, color)

func get_lane_cells(path : EnemyPathClass) -> PackedVector2Array:
	if laneCells.has(path):
		return laneCells[path]
	var cells : PackedVector2Array = []
	var seen : Dictionary[Vector2, bool] = {}
	var length : float = path.get_length()
	if length > 0.0:
		var steps : int = maxi(int(length / (mapSize.x / size.x * pixel)) * 2, 1)
		for i in steps + 1:
			var cell : Vector2 = to_cell(path.get_global_point(length * float(i) / float(steps)))
			if not seen.has(cell):
				seen[cell] = true
				cells.append(cell)
	laneCells[path] = cells
	return cells

func draw_portals() -> void:
	if not waveManager:
		return
	for portal in waveManager.portals:
		draw_portal(portal)

func draw_portal(portal : PortalClass) -> void:
	var open : bool = portal.path == null or portal.path.active
	var center : Vector2 = to_cell(portal.global_position)
	var rim : Color = fade(portal.color, open)
	var core : Color = fade(portal.color.lerp(Color.WHITE, 0.5), open)
	var hole : Color = fade(portal.voidColor, open)
	for y in range(-portalRadius.y - 1, portalRadius.y + 2):
		for x in range(-portalRadius.x - 1, portalRadius.x + 2):
			var spread : float = Vector2(float(x) / float(portalRadius.x), float(y) / float(portalRadius.y)).length()
			if spread > 1.2:
				continue
			var cellColor : Color = hole
			if spread > 1.0:
				cellColor = outlineColor
			elif spread > 0.78:
				cellColor = core
			elif spread > 0.5:
				cellColor = rim
			draw_block(center + Vector2(float(x), float(y)), 1, cellColor)

func draw_towers() -> void:
	if not towerBuilder:
		return
	for tower in towerBuilder.built:
		var cell : Vector2 = to_cell(tower.global_position)
		draw_block(cell, towerBlock + 2, outlineColor)
		draw_block(cell, towerBlock, tower.get_color())

func draw_enemies() -> void:
	if not waveManager:
		return
	for enemy in waveManager.get_enemy_parent().get_children():
		if enemy is EnemyClass:
			var cell : Vector2 = to_cell(enemy.global_position)
			draw_block(cell, enemyBlock + 2, outlineColor)
			draw_block(cell, enemyBlock, enemy.sprite.modulate)

func draw_player() -> void:
	if not player:
		return
	var cell : Vector2 = to_cell(player.global_position)
	var icon : Texture2D = get_player_icon()
	if not icon:
		draw_block(cell, 4, outlineColor)
		draw_block(cell, 2, playerColor)
		return
	draw_block(cell, int(playerIconSize * unit / pixel) - 2, outlineColor)
	var iconSize : Vector2 = Vector2.ONE * playerIconSize * unit
	draw_texture_rect(icon, Rect2((cell * pixel).round() - iconSize / 2.0, iconSize), false)

func draw_block(cell : Vector2, thickness : int, color : Color) -> void:
	if thickness <= 0:
		return
	var half : float = float(thickness) * 0.5 - 0.5
	draw_rect(Rect2((cell - Vector2.ONE * half) * pixel, Vector2.ONE * float(thickness) * pixel), color)

func to_cell(spot : Vector2) -> Vector2:
	return (spot / mapSize * size / pixel).floor()

func get_player_icon() -> Texture2D:
	if playerIcon:
		return playerIcon
	var sprite : Sprite2D = player.get_node_or_null("Visuals/Sprite2D")
	if sprite:
		return sprite.texture
	return null

func get_path_color() -> Color:
	if pathNetwork and pathNetwork.style:
		return pathNetwork.style.color
	return Color(0.62, 0.3, 1.0)

func get_core_color() -> Color:
	if pathNetwork and pathNetwork.style:
		return pathNetwork.style.coreColor
	return Color(0.9, 0.78, 1.0)

func fade(color : Color, active : bool) -> Color:
	return color if active else color.darkened(1.0 - lockedFade)
