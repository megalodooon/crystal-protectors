extends Node2D
class_name LightningClass


@export var duration : float = 0.25
@export var segmentLength : float = 5.0
@export var jaggedness : float = 2.5
@export var width : float = 1.2
@export var flickerTime : float = 0.05

var points : PackedVector2Array = []
var color : Color = Color.WHITE
var elapsed : float = 0.0
var flickerTimer : float = 0.0
var bolts : Array[PackedVector2Array] = []

#------------------------#

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
	queue_redraw()

func _draw() -> void:
	var fade : float = 1.0 - minf(elapsed / duration, 1.0)
	for point in points:
		draw_circle(point, 1.0 + 3.0 * fade, Color(color, fade * 0.35))
	for bolt in bolts:
		draw_polyline(bolt, Color(color, fade * 0.4), width * 3.0)
		draw_polyline(bolt, Color(color.lerp(Color.WHITE, 0.3), fade), width)
		draw_polyline(bolt, Color(1.0, 1.0, 1.0, fade), width * 0.4)

func build_bolts() -> void:
	bolts.clear()
	for i in points.size() - 1:
		bolts.append(get_bolt(points[i], points[i + 1]))

func get_bolt(from : Vector2, to : Vector2) -> PackedVector2Array:
	var bolt : PackedVector2Array = [from]
	var segments : int = maxi(ceili(from.distance_to(to) / segmentLength), 2)
	var side : Vector2 = from.direction_to(to).orthogonal()
	for i in range(1, segments):
		bolt.append(from.lerp(to, float(i) / segments) + side * randf_range(-jaggedness, jaggedness))
	bolt.append(to)
	return bolt
