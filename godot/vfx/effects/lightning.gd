extends Node2D
class_name LightningClass


@export var duration : float = 0.3
@export var segmentLength : float = 4.0
@export var jaggedness : float = 2.5
@export var width : float = 1.4
@export var flickerTime : float = 0.045
@export_range(0.0, 1.0) var branchChance : float = 0.3

var points : PackedVector2Array = []
var color : Color = Color.WHITE
var elapsed : float = 0.0
var flickerTimer : float = 0.0
var bolts : Array[PackedVector2Array] = []
var branches : Array[PackedVector2Array] = []

#------------------------#

static func create_bolt(from : Vector2, to : Vector2, stepLength : float, jagged : float) -> PackedVector2Array:
	var bolt : PackedVector2Array = [from]
	var segments : int = maxi(ceili(from.distance_to(to) / stepLength), 2)
	var side : Vector2 = from.direction_to(to).orthogonal()
	for i in range(1, segments):
		bolt.append(from.lerp(to, float(i) / segments) + side * randf_range(-jagged, jagged))
	bolt.append(to)
	return bolt

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
	var flicker : float = randf_range(0.75, 1.0)
	for point in points:
		draw_circle(point, 2.5 + 5.0 * fade, Color(color, fade * 0.18))
		draw_circle(point, 1.0 + 2.0 * fade, Color(color.lerp(Color.WHITE, 0.5), fade * 0.6))
	for branch in branches:
		draw_polyline(branch, Color(color, fade * 0.35 * flicker), width * 1.6)
		draw_polyline(branch, Color(color.lerp(Color.WHITE, 0.4), fade * flicker), width * 0.5)
	for bolt in bolts:
		draw_polyline(bolt, Color(color, fade * 0.14), width * 6.0)
		draw_polyline(bolt, Color(color, fade * 0.45 * flicker), width * 2.6)
		draw_polyline(bolt, Color(color.lerp(Color.WHITE, 0.35), fade * flicker), width)
		draw_polyline(bolt, Color(1.0, 1.0, 1.0, fade), width * 0.45)

func build_bolts() -> void:
	bolts.clear()
	branches.clear()
	for i in points.size() - 1:
		var bolt : PackedVector2Array = create_bolt(points[i], points[i + 1], segmentLength, jaggedness)
		bolts.append(bolt)
		for j in range(1, bolt.size() - 1):
			if randf() < branchChance:
				var direction : Vector2 = points[i].direction_to(points[i + 1]).rotated(randf_range(-1.1, 1.1))
				branches.append(create_bolt(bolt[j], bolt[j] + direction * randf_range(4.0, 9.0), 3.0, 1.5))
