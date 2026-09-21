extends Node2D
class_name VfxTrailClass


@export var length : float = 0.15
@export var width : float = 1.5
@export var color : Color = Color.WHITE
@export var colorRamp : Gradient
@export var widthCurve : Curve
@export var fadePower : float = 1.5
@export var soft : bool = true
@export var maxPoints : int = 32
@export var emitting : bool = true

var points : PackedVector2Array = []
var times : PackedFloat32Array = []
var age : float = 0.0
var meshPoints : PackedVector2Array = []
var meshColors : PackedColorArray = []
var meshUvs : PackedVector2Array = []
var meshIndices : PackedInt32Array = []

#------------------------#

func _ready() -> void:
	clear()

func _physics_process(delta : float) -> void:
	age += delta
	if emitting:
		points.append(global_position)
		times.append(age)
		if points.size() > maxPoints:
			points = points.slice(1)
			times = times.slice(1)
	var expired : int = 0
	while expired < times.size() - 1 and age - times[expired] > length:
		expired += 1
	if expired > 0:
		points = points.slice(expired)
		times = times.slice(expired)
	queue_redraw()

func clear() -> void:
	points.clear()
	times.clear()
	points.append(global_position)
	times.append(age)

func is_faded() -> bool:
	return points.size() <= 1 or age - times[0] > length

func _draw() -> void:
	var count : int = points.size()
	if count < 2:
		return
	meshPoints.resize(count * 3)
	meshColors.resize(count * 3)
	meshUvs.resize(count * 3)
	meshIndices.resize((count - 1) * 12)
	var head : Vector2 = to_local(points[count - 1])
	for i in count:
		var k : int = count - 1 - i
		var spot : Vector2 = to_local(points[k])
		var t : float = clampf((age - times[k]) / length, 0.0, 1.0)
		var previous : Vector2 = to_local(points[mini(k + 1, count - 1)])
		var next : Vector2 = to_local(points[maxi(k - 1, 0)])
		var direction : Vector2 = previous - next
		if direction.length_squared() < 0.0001:
			direction = head - spot if i > 0 else Vector2.RIGHT
		var halfWidth : float = width * (widthCurve.sample(t) if widthCurve else 1.0 - t)
		var side : Vector2 = direction.normalized().orthogonal() * halfWidth
		var tint : Color = color * colorRamp.sample(t) if colorRamp else color
		var fade : Color = Color(tint, tint.a * pow(1.0 - t, fadePower))
		var edge : Color = Color(fade, 0.0) if soft else fade
		var v : int = i * 3
		meshPoints[v] = spot + side
		meshPoints[v + 1] = spot
		meshPoints[v + 2] = spot - side
		meshColors[v] = edge
		meshColors[v + 1] = fade
		meshColors[v + 2] = edge
		meshUvs[v] = Vector2(t, 0.0)
		meshUvs[v + 1] = Vector2(t, 0.5)
		meshUvs[v + 2] = Vector2(t, 1.0)
	for i in count - 1:
		var a : int = i * 3
		var b : int = a + 3
		var n : int = i * 12
		meshIndices[n] = a
		meshIndices[n + 1] = b
		meshIndices[n + 2] = b + 1
		meshIndices[n + 3] = a
		meshIndices[n + 4] = b + 1
		meshIndices[n + 5] = a + 1
		meshIndices[n + 6] = a + 2
		meshIndices[n + 7] = b + 2
		meshIndices[n + 8] = b + 1
		meshIndices[n + 9] = a + 2
		meshIndices[n + 10] = b + 1
		meshIndices[n + 11] = a + 1
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), meshIndices, meshPoints, meshColors, meshUvs)
