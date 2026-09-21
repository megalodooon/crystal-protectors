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
@export_flags_2d_render var mapLayer : int = 512
@export var playerIcon : Texture2D
@export var detailScale : int = 0
@export_range(0.125, 1.0) var pixelScale : float = 0.5

@export_group("Look")
@export var emptyColor : Color = Color(0.1, 0.1, 0.12)
@export var frameColor : Color = Color(0.08, 0.06, 0.09)
@export var outlineColor : Color = Color(0.05, 0.03, 0.07)
@export var playerColor : Color = Color(1.0, 1.0, 1.0)
@export_range(0.0, 1.0) var laneCore : float = 0.7
@export_range(0.0, 1.0) var laneGlow : float = 0.4
@export_range(0.0, 1.0) var lockedStrength : float = 0.08
@export_range(0.0, 1.0) var lockedPortal : float = 0.2
@export var portalSize : float = 8.0
@export var towerBlock : int = 2
@export var enemyBlock : int = 2
@export var playerBlock : int = 2
@export var playerIconSize : float = 5.0
@export var maxMarkers : int = 600

var unit : float = 1.0
var pixel : float = 1.0
var cells : int = 1
var worldPerCell : float = 1.0
var view : Rect2 = Rect2()
var groundImage : Image
var mapTexture : ImageTexture
var portalSprites : Dictionary[PortalClass, Sprite2D] = {}
var textureColors : Dictionary[Texture2D, Color] = {}
var lookColors : Dictionary[Node2D, Color] = {}
var markers : MultiMesh
var markerCount : int = 0
var laneGray : bool = false
var bakeId : int = 0

#------------------------#

func _ready() -> void:
	clip_contents = true
	make_markers()
	get_viewport().size_changed.connect(apply_scale)
	start.call_deferred()

func start() -> void:
	if pathNetwork:
		pathNetwork.pulses_rebuilt.connect(bake_map)
		for path in pathNetwork.paths:
			path.active_changed.connect(bake_portals)
	apply_scale()

func _process(_delta : float) -> void:
	if pathNetwork and is_lane_gray() != laneGray:
		bake_map()
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
	bake_ground()

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

func bake_ground() -> void:
	bakeId += 1
	var id : int = bakeId
	var mapCells : Vector2i = Vector2i((mapSize / worldPerCell).ceil())
	var camera : SubViewport = SubViewport.new()
	camera.size = mapCells
	camera.transparent_bg = true
	camera.disable_3d = true
	camera.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(camera)
	camera.world_2d = get_viewport().world_2d
	camera.canvas_cull_mask = mapLayer
	camera.canvas_transform = Transform2D.IDENTITY.scaled(Vector2.ONE / worldPerCell)
	await RenderingServer.frame_post_draw
	var image : Image = camera.get_texture().get_image()
	camera.queue_free()
	if id != bakeId:
		return
	image.convert(Image.FORMAT_RGBA8)
	var backdrop : Image = Image.create_empty(mapCells.x, mapCells.y, false, Image.FORMAT_RGBA8)
	backdrop.fill(emptyColor)
	backdrop.blend_rect(image, Rect2i(Vector2i.ZERO, mapCells), Vector2i.ZERO)
	groundImage = backdrop
	bake()

func bake_map() -> void:
	laneGray = is_lane_gray()
	if not groundImage:
		return
	var mapImage : Image = groundImage.duplicate()
	if pathNetwork:
		var lit : Dictionary[Vector2i, float] = {}
		var locked : Dictionary[Vector2i, float] = {}
		for path in pathNetwork.paths:
			collect_lane(path, lit if is_shown(path) else locked)
		var style : PathPulseStyleClass = pathNetwork.style
		var gray : float = 1.0 if laneGray else 0.0
		var opacity : float = lerpf(1.0, style.waveOpacity, gray)
		var glow : Color = PathDotClass.get_gray_color(style.color, gray) * style.glowStrength * laneGlow * opacity
		var core : Color = PathDotClass.get_gray_color(style.coreColor, gray) * laneCore * opacity
		var lockedColor : Color = PathDotClass.get_gray_color(style.coreColor, 1.0) * lockedStrength
		for cell in locked:
			if not lit.has(cell) and locked[cell] >= 1.0:
				add_light(mapImage, cell, lockedColor)
		for cell in lit:
			add_light(mapImage, cell, glow * lit[cell] + core * maxf(lit[cell] - 0.5, 0.0) * 2.0)
	mapTexture = ImageTexture.create_from_image(mapImage)

func collect_lane(path : EnemyPathClass, lane : Dictionary[Vector2i, float]) -> void:
	var length : float = path.get_length()
	if length <= 0.0:
		return
	var steps : int = maxi(int(length / (worldPerCell * 0.7)), 1)
	for i in steps + 1:
		var cell : Vector2i = Vector2i((path.get_global_point(length * float(i) / float(steps)) / worldPerCell).floor())
		lane[cell] = 1.0
		for side : Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			lane[cell + side] = maxf(lane.get(cell + side, 0.0), 0.5)

