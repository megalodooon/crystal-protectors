extends Node2D
class_name LightningClass


const GLOW_TEXTURE := preload("res://vfx/shared/soft_glow.tres")

@export var duration : float = 0.32
@export var segmentLength : float = 4.0
@export var jaggedness : float = 5.0
@export var width : float = 1.4
@export var flickerTime : float = 0.06
@export_range(0.0, 1.0) var branchChance : float = 0.35
@export var endGlowSize : float = 14.0

var points : PackedVector2Array = []
var color : Color = Color.WHITE
var elapsed : float = 0.0
var flickerTimer : float = 0.0
var bolts : Array[PackedVector2Array] = []
var branches : Array[PackedVector2Array] = []

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

static func draw_bolt(canvas : CanvasItem, bolt : PackedVector2Array, boltWidth : float, boltColor : Color, taper : float = 0.0) -> void:
	var count : int = bolt.size()
	if count < 2 or boltWidth <= 0.01 or boltColor.a <= 0.01:
		return
	var sides : PackedVector2Array = []
	for i in count:
		var direction : Vector2 = bolt[mini(i + 1, count - 1)] - bolt[maxi(i - 1, 0)]
		var progress : float = float(i) / (count - 1)
		sides.append(direction.normalized().orthogonal() * boltWidth * (1.0 - taper * progress))
	var edge : Color = Color(boltColor, 0.0)
	var edgeColors : PackedColorArray = [edge, edge, boltColor, boltColor]
	for i in count - 1:
		canvas.draw_primitive(PackedVector2Array([bolt[i] + sides[i], bolt[i + 1] + sides[i + 1], bolt[i + 1], bolt[i]]), edgeColors, PackedVector2Array())
		canvas.draw_primitive(PackedVector2Array([bolt[i] - sides[i], bolt[i + 1] - sides[i + 1], bolt[i + 1], bolt[i]]), edgeColors, PackedVector2Array())

static func draw_layers(canvas : CanvasItem, bolt : PackedVector2Array, boltWidth : float, boltColor : Color, alpha : float, taper : float = 0.0) -> void:
	draw_bolt(canvas, bolt, boltWidth * 3.5, Color(boltColor, alpha * 0.25), taper)
	draw_bolt(canvas, bolt, boltWidth * 1.3, Color(boltColor.lerp(Color.WHITE, 0.25), alpha * 0.85), taper)
	draw_bolt(canvas, bolt, boltWidth * 0.55, Color(1.0, 1.0, 1.0, alpha), taper)

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
	var progress : float = minf(elapsed / duration, 1.0)
	var fade : float = 1.0 - progress * progress
	var flicker : float = 0.8 + 0.2 * sin(elapsed * 90.0)
	for point in points:
		var glowSize : float = endGlowSize * (0.6 + 0.4 * fade)
		draw_texture_rect(GLOW_TEXTURE, Rect2(point - Vector2.ONE * glowSize / 2.0, Vector2.ONE * glowSize), false, Color(color, fade * 0.55))
	for branch in branches:
		draw_layers(self, branch, width * 0.5, color, fade * flicker * 0.8, 1.0)
	for bolt in bolts:
		draw_layers(self, bolt, width, color, fade * flicker, 0.15)

func build_bolts() -> void:
	bolts.clear()
	branches.clear()
	for i in points.size() - 1:
		var bolt : PackedVector2Array = create_bolt(points[i], points[i + 1], segmentLength, jaggedness)
		bolts.append(bolt)
		for j in range(2, bolt.size() - 2):
			if randf() < branchChance / bolt.size() * 4.0:
				var direction : Vector2 = points[i].direction_to(points[i + 1]).rotated(randf_range(-0.9, 0.9))
				branches.append(create_bolt(bolt[j], bolt[j] + direction * randf_range(5.0, 11.0), 2.5, 2.5))
