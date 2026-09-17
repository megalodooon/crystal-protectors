extends Node2D
class_name VfxReticleClass


const CORNERS : Array[Vector2] = [Vector2(1.0, 1.0), Vector2(-1.0, 1.0), Vector2(1.0, -1.0), Vector2(-1.0, -1.0)]

@export var radius : float = 9.0
@export var width : float = 1.0
@export var wobble : float = 2.0
@export var pulseSpeed : float = 6.0
@export var color : Color = Color(1.0, 0.2, 0.25)

var elapsed : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var pulse : float = 0.5 + 0.5 * sin(elapsed * pulseSpeed)
	var size : float = radius * (1.0 - pulse * 0.15)
	var arm : float = radius * 0.45
	draw_set_transform(Vector2.ZERO, sin(elapsed * wobble) * 0.15, Vector2.ONE)
	for corner in CORNERS:
		var tip : Vector2 = corner * size
		var bracket : PackedVector2Array = PackedVector2Array([tip - Vector2(corner.x * arm, 0.0), tip, tip - Vector2(0.0, corner.y * arm)])
		draw_polyline(bracket, Color(color, 0.3), width * 3.0, true)
		draw_polyline(bracket, Color(color.lerp(Color.WHITE, 0.35), 0.95), width, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 1.0 + pulse * 0.6, Color(color.lerp(Color.WHITE, 0.4), 0.9))
