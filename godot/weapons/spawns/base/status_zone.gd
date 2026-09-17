extends Node2D
class_name StatusZoneClass


@export var baseRadius : float = 28.0
@export var duration : float = 3.0
@export var tickInterval : float = 0.5
@export var fadeTime : float = 0.5

@onready var detectorShape : CollisionShape2D = $Detector/CollisionShape2D
@onready var detector : Area2D = $Detector
@onready var visuals : Node2D = $Visuals

var radius : float = 28.0
var status : StatusEffectClass
var age : float = 0.0
var tickTimer : float = 0.0

#------------------------#

func _ready() -> void:
	var shape : CircleShape2D = detectorShape.shape
	shape.radius = radius
	visuals.scale = Vector2.ONE * radius / baseRadius
	modulate.a = 0.0

func _process(delta : float) -> void:
	age += delta
	var fadeIn : float = clampf(age / 0.2, 0.0, 1.0)
	var fadeOut : float = clampf((duration + fadeTime - age) / fadeTime, 0.0, 1.0)
	modulate.a = minf(fadeIn, fadeOut)
	if age >= duration:
		for child in visuals.find_children("*", "CPUParticles2D", true, false):
			child.emitting = false
	if age >= duration + fadeTime + 0.5:
		queue_free()

func _physics_process(delta : float) -> void:
	if age >= duration or not status:
		return
	tickTimer += delta
	if tickTimer < tickInterval:
		return
	tickTimer -= tickInterval
	for area in detector.get_overlapping_areas():
		var hurtbox : HurtboxComponentClass = area as HurtboxComponentClass
		if hurtbox:
			hurtbox.apply_status(status.duplicate())
