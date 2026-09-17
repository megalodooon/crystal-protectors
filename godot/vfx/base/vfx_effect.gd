extends Node2D
class_name VfxEffectClass


@export var baseRadius : float = 20.0
@export var lifetime : float = 1.0
@export var shake : float = 0.0
@export var tinted : Array[CanvasItem]

var radius : float = 0.0
var color : Color = Color.WHITE

#------------------------#

func _ready() -> void:
	if radius > 0.0 and baseRadius > 0.0:
		scale = Vector2.ONE * radius / baseRadius
	for node in tinted:
		node.modulate = Color(color, node.modulate.a)
	if shake > 0.0:
		GameFeel.shake(shake)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
