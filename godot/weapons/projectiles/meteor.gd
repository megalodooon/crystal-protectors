extends Node2D
class_name MeteorClass


@export var fallTime : float = 0.45
@export var startOffset : Vector2 = Vector2(-40.0, -110.0)
@export var impactScene : PackedScene

@onready var rock : Node2D = $Rock
@onready var marker : Node2D = $Marker

var radius : float = 22.0
var delay : float = 0.0
var onImpact : Callable
var elapsed : float = 0.0
var landed : bool = false

#------------------------#

func _ready() -> void:
	elapsed = -delay
	rock.visible = false
	marker.visible = false
	rock.position = startOffset
	rock.rotation = startOffset.angle() + PI
	marker.scale = Vector2(radius / 20.0, radius / 20.0 * 0.4)
	marker.modulate.a = 0.0

func _physics_process(delta : float) -> void:
	if landed:
		return
	elapsed += delta
	if elapsed < 0.0:
		return
	var progress : float = clampf(elapsed / fallTime, 0.0, 1.0)
	rock.visible = true
	marker.visible = true
	rock.position = startOffset * (1.0 - progress * progress)
	marker.modulate.a = progress
	if progress >= 1.0:
		land()

func land() -> void:
	landed = true
	marker.visible = false
	rock.visible = false
	for child in rock.find_children("*", "CPUParticles2D", true, false):
		child.emitting = false
	if onImpact.is_valid():
		onImpact.call(global_position)
	Vfx.spawn_effect(impactScene, global_position, radius)
	get_tree().create_timer(0.6).timeout.connect(queue_free)
