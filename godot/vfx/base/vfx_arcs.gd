extends Node2D
class_name VfxArcsClass


@export var count : int = 6
@export var innerRadius : float = 2.0
@export var outerRadius : float = 18.0
@export var duration : float = 0.35
@export var delay : float = 0.0
@export var flickerTime : float = 0.04
@export var width : float = 1.0
@export var color : Color = Color(1.0, 0.9, 0.4)
@export var loop : bool = false

var elapsed : float = 0.0
var flickerTimer : float = 0.0
var bolts : Array[PackedVector2Array] = []

#------------------------#

func _ready() -> void:
	build_bolts()

func _process(delta : float) -> void:
	elapsed += delta
	if loop and elapsed > delay + duration:
		elapsed -= duration
	flickerTimer += delta
	if flickerTimer >= flickerTime:
		flickerTimer = 0.0
		build_bolts()
	queue_redraw()

func _draw() -> void:
	var progress : float = (elapsed - delay) / duration
	if progress < 0.0 or progress > 1.0:
		return
	var fade : float = 1.0 - progress
	for bolt in bolts:
		draw_polyline(bolt, Color(color, fade * 0.3), width * 3.0)
		draw_polyline(bolt, Color(color.lerp(Color.WHITE, 0.3), fade), width)
		draw_polyline(bolt, Color(1.0, 1.0, 1.0, fade * 0.9), width * 0.4)

func build_bolts() -> void:
	bolts.clear()
	var progress : float = clampf((elapsed - delay) / duration, 0.0, 1.0)
	var reach : float = lerpf(innerRadius, outerRadius, minf(progress * 2.5 + 0.3, 1.0))
	for i in count:
		var direction : Vector2 = Vector2.from_angle(TAU * i / maxi(count, 1) + randf_range(-0.35, 0.35))
		bolts.append(LightningClass.create_bolt(direction * innerRadius, direction * reach * randf_range(0.7, 1.0), 3.0, 1.8))
