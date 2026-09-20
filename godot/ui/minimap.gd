extends Control
class_name MinimapClass


@export var pathNetwork : PathNetworkClass
@export var waveManager : WaveManagerClass
@export var towerBuilder : TowerBuilderClass
@export var player : Node2D
@export var mapSize : Vector2 = Vector2(512.0, 288.0)
@export var groundTexture : Texture2D
@export var updateInterval : float = 0.1
@export var pathStep : float = 3.0

@export_group("Look")
@export var shadeColor : Color = Color(0.0, 0.0, 0.05, 0.35)
@export var outlineColor : Color = Color(0.03, 0.02, 0.05, 0.9)
@export var lockedFade : float = 0.35
@export var playerColor : Color = Color(1.0, 1.0, 1.0)
@export var portalSize : int = 3
@export var towerSize : int = 2

var timer : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	timer += delta
	if timer < updateInterval:
		return
	timer = 0.0
	queue_redraw()

func _draw() -> void:
	if groundTexture:
		draw_texture_rect_region(groundTexture, Rect2(Vector2.ZERO, size), Rect2(Vector2.ZERO, mapSize))
	draw_rect(Rect2(Vector2.ZERO, size), shadeColor)
	draw_paths()
	draw_portals()
	draw_units()
	draw_rect(Rect2(Vector2.ZERO, size), Color(get_path_color(), 0.45), false, 1.0)

func draw_paths() -> void:
	if not pathNetwork:
		return
	for path in pathNetwork.paths:
		draw_path(path, 3, outlineColor)
	for path in pathNetwork.paths:
		draw_path(path, 2, fade(get_path_color(), path.active))
	for path in pathNetwork.paths:
		draw_path(path, 1, fade(get_core_color(), path.active))

func draw_path(path : EnemyPathClass, width : int, color : Color) -> void:
	var length : float = path.get_length()
	if length <= 0.0:
		return
	var steps : int = maxi(int(length / pathStep), 1)
	for i in steps + 1:
		draw_pixel(path.get_global_point(length * float(i) / float(steps)), width, color)

func draw_portals() -> void:
	if not waveManager:
		return
	for portal in waveManager.portals:
		var open : bool = portal.path == null or portal.path.active
		draw_pixel(portal.global_position, portalSize + 2, outlineColor)
		draw_pixel(portal.global_position, portalSize, fade(portal.color, open))
		draw_pixel(portal.global_position, 1, fade(Color.WHITE, open))

func draw_units() -> void:
	if towerBuilder:
		for tower in towerBuilder.built:
			draw_pixel(tower.global_position, towerSize + 2, outlineColor)
			draw_pixel(tower.global_position, towerSize, tower.get_color())
	if waveManager:
		for enemy in waveManager.get_enemy_parent().get_children():
			if enemy is EnemyClass:
				draw_pixel(enemy.global_position, 1, enemy.sprite.modulate)
	if player:
		draw_pixel(player.global_position, 3, outlineColor)
		draw_pixel(player.global_position, 1, playerColor)

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

func draw_pixel(spot : Vector2, pixelSize : int, color : Color) -> void:
	var point : Vector2 = (spot / mapSize * size).floor() - Vector2.ONE * float(pixelSize / 2)
	draw_rect(Rect2(point, Vector2.ONE * float(pixelSize)), color)
