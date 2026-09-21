extends Control
class_name MinimapClass


@export var pathNetwork : PathNetworkClass
@export var waveManager : WaveManagerClass
@export var towerBuilder : TowerBuilderClass
@export var player : Node2D
@export var mapSize : Vector2 = Vector2(512.0, 288.0)
@export var minimapSize : float = 36.0
@export var viewSize : float = 160.0
@export var margin : float = 2.0
@export var groundTexture : Texture2D
@export var playerIcon : Texture2D
@export var detailScale : int = 0
@export_range(0.125, 1.0) var pixelScale : float = 0.5

@export_group("Look")
@export var shadeColor : Color = Color(0.0, 0.0, 0.05, 0.3)
@export var frameColor : Color = Color(0.08, 0.06, 0.09)
@export var outlineColor : Color = Color(0.05, 0.03, 0.07)
@export var playerColor : Color = Color(1.0, 1.0, 1.0)
@export var lockedFade : float = 0.4
@export var laneOutline : int = 3
@export var laneCore : int = 1
@export var portalSize : float = 8.0
@export var towerBlock : int = 2
@export var enemyBlock : int = 2
@export var playerBlock : int = 2
@export var playerIconSize : float = 5.0

var unit : float = 1.0
var pixel : float = 1.0
var cells : int = 1
var worldPerCell : float = 1.0
var view : Rect2 = Rect2()
var groundImage : Image
var mapTexture : ImageTexture
var portalSprites : Dictionary[PortalClass, Sprite2D] = {}

#------------------------#

func _ready() -> void:
	clip_contents = true
	get_viewport().size_changed.connect(apply_scale)
	start.call_deferred()

func start() -> void:
	if pathNetwork:
		for path in pathNetwork.paths:
			path.active_changed.connect(bake)
	apply_scale()

func _process(_delta : float) -> void:
	update_view()
	update_portals()
	queue_redraw()

func apply_scale() -> void:
	unit = float(get_detail_scale())
	pixel = maxf(roundf(unit * pixelScale), 1.0)
	size = Vector2.ONE * minimapSize * unit
	scale = Vector2.ONE / unit
	position = Vector2(get_canvas_size().x - minimapSize - margin, margin)
	cells = int(size.x / pixel)
	worldPerCell = viewSize / float(cells)
	groundImage = null
	bake()

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
	return Rect2(position, Vector2.ONE * minimapSize)

#-------------BAKING-------------#

func bake() -> void:
	bake_map()
	bake_portals()
	queue_redraw()

func bake_map() -> void:
	if not groundImage:
		bake_ground()
	var mapImage : Image = groundImage.duplicate()
	if pathNetwork:
		for path in get_ordered_paths():
			stamp_lane(mapImage, path, laneOutline, outlineColor)
		for path in get_ordered_paths():
			stamp_lane(mapImage, path, laneCore, fade(get_core_color(), path.active))
	mapTexture = ImageTexture.create_from_image(mapImage)

func bake_ground() -> void:
	var mapCells : Vector2i = Vector2i((mapSize / worldPerCell).ceil())
	groundImage = Image.create_empty(mapCells.x, mapCells.y, false, Image.FORMAT_RGBA8)
	if not groundTexture:
		groundImage.fill(Color(0.1, 0.1, 0.12))
		return
	var ground : Image = groundTexture.get_image()
	if ground.is_compressed():
		ground.decompress()
	for y in mapCells.y:
		for x in mapCells.x:
			var spot : Vector2i = Vector2i(Vector2(float(x), float(y)) * worldPerCell)
			var tone : Color = ground.get_pixel(spot.x % ground.get_width(), spot.y % ground.get_height())
			groundImage.set_pixel(x, y, tone.lerp(Color(shadeColor, 1.0), shadeColor.a))

func stamp_lane(image : Image, path : EnemyPathClass, thickness : int, color : Color) -> void:
	var length : float = path.get_length()
	if length <= 0.0:
		return
	var steps : int = maxi(int(length / (worldPerCell * 0.7)), 1)
	var half : int = (thickness - 1) / 2
	var bounds : Rect2i = Rect2i(Vector2i.ZERO, image.get_size())
	for i in steps + 1:
		var cell : Vector2i = Vector2i((path.get_global_point(length * float(i) / float(steps)) / worldPerCell).floor())
		var block : Rect2i = Rect2i(cell - Vector2i.ONE * half, Vector2i.ONE * thickness).intersection(bounds)
		if block.has_area():
			image.fill_rect(block, color)

