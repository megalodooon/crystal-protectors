extends Node2D
class_name VfxArcsClass


@export var count : int = 6
@export var innerRadius : float = 2.0
@export var outerRadius : float = 18.0
@export var duration : float = 0.35
@export var delay : float = 0.0
@export var flickerTime : float = 0.06
@export var width : float = 1.0
@export var color : Color = Color(1.0, 0.9, 0.4)
@export var loop : bool = false

var elapsed : float = 0.0
var flickerTimer : float = 0.0
var boltMeshes : Array[ArrayMesh] = []
var boltTransforms : Array[Transform2D] = []

#------------------------#

func _ready() -> void:
	build_bolts()
	update_fade()

func restart() -> void:
	elapsed = 0.0
	flickerTimer = 0.0
	build_bolts()
	update_fade()

func _process(delta : float) -> void:
	elapsed += delta
	if loop and elapsed > delay + duration:
		elapsed -= duration
	flickerTimer += delta
	if flickerTimer >= flickerTime:
		flickerTimer = 0.0
		build_bolts()
	update_fade()

func _draw() -> void:
	for i in boltMeshes.size():
		draw_mesh(boltMeshes[i], null, boltTransforms[i])

func update_fade() -> void:
	var progress : float = (elapsed - delay) / duration
	if progress < 0.0 or progress > 1.0:
		self_modulate.a = 0.0
	else:
		self_modulate.a = 1.0 - progress * progress

func build_bolts() -> void:
	boltMeshes.clear()
	boltTransforms.clear()
	var progress : float = clampf((elapsed - delay) / duration, 0.0, 1.0)
	var reach : float = lerpf(innerRadius, outerRadius, minf(progress * 2.5 + 0.3, 1.0))
	for i in count:
		var direction : Vector2 = Vector2.from_angle(TAU * i / maxi(count, 1) + randf_range(-0.35, 0.35))
		var from : Vector2 = direction * innerRadius
		var to : Vector2 = direction * reach * randf_range(0.7, 1.0)
		if from.distance_to(to) < 0.5:
			continue
		boltMeshes.append(LightningClass.get_bolt_mesh(from.distance_to(to), 2.0, 2.5, width * 0.7, color, 0.9))
		boltTransforms.append(LightningClass.get_bolt_transform(from, to))
	queue_redraw()
