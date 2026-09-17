extends Node2D
class_name StatusVisualClass


@export var fadeInTime : float = 0.1
@export var fadeOutTime : float = 0.35

@onready var loop : Node2D = get_node_or_null("Loop")
@onready var pulseNode : Node2D = get_node_or_null("Pulse")

var strength : float = 0.0
var active : bool = true

#------------------------#

func _process(delta : float) -> void:
	if active:
		strength = move_toward(strength, 1.0, delta / maxf(fadeInTime, 0.01))
	else:
		strength = move_toward(strength, 0.0, delta / maxf(fadeOutTime, 0.01))
	if loop:
		loop.modulate.a = strength

func pulse() -> void:
	if not active or not pulseNode:
		return
	for particles : CPUParticles2D in pulseNode.find_children("*", "CPUParticles2D", true, false):
		particles.restart()

func stop() -> void:
	active = false
	if loop:
		for child in loop.find_children("*", "CPUParticles2D", true, false):
			child.emitting = false