func bake_portals() -> void:
	for sprite : Sprite2D in portalSprites.values():
		sprite.queue_free()
	portalSprites.clear()
	if not waveManager:
		return
	for portal in waveManager.portals:
		portalSprites[portal] = make_portal(portal)

func make_portal(portal : PortalClass) -> Sprite2D:
	var body : Sprite2D = portal.body
	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = body.texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = body.scale * portalSize * unit / (float(body.texture.get_height()) * body.scale.y)
	var shader : ShaderMaterial = ShaderMaterial.new()
	shader.shader = (body.material as ShaderMaterial).shader
	shader.set_shader_parameter("glowColor", portal.color)
	shader.set_shader_parameter("coreColor", portal.color.lerp(Color.WHITE, 0.55))
	shader.set_shader_parameter("voidColor", portal.voidColor)
	shader.set_shader_parameter("intensity", 1.0 if is_open(portal) else lockedFade)
	shader.set_shader_parameter("flash", 0.0)
	sprite.material = shader
	add_child(sprite)
	return sprite

#-------------DRAWING-------------#

func update_view() -> void:
	var center : Vector2 = player.global_position if player else mapSize / 2.0
	var origin : Vector2 = center - Vector2.ONE * viewSize / 2.0
	origin.x = clampf(origin.x, 0.0, maxf(mapSize.x - viewSize, 0.0))
	origin.y = clampf(origin.y, 0.0, maxf(mapSize.y - viewSize, 0.0))
	view = Rect2((origin / worldPerCell).floor() * worldPerCell, Vector2.ONE * viewSize)

func update_portals() -> void:
	for portal : PortalClass in portalSprites:
		var sprite : Sprite2D = portalSprites[portal]
		sprite.visible = view.has_point(portal.global_position)
		if sprite.visible:
			sprite.position = (to_cell(portal.global_position) * pixel).round()

func _draw() -> void:
	if not mapTexture:
		return
	var offset : Vector2 = (view.position / worldPerCell).round()
	draw_texture_rect_region(mapTexture, Rect2(Vector2.ZERO, size), Rect2(offset, Vector2.ONE * float(cells)))
	draw_towers()
	draw_enemies()
	draw_player()
	draw_rect(Rect2(Vector2.ZERO, size), frameColor, false, unit)

func draw_towers() -> void:
	if not towerBuilder:
		return
	for tower in towerBuilder.built:
		draw_marker(tower.global_position, towerBlock, tower.get_color())

func draw_enemies() -> void:
	if not waveManager:
		return
	for enemy in waveManager.get_enemy_parent().get_children():
		if enemy is EnemyClass:
			draw_marker(enemy.global_position, enemyBlock, enemy.sprite.modulate)

func draw_player() -> void:
	if not player:
		return
	if not playerIcon:
		draw_marker(player.global_position, playerBlock, playerColor)
		return
	var iconSize : Vector2 = Vector2.ONE * playerIconSize * unit
	var spot : Vector2 = (to_cell(player.global_position) * pixel).round()
	draw_texture_rect(playerIcon, Rect2(spot - iconSize / 2.0, iconSize), false)

func draw_marker(spot : Vector2, block : int, color : Color) -> void:
	if not view.has_point(spot):
		return
	var cell : Vector2 = to_cell(spot)
	draw_block(cell, block + 2, outlineColor)
	draw_block(cell, block, color)

func draw_block(cell : Vector2, thickness : int, color : Color) -> void:
	var half : float = float(thickness) * 0.5 - 0.5
	draw_rect(Rect2((cell - Vector2.ONE * half) * pixel, Vector2.ONE * float(thickness) * pixel), color)

func to_cell(spot : Vector2) -> Vector2:
	return ((spot - view.position) / worldPerCell).floor()

#-------------HELPERS-------------#

func get_ordered_paths() -> Array[EnemyPathClass]:
	var ordered : Array[EnemyPathClass] = []
	for path in pathNetwork.paths:
		if not path.active:
			ordered.append(path)
	for path in pathNetwork.paths:
		if path.active:
			ordered.append(path)
	return ordered

func is_open(portal : PortalClass) -> bool:
	return portal.path == null or portal.path.active

func get_core_color() -> Color:
	if pathNetwork and pathNetwork.style:
		return pathNetwork.style.coreColor
	return Color(0.9, 0.78, 1.0)

func fade(color : Color, active : bool) -> Color:
	return color if active else color.darkened(1.0 - lockedFade)
