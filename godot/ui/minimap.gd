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
@export var laneStep : float = 3.0

@export_group("Look")
@export var shadeColor : Color = Color(0.0, 0.0, 0.05, 0.35)
@export var outlineColor : Color = Color(0.03, 0.02, 0.05, 0.95)
@export var playerColor : Color = Color(1.0, 1.0, 1.0)
@export var lockedFade : float = 0.35
@export var laneWidth : float = 1.5
@export var laneOutline : float = 0.9
@export var portalRadius : float = 2.8
@export var towerRadius : float = 1.5
@export var enemyRadius : float = 0.9
@export var playerIconSize : float = 6.0

var unit : float = 1.0
var timer : float = 0.0
var lanePoints : Dictionary[EnemyPathClass, PackedVector2Array] = {}

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
	size = minimapSize * unit
	scale = Vector2.ONE / unit
	position = Vector2(get_canvas_size().x - minimapSize.x - margin, margin)
	lanePoints.clear()
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
	draw_rect(Rect2(Vector2.ZERO, size), Color(get_path_color(), 0.5), false, unit)

func draw_lanes() -> void:
	if not pathNetwork:
		return
	for path in pathNetwork.paths:
		draw_lane(path, laneWidth + laneOutline * 2.0, outlineColor)
	for path in pathNetwork.paths:
		draw_lane(path, laneWidth, fade(get_path_color(), path.active))
	for path in pathNetwork.paths:
		draw_lane(path, laneWidth * 0.4, fade(get_core_color(), path.active))

func draw_lane(path : EnemyPathClass, width : float, color : Color) -> void:
	var points : PackedVector2Array = get_lane_points(path)
	if points.size() < 2:
		return
	draw_polyline(points, color, width * unit, true)

func get_lane_points(path : EnemyPathClass) -> PackedVector2Array:
	if lanePoints.has(path):
		return lanePoints[path]
	var points : PackedVector2Array = []
	var length : float = path.get_length()
	if length > 0.0:
		var steps : int = maxi(int(length / laneStep), 1)
		for i in steps + 1:
			points.append(to_map(path.get_global_point(length * float(i) / float(steps))))
	lanePoints[path] = points
	return points

func draw_portals() -> void:
	if not waveManager:
		return
	for portal in waveManager.portals:
		var open : bool = portal.path == null or portal.path.active
		var spot : Vector2 = to_map(portal.global_position)
		var color : Color = fade(portal.color, open)
		draw_circle(spot, (portalRadius + 0.7) * unit, outlineColor)
		draw_circle(spot, portalRadius * unit, Color(color, 0.4))
		draw_arc(spot, portalRadius * unit, 0.0, TAU, 28, color, 0.9 * unit, true)
		draw_circle(spot, portalRadius * 0.4 * unit, fade(color.lerp(Color.WHITE, 0.65), open))

func draw_towers() -> void:
	if not towerBuilder:
		return
	for tower in towerBuilder.built:
		var spot : Vector2 = to_map(tower.global_position)
		draw_circle(spot, (towerRadius + 0.7) * unit, outlineColor)
		draw_circle(spot, towerRadius * unit, tower.get_color())

func draw_enemies() -> void:
	if not waveManager:
		return
	for enemy in waveManager.get_enemy_parent().get_children():
		if enemy is EnemyClass:
			var spot : Vector2 = to_map(enemy.global_position)
			draw_circle(spot, (enemyRadius + 0.5) * unit, outlineColor)
			draw_circle(spot, enemyRadius * unit, enemy.sprite.modulate)

func draw_player() -> void:
	if not player:
		return
	var spot : Vector2 = to_map(player.global_position)
	var icon : Texture2D = get_player_icon()
	if not icon:
		draw_circle(spot, 1.7 * unit, outlineColor)
		draw_circle(spot, 1.1 * unit, playerColor)
		return
	draw_circle(spot, playerIconSize * 0.42 * unit, outlineColor)
	var iconSize : Vector2 = Vector2.ONE * playerIconSize * unit
	draw_texture_rect(icon, Rect2(spot - iconSize / 2.0, iconSize), false)

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

func to_map(spot : Vector2) -> Vector2:
	return spot / mapSize * size
