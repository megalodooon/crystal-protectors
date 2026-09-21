extends Node2D
class_name LightningClass


const GLOW_TEXTURE := preload("res://vfx/shared/soft_glow.tres")
const MESH_VARIANTS : int = 6

@export var duration : float = 0.32
@export var segmentLength : float = 4.0
@export var jaggedness : float = 5.0
@export var width : float = 1.4
@export var flickerTime : float = 0.06
@export_range(0.0, 1.0) var branchChance : float = 0.35
@export var endGlowSize : float = 14.0

static var meshCache : Dictionary[String, Array] = {}

var points : PackedVector2Array = []
var color : Color = Color.WHITE
var elapsed : float = 0.0
var flickerTimer : float = 0.0
var flicker : float = 1.0
var boltMeshes : Array[ArrayMesh] = []
var boltTransforms : Array[Transform2D] = []

#------------------------#

static func create_bolt(from : Vector2, to : Vector2, stepLength : float, jagged : float) -> PackedVector2Array:
	var bolt : PackedVector2Array = [from, to]
	var offset : float = minf(jagged, from.distance_to(to) * 0.25)
	while bolt.size() < 64 and bolt[0].distance_to(bolt[1]) > stepLength:
		var detailed : PackedVector2Array = [bolt[0]]
		for i in bolt.size() - 1:
			var side : Vector2 = bolt[i].direction_to(bolt[i + 1]).orthogonal()
			detailed.append((bolt[i] + bolt[i + 1]) / 2.0 + side * randf_range(-offset, offset))
			detailed.append(bolt[i + 1])
		bolt = detailed
		offset *= 0.55
	return bolt

static func add_bolt(targetPoints : PackedVector2Array, targetColors : PackedColorArray, targetIndices : PackedInt32Array, bolt : PackedVector2Array, boltWidth : float, boltColor : Color, taper : float = 0.0) -> void:
	var count : int = bolt.size()
	if count < 2 or boltWidth <= 0.01 or boltColor.a <= 0.01:
		return
	var edge : Color = Color(boltColor, 0.0)
	var first : int = targetPoints.size()
	var firstIndex : int = targetIndices.size()
	targetPoints.resize(first + count * 3)
	targetColors.resize(first + count * 3)
	targetIndices.resize(firstIndex + (count - 1) * 12)
	for i in count:
		var direction : Vector2 = bolt[mini(i + 1, count - 1)] - bolt[maxi(i - 1, 0)]
		var side : Vector2 = direction.normalized().orthogonal() * boltWidth * (1.0 - taper * float(i) / (count - 1))
		var v : int = first + i * 3
		targetPoints[v] = bolt[i] + side
		targetPoints[v + 1] = bolt[i]
		targetPoints[v + 2] = bolt[i] - side
		targetColors[v] = edge
		targetColors[v + 1] = boltColor
		targetColors[v + 2] = edge
	for i in count - 1:
		var a : int = first + i * 3
		var b : int = a + 3
		var n : int = firstIndex + i * 12
		targetIndices[n] = a
		targetIndices[n + 1] = b
		targetIndices[n + 2] = b + 1
		targetIndices[n + 3] = a
		targetIndices[n + 4] = b + 1
		targetIndices[n + 5] = a + 1
		targetIndices[n + 6] = a + 2
		targetIndices[n + 7] = b + 2
		targetIndices[n + 8] = b + 1
		targetIndices[n + 9] = a + 2
		targetIndices[n + 10] = b + 1
		targetIndices[n + 11] = a + 1

static func add_layers(targetPoints : PackedVector2Array, targetColors : PackedColorArray, targetIndices : PackedInt32Array, bolt : PackedVector2Array, boltWidth : float, boltColor : Color, alpha : float, taper : float = 0.0) -> void:
	add_bolt(targetPoints, targetColors, targetIndices, bolt, boltWidth * 3.5, Color(boltColor, alpha * 0.25), taper)
	add_bolt(targetPoints, targetColors, targetIndices, bolt, boltWidth * 1.3, Color(boltColor.lerp(Color.WHITE, 0.25), alpha * 0.85), taper)
	add_bolt(targetPoints, targetColors, targetIndices, bolt, boltWidth * 0.55, Color(1.0, 1.0, 1.0, alpha), taper)

