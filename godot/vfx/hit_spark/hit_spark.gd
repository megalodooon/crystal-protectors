extends Node2D
class_name HitSparkClass


@export var duration : float = 0.25
@export var spikeLength : float = 9.0
@export var spikeWidth : float = 1.2

@onready var flash : Sprite2D = $Flash
@onready var sparks : CPUParticles2D = $Sparks
@onready var orbs : CPUParticles2D = $Orbs

var color : Color = Color.WHITE
var strength : float = 1.0
var sparkAmount : int = 6
var orbAmount : int = 0
var angle : float = 0.0
var elapsed : float = 0.0
var spikes : Array[Vector3] = []

#------------------------#

func _ready() -> void:
	scale = Vector2.ONE * strength
	spikes.append(Vector3(angle, 1.6, 1.0))
	spikes.append(Vector3(angle + PI, 1.6, 1.0))
	for i in randi_range(4, 7):
		spikes.append(Vector3(randf() * TAU, randf_range(0.35, 0.9), randf_range(0.5, 0.9)))
	sparks.amount = maxi(sparkAmount, 1)
	sparks.color = color
	sparks.emitting = true
	if orbAmount > 0:
		orbs.amount = orbAmount
		orbs.color = color.lightened(0.3)
		orbs.emitting = true
	get_tree().create_timer(maxf(duration, orbs.lifetime) + 0.1).timeout.connect(queue_free)

func _process(delta : float) -> void:
	elapsed += delta
	var progress : float = minf(elapsed / duration, 1.0)
	flash.scale = Vector2.ONE * (0.4 + progress * 0.6)
	flash.modulate = Color(color, (1.0 - progress) * 0.8)
	queue_redraw()

func _draw() -> void:
	var progress : float = minf(elapsed / duration, 1.0)
	var grow : float = 1.0 - pow(1.0 - minf(progress * 4.0, 1.0), 3.0)
	var fade : float = 1.0 - progress
	for spike in spikes:
		draw_spike(spike, grow, fade, Color(color, fade * 0.9), 2.0)
	for spike in spikes:
		draw_spike(spike, grow, fade, Color(1.0, 1.0, 1.0, fade), 0.7)

func draw_spike(spike : Vector3, grow : float, fade : float, spikeColor : Color, widthScale : float) -> void:
	var direction : Vector2 = Vector2.from_angle(spike.x)
	var length : float = spikeLength * spike.y * grow
	var width : float = spikeWidth * spike.z * widthScale * fade
	if length < 0.2 or width < 0.05:
		return
	var side : Vector2 = direction.orthogonal() * width
	draw_colored_polygon(PackedVector2Array([side, direction * length, -side, -direction * width * 2.0]), spikeColor)
