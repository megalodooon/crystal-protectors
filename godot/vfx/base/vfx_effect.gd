extends Node2D
class_name VfxEffectClass


signal finished(effect : VfxEffectClass)

@export var baseRadius : float = 20.0
@export var lifetime : float = 1.0
@export var shake : float = 0.0
@export var tinted : Array[CanvasItem]

var radius : float = 0.0
var color : Color = Color.WHITE
var pooled : bool = false
var startScale : Vector2
var playId : int = 0

#------------------------#

func _ready() -> void:
	startScale = scale
	if not pooled:
		play()

func play(shakes : bool = true) -> void:
	playId += 1
	scale = startScale
	if radius > 0.0 and baseRadius > 0.0:
		scale = Vector2.ONE * radius / baseRadius
	for node in tinted:
		node.modulate = Color(color, node.modulate.a)
	if shake > 0.0 and shakes:
		GameFeel.shake(shake)
	if pooled:
		restart_parts(self)
	get_tree().create_timer(lifetime).timeout.connect(finish.bind(playId))

func finish(id : int) -> void:
	if id != playId:
		return
	if pooled:
		finished.emit(self)
	else:
		queue_free()

func restart_parts(node : Node) -> void:
	for child in node.get_children():
		if child.has_method("restart"):
			child.restart()
		var animation : AnimationPlayer = child as AnimationPlayer
		if animation and animation.autoplay != &"":
			animation.stop()
			animation.play(animation.autoplay)
		restart_parts(child)