static func draw_bolt_mesh(canvas : CanvasItem, targetPoints : PackedVector2Array, targetColors : PackedColorArray, targetIndices : PackedInt32Array) -> void:
	if not targetIndices.is_empty():
		RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), targetIndices, targetPoints, targetColors)

static func snap_length(length : float) -> float:
	if length < 16.0:
		return maxf(roundf(length), 1.0)
	return snappedf(length, 4.0)

static func get_bolt_mesh(length : float, stepLength : float, jagged : float, boltWidth : float, boltColor : Color, taper : float, branches : float = 0.0) -> ArrayMesh:
	var snappedLength : float = snap_length(length)
	var key : String = "%d %.2f %.2f %.2f %s %.2f %.2f" % [snappedLength, stepLength, jagged, boltWidth, boltColor.to_html(), taper, branches]
	if not meshCache.has(key):
		meshCache[key] = []
	var variants : Array = meshCache[key]
	if variants.size() < MESH_VARIANTS:
		var mesh : ArrayMesh = build_bolt_mesh(snappedLength, stepLength, jagged, boltWidth, boltColor, taper, branches)
		variants.append(mesh)
		return mesh
	return variants.pick_random()

static func build_bolt_mesh(length : float, stepLength : float, jagged : float, boltWidth : float, boltColor : Color, taper : float, branches : float) -> ArrayMesh:
	var meshPoints : PackedVector2Array = []
	var meshColors : PackedColorArray = []
	var meshIndices : PackedInt32Array = []
	var bolt : PackedVector2Array = create_bolt(Vector2.ZERO, Vector2(length, 0.0), stepLength, jagged)
	for j in range(2, bolt.size() - 2):
		if randf() < branches / bolt.size() * 4.0:
			var direction : Vector2 = Vector2.RIGHT.rotated(randf_range(-0.9, 0.9))
			add_layers(meshPoints, meshColors, meshIndices, create_bolt(bolt[j], bolt[j] + direction * randf_range(5.0, 11.0), 2.5, 2.5), boltWidth * 0.5, boltColor, 0.8, 1.0)
	add_layers(meshPoints, meshColors, meshIndices, bolt, boltWidth, boltColor, 1.0, taper)
	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = meshPoints
	arrays[Mesh.ARRAY_COLOR] = meshColors
	arrays[Mesh.ARRAY_INDEX] = meshIndices
	var mesh : ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func get_bolt_transform(from : Vector2, to : Vector2) -> Transform2D:
	var length : float = from.distance_to(to)
	return Transform2D(from.angle_to_point(to), Vector2(length / snap_length(length), 1.0), 0.0, from)

func _ready() -> void:
	build_bolts()

func _process(delta : float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	flickerTimer += delta
	if flickerTimer >= flickerTime:
		flickerTimer = 0.0
		build_bolts()
	var progress : float = minf(elapsed / duration, 1.0)
	flicker = 0.8 + 0.2 * sin(elapsed * 90.0)
	self_modulate.a = (1.0 - progress * progress) * flicker
	queue_redraw()

func _draw() -> void:
	var progress : float = minf(elapsed / duration, 1.0)
	var glowSize : float = endGlowSize * (0.6 + 0.4 * (1.0 - progress * progress))
	for point in points:
		draw_texture_rect(GLOW_TEXTURE, Rect2(point - Vector2.ONE * glowSize / 2.0, Vector2.ONE * glowSize), false, Color(color, 0.55 / flicker))
	for i in boltMeshes.size():
		draw_mesh(boltMeshes[i], null, boltTransforms[i])

func build_bolts() -> void:
	boltMeshes.clear()
	boltTransforms.clear()
	for i in points.size() - 1:
		boltMeshes.append(get_bolt_mesh(points[i].distance_to(points[i + 1]), segmentLength, jaggedness, width, color, 0.15, branchChance))
		boltTransforms.append(get_bolt_transform(points[i], points[i + 1]))