func add_light(image : Image, cell : Vector2i, light : Color) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= image.get_width() or cell.y >= image.get_height():
		return
	var base : Color = image.get_pixelv(cell)
	image.set_pixelv(cell, Color(minf(base.r + light.r, 1.0), minf(base.g + light.g, 1.0), minf(base.b + light.b, 1.0), 1.0))

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
	var open : bool = is_open(portal)
	var gray : float = 0.0 if open else 1.0
	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = body.texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = body.scale * portalSize * unit / (float(body.texture.get_height()) * body.scale.y)
	var shader : ShaderMaterial = ShaderMaterial.new()
	shader.shader = (body.material as ShaderMaterial).shader
	shader.set_shader_parameter("glowColor", PathDotClass.get_gray_color(portal.color, gray))
	shader.set_shader_parameter("coreColor", PathDotClass.get_gray_color(portal.color.lerp(Color.WHITE, 0.55), gray))
	shader.set_shader_parameter("voidColor", PathDotClass.get_gray_color(portal.voidColor, gray))
	shader.set_shader_parameter("intensity", 1.0 if open else lockedPortal)
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
	markerCount = 0
	add_towers()
	add_enemies()
	add_player()
	markers.visible_instance_count = markerCount
	draw_multimesh(markers, null)
	if playerIcon and player:
		var iconSize : Vector2 = Vector2.ONE * playerIconSize * unit
		var spot : Vector2 = (to_cell(player.global_position) * pixel).round()
		draw_texture_rect(playerIcon, Rect2(spot - iconSize / 2.0, iconSize), false)
	draw_rect(Rect2(Vector2.ZERO, size), frameColor, false, unit)

func add_towers() -> void:
	if not towerBuilder:
		return
	for tower in towerBuilder.built:
		add_marker(tower.global_position, towerBlock, get_look_color(tower.visuals))

func add_enemies() -> void:
	if not waveManager:
		return
	if lookColors.size() > waveManager.enemies.size() * 2 + 16:
		lookColors.clear()
	for enemy in waveManager.enemies:
		if is_instance_valid(enemy) and view.has_point(enemy.global_position):
			if not lookColors.has(enemy):
				lookColors[enemy] = get_look_color(enemy.visuals)
			add_marker(enemy.global_position, enemyBlock, lookColors[enemy])

func add_player() -> void:
	if player and not playerIcon:
		add_marker(player.global_position, playerBlock, playerColor)

func add_marker(spot : Vector2, block : int, color : Color) -> void:
	if not view.has_point(spot) or markerCount >= markers.instance_count:
		return
	var cell : Vector2 = to_cell(spot)
	var extent : float = float(block) * pixel
	markers.set_instance_transform_2d(markerCount, Transform2D(0.0, Vector2.ONE * extent, 0.0, (cell + Vector2.ONE * 0.5) * pixel))
	markers.set_instance_color(markerCount, color)
	markerCount += 1

func make_markers() -> void:
	var inner : float = 0.5
	var outer : float = inner + 1.0 / float(maxi(enemyBlock, 1))
	var dark : Color = Color(outlineColor, 1.0)
	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(-outer, -outer), Vector2(outer, -outer), Vector2(outer, outer), Vector2(-outer, outer), Vector2(-inner, -inner), Vector2(inner, -inner), Vector2(inner, inner), Vector2(-inner, inner)])
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray([dark, dark, dark, dark, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7])
	var quad : ArrayMesh = ArrayMesh.new()
	quad.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	markers = MultiMesh.new()
	markers.transform_format = MultiMesh.TRANSFORM_2D
	markers.use_colors = true
	markers.mesh = quad
	markers.instance_count = maxMarkers

func to_cell(spot : Vector2) -> Vector2:
	return ((spot - view.position) / worldPerCell).floor()

#-------------HELPERS-------------#

func is_lane_gray() -> bool:
	return pathNetwork != null and not pathNetwork.isPlaying

func is_shown(path : EnemyPathClass) -> bool:
	return path.active and path.pulse and not path.pulse.sources.is_empty()

func is_open(portal : PortalClass) -> bool:
	return portal.path == null or portal.path.active

func get_look_color(visuals : Node2D) -> Color:
	for child in visuals.get_children():
		var sprite : Sprite2D = child as Sprite2D
		if sprite and sprite.texture and sprite.visible:
			return get_texture_color(sprite.texture) * sprite.modulate * sprite.self_modulate
	return Color.WHITE

func get_texture_color(texture : Texture2D) -> Color:
	if textureColors.has(texture):
		return textureColors[texture]
	var image : Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	var total : Color = Color(0.0, 0.0, 0.0, 0.0)
	var weight : float = 0.0
	for y in image.get_height():
		for x in image.get_width():
			var pixelColor : Color = image.get_pixel(x, y)
			if pixelColor.a > 0.5:
				var pixelWeight : float = 0.25 + pixelColor.s * pixelColor.v
				total += pixelColor * pixelWeight
				weight += pixelWeight
	var color : Color = Color(total / weight, 1.0) if weight > 0.0 else Color.WHITE
	textureColors[texture] = color
	return color
