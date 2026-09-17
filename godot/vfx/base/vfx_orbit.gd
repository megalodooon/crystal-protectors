extends Node2D
class_name VfxOrbitClass


enum Shape { STAR, SHARD }

@export var shape : Shape = Shape.STAR
@export var count : int = 3
@export var orbitSize : Vector2 = Vector2(7.0, 2.5)
@export var speed : float = 5.0
@export var size : float = 2.2
@export var color : Color = Color(1.0, 0.9, 0.35)
@export var twinkleSpeed : float = 9.0

var elapsed : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var items : Array[Vector3] = []
	for i in count:
		var angle : float = elapsed * speed + TAU * i / maxi(count, 1)
		items.append(Vector3(cos(angle) * orbitSize.x, sin(angle) * orbitSize.y, angle))
	items.sort_custom(func(a : Vector3, b : Vector3) -> bool: return sin(a.z) < sin(b.z))
	for i in items.size():
		var item : Vector3 = items[i]
		var depth : float = (sin(item.z) + 1.0) * 0.5
		var twinkle : float = 0.85 + 0.15 * sin(elapsed * twinkleSpeed + i * 2.1)
		var itemSize : float = size * lerpf(0.65, 1.15, depth) * twinkle
		var alpha : float = lerpf(0.55, 1.0, depth)
		if shape == Shape.STAR:
			draw_star(Vector2(item.x, item.y), itemSize, alpha)
		else:
			draw_shard(Vector2(item.x, item.y), item.z + PI / 2.0 + elapsed * 4.0, itemSize, alpha)

func draw_star(center : Vector2, starSize : float, alpha : float) -> void:
	draw_circle(center, starSize * 1.2, Color(color, alpha * 0.1))
	draw_circle(center, starSize * 0.7, Color(color, alpha * 0.18))
	var points : PackedVector2Array = []
	for i in 8:
		var pointLength : float = starSize if i % 2 == 0 else starSize * 0.32
		points.append(center + Vector2.from_angle(TAU * i / 8.0 - PI / 2.0) * pointLength)
	draw_colored_polygon(points, Color(color.lerp(Color.WHITE, 0.25), alpha))
	draw_circle(center, starSize * 0.28, Color(1.0, 1.0, 1.0, alpha))

func draw_shard(center : Vector2, angle : float, shardSize : float, alpha : float) -> void:
	var along : Vector2 = Vector2.from_angle(angle)
	var side : Vector2 = along.orthogonal()
	draw_colored_polygon(PackedVector2Array([center + along * shardSize, center + side * shardSize * 0.45, center - along * shardSize * 0.7, center - side * shardSize * 0.35]), Color(color, alpha))
	draw_line(center - along * shardSize * 0.4, center + along * shardSize * 0.7, Color(1.0, 0.95, 0.85, alpha), 0.5, true)
