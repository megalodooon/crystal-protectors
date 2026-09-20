extends Node2D


const SOURCE_SCENE := preload("res://waves/portal_source.tscn")
const OUT_PATH : String = "res://waves/portal.png"

@export var frameSize : Vector2i = Vector2i(96, 120)
@export var center : Vector2 = Vector2(48.0, 74.0)
@export var fps : float = 15.0
@export var loopFrames : int = 30
@export var openBurstFrames : int = 12
@export var spawnBurstFrames : int = 12
@export var closeBurstFrames : int = 9
@export var settleTime : float = 3.0
@export var alphaCutoff : int = 6

@onready var viewport : SubViewport = $SubViewport

var source : PortalSourceClass
var rows : Array[Array] = []

#------------------------#

func _ready() -> void:
	viewport.size = frameSize
	source = SOURCE_SCENE.instantiate()
	source.position = center
	viewport.add_child(source)
	bake()

func bake() -> void:
	source.set_warning(true)
	await settle()
	var warning : Array[Image] = await grab(loopFrames * 2)
	source.set_warning(false)
	source.update_state()
	source.open()
	await settle()
	var open : Array[Image] = await grab(loopFrames * 2)
	hide_loops()
	source.body.visible = false
	source.groundGlow.visible = false
	source.play_burst(source.openBurst)
	var openBurst : Array[Image] = await grab(openBurstFrames)
	await settle()
	source.play_burst(source.spawnBurst)
	var spawnBurst : Array[Image] = await grab(spawnBurstFrames)
	await settle()
	source.play_burst(source.closeBurst)
	var closeBurst : Array[Image] = await grab(closeBurstFrames)
	rows = [make_seamless(warning), make_seamless(open), openBurst, spawnBurst, closeBurst]
	save_sheet()
	get_tree().quit()

func hide_loops() -> void:
	for group : Node2D in [source.openLoop, source.warningLoop]:
		for child in group.get_children():
			if child is CPUParticles2D:
				child.emitting = false
				child.visible = false

func settle() -> void:
	var left : float = settleTime
	while left > 0.0:
		left -= await next_frame()

func next_frame() -> float:
	await RenderingServer.frame_post_draw
	return get_process_delta_time()

func grab(count : int) -> Array[Image]:
	var frames : Array[Image] = []
	var wait : float = 0.0
	while frames.size() < count:
		wait -= await next_frame()
		if wait <= 0.0:
			frames.append(viewport.get_texture().get_image())
			wait += 1.0 / fps
	return frames

func make_seamless(frames : Array[Image]) -> Array[Image]:
	var half : int = frames.size() / 2
	var blended : Array[Image] = []
	for i in half:
		blended.append(blend(frames[i], frames[i + half], float(i) / float(half)))
	return blended

func blend(first : Image, second : Image, weight : float) -> Image:
	var result : Image = Image.create_empty(first.get_width(), first.get_height(), false, Image.FORMAT_RGBA8)
	for y in first.get_height():
		for x in first.get_width():
			var a : Color = first.get_pixel(x, y)
			var b : Color = second.get_pixel(x, y)
			var alpha : float = lerpf(a.a, b.a, weight)
			var mixed : Color = Color(0.0, 0.0, 0.0, 0.0)
			if alpha > 0.0:
				mixed = (a * a.a * (1.0 - weight) + b * b.a * weight) / alpha
				mixed.a = alpha
			result.set_pixel(x, y, mixed)
	return result

func get_used_rect() -> Rect2i:
	var start : Vector2i = frameSize
	var end : Vector2i = Vector2i.ZERO
	for row in rows:
		for frame : Image in row:
			var pixels : PackedByteArray = frame.get_data()
			for y in frame.get_height():
				for x in frame.get_width():
					if pixels[(y * frame.get_width() + x) * 4 + 3] <= alphaCutoff:
						continue
					start = Vector2i(mini(start.x, x), mini(start.y, y))
					end = Vector2i(maxi(end.x, x), maxi(end.y, y))
	return Rect2i(start, end - start)

func save_sheet() -> void:
	var used : Rect2i = get_used_rect()
	var half : Vector2i = Vector2i(
		maxi(int(center.x) - used.position.x, used.end.x - int(center.x) + 1),
		maxi(int(center.y) - used.position.y, used.end.y - int(center.y) + 1))
	var frame : Vector2i = half * 2
	var origin : Vector2i = Vector2i(center) - half
	var columns : int = 0
	for row in rows:
		columns = maxi(columns, row.size())
	var sheet : Image = Image.create_empty(frame.x * columns, frame.y * rows.size(), false, Image.FORMAT_RGBA8)
	for r in rows.size():
		for c in rows[r].size():
			sheet.blit_rect(rows[r][c], Rect2i(origin, frame), Vector2i(frame.x * c, frame.y * r))
	sheet.save_png(ProjectSettings.globalize_path(OUT_PATH))
	print("portal sheet saved: ", OUT_PATH)
	print("frame ", frame, "  hframes ", columns, "  vframes ", rows.size())
	print("frameCounts = PackedInt32Array(", rows.map(func(row : Array) -> int: return row.size()), ")")
