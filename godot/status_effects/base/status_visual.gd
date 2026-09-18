extends Node2D
class_name StatusVisualClass


@export var fadeInTime : float = 0.1
@export var fadeOutTime : float = 0.35

@onready var loop : Node2D = get_node_or_null("Loop")
@onready var pulseNode : Node2D = get_node_or_null("Pulse")
@onready var burstNode : Node2D = get_node_or_null("Burst")

var strength : float = 0.0
var active : bool = true
var skipBurst : bool = false

#------------------------#

func _ready() -> void:
	if skipBurst and burstNode:
		for particles : CPUParticles2D in burstNode.find_children("*", "CPUParticles2D", true, false):
			particles.emitting = false

func _process(delta : float) -> void:
	if active:
		strength = move_toward(strength, 1.0, delta / maxf(fadeInTime, 0.01))
	else:
		strength = move_toward(strength, 0.0, delta / maxf(fadeOutTime, 0.01))
	if loop:
		loop.modulate.a = strength
	if active and strength >= 1.0:
		set_process(false)

func pulse() -> void:
	if not active or not pulseNode:
		return
	for particles : CPUParticles2D in pulseNode.find_children("*", "CPUParticles2D", true, false):
		particles.restart()

func stop() -> void:
	active = false
	set_process(true)
	if loop:
		for child in loop.find_children("*", "CPUParticles2D", true, false):
			child.emitting = false
